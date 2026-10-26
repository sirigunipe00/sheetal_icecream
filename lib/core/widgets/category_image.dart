import 'package:flutter/material.dart';
import 'package:sheetal_icecream/core/theme/app_colors.dart';
import 'package:sheetal_icecream/core/widgets/product_image.dart';
import 'package:sheetal_icecream/data/models/product.dart';

/// Category art is stored as `categories/<file>`. Product art is stored as
/// `products/<file>`. When the category object is missing, use a product
/// picture from that category, preferring the same filename.
String? categoryImageFallback(
  List<Product> products,
  String category,
  String? primary,
) {
  final primaryName = _fileName(primary);
  String? any;
  for (final product in products) {
    if (product.category != category) continue;
    final image = product.image;
    if (image == null || image.isEmpty || image == primary) continue;
    if (primaryName != null && _fileName(image) == primaryName) return image;
    any ??= image;
  }
  return any;
}

String? _fileName(String? url) {
  if (url == null || url.isEmpty) return null;
  final segments = Uri.tryParse(url)?.pathSegments;
  final name = (segments == null || segments.isEmpty) ? url : segments.last;
  return Uri.decodeComponent(name);
}

class CategoryImage extends StatefulWidget {
  const CategoryImage({
    super.key,
    required this.imageUrl,
    required this.fallbackUrl,
    required this.label,
    this.fontSize = 22,
  });

  final String? imageUrl;
  final String? fallbackUrl;
  final String label;
  final double fontSize;

  @override
  State<CategoryImage> createState() => _CategoryImageState();
}

class _CategoryImageState extends State<CategoryImage> {
  late String? _url = widget.imageUrl ?? widget.fallbackUrl;
  var _usedFallback = false;

  @override
  void didUpdateWidget(CategoryImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.fallbackUrl != widget.fallbackUrl) {
      _url = widget.imageUrl ?? widget.fallbackUrl;
      _usedFallback = widget.imageUrl == null && widget.fallbackUrl != null;
    }
  }

  void _onError() {
    final fallback = widget.fallbackUrl;
    if (!_usedFallback && fallback != null && fallback.isNotEmpty && fallback != _url) {
      setState(() {
        _url = fallback;
        _usedFallback = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _url;
    if (url == null || url.isEmpty) return _letter();
    return Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        final fallback = widget.fallbackUrl;
        if (!_usedFallback &&
            fallback != null &&
            fallback.isNotEmpty &&
            fallback != url) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _onError();
          });
        }
        return _bundledOrLetter(url);
      },
    );
  }

  Widget _bundledOrLetter(String? url) {
    final asset = bundledProductAsset(url);
    if (asset == null) return _letter();
    return Image.asset(
      asset,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _letter(),
    );
  }

  Widget _letter() {
    final label = widget.label.isEmpty ? '?' : widget.label[0];
    return Center(
      child: Text(
        label,
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
