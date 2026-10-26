import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sheetal_icecream/data/catalog/catalog_repository.dart';
import 'package:sheetal_icecream/features/cart/cubit/cart_state.dart';
import 'package:sheetal_icecream/services/supabase_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit(this._catalog) : super(const CartState()) {
    _subscribeRealtime();
    _listenAuth();
  }

  final CatalogRepository _catalog;
  final Map<int, int> _quantities = {};
  StreamSubscription<List<Map<String, dynamic>>>? _cartSubscription;
  StreamSubscription<AuthState>? _authSubscription;

  void _listenAuth() {
    if (!SupabaseGate.ready) return;
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      debugPrint('[Cart Auth] Auth event: ${data.event.name}');
      if (data.event == AuthChangeEvent.initialSession) return;
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
        if (qty > 0) {
          _quantities[pid] = qty;
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

  void increment(int productId) {
    final next = (_quantities[productId] ?? 0) + 1;
    _quantities[productId] = next;
    _publish();
    SupabaseService.instance.setCartQuantity(productId, next);
  }

  void decrement(int productId) {
    final next = (_quantities[productId] ?? 1) - 1;
    if (next <= 0) {
      _quantities.remove(productId);
    } else {
      _quantities[productId] = next;
    }
    _publish();
    SupabaseService.instance.setCartQuantity(productId, next);
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
            if (_catalog.productById(entry.key) case final product?)
              CartLine(
                product: product,
                quantity: entry.value,
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
