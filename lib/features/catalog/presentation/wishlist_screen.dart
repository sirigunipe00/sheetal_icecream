import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sheetal_icecream/core/theme/app_colors.dart';
import 'package:sheetal_icecream/features/cart/cubit/cart_cubit.dart';
import 'package:sheetal_icecream/features/catalog/cubit/catalog_cubit.dart';
import 'package:sheetal_icecream/features/catalog/cubit/catalog_state.dart';
import 'package:sheetal_icecream/features/catalog/presentation/widgets/product_card.dart';
import 'package:sheetal_icecream/features/shell/cubit/shell_cubit.dart';
import 'package:sheetal_icecream/features/shell/cubit/shell_state.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartCubit>().state;

    return BlocBuilder<CatalogCubit, CatalogState>(
      builder: (context, state) {
        final wishlisted = state.wishlistedProducts;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Wishlist ${wishlisted.isNotEmpty ? '(${wishlisted.length})' : ''}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.royalPurple,
              ),
            ),
            centerTitle: false,
          ),
          body: wishlisted.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 42,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Your wishlist is empty',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.royalPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap the heart icon on any ice cream to save your favorite flavors here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.softMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            context.read<ShellCubit>().select(AppTab.home);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Browse ice creams',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 228,
                  ),
                  itemCount: wishlisted.length,
                  itemBuilder: (context, index) {
                    final product = wishlisted[index];
                    return ProductCard(
                      key: ValueKey('wishlist-${product.id}'),
                      product: product,
                      quantity: cart.quantityOf(product.id),
                      onIncrement: () => context.read<CartCubit>().increment(product.id),
                      onDecrement: () => context.read<CartCubit>().decrement(product.id),
                    );
                  },
                ),
        );
      },
    );
  }
}

