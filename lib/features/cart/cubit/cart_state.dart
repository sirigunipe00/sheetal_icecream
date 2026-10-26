import 'package:equatable/equatable.dart';
import 'package:sheetal_icecream/data/models/product.dart';

class CartLine extends Equatable {
  const CartLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  int get lineTotal => product.price * quantity;

  @override
  List<Object?> get props => [product, quantity];
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

  int quantityOf(int productId) {
    for (final line in lines) {
      if (line.product.id == productId) return line.quantity;
    }
    return 0;
  }

  @override
  List<Object?> get props => [lines];
}
