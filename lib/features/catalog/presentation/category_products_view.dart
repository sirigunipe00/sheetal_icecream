import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sheetal_icecream/core/theme/app_colors.dart';
import 'package:sheetal_icecream/data/models/product.dart';
import 'package:sheetal_icecream/features/cart/cubit/cart_cubit.dart';
import 'package:sheetal_icecream/features/catalog/cubit/catalog_cubit.dart';
import 'package:sheetal_icecream/features/catalog/cubit/catalog_state.dart';
import 'package:sheetal_icecream/features/catalog/presentation/widgets/product_card.dart';

/// Same product listing for every category: title, search, sort, and a grid.
class CategoryProductsView extends StatefulWidget {
  const CategoryProductsView({super.key, required this.category});

  final String category;

  @override
  State<CategoryProductsView> createState() => _CategoryProductsViewState();
}

class _CategoryProductsViewState extends State<CategoryProductsView> {
  final _search = TextEditingController();
  String _sort = 'rel';

  @override
  void didUpdateWidget(CategoryProductsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _search.clear();
      _sort = 'rel';
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Product> _products(CatalogState state) {
    final query = _search.text.trim().toLowerCase();
    final list = [
      for (final product in state.products)
        if (product.category == widget.category &&
            (query.isEmpty || product.name.toLowerCase().contains(query)))
          product,
    ];
    if (_sort == 'lo') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sort == 'hi') {
      list.sort((a, b) => b.price.compareTo(a.price));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogCubit>().state;
    final cart = context.watch<CartCubit>().state;
    final products = _products(catalog);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.read<CatalogCubit>().closeCategory(),
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: AppColors.royalPurple,
            size: 30,
          ),
        ),
        title: Text(
          widget.category,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.royalPurple,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(child: _SearchField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                )),
                const SizedBox(width: 10),
                _SortMenu(
                  sort: _sort,
                  onSelected: (value) => setState(() => _sort = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? const Center(
                    child: Text(
                      'No products found',
                      style: TextStyle(color: AppColors.softMuted),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 248,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        key: ValueKey('category-product-${product.id}'),
                        product: product,
                        quantity: cart.quantityOf(product.id),
                        onIncrement: () =>
                            context.read<CartCubit>().increment(product.id),
                        onDecrement: () =>
                            context.read<CartCubit>().decrement(product.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        autocorrect: false,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.deepInk,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Search your favourite',
          hintStyle: const TextStyle(
            fontSize: 13,
            color: AppColors.softMuted,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.softMuted,
            size: 20,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: _border(AppColors.linePink),
          enabledBorder: _border(AppColors.linePink),
          focusedBorder: _border(AppColors.primary),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: 1.5),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.sort, required this.onSelected});

  final String sort;
  final ValueChanged<String> onSelected;

  static const _labels = {
    'rel': 'Sort',
    'lo': 'Price ↑',
    'hi': 'Price ↓',
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: sort,
      onSelected: onSelected,
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'rel', child: Text('Recommended')),
        PopupMenuItem(value: 'lo', child: Text('Price: Low to High')),
        PopupMenuItem(value: 'hi', child: Text('Price: High to Low')),
      ],
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.linePink, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _labels[sort] ?? 'Sort',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.deepInk,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.softMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
