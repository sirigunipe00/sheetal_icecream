import 'package:flutter/material.dart';

import 'package:sheetal_icecream/core/theme/app_colors.dart';
import 'package:sheetal_icecream/core/widgets/product_image.dart';
import 'package:sheetal_icecream/core/theme/category_tint.dart';
import 'package:sheetal_icecream/data/models/product.dart';

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
    return Container(
      width: width ?? double.infinity,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: categoryTint(product.category),
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: ProductImage(
          product: product,
          fontSize: fontSize,
          color: AppColors.deepInk,
        ),
      ),
    );
  }
}
