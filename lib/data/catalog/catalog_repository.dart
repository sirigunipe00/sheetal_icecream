import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:blinkit_clone/data/models/product.dart';
import 'package:blinkit_clone/services/supabase_service.dart';

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

/// Catalog loaded from Supabase tables, with pictures from the
/// public `product-images` storage bucket.
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
        error.message.contains('schema cache');
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
    final rows = await client.from('products').select().order('id', ascending: true);
    final products = <Product>[];
    final names = <String>[];
    final images = <String, String>{};

    for (final row in rows) {
      final category = _categoryName(row['category'] ?? row['category_id']);
      if (category != 'All' && !names.contains(category)) names.add(category);
      final image = _flatImage(client, row);
      if (image != null && category != 'All') {
        images.putIfAbsent(category, () => image);
      }
      products.add(
        Product(
          id: _money(row['id']),
          name: (row['name'] as String?) ?? '',
          unit: (row['unit'] as String?) ?? 'Regular pack',
          price: _money(row['price']),
          category: category,
          image: image,
          description: row['description'] as String?,
          isNew: row['is_new'] == true,
          key: row['legacy_key'] as String?,
          bestSellerRank: row['best_seller_rank'] == null
              ? null
              : _money(row['best_seller_rank']),
        ),
      );
    }

    _categories = ['All', ...names];
    _categoryImages = images;
    _segments = names.isEmpty
        ? const []
        : [CategorySegment(name: 'Shop', categoryNames: names)];
    _products = products;
    if (products.isEmpty) {
      throw const CatalogUnavailable(
        'The products table is empty. Run supabase/seed.sql in the SQL editor, '
        'and upload the pictures to the product-images storage bucket.',
      );
    }
    debugPrint('[Catalog] Loaded ${products.length} products from the products table');
  }

  String _categoryName(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return 'All';
  }

  String? _flatImage(SupabaseClient client, Map<String, dynamic> row) {
    final direct = row['image_url'] ?? row['image'];
    if (direct is String && direct.startsWith('http')) return direct;
    final path = row['image_path'] ?? direct;
    return _publicImage(client, path is String ? path : null);
  }

  Product? _productFromRow(SupabaseClient client, Map<String, dynamic> row) {
    final rawVariants = row['product_variants'];
    final variants = <_RankedVariant>[];
    if (rawVariants is List) {
      for (final item in rawVariants) {
        if (item is! Map) continue;
        if (item['is_active'] == false) continue;
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

    return Product(
      id: _money(row['id']),
      name: (row['name'] as String?) ?? '',
      unit: primary.label,
      price: primary.price,
      category: categoryName,
      image: _publicImage(client, row['image_path'] as String?),
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
