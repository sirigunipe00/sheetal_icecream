import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:blinkit_clone/core/theme/app_colors.dart';
import 'package:blinkit_clone/core/widgets/quantity_stepper.dart';
import 'package:blinkit_clone/data/models/product.dart';
import 'package:blinkit_clone/features/catalog/cubit/catalog_cubit.dart';
import 'package:blinkit_clone/features/catalog/cubit/catalog_state.dart';
import 'package:blinkit_clone/features/catalog/presentation/product_detail_sheet.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final Product product;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ProductDetailSheet.show(context, product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderPink, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack with NEW badge & Wishlist Heart
            Stack(
              children: [
                Container(
                  height: 112,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppColors.imgCardGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Center(
                    child: product.image != null && product.image!.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(6),
                            child: product.image!.startsWith('http')
                                ? Image.network(
                                    product.image!,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return const Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) => Text(
                                      product.initial,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  )
                                : Text(
                                    product.initial,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                          )
                        : Text(
                            product.initial,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                ),

                // NEW Badge
                if (product.isNew)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.royalPurple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),

                // Wishlist Heart Button
                Positioned(
                  top: 2,
                  right: 2,
                  child: BlocBuilder<CatalogCubit, CatalogState>(
                    builder: (context, state) {
                      final isWishlisted = state.isWishlisted(product.id);
                      return GestureDetector(
                        onTap: () {
                          context.read<CatalogCubit>().toggleWishlist(product.id);
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 18,
                            color: isWishlisted ? AppColors.primary : AppColors.softMuted,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            // Category tag (Kicker)
            Text(
              product.category.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.hotPink,
              ),
            ),

            // Product Name
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.royalPurple,
              ),
            ),

            // Unit
            Text(
              product.unit,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.softMuted,
              ),
            ),

            const Spacer(),

            // Price and Stepper/Add
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${product.price}',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepInk,
                  ),
                ),
                QuantityStepper(
                  quantity: quantity,
                  compact: true,
                  onIncrement: onIncrement,
                  onDecrement: onDecrement,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
