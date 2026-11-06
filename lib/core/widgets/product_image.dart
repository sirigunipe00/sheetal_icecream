import 'package:flutter/material.dart';
import 'package:sheetal_icecream/core/theme/app_colors.dart';
import 'package:sheetal_icecream/data/models/product.dart';

const _publicBucket =
    'https://kmiuxdaaznmzdbhmrmmh.supabase.co/storage/v1/object/public/product-images';

/// Storage URLs look like `.../product-images/products/products/natural-cup-guava.png`.
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

String _plainName(Product product) {
  return product.name.trim().replaceFirst(RegExp(r'\s*\([^)]*\)\s*$'), '').trim();
}

String _slug(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9]+"), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

/// Catalogue import used `{category}-{name}.png` after stripping size text.
String? catalogueProductAsset(Product product) {
  final category = product.category.trim();
  final name = _plainName(product);
  if (category.isEmpty || name.isEmpty) return null;
  final slug = _slug('$category-$name');
  if (slug.isEmpty) return null;
  return 'assets/images/$slug.png';
}

/// Filenames that may exist in Storage for this product.
List<String> productImageFilenames(Product product) {
  final name = _plainName(product);
  final category = product.category.trim();
  final files = <String>{};

  void add(String? value) {
    if (value == null || value.isEmpty) return;
    final cleaned = value.startsWith('/') ? value.substring(1) : value;
    files.add(cleaned);
  }

  final fromUrl = bundledProductAsset(product.image);
  if (fromUrl != null) add(fromUrl.split('/').last);

  if (product.image != null && product.image!.startsWith('http')) {
    final uri = Uri.tryParse(product.image!);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      add(Uri.decodeComponent(uri.pathSegments.last));
    }
  }

  if (category.isNotEmpty && name.isNotEmpty) {
    add('${_slug('$category-$name')}.png');
  }
  if (name.isNotEmpty) {
    add('${_slug(name)}.png');
    add('${name.replaceAll(RegExp(r"\s+"), '-')}.png');
    add('${name.replaceAll(RegExp(r"[^a-zA-Z0-9]+"), '-')}.png');
  }

  return files.toList();
}

/// Public Storage URLs to try, matching how files were uploaded.
List<String> productImageNetworkCandidates(Product product) {
  final urls = <String>{};
  if (product.image != null && product.image!.startsWith('http')) {
    urls.add(product.image!);
  }
  const prefixes = [
    'products/',
    'products/products/',
    '',
  ];
  for (final file in productImageFilenames(product)) {
    for (final prefix in prefixes) {
      urls.add('$_publicBucket/$prefix$file');
    }
  }
  return urls.toList();
}

class ProductImage extends StatefulWidget {
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
  State<ProductImage> createState() => _ProductImageState();
}

class _ProductImageState extends State<ProductImage> {
  late List<String> _urls = productImageNetworkCandidates(widget.product);
  var _index = 0;

  @override
  void didUpdateWidget(covariant ProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id ||
        oldWidget.product.image != widget.product.image ||
        oldWidget.product.name != widget.product.name) {
      _urls = productImageNetworkCandidates(widget.product);
      _index = 0;
    }
  }

  void _tryNext() {
    if (_index + 1 < _urls.length) {
      setState(() => _index += 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assets = <String?>[
      if (widget.product.image != null &&
          widget.product.image!.startsWith('assets/'))
        widget.product.image,
      bundledProductAsset(widget.product.image),
      catalogueProductAsset(widget.product),
      ...productImageFilenames(widget.product).map((f) => 'assets/images/$f'),
    ].whereType<String>().toSet().toList();

    // Catalogue / bundled assets are preferred when the repository already
    // resolved a local file. This avoids broken Storage folder paths.
    if (widget.product.image != null &&
        widget.product.image!.startsWith('assets/')) {
      return _assetsOrLetter(assets);
    }

    if (_index < _urls.length) {
      final url = _urls[_index];
      return Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: widget.showProgress
            ? (context, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.color,
                    ),
                  ),
                );
              }
            : null,
        errorBuilder: (_, _, _) {
          if (_index + 1 < _urls.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _tryNext();
            });
            return const SizedBox.shrink();
          }
          return _assetsOrLetter(assets);
        },
      );
    }
    return _assetsOrLetter(assets);
  }

  Widget _assetsOrLetter(List<String> assets) {
    if (assets.isEmpty) return _letter();
    return Image.asset(
      assets.first,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) {
        if (assets.length == 1) return _letter();
        return Image.asset(
          assets[1],
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) =>
              assets.length > 2
                  ? Image.asset(
                      assets[2],
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => _letter(),
                    )
                  : _letter(),
        );
      },
    );
  }

  Widget _letter() {
    return Text(
      widget.product.initial,
      style: TextStyle(
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w800,
        color: widget.color,
      ),
    );
  }
}
