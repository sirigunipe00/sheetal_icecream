import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sheetal_icecream/data/catalog/catalog_repository.dart';
import 'package:sheetal_icecream/features/catalog/cubit/catalog_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sheetal_icecream/services/supabase_service.dart';

class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this._repository)
      : super(
          CatalogState(
            products: _repository.products,
            categories: _repository.categories,
            segments: _repository.segments,
            categoryImages: _repository.categoryImages,
            loading: _repository is SupabaseCatalogRepository,
          ),
        ) {
    loadFromSupabase();
    _subscribeWishlist();
    _listenAuth();
  }

  final CatalogRepository _repository;
  StreamSubscription<Set<int>>? _wishlistSubscription;
  StreamSubscription<AuthState>? _authSubscription;

  void _listenAuth() {
    if (!SupabaseGate.ready) return;
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.initialSession) return;
      _subscribeWishlist();
    });
  }

  void _subscribeWishlist() {
    _wishlistSubscription?.cancel();
    if (!SupabaseGate.ready) return;
    _wishlistSubscription = SupabaseService.instance.streamWishlist().listen((liveWishlist) {
      emit(state.copyWith(wishlist: liveWishlist));
      debugPrint('[Wishlist Realtime] Synced ${liveWishlist.length} wishlist items');
    }, onError: (e) {
      debugPrint('[Wishlist Realtime Error] $e');
      _wishlistSubscription?.cancel();
      _wishlistSubscription = null;
    });
  }

  Future<void> loadFromSupabase() async {
    if (_repository is! SupabaseCatalogRepository) {
      emit(state.copyWith(loading: false, error: null));
      return;
    }

    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.refresh();
      final segments = _repository.segments;
      final selected = segments.any((segment) => segment.name == state.selectedSegment)
          ? state.selectedSegment
          : (segments.isNotEmpty ? segments.first.name : state.selectedSegment);
      emit(
        state.copyWith(
          products: _repository.products,
          categories: _repository.categories,
          segments: segments,
          categoryImages: _repository.categoryImages,
          selectedSegment: selected,
          loading: false,
          error: null,
        ),
      );
    } on CatalogUnavailable catch (error) {
      debugPrint('[Catalog] $error');
      emit(state.copyWith(loading: false, error: error.message));
    } catch (error, stack) {
      debugPrint('[Catalog] $error\n$stack');
      emit(
        state.copyWith(
          loading: false,
          error: 'Could not load ice creams from Supabase.',
        ),
      );
    }

    final liveWishlist = await SupabaseService.instance.fetchWishlist();
    if (liveWishlist.isNotEmpty && !isClosed) {
      emit(state.copyWith(wishlist: liveWishlist));
    }
  }

  void selectCategory(String category) {
    emit(state.copyWith(category: category));
  }

  void openCategory(String category) {
    emit(state.copyWith(openedCategory: category));
  }

  void closeCategory() {
    emit(state.copyWith(clearOpenedCategory: true));
  }

  void search(String query) {
    emit(state.copyWith(query: query.trim().toLowerCase()));
  }

  void toggleWishlist(int productId) {
    final isCurrently = state.isWishlisted(productId);
    final next = Set<int>.from(state.wishlist);
    if (isCurrently) {
      next.remove(productId);
    } else {
      next.add(productId);
    }
    emit(state.copyWith(wishlist: next));
    SupabaseService.instance.toggleWishlist(productId, isCurrently);
  }

  void setSort(String sortBy) {
    emit(state.copyWith(sortBy: sortBy));
  }

  void selectSegment(String segment) {
    emit(state.copyWith(selectedSegment: segment));
  }

  @override
  Future<void> close() {
    _wishlistSubscription?.cancel();
    _authSubscription?.cancel();
    return super.close();
  }
}
