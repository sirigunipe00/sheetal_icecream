import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sheetal_icecream/data/catalog/catalog_repository.dart';
import 'package:sheetal_icecream/data/models/product.dart';
import 'package:sheetal_icecream/features/cart/cubit/cart_state.dart';
import 'package:sheetal_icecream/services/supabase_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class _CartKey {
  const _CartKey(this.productId, this.variantId);

  final int productId;
  final int variantId;

  @override
  bool operator ==(Object other) =>
      other is _CartKey &&
      other.productId == productId &&
      other.variantId == variantId;

  @override
  int get hashCode => Object.hash(productId, variantId);
}

class CartCubit extends Cubit<CartState> {
  CartCubit(this._catalog) : super(const CartState()) {
    loadCart();
    _subscribeRealtime();
    _listenAuth();
  }

  final CatalogRepository _catalog;
  final Map<_CartKey, int> _quantities = {};
  StreamSubscription<List<Map<String, dynamic>>>? _cartSubscription;
  StreamSubscription<AuthState>? _authSubscription;

  Future<void> loadCart() async {
    if (!SupabaseGate.ready) return;
    try {
      final rows = await SupabaseService.instance.fetchCart();
      _quantities
        ..clear()
        ..addAll({
          for (final entry in rows.entries)
            _CartKey(entry.key.$1, entry.key.$2): entry.value,
        });
      _publish();
    } catch (e) {
      debugPrint('[Cart] Initial fetch error: $e');
    }
  }

  void republish() {
    _publish();
  }

  void _listenAuth() {
    if (!SupabaseGate.ready) return;
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      debugPrint('[Cart Auth] Auth event: ${data.event.name}');
      loadCart();
      _subscribeRealtime();
    });
  }

  void _subscribeRealtime() {
    _cartSubscription?.cancel();
    if (!SupabaseGate.ready) return;
    _cartSubscription = SupabaseService.instance.streamCart().listen((rows) {
      _quantities.clear();
      for (final row in rows) {
        final pid = (row['product_id'] as num).toInt();
        final qty = (row['quantity'] as num).toInt();
        final vid = (row['variant_id'] as num?)?.toInt() ?? 0;
        if (qty > 0) {
          _quantities[_CartKey(pid, vid)] = qty;
        }
      }
      _publish();
      debugPrint('[Cart Realtime] Received ${rows.length} items from Supabase');
    }, onError: (e) {
      debugPrint('[Cart Realtime Error] $e');
      _cartSubscription?.cancel();
      _cartSubscription = null;
    });
  }

  void increment(int productId, {int variantId = 0}) {
    final key = _CartKey(productId, variantId);
    final next = (_quantities[key] ?? 0) + 1;
    _quantities[key] = next;
    _publish();
    SupabaseService.instance.setCartQuantity(
      productId,
      next,
      variantId: variantId,
    );
  }

  void decrement(int productId, {int variantId = 0}) {
    final key = _CartKey(productId, variantId);
    final next = (_quantities[key] ?? 1) - 1;
    if (next <= 0) {
      _quantities.remove(key);
    } else {
      _quantities[key] = next;
    }
    _publish();
    SupabaseService.instance.setCartQuantity(
      productId,
      next,
      variantId: variantId,
    );
  }

  /// Decrements any size line for [productId] (used by catalogue cards).
  void decrementProduct(int productId) {
    final matches = _quantities.keys
        .where((key) => key.productId == productId)
        .toList();
    if (matches.isEmpty) return;
    matches.sort((a, b) => a.variantId.compareTo(b.variantId));
    decrement(matches.first.productId, variantId: matches.first.variantId);
  }

  void incrementProduct(Product product) {
    if (product.hasVariants) {
      addProduct(product, variant: product.defaultVariant);
      return;
    }
    increment(product.id);
  }

  void addProduct(Product product, {ProductVariant? variant, int quantity = 1}) {
    final selected = variant ??
        (product.variants.isNotEmpty ? product.defaultVariant : null);
    final variantId = selected?.id ?? 0;
    final key = _CartKey(product.id, variantId);
    final next = (_quantities[key] ?? 0) + quantity;
    _quantities[key] = next;
    _publish();
    SupabaseService.instance.setCartQuantity(
      product.id,
      next,
      variantId: variantId,
    );
  }

  void clear() {
    _quantities.clear();
    emit(const CartState());
    SupabaseService.instance.clearCart();
  }

  void _publish() {
    emit(
      CartState(
        lines: [
          for (final entry in _quantities.entries)
            if (_catalog.productById(entry.key.productId) case final product?)
              CartLine(
                product: product,
                quantity: entry.value,
                variant: entry.key.variantId == 0
                    ? (product.variants.isNotEmpty
                        ? product.defaultVariant
                        : null)
                    : product.variantById(entry.key.variantId),
              ),
        ],
      ),
    );
  }

  @override
  Future<void> close() {
    _cartSubscription?.cancel();
    _authSubscription?.cancel();
    return super.close();
  }
}
