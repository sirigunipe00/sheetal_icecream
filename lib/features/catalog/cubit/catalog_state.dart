import 'package:equatable/equatable.dart';
import 'package:blinkit_clone/data/catalog/catalog_repository.dart';
import 'package:blinkit_clone/data/models/product.dart';

class CatalogState extends Equatable {
  const CatalogState({
    required this.products,
    required this.categories,
    this.segments = const [],
    this.categoryImages = const {},
    this.category = 'All',
    this.query = '',
    this.wishlist = const {},
    this.sortBy = 'rel',
    this.selectedSegment = 'Ice Cream',
    this.loading = false,
    this.error,
  });

  final List<Product> products;
  final List<String> categories;
  final List<CategorySegment> segments;
  final Map<String, String> categoryImages;
  final String category;
  final String query;
  final Set<int> wishlist;
  final String sortBy;
  final String selectedSegment;
  final bool loading;
  final String? error;

  bool isWishlisted(int id) => wishlist.contains(id);

  List<Product> get visible {
    var list = [
      for (final product in products)
        if ((category == 'All' || product.category == category) &&
            (query.isEmpty || product.name.toLowerCase().contains(query)))
          product,
    ];
    if (sortBy == 'lo') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (sortBy == 'hi') {
      list.sort((a, b) => b.price.compareTo(a.price));
    }
    return list;
  }

  List<Product> get wishlistedProducts {
    return products.where((p) => wishlist.contains(p.id)).toList();
  }

  List<Product> get bestSellers {
    final ranked = products.where((product) => product.bestSellerRank != null).toList()
      ..sort((a, b) => a.bestSellerRank!.compareTo(b.bestSellerRank!));
    return ranked;
  }

  List<Product> get newArrivals => products.where((p) => p.isNew).toList();

  CatalogState copyWith({
    List<Product>? products,
    List<String>? categories,
    List<CategorySegment>? segments,
    Map<String, String>? categoryImages,
    String? category,
    String? query,
    Set<int>? wishlist,
    String? sortBy,
    String? selectedSegment,
    bool? loading,
    Object? error = _keepError,
  }) {
    return CatalogState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      segments: segments ?? this.segments,
      categoryImages: categoryImages ?? this.categoryImages,
      category: category ?? this.category,
      query: query ?? this.query,
      wishlist: wishlist ?? this.wishlist,
      sortBy: sortBy ?? this.sortBy,
      selectedSegment: selectedSegment ?? this.selectedSegment,
      loading: loading ?? this.loading,
      error: identical(error, _keepError) ? this.error : error as String?,
    );
  }

  static const Object _keepError = Object();

  @override
  List<Object?> get props => [
        products,
        categories,
        segments,
        categoryImages,
        category,
        query,
        wishlist,
        sortBy,
        selectedSegment,
        loading,
        error,
      ];
}
