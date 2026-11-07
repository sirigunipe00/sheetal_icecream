import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sheetal_icecream/core/widgets/product_asset_registry.dart';
import 'package:sheetal_icecream/data/catalog/catalogue_menus.dart';
import 'package:sheetal_icecream/data/models/product.dart';
import 'package:sheetal_icecream/services/supabase_service.dart';

class CategorySegment {
  const CategorySegment({
    required this.name,
    required this.categoryNames,
  });

  final String name;
  final List<String> categoryNames;
}

class CatalogUnavailable implements Exception {
  const CatalogUnavailable(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class CatalogRepository {
  const CatalogRepository();

  List<Product> get products;

  List<String> get categories;

  List<CategorySegment> get segments;

  Map<String, String> get categoryImages;

  Product? productById(int id);

  Future<void> refresh();
}

class SupabaseCatalogRepository extends CatalogRepository {
  List<Product> _products = const [];
  List<String> _categories = const ['All'];
  List<CategorySegment> _segments = const [];
  Map<String, String> _categoryImages = const {};

  @override
  List<Product> get products => _products;

  @override
  List<String> get categories => _categories;

  @override
  List<CategorySegment> get segments => _segments;

  @override
  Map<String, String> get categoryImages => _categoryImages;

  @override
  Product? productById(int id) {
    for (final product in _products) {
      if (product.id == id) return product;
    }
    return null;
  }

  @override
  Future<void> refresh() async {
    if (!SupabaseGate.ready) {
      throw StateError('Supabase is not initialized');
    }

    final client = Supabase.instance.client;

    try {
      await _loadRelational(client);
      return;
    } on PostgrestException catch (error) {
      if (!_isMissingSchema(error)) rethrow;
      debugPrint('[Catalog] Relational schema is not installed ($error). Trying products.');
    }

    try {
      await _loadFlat(client);
    } on PostgrestException catch (error) {
      if (_isMissingSchema(error)) {
        throw const CatalogUnavailable(
          'Supabase is connected, but the Sheetal tables are not created yet. '
          'In the SQL editor, run supabase/migrations/20261016120000_init_schema.sql '
          'and then supabase/seed.sql.',
        );
      }
      rethrow;
    }
  }

  bool _isMissingSchema(PostgrestException error) {
    return error.code == 'PGRST205' ||
        error.code == 'PGRST200' ||
        error.code == '42703' ||
        error.message.contains('schema cache') ||
        error.message.contains('does not exist');
  }

  Future<void> _loadRelational(SupabaseClient client) async {
    final categoryRows = await client
        .from('categories')
        .select('name, image_path, sort_order, segments(name, sort_order)')
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    final productRows = await client
        .from('products')
        .select(
          'id, legacy_key, name, description, image_path, is_new, best_seller_rank, '
          'categories(name), '
          'product_variants(id, label, price, units_per_pack, sort_order, is_active)',
        )
        .eq('is_active', true)
        .isFilter('archived_at', null)
        .order('id', ascending: true);

    final images = <String, String>{};
    final names = <String>[];
    final grouped = <String, List<String>>{};
    final segmentSort = <String, int>{};

    for (final row in categoryRows) {
      final name = row['name'] as String?;
      if (name == null || name.isEmpty) continue;
      names.add(name);
      final image = _publicImage(client, row['image_path'] as String?);
      if (image != null) images[name] = image;

      final segment = row['segments'];
      final segmentName = segment is Map && segment['name'] is String
          ? segment['name'] as String
          : 'Other';
      final sort = segment is Map ? _money(segment['sort_order']) : 0;
      segmentSort[segmentName] = sort;
      grouped.putIfAbsent(segmentName, () => []).add(name);
    }

    final segmentNames = grouped.keys.toList()
      ..sort((a, b) => (segmentSort[a] ?? 0).compareTo(segmentSort[b] ?? 0));

    final products = <Product>[];
    for (final row in productRows) {
      final product = _productFromRow(client, row);
      if (product != null) products.add(product);
    }

    _categories = ['All', ...names];
    _categoryImages = images;
    _segments = [
      for (final name in segmentNames)
        CategorySegment(name: name, categoryNames: grouped[name]!),
    ];
    _products = products;
    if (products.isEmpty) {
      throw const CatalogUnavailable(
        'The products table is empty. Run supabase/seed.sql in the SQL editor, '
        'and upload the pictures to the product-images storage bucket.',
      );
    }
    debugPrint('[Catalog] Loaded ${products.length} products from Supabase');
  }

  Future<void> _loadFlat(SupabaseClient client) async {
    // Flat Sheetal schema: id, name, price, image_url, category, unit,
    // description, is_new, is_active + product_variants embed.
    // Do not request legacy_key / best_seller_rank (those are relational-only).
    final selectAttempts = <String>[
      'id, name, price, image_url, category, unit, description, is_new, is_active, '
          'product_variants(id, label, price, sort_order, is_active)',
      'id, name, price, image_url, category, unit, description, is_new, '
          'product_variants(id, label, price, sort_order, is_active)',
      '*',
    ];

    List<dynamic>? rows;
    Object? lastError;
    for (final select in selectAttempts) {
      try {
        rows = await client
            .from('products')
            .select(select)
            .order('id', ascending: true);
        break;
      } on PostgrestException catch (error) {
        lastError = error;
        if (!_isMissingSchema(error)) rethrow;
        debugPrint('[Catalog] Flat select failed ($select): $error');
      }
    }
    if (rows == null) {
      throw lastError ??
          const CatalogUnavailable('Could not load products from Supabase.');
    }

    final variantsByProduct = await _loadVariantsByProduct(client, rows);

    final products = <Product>[];
    final names = <String>[];
    final images = <String, String>{};

    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw as Map);
      if (row['is_active'] == false) continue;

      final category = _categoryName(row['category'] ?? row['category_id']);
      if (category != 'All' && !names.contains(category)) names.add(category);
      final name = (row['name'] as String?) ?? '';
      final image = _productImage(
        client,
        path: _storedImagePath(row),
        directUrl: _directImageUrl(row),
        name: name,
        category: category,
        legacyKey: row['legacy_key'] as String?,
      );
      if (image != null && category != 'All') {
        images.putIfAbsent(category, () => image);
      }

      final productId = _money(row['id']);
      final embedded = _variantsFromFlatRow(row);
      final variants = embedded.isNotEmpty
          ? embedded
          : (variantsByProduct[productId] ?? const <ProductVariant>[]);
      final primary = variants.isNotEmpty ? variants.first : null;

      products.add(
        Product(
          id: _money(row['id']),
          name: name,
          unit: primary?.label ?? (row['unit'] as String?) ?? 'Regular pack',
          price: primary?.price ?? _money(row['price']),
          category: category,
          image: image,
          description: row['description'] as String?,
          isNew: row['is_new'] == true,
          key: row['legacy_key'] as String?,
          bestSellerRank: row['best_seller_rank'] == null
              ? null
              : _money(row['best_seller_rank']),
          variants: variants,
        ),
      );
    }

    _categories = ['All', ...names];
    _categoryImages = images;
    final menus = CatalogueMenus.menusWithProducts(names);
    _segments = [
      for (final menu in menus)
        CategorySegment(name: menu.menu, categoryNames: menu.categories),
    ];
    _products = products;
    if (products.isEmpty) {
      throw const CatalogUnavailable(
        'The products table is empty. Run supabase/seed.sql in the SQL editor, '
        'and upload the pictures to the product-images storage bucket.',
      );
    }
    debugPrint(
      '[Catalog] Loaded ${products.length} active products '
      '(${products.where((p) => p.hasVariants).length} with size variants)',
    );
  }

  List<ProductVariant> _variantsFromFlatRow(Map<String, dynamic> row) {
    final raw = row['product_variants'];
    if (raw is! List || raw.isEmpty) return const [];
    return _parseVariantList(raw);
  }

  Future<Map<int, List<ProductVariant>>> _loadVariantsByProduct(
    SupabaseClient client,
    List<dynamic> productRows,
  ) async {
    final alreadyEmbedded = productRows.any(
      (row) => row is Map && row['product_variants'] is List,
    );
    if (alreadyEmbedded) return const {};

    try {
      final data = await client
          .from('product_variants')
          .select('id, product_id, label, price, sort_order, is_active')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final map = <int, List<ProductVariant>>{};
      for (final item in data as List) {
        if (item is! Map) continue;
        if (item['is_active'] == false) continue;
        final label = (item['label'] as String?)?.toLowerCase() ?? '';
        if (label.contains('pack of 4')) continue;
        final productId = _money(item['product_id']);
        map.putIfAbsent(productId, () => []).add(
              ProductVariant(
                id: _money(item['id']),
                label: (item['label'] as String?) ?? 'Regular pack',
                price: _money(item['price']),
                unitsPerPack: 1,
              ),
            );
      }
      return map;
    } on PostgrestException catch (error) {
      debugPrint('[Catalog] product_variants load skipped: $error');
      return const {};
    }
  }

  List<ProductVariant> _parseVariantList(List<dynamic> raw) {
    final ranked = <_RankedVariant>[];
    for (final item in raw) {
      if (item is! Map) continue;
      if (item['is_active'] == false) continue;
      ranked.add(
        _RankedVariant(
          variant: ProductVariant(
            id: _money(item['id']),
            label: (item['label'] as String?) ?? 'Regular pack',
            price: _money(item['price']),
            unitsPerPack: 1,
          ),
          sortOrder: _money(item['sort_order']),
        ),
      );
    }
    ranked.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return [for (final item in ranked) item.variant];
  }

  String _categoryName(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return 'All';
  }

  String? _storedImagePath(Map<String, dynamic> row) {
    final path = row['image_path'] ?? row['image_url'] ?? row['image'];
    if (path is! String || path.startsWith('http')) return null;
    return path;
  }

  String? _directImageUrl(Map<String, dynamic> row) {
    final direct = row['image_url'] ?? row['image'];
    if (direct is String && direct.startsWith('http')) return direct;
    final path = row['image_path'];
    if (path is String && path.startsWith('http')) return path;
    return null;
  }

  String? _bundledProductImage({
    required String name,
    required String category,
    String? legacyKey,
  }) {
    const byKey = {
      '13|Kesar': 'assets/images/Kesar_New-337x1024.png',
      '13|Kulfi': 'assets/images/Kulfi-_-New--337x1024.png',
      '7|Nutty Roll Cut': 'assets/images/Nutty-Roll-Cut.png',
      '7|Cookies Sandwich': 'assets/images/Cookies-Sandwich.png',
      '7|Sandwich Ice Cream': 'assets/images/Sandwich-Ice-Cream.png',
      '6|Kesar': 'assets/images/Cone-Kesar.png',
      '6|Kesar Pista': 'assets/images/Cone-Kesar-Pista.png',
      '6|Butterscotch Waffle Cone': 'assets/images/Cone-Nutty-Butterscotch.png',
      '6|Salted Caramel': 'assets/images/Cone-Salted-Caramel.png',
      '2|Butterscotch': 'assets/images/Big-Cup-Butterscotch.png',
      '2|Kaju Draksh': 'assets/images/Big-Cup-Kaju-Draksh.png',
      '2|Sugar Free': 'assets/images/Big-Cup-Sugar-Free-Vanilla.png',
      '2|Sugar Free Kesar Pista': 'assets/images/Big-Cup-Sugar-Free-Kesar-Pista.png',
      '4|Jamun': 'assets/images/Kulfi-Jamun.png',
      '5|Alphonso Mango': 'assets/images/Candy-Alphonso-Mango.png',
      '5|Rajbhog': 'assets/images/Candy-Rajbhog.png',
    };
    final keyed = byKey[legacyKey];
    if (keyed != null) return keyed;

    final resolved = resolveBundledAsset('$category-$name') ??
        resolveBundledAsset('$category-${name.replaceFirst(RegExp(r'\s*\([^)]*\)\s*$'), '')}') ??
        resolveBundledAsset(name);
    if (resolved != null) return resolved;

    final normalized = category.trim().toLowerCase();
    final productName = name.trim();
    if (normalized == 'flavoured milk' || normalized == 'flavoured-milk') {
      return switch (productName) {
        'Kesar' => 'assets/images/Kesar_New-337x1024.png',
        'Kulfi' => 'assets/images/Kulfi-_-New--337x1024.png',
        _ => null,
      };
    }
    if (normalized == 'novelties' || normalized == 'novelty') {
      return switch (productName) {
        'Nutty Roll Cut' => 'assets/images/Nutty-Roll-Cut.png',
        'Cookies Sandwich' => 'assets/images/Cookies-Sandwich.png',
        'Sandwich Ice Cream' => 'assets/images/Sandwich-Ice-Cream.png',
        _ => null,
      };
    }
    if (normalized == 'cones' || normalized == 'cone') {
      return switch (productName) {
        'Cones Kesar' => 'assets/images/Cone-Kesar.png',
        'Cones Kesar Pista' => 'assets/images/Cone-Kesar-Pista.png',
        'Butterscotch Waffle Cone' => 'assets/images/Cone-Nutty-Butterscotch.png',
        'Cones Salted Caramel' => 'assets/images/Cone-Salted-Caramel.png',
        _ => null,
      };
    }
    if (normalized == 'big cup' || normalized == 'big-cup') {
      return switch (productName) {
        'Big Cup Butterscotch' => 'assets/images/Big-Cup-Butterscotch.png',
        'Big Cup Kaju Draksh' => 'assets/images/Big-Cup-Kaju-Draksh.png',
        'Big Cup Sugar Free' => 'assets/images/Big-Cup-Sugar-Free-Vanilla.png',
        'Big Cup Sugar Free Kesar Pista' =>
          'assets/images/Big-Cup-Sugar-Free-Kesar-Pista.png',
        _ => null,
      };
    }
    if (normalized == 'kulfi' && productName == 'Kulfi Jamun') {
      return 'assets/images/Kulfi-Jamun.png';
    }
    if (normalized == 'candy') {
      return switch (productName) {
        'Candy Alphonso Mango' => 'assets/images/Candy-Alphonso-Mango.png',
        'Candy Rajbhog' => 'assets/images/Candy-Rajbhog.png',
        _ => null,
      };
    }
    return null;
  }

  String? _catalogueAsset({required String name, required String category}) {
    final plain = name.trim().replaceFirst(RegExp(r'\s*\([^)]*\)\s*$'), '').trim();
    final cat = category.trim();
    if (plain.isEmpty || cat.isEmpty || cat == 'All') return null;
    final resolved = resolveBundledAsset('$cat-$plain') ??
        resolveBundledAsset('$cat-$name') ??
        resolveBundledAsset(plain);
    if (resolved != null) return resolved;
    final slug = '$cat-$plain'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.isEmpty) return null;
    return 'assets/images/$slug.png';
  }

  String? _normalizedStorageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    // Files live in product-images/products/<file>, not products/products/.
    return url.replaceAll(
      '/storage/v1/object/public/product-images/products/products/',
      '/storage/v1/object/public/product-images/products/',
    );
  }

  String? _productImage(
    SupabaseClient client, {
    required String? path,
    required String? directUrl,
    required String name,
    required String category,
    String? legacyKey,
  }) {
    final storageUrl = _normalizedStorageUrl(directUrl);
    if (storageUrl != null) return storageUrl;

    final bundled = _bundledProductImage(
      name: name,
      category: category,
      legacyKey: legacyKey,
    );
    if (bundled != null) return bundled;

    final catalogue = _catalogueAsset(name: name, category: category);
    if (catalogue != null) return catalogue;

    final fromPath = _publicImage(client, path);
    return _normalizedStorageUrl(fromPath) ?? fromPath;
  }

  Product? _productFromRow(SupabaseClient client, Map<String, dynamic> row) {
    final rawVariants = row['product_variants'];
    final variants = <_RankedVariant>[];
    if (rawVariants is List) {
      for (final item in rawVariants) {
        if (item is! Map) continue;
        if (item['is_active'] == false) continue;
        final label = (item['label'] as String?)?.toLowerCase() ?? '';
        if (label.contains('pack of 4')) continue;
        variants.add(
          _RankedVariant(
            variant: ProductVariant(
              id: _money(item['id']),
              label: (item['label'] as String?) ?? 'Regular pack',
              price: _money(item['price']),
              unitsPerPack: _money(item['units_per_pack']).clamp(1, 100).toInt(),
            ),
            sortOrder: _money(item['sort_order']),
          ),
        );
      }
    }
    variants.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (variants.isEmpty) return null;

    final primary = variants
        .firstWhere(
          (variant) => variant.variant.unitsPerPack == 1,
          orElse: () => variants.first,
        )
        .variant;

    final category = row['categories'];
    final categoryName = category is Map && category['name'] is String
        ? category['name'] as String
        : 'All';
    final name = (row['name'] as String?) ?? '';

    return Product(
      id: _money(row['id']),
      name: name,
      unit: primary.label,
      price: primary.price,
      category: categoryName,
      image: _productImage(
        client,
        path: row['image_path'] as String?,
        directUrl: null,
        name: name,
        category: categoryName,
        legacyKey: row['legacy_key'] as String?,
      ),
      description: row['description'] as String?,
      isNew: row['is_new'] == true,
      key: row['legacy_key'] as String?,
      bestSellerRank: row['best_seller_rank'] == null
          ? null
          : _money(row['best_seller_rank']),
      variants: [for (final variant in variants) variant.variant],
    );
  }

  String? _publicImage(SupabaseClient client, String? path) {
    if (path == null || path.trim().isEmpty) return null;
    if (path.startsWith('http')) return path;
    final cleaned = path.startsWith('/') ? path.substring(1) : path;
    return client.storage.from('product-images').getPublicUrl(cleaned);
  }

  int _money(Object? value) {
    if (value is num) return value.round();
    return int.tryParse('$value') ?? 0;
  }
}

class _RankedVariant {
  const _RankedVariant({required this.variant, required this.sortOrder});

  final ProductVariant variant;
  final int sortOrder;
}
