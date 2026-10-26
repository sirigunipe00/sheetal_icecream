import 'package:equatable/equatable.dart';

class ProductVariant extends Equatable {
  const ProductVariant({
    required this.id,
    required this.label,
    required this.price,
    required this.unitsPerPack,
  });

  final int id;
  final String label;
  final int price;
  final int unitsPerPack;

  @override
  List<Object?> get props => [id, label, price, unitsPerPack];
}

class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.category,
    this.image,
    this.description,
    this.isNew = false,
    this.key,
    this.bestSellerRank,
    this.variants = const [],
  });

  final int id;
  final String name;
  final String unit;
  final int price;
  final String category;
  final String? image;
  final String? description;
  final bool isNew;
  final String? key;
  final int? bestSellerRank;
  final List<ProductVariant> variants;

  int get packOf4Price {
    for (final variant in variants) {
      if (variant.unitsPerPack == 4) return variant.price;
    }
    return (price * 4) - 15;
  }

  String get initial => name.isEmpty ? '?' : name[0];

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: (map['name'] as String?) ?? '',
      unit: (map['unit'] as String?) ?? 'Regular pack',
      price: (map['price'] as num?)?.toInt() ?? 0,
      category: (map['category'] as String?) ?? 'All',
      image: (map['image_url'] ?? map['image']) as String?,
      description: map['description'] as String?,
      isNew: (map['is_new'] as bool?) ?? false,
      key: '${map['id']}|${map['name']}',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'price': price,
      'category': category,
      'image_url': image,
      'description': description,
      'is_new': isNew,
    };
  }

  @override
  List<Object?> get props =>
      [id, name, unit, price, category, image, isNew, key, bestSellerRank, variants];
}
