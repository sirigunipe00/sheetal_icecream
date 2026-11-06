import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sheetal_icecream/services/supabase_service.dart';

class InventoryProduct {
  const InventoryProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.price,
    required this.stockQty,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String category;
  final String unit;
  final int price;
  final int stockQty;
  final String? imageUrl;

  InventoryProduct copyWith({int? price, int? stockQty}) {
    return InventoryProduct(
      id: id,
      name: name,
      category: category,
      unit: unit,
      price: price ?? this.price,
      stockQty: stockQty ?? this.stockQty,
      imageUrl: imageUrl,
    );
  }

  factory InventoryProduct.fromMap(Map<String, dynamic> map) {
    return InventoryProduct(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: (map['name'] as String?) ?? '',
      category: (map['category'] as String?) ?? '',
      unit: (map['unit'] as String?) ?? 'Regular pack',
      price: (map['price'] as num?)?.round() ?? 0,
      stockQty: (map['stock_qty'] as num?)?.toInt() ?? 0,
      imageUrl: map['image_url'] as String?,
    );
  }
}

class AdminRepository {
  AdminRepository();

  SupabaseClient get _client => Supabase.instance.client;

  Future<bool> amIAdmin() async {
    if (!SupabaseGate.ready || !SupabaseService.instance.isSignedIn) {
      return false;
    }
    try {
      final result = await _client.rpc('am_i_admin');
      return result == true;
    } catch (e) {
      debugPrint('[Admin] am_i_admin failed: $e');
      // Fallback: read profiles.role directly
      try {
        final row = await _client
            .from('profiles')
            .select('role')
            .eq('id', _client.auth.currentUser!.id)
            .maybeSingle();
        return row != null && row['role'] == 'admin';
      } catch (e2) {
        debugPrint('[Admin] profiles role check failed: $e2');
        return false;
      }
    }
  }

  Future<List<InventoryProduct>> fetchInventory({String query = ''}) async {
    final data = await _client
        .from('products')
        .select('id, name, category, unit, price, stock_qty, image_url, is_active')
        .order('name', ascending: true);
    final q = query.trim().toLowerCase();
    final items = <InventoryProduct>[];
    for (final row in data as List) {
      if (row is! Map) continue;
      if (row['is_active'] == false) continue;
      final item = InventoryProduct.fromMap(Map<String, dynamic>.from(row));
      if (q.isNotEmpty) {
        final hay = '${item.name} ${item.category} ${item.unit}'.toLowerCase();
        if (!hay.contains(q)) continue;
      }
      items.add(item);
    }
    return items;
  }

  Future<InventoryProduct> updateInventory({
    required int productId,
    required int price,
    required int stockQty,
  }) async {
    final row = await _client.rpc(
      'admin_update_inventory',
      params: {
        'p_product_id': productId,
        'p_price': price,
        'p_stock_qty': stockQty,
      },
    );
    return InventoryProduct.fromMap(Map<String, dynamic>.from(row as Map));
  }

  /// Uploads bytes to Storage bucket `product-images` under `products/`.
  /// Returns the public URL to store on `products.image_url`.
  Future<String> uploadProductImage({
    required String productName,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    String extension = 'jpg',
  }) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final slug = _slugify(productName);
    final path = 'products/$slug-$stamp.$extension';

    await _client.storage.from('product-images').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );

    return _client.storage.from('product-images').getPublicUrl(path);
  }

  Future<InventoryProduct> addProduct({
    required String name,
    required String category,
    required String unit,
    required int price,
    required int stockQty,
    required String imageUrl,
    String? description,
  }) async {
    if (imageUrl.trim().isEmpty) {
      throw StateError('Product image is required');
    }
    final row = await _client.rpc(
      'admin_add_product',
      params: {
        'p_name': name,
        'p_category': category,
        'p_unit': unit,
        'p_price': price,
        'p_stock_qty': stockQty,
        'p_image_url': imageUrl.trim(),
        'p_description': description,
      },
    );
    return InventoryProduct.fromMap(Map<String, dynamic>.from(row as Map));
  }

  String _slugify(String input) {
    final lower = input.toLowerCase().trim();
    final cleaned = lower
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (cleaned.isEmpty) return 'product';
    return cleaned.length > 40 ? cleaned.substring(0, 40) : cleaned;
  }

  Future<List<String>> fetchCategories() async {
    final data = await _client
        .from('products')
        .select('category')
        .eq('is_active', true);
    final set = <String>{};
    for (final row in data as List) {
      final c = (row as Map)['category'] as String?;
      if (c != null && c.trim().isNotEmpty) set.add(c.trim());
    }
    final list = set.toList()..sort();
    return list;
  }
}
