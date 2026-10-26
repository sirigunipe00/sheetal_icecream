import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  bool get isSignedIn => _client.auth.currentUser != null;

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

  /// Fetches cart items from Supabase for the current user
  Future<Map<int, int>> fetchCart() async {
    if (!SupabaseGate.ready) return {};
    try {
      return await _retry(() async {
        final data = await _client
            .from('cart_items')
            .select('product_id, quantity')
            .eq('user_id', currentUserId);

        final Map<int, int> quantities = {};
        for (final row in (data as List)) {
          final pid = (row['product_id'] as num).toInt();
          final qty = (row['quantity'] as num).toInt();
          quantities[pid] = qty;
        }
        return quantities;
      });
    } catch (e) {
      debugPrint('Error fetching cart from Supabase: $e');
      return {};
    }
  }

  /// Updates or removes an item in the Supabase cart
  Future<void> setCartQuantity(int productId, int quantity) async {
    if (!SupabaseGate.ready) return;
    try {
      await _retry(() async {
        if (quantity <= 0) {
          await _client
              .from('cart_items')
              .delete()
              .eq('user_id', currentUserId)
              .eq('product_id', productId);
          debugPrint('[Cart] Removed product $productId from Supabase cart');
        } else {
          // Check if row already exists for this user and product
          final existing = await _client
              .from('cart_items')
              .select('id')
              .eq('user_id', currentUserId)
              .eq('product_id', productId)
              .maybeSingle();

          if (existing != null) {
            await _client
                .from('cart_items')
                .update({
                  'quantity': quantity,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', existing['id']);
            debugPrint('[Cart] Updated product $productId quantity to $quantity in Supabase');
          } else {
            await _client.from('cart_items').insert({
              'user_id': currentUserId,
              'product_id': productId,
              'quantity': quantity,
            });
            debugPrint('[Cart] Inserted product $productId quantity $quantity into Supabase');
          }
        }
      });
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
}

