import 'package:sheetal_icecream/data/catalog/catalog_repository.dart';
import 'package:sheetal_icecream/data/models/product.dart';
import 'package:sheetal_icecream/features/cart/cubit/cart_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixtureCatalog extends CatalogRepository {
  const _FixtureCatalog();

  static const _items = [
    Product(id: 0, name: 'Cone', unit: '110 ml', price: 55, category: 'Cones'),
    Product(id: 4, name: 'Mixed', unit: 'Regular', price: 90, category: 'Natural Cup'),
    Product(id: 7, name: 'Nuts', unit: 'Regular', price: 255, category: 'Jumbo Cup'),
    Product(id: 18, name: 'Rajbhog', unit: 'Regular', price: 240, category: 'Big Cup'),
  ];

  @override
  List<Product> get products => _items;

  @override
  List<String> get categories => const ['All'];

  @override
  List<CategorySegment> get segments => const [];

  @override
  Map<String, String> get categoryImages => const {};

  @override
  Product? productById(int id) {
    for (final product in _items) {
      if (product.id == id) return product;
    }
    return null;
  }

  @override
  Future<void> refresh() async {}
}

void main() {
  late CartCubit cubit;

  setUp(() {
    cubit = CartCubit(const _FixtureCatalog());
  });

  tearDown(() async {
    await cubit.close();
  });

  test('adds a delivery fee and handling fee under ₹199', () {
    cubit.increment(0);
    expect(cubit.state.itemCount, 1);
    expect(cubit.state.subtotal, 55);
    expect(cubit.state.deliveryFee, 25);
    expect(cubit.state.handlingFee, 5);
    expect(cubit.state.total, 85);
  });

  test('delivery is free at ₹199 and above', () {
    cubit.increment(18);
    expect(cubit.state.subtotal, 240);
    expect(cubit.state.deliveryFee, 0);
    expect(cubit.state.handlingFee, 5);
    expect(cubit.state.total, 245);
  });

  test('removing the last unit drops the line', () {
    cubit.increment(7);
    cubit.increment(7);
    cubit.decrement(7);
    expect(cubit.state.quantityOf(7), 1);
    cubit.decrement(7);
    expect(cubit.state.isEmpty, isTrue);
    expect(cubit.state.total, 0);
  });

  test('clear empties the cart', () {
    cubit.increment(4);
    cubit.clear();
    expect(cubit.state.lines, isEmpty);
  });
}
