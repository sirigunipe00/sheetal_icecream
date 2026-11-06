import 'package:equatable/equatable.dart';
import 'package:sheetal_icecream/data/models/product.dart';

class CartLine extends Equatable {
  const CartLine({
    required this.product,
    required this.quantity,
    this.variant,
  });

  final Product product;
  final int quantity;
  final ProductVariant? variant;

  int get unitPrice => variant?.price ?? product.price;

  String get unitLabel => variant?.label ?? product.unit;

  int get variantId => variant?.id ?? 0;

  int get lineTotal => unitPrice * quantity;

  @override
  List<Object?> get props => [product, quantity, variant];
}

class CartState extends Equatable {
  const CartState({this.lines = const []});

  final List<CartLine> lines;

  bool get isEmpty => lines.isEmpty;

  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);

  int get subtotal => lines.fold(0, (sum, line) => sum + line.lineTotal);

  /// Free once the basket reaches ₹199. An empty basket has no fee.
  int get deliveryFee => subtotal == 0 || subtotal >= 199 ? 0 : 25;

  int get handlingFee => subtotal == 0 ? 0 : 5;

  int get total => subtotal + deliveryFee + handlingFee;

  int quantityOf(int productId, {int variantId = 0}) {
    for (final line in lines) {
      if (line.product.id == productId && line.variantId == variantId) {
        return line.quantity;
      }
    }
    return 0;
  }

  /// Total qty across all size variants of a product (for card badge).
  int quantityOfProduct(int productId) {
    var total = 0;
    for (final line in lines) {
      if (line.product.id == productId) total += line.quantity;
    }
    return total;
  }

  @override
  List<Object?> get props => [lines];
}
