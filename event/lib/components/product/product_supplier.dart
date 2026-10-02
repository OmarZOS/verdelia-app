// lib/event/components/product/product_supplier.dart

import 'dart:async';
import 'dart:developer';

import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/services/ProductService.dart';

import 'product_cache.dart';
import 'product_state.dart';

/// Fetches and caches a supplier's product list.
///
/// The cache is keyed on `(supplierId, includeHidden)` so the buyer
/// catalog and the editor catalog can coexist without overwriting each
/// other. A fetch in progress for one mode does not block the other.
class ProductSupplier {
  final ProductService _service;
  final ProductCache _cache;
  final ProductState _state;

  /// Keyed by the composite cache key, not the raw supplier id.
  final Map<String, bool> _fetchingState = {};
  final Map<String, List<void Function(List<Product>)>> _callbacks = {};

  ProductSupplier({
    required ProductService service,
    required ProductCache cache,
    required ProductState state,
  })  : _service = service,
        _cache = cache,
        _state = state;

  String _cacheKey(int supplierId, bool includeHidden) =>
      '$supplierId:${includeHidden ? "all" : "public"}';

  bool isFetching(int supplierId, {bool includeHidden = false}) =>
      _fetchingState[_cacheKey(supplierId, includeHidden)] == true;

  List<Product>? getCached(int supplierId, {bool includeHidden = false}) {
    return _cache.getSupplierProducts(
      supplierId,
      includeHidden: includeHidden,
    );
  }

  Future<List<Product>> fetch(
    int supplierId, {
    bool forceRefresh = false,
    bool includeHidden = false,
  }) async {
    final key = _cacheKey(supplierId, includeHidden);

    // Cache first.
    if (!forceRefresh) {
      final cached = _cache.getSupplierProducts(
        supplierId,
        includeHidden: includeHidden,
      );
      if (cached != null) {
        log('Returning cached products for supplier $supplierId '
            '(includeHidden=$includeHidden)');
        return cached;
      }
    }

    // Deduplicate in-flight requests for the same (supplier, mode).
    if (_fetchingState[key] == true) {
      log('Already fetching $key, waiting...');
      return await _waitForFetch(key);
    }

    _fetchingState[key] = true;
    log('Fetching products for supplier $supplierId '
        '(includeHidden=$includeHidden)');

    try {
      final products = await _service.getAllProducts(
        providerId: supplierId,
        page: 0,
        limit: 100,
        includeHidden: includeHidden,
      );

      final productList = products ?? <Product>[];

      _cache.cacheSupplierProducts(
        supplierId,
        productList,
        includeHidden: includeHidden,
      );

      _notifyCallbacks(key, productList);
      return productList;
    } catch (e) {
      log('Failed to fetch supplier products: $e');
      _notifyCallbacks(key, []);
      return [];
    } finally {
      _fetchingState[key] = false;
      _callbacks.remove(key);
    }
  }

  Future<List<Product>> _waitForFetch(String key) async {
    final completer = Completer<List<Product>>();

    _callbacks.putIfAbsent(key, () => []);
    _callbacks[key]!.add((products) {
      if (!completer.isCompleted) {
        completer.complete(products);
      }
    });

    // Timeout fallback so a hung fetch can't leak a pending future.
    Future.delayed(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.complete([]);
      }
    });

    return completer.future;
  }

  void _notifyCallbacks(String key, List<Product> products) {
    final callbacks = _callbacks[key];
    if (callbacks != null) {
      for (final callback in callbacks) {
        callback(products);
      }
    }
  }

  void invalidateCache(int supplierId, {bool includeHidden = false}) {
    _cache.invalidateSupplierCache(
      supplierId,
      includeHidden: includeHidden,
    );
  }

  bool hasValidCache(int supplierId, {bool includeHidden = false}) {
    return _cache.hasValidSupplierCache(
      supplierId,
      includeHidden: includeHidden,
    );
  }
}
