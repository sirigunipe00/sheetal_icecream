import 'package:flutter/material.dart';
import 'package:sheetal_icecream/core/theme/app_colors.dart';
import 'package:sheetal_icecream/data/models/product.dart';

/// Storage URLs look like `.../product-images/products/Rajbhog.png`.
/// The same filename is bundled under `assets/images/` for pictures that
/// were not uploaded to the bucket.
String? bundledProductAsset(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('assets/')) return url;
  final uri = Uri.tryParse(url);
  final raw = uri != null && uri.pathSegments.isNotEmpty
      ? uri.pathSegments.last
      : url.split('/').last;
  final name = Uri.decodeComponent(raw).trim();
  if (name.isEmpty || !name.contains('.')) return null;
  return 'assets/images/$name';
}

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.product,
    this.fontSize = 32,
    this.color = AppColors.primary,
    this.showProgress = false,
  });

  final Product product;
  final double fontSize;
  final Color color;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final url = product.image;
    final asset = bundledProductAsset(url);
    if (url != null && url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: showProgress
            ? (context, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  ),
                );
              }
            : null,
        errorBuilder: (_, __, ___) => _assetOrLetter(asset),
      );
    }
    return _assetOrLetter(asset);
  }

  Widget _assetOrLetter(String? asset) {
    if (asset == null) return _letter();
    return Image.asset(
      asset,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _letter(),
    );
  }

  Widget _letter() {
    return Text(
      product.initial,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }
}
