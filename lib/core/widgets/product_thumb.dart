import 'package:flutter/material.dart';

import 'package:blinkit_clone/core/theme/app_colors.dart';
import 'package:blinkit_clone/core/theme/category_tint.dart';
import 'package:blinkit_clone/data/models/product.dart';

class ProductThumb extends StatelessWidget {
  const ProductThumb({
    super.key,
    required this.product,
    required this.height,
    this.width,
    this.radius = 10,
    this.fontSize = 30,
  });

  final Product product;
  final double height;
  final double? width;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final image = product.image;
    return Container(
      width: width ?? double.infinity,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: categoryTint(product.category),
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: image != null && image.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(6),
              child: image.startsWith('http')
                  ? Image.network(
                      image,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Text(
                        product.initial,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepInk,
                        ),
                      ),
                    )
                  : Text(
                      product.initial,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepInk,
                      ),
                    ),
            )
          : Text(
              product.initial,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: AppColors.deepInk,
              ),
            ),
    );
  }
}
