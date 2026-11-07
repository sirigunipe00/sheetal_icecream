import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sheetal_icecream/data/models/order.dart';
import 'package:sheetal_icecream/data/models/user_address.dart';
import 'package:sheetal_icecream/features/cart/cubit/cart_state.dart';

/// True only after [Supabase.initialize] has finished.
class SupabaseGate {
  static bool get ready {
    try {
      return Supabase.instance.isInitialized;
    } catch (_) {
      return false;
    }
  }
}

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  static String? _guestId;

  /// Returns the logged-in user ID or a persistent guest ID
  String get currentUserId {
    final user = _client.auth.currentUser;
    if (user != null) return user.id;
    _guestId ??= 'guest_device_user';
    return _guestId!;
  }

  bool get isSignedIn {
    if (!SupabaseGate.ready) return false;
    try {
      return _client.auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------
  // Realtime Streams
  // ---------------------------------------------------------------------

  /// Realtime Stream for cart items of the current user
  Stream<List<Map<String, dynamic>>> streamCart() {
    if (!SupabaseGate.ready) return const Stream.empty();
    return _client
        .from('cart_items')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId);
  }

  /// Realtime Stream for wishlist of the current user
  Stream<Set<int>> streamWishlist() {
    if (!SupabaseGate.ready) return const Stream.empty();
    return _client
        .from('wishlist')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .map((rows) => rows.map((r) => (r['product_id'] as num).toInt()).toSet());
  }

  // ---------------------------------------------------------------------
  // Network Resilience Helper
  // ---------------------------------------------------------------------

  Future<T> _retry<T>(Future<T> Function() action, {int maxAttempts = 3}) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await action();
      } catch (e) {
        final errStr = e.toString();
        final isNetwork = errStr.contains('HandshakeException') ||
            errStr.contains('SocketException') ||
            errStr.contains('Connection terminated') ||
            errStr.contains('ClientException') ||
            errStr.contains('HttpException');
        if (attempts >= maxAttempts || !isNetwork) {
          rethrow;
        }
        debugPrint('[Supabase Retry] Network drop ($errStr). Retrying attempt $attempts...');
        await Future.delayed(Duration(milliseconds: 300 * attempts));
      }
    }
  }

  // ---------------------------------------------------------------------
  // Cart Operations
  // ---------------------------------------------------------------------

  /// Fetches cart items. Key is (productId, variantId).
  Future<Map<(int, int), int>> fetchCart() async {
    if (!SupabaseGate.ready) return {};
    try {
      return await _retry(() async {
        final data = await _client
            .from('cart_items')
            .select('product_id, quantity, variant_id')
            .eq('user_id', currentUserId);

        final Map<(int, int), int> quantities = {};
        for (final row in (data as List)) {
          final pid = (row['product_id'] as num).toInt();
          final qty = (row['quantity'] as num).toInt();
          final vid = (row['variant_id'] as num?)?.toInt() ?? 0;
          quantities[(pid, vid)] = qty;
        }
        return quantities;
      });
    } catch (e) {
      // Fallback if variant_id column is not migrated yet.
      debugPrint('Error fetching cart (trying legacy): $e');
      try {
        final data = await _client
            .from('cart_items')
            .select('product_id, quantity')
            .eq('user_id', currentUserId);
        final Map<(int, int), int> quantities = {};
        for (final row in (data as List)) {
          final pid = (row['product_id'] as num).toInt();
          final qty = (row['quantity'] as num).toInt();
          quantities[(pid, 0)] = qty;
        }
        return quantities;
      } catch (e2) {
        debugPrint('Error fetching cart from Supabase: $e2');
        return {};
      }
    }
  }

  /// Updates or removes an item in the Supabase cart immediately.
  /// [variantId] 0 = single-size product / legacy rows.
  Future<void> setCartQuantity(
    int productId,
    int quantity, {
    int variantId = 0,
  }) async {
    if (!SupabaseGate.ready) return;
    try {
      if (quantity <= 0) {
        var query = _client
            .from('cart_items')
            .delete()
            .eq('user_id', currentUserId)
            .eq('product_id', productId);
        query = query.eq('variant_id', variantId);
        await query;
        debugPrint(
          '[Cart] Removed product $productId variant $variantId immediately',
        );
      } else {
        try {
          await _client.from('cart_items').upsert(
            {
              'user_id': currentUserId,
              'product_id': productId,
              'variant_id': variantId,
              'quantity': quantity,
              'updated_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'user_id,product_id,variant_id',
          );
        } catch (_) {
          // Legacy cart without variant_id column / unique constraint.
          await _client.from('cart_items').upsert(
            {
              'user_id': currentUserId,
              'product_id': productId,
              'quantity': quantity,
              'updated_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'user_id,product_id',
          );
        }
        debugPrint(
          '[Cart] Upserted product $productId variant $variantId qty $quantity',
        );
      }
    } catch (e, stack) {
      debugPrint('[Cart Error] Could not update cart in Supabase: $e\n$stack');
    }
  }

  /// Clears all cart items for current user in Supabase
  Future<void> clearCart() async {
    if (!SupabaseGate.ready) return;
    try {
      await _retry(() async {
        await _client.from('cart_items').delete().eq('user_id', currentUserId);
        debugPrint('[Cart] Cleared cart in Supabase');
      });
    } catch (e) {
      debugPrint('[Cart Error] Could not clear cart in Supabase: $e');
    }
  }

  // ---------------------------------------------------------------------
  // Wishlist Operations
  // ---------------------------------------------------------------------

  /// Fetches wishlist product IDs for current user from Supabase
  Future<Set<int>> fetchWishlist() async {
    if (!SupabaseGate.ready) return {};
    try {
      return await _retry(() async {
        final data = await _client
            .from('wishlist')
            .select('product_id')
            .eq('user_id', currentUserId);

        final Set<int> result = {};
        for (final row in (data as List)) {
          result.add((row['product_id'] as num).toInt());
        }
        return result;
      });
    } catch (e) {
      debugPrint('[Wishlist Error] Could not fetch wishlist from Supabase: $e');
      return {};
    }
  }

  /// Toggles wishlist status in Supabase
  Future<void> toggleWishlist(int productId, bool isCurrentlyWishlisted) async {
    if (!SupabaseGate.ready) return;
    try {
      await _retry(() async {
        if (isCurrentlyWishlisted) {
          await _client
              .from('wishlist')
              .delete()
              .eq('user_id', currentUserId)
              .eq('product_id', productId);
          debugPrint('[Wishlist] Removed product $productId from Supabase');
        } else {
          final existing = await _client
              .from('wishlist')
              .select('id')
              .eq('user_id', currentUserId)
              .eq('product_id', productId)
              .maybeSingle();

          if (existing == null) {
            await _client.from('wishlist').insert({
              'user_id': currentUserId,
              'product_id': productId,
            });
            debugPrint('[Wishlist] Added product $productId to Supabase');
          }
        }
      });
    } catch (e) {
      debugPrint('[Wishlist Error] Could not toggle wishlist in Supabase: $e');
    }
  }

  // ---------------------------------------------------------------------
  // Address Operations
  // ---------------------------------------------------------------------

  /// Fetches saved addresses for current user from Supabase
  Future<List<UserAddress>> fetchAddresses() async {
    if (!SupabaseGate.ready || !isSignedIn) return [];
    try {
      return await _retry(() async {
        final data = await _client
            .from('addresses')
            .select()
            .eq('user_id', currentUserId)
            .order('is_default', ascending: false)
            .order('created_at', ascending: false);

        final list = (data as List)
            .map((row) => UserAddress.fromMap(row as Map<String, dynamic>))
            .toList();
        return list;
      });
    } catch (e) {
      debugPrint('[Address Error] Could not fetch addresses: $e');
      return [];
    }
  }

  /// Inserts or updates an address for the current user
  Future<UserAddress?> saveAddress(UserAddress address) async {
    if (!SupabaseGate.ready || !isSignedIn) return null;
    try {
      return await _retry(() async {
        final payload = address.toMap();
        payload['user_id'] = currentUserId;
        if (address.id.isEmpty) {
          payload.remove('id');
        }

        final res = await _client
            .from('addresses')
            .upsert(payload)
            .select()
            .single();

        return UserAddress.fromMap(res);
      });
    } catch (e) {
      debugPrint('[Address Error] Could not save address: $e');
      rethrow;
    }
  }

  /// Sets an address as default and unsets others
  Future<void> setDefaultAddress(String addressId) async {
    if (!SupabaseGate.ready || !isSignedIn) return;
    try {
      await _retry(() async {
        // Unset previous defaults
        await _client
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', currentUserId)
            .eq('is_default', true);

        // Set target address as default
        await _client
            .from('addresses')
            .update({'is_default': true})
            .eq('user_id', currentUserId)
            .eq('id', addressId);
      });
    } catch (e) {
      debugPrint('[Address Error] Could not set default address: $e');
      rethrow;
    }
  }

  /// Deletes an address
  Future<void> deleteAddress(String addressId) async {
    if (!SupabaseGate.ready || !isSignedIn) return;
    try {
      await _retry(() async {
        await _client
            .from('addresses')
            .delete()
            .eq('user_id', currentUserId)
            .eq('id', addressId);
      });
    } catch (e) {
      debugPrint('[Address Error] Could not delete address: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------
  // Orders Operations (COD & Online)
  // ---------------------------------------------------------------------

  /// Creates a new order in Supabase and saves its items into the items column
  Future<CustomerOrder> createOrder({
    required String orderNumber,
    required String customerName,
    required String customerPhone,
    required String addressText,
    String addressLabel = 'Home',
    required int subtotal,
    required int deliveryFee,
    required int handlingFee,
    required int total,
    String paymentMethod = 'cod',
    required List<CartLine> lines,
  }) async {
    if (!SupabaseGate.ready) {
      throw Exception('Supabase is not initialized');
    }

    final userId = currentUserId;
    return await _retry(() async {
      // Build items json array
      final itemsPayload = [
        for (final line in lines)
          {
            'product_id': line.product.id,
            'variant_id': line.variantId,
            'product_name': line.product.name,
            'unit_label': line.unitLabel,
            'unit_price': line.unitPrice,
            'quantity': line.quantity,
            'line_total': line.lineTotal,
            if (line.product.image != null) 'image_url': line.product.image,
          }
      ];

      // Exact columns matching public.orders table in Supabase
      final orderPayload = {
        'order_number': orderNumber,
        'user_id': userId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'delivery_address': addressText,
        'status': 'placed',
        'payment_method': paymentMethod,
        'payment_status': paymentMethod == 'cod' ? 'pending' : 'paid',
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'handling_fee': handlingFee,
        'total': total,
        'items': itemsPayload,
      };

      final orderRes = await _client
          .from('orders')
          .insert(orderPayload)
          .select()
          .single();

      // Clear remote cart after order placement
      clearCart();

      debugPrint('[Order Success] Order $orderNumber placed in database with ${lines.length} items');
      return CustomerOrder.fromMap(Map<String, dynamic>.from(orderRes));
    });
  }

  /// Fetches orders for the currently authenticated user
  Future<List<CustomerOrder>> fetchUserOrders() async {
    if (!SupabaseGate.ready || !isSignedIn) return [];
    try {
      return await _retry(() async {
        final data = await _client
            .from('orders')
            .select()
            .eq('user_id', currentUserId)
            .order('created_at', ascending: false);

        final list = (data as List)
            .map((row) => CustomerOrder.fromMap(Map<String, dynamic>.from(row as Map)))
            .toList();
        return list;
      });
    } catch (e) {
      debugPrint('[Orders Error] Could not fetch user orders: $e');
      return [];
    }
  }

  /// Fetches all orders for Admin view
  Future<List<CustomerOrder>> fetchAdminOrders() async {
    if (!SupabaseGate.ready) return [];
    try {
      return await _retry(() async {
        final data = await _client
            .from('orders')
            .select()
            .order('created_at', ascending: false)
            .limit(200);

        final list = (data as List)
            .map((row) => CustomerOrder.fromMap(Map<String, dynamic>.from(row as Map)))
            .toList();
        return list;
      });
    } catch (e) {
      debugPrint('[Orders Error] Could not fetch admin orders: $e');
      return [];
    }
  }

  /// Updates status of an order (for Admin)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    if (!SupabaseGate.ready) return;
    try {
      await _retry(() async {
        await _client
            .from('orders')
            .update({
              'status': newStatus,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', orderId);
        debugPrint('[Orders] Updated order $orderId to status $newStatus');
      });
    } catch (e) {
      debugPrint('[Orders Error] Could not update order status: $e');
      rethrow;
    }
  }
}

