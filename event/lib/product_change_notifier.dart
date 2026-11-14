// lib/event/components/product/product_notifier.dart

import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:event/components/product/product_cache.dart';
import 'package:event/components/product/product_cart.dart';
import 'package:event/components/product/product_category_persistence.dart';
import 'package:event/components/product/product_crud.dart';
import 'package:event/components/product/product_fetch.dart';
import 'package:event/components/product/product_polling.dart';
import 'package:event/components/product/product_state.dart';
import 'package:event/components/product/product_supplier.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/CategoryHierarchyIndex.dart';
import 'package:verdelia_core/business/services/ProductService.dart';
import 'package:locator/locator.dart';

class ProductNotifier extends ChangeNotifier {
  final ProductService _service = AppLocator.get<ProductService>();
  final ProductCategoryPersistence _categoryPersistence =
      ProductCategoryPersistence();
  late final Future<void> _categoryBootstrap;
  Future<List<ProductCategory>>? _categoriesInFlight;

  // Components
  late final ProductState _state;
  late final ProductCache _cache;
  late final ProductCrud _crud;
  late final ProductFetch _fetch;
  late final ProductCart _cart;
  late final ProductSupplier _supplier;
  late final ProductPolling _polling;

  ProductNotifier() {
    _initComponents();
    _categoryBootstrap = _bootstrapCategories();
  }

  // ============ STATE GETTERS ============

  String get currentSearchQuery => _state.currentSearchQuery;
  int get currentProviderId => _state.currentProviderId;
  int get currentCategory => _state.currentCategory;
  int get currentUserId => _state.currentUserId;
  String? get currentDomain => _state.currentDomain;
  String? get currentSubdomain => _state.currentSubdomain;
  int get itemsPerPage => _state.itemsPerPage;

  List<Product> get products => _state.products;
  List<Product> get cartItems => _cart.items;
  Map<int, int> get cartQuantities => _cart.quantities;
  bool get isLoading => _state.isLoading;
  bool get isCartLoading => _cart.isLoading;
  bool get hasMoreProducts => _state.hasMoreProducts;
  List<String> get categories => categoriesFor();

  List<ProductCategory> get productCategories {
    if (_state.categories.isEmpty && _categoriesInFlight == null) {
      unawaited(fetchCategories());
    }
    return _state.categories;
  }

  bool get supportsSupplierFilter => _state.supportsSupplierFilter;
  bool get isCacheEnabled => _cache.isEnabled;
  bool get includeHidden => _state.includeHidden;

  List<Product> get hiddenProducts =>
      _state.products.where((p) => !p.isVisible).toList();

  List<Product> get visibleProducts =>
      _state.products.where((p) => p.isVisible).toList();

  // ============ CATEGORIES ============

  Future<List<ProductCategory>> ensureCategoriesLoaded({
    bool forceRefresh = false,
    String? callerKey,
  }) =>
      fetchCategories(forceRefresh: forceRefresh, callerKey: callerKey);

  Future<List<ProductCategory>> fetchCategories({
    bool forceRefresh = false,
    String? callerKey,
  }) async {
    await _categoryBootstrap;

    if (!forceRefresh && _state.categories.isNotEmpty) {
      return _state.categories;
    }

    if (!forceRefresh) {
      final cached = _cache.getCategories();
      if (cached != null && cached.isNotEmpty) {
        _setCategories(cached);
        return _state.categories;
      }
    }

    final pending = _categoriesInFlight;
    if (pending != null) {
      if (!forceRefresh) return pending;
      try {
        await pending;
      } catch (_) {}
    }

    final request = _fetchAndPersistCategories(
      callerKey: callerKey,
      forceRefresh: forceRefresh,
    );
    _categoriesInFlight = request;
    try {
      return await request;
    } finally {
      if (identical(_categoriesInFlight, request)) {
        _categoriesInFlight = null;
      }
    }
  }

  Future<void> _bootstrapCategories() async {
    await _restorePersistedCategories();

    if (_state.categories.isEmpty) {
      try {
        await fetchCategories();
      } catch (error, stackTrace) {
        debugPrint(
          '[ProductNotifier] Category bootstrap fetch failed: '
          '$error\n$stackTrace',
        );
      }
    }
  }

  Future<void> _restorePersistedCategories() async {
    try {
      final persisted = await _categoryPersistence.load();
      if (persisted == null || persisted.isEmpty) {
        _state.categories = const [];
        return;
      }
      _setCategories(persisted);
    } catch (error, stackTrace) {
      debugPrint(
        '[ProductNotifier] Failed to restore product categories: '
        '$error\n$stackTrace',
      );
    }
  }

  Future<List<ProductCategory>> _fetchAndPersistCategories({
    String? callerKey,
    required bool forceRefresh,
  }) async {
    final fetched = await _service.getCategories(
      forceRefresh: forceRefresh,
      callerKey: callerKey,
    );

    final categories = fetched ?? const <ProductCategory>[];
    if (categories.isEmpty) {
      debugPrint(
        '[ProductNotifier] getCategories returned an empty list '
        '(forceRefresh=$forceRefresh, callerKey=$callerKey)',
      );
      return _state.categories;
    }

    _setCategories(categories);
    try {
      await _categoryPersistence.save(categories);
    } catch (error, stackTrace) {
      debugPrint(
        '[ProductNotifier] Failed to persist product categories: '
        '$error\n$stackTrace',
      );
    }
    return _state.categories;
  }

  void _setCategories(List<ProductCategory> categories) {
    _cache.cacheCategories(categories);
    _state.categories = List.of(categories);
    _state.categoryHierarchy = CategoryHierarchyIndex.fromItems(
      categories,
      (category) => category.productCategoryDesc,
    );
    _notify();
  }

  CategoryHierarchyIndex<ProductCategory> get categoryHierarchy =>
      _state.categoryHierarchy;

  List<String> categoriesFor([String languageCode = 'en']) => _state.categories
      .map((category) => category.nameFor(languageCode))
      .toList();

  String categoryName(int? categoryId, {String languageCode = 'en'}) {
    if (categoryId == null) return '';
    for (final category in _state.categories) {
      if (category.productCategoryId == categoryId) {
        return category.nameFor(languageCode);
      }
    }
    return '';
  }

  List<ProductCategory> categoriesForDomain({
    required String domain,
    String? subdomain,
  }) {
    final prefix = subdomain == null || subdomain.isEmpty
        ? '$domain.'
        : '$domain.$subdomain.';
    return _state.categories
        .where((c) => c.productCategoryDesc.startsWith(prefix))
        .toList();
  }

  // ============ INIT ============

  void _initComponents() {
    _state = ProductState();
    _cache = ProductCache();
    _crud = ProductCrud(
      service: _service,
      cache: _cache,
      state: _state,
    );
    _fetch = ProductFetch(
      service: _service,
      cache: _cache,
      state: _state,
    );
    _cart = ProductCart(_state);
    _supplier = ProductSupplier(
      service: _service,
      cache: _cache,
      state: _state,
    );
    _polling = ProductPolling(
      service: _service,
      cache: _cache,
      state: _state,
    );
  }

  @override
  void dispose() {
    _polling.dispose();
    super.dispose();
  }

  // ============ SAFE NOTIFICATION ============

  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_state.isLoading && hasListeners) {
        notifyListeners();
      }
    });
  }

  void _notify() {
    if (!_state.isLoading) {
      _safeNotify();
    }
  }

  // ============ CART OPERATIONS ============

  void addToCart(Product product, {int quantity = 1}) {
    _cart.add(product, quantity: quantity);
    _notify();
  }

  void removeFromCart(int productId) {
    _cart.remove(productId);
    _notify();
  }

  void updateCartQuantity(int productId, int quantity) {
    _cart.updateQuantity(productId, quantity);
    _notify();
  }

  void clearCart() {
    _cart.clear();
    _notify();
  }

  int getCartQuantity(int productId) => _cart.getQuantity(productId);
  bool isInCart(int productId) => _cart.contains(productId);
  int get totalCartItems => _cart.totalItems;

  /// Sum of `product_price × quantity` across every cart line, in
  /// [Decimal]. Delegates to [ProductCart.totalPrice], which is now
  /// `Decimal`.
  Decimal get totalCartPrice => _cart.totalPrice;

  // ============ CRUD OPERATIONS ============

  Future<Product?> addOrUpdateProduct(Product product) async {
    final result = await _crud.createOrUpdate(product);
    if (result != null) {
      await _fetch.fetchProducts(reset: true);
      _notify();
    }
    return result;
  }

  Future<int?> deleteProduct(String idProduct) async {
    final result = await _crud.delete(idProduct);
    _notify();
    return result;
  }

  // ============ VISIBILITY ============

  Future<int> updateProductVisibility(
    int productId,
    String visibility, {
    String? callerKey,
  }) async {
    final normalized = visibility.toUpperCase().trim();
    if (normalized != 'VISIBLE' && normalized != 'HIDDEN') {
      debugPrint(
        '[ProductNotifier] updateProductVisibility: '
        'rejected non-canonical value "$visibility"',
      );
      return 400;
    }

    if (productId <= 0) {
      debugPrint(
        '[ProductNotifier] updateProductVisibility: '
        'invalid product id $productId',
      );
      return 400;
    }

    try {
      final updated = await _service.updateProductVisibility(
        productId.toString(),
        normalized,
        callerKey: callerKey,
      );

      if (updated == null) {
        return 500;
      }

      _replaceInState(updated);
      _cache.invalidateProduct(productId);

      final supplierId = updated.product_provider_id ?? 0;
      if (supplierId > 0) {
        _cache.invalidateSupplierCacheAll(supplierId);
      }

      if (!_state.includeHidden && !updated.isVisible) {
        _state.products.removeWhere((p) => p.id_product == productId);
      }

      _notify();
      return 200;
    } catch (e, st) {
      debugPrint('[ProductNotifier] updateProductVisibility failed: $e\n$st');
      return 500;
    }
  }

  Future<int> showProduct(int productId, {String? callerKey}) =>
      updateProductVisibility(productId, 'VISIBLE', callerKey: callerKey);

  Future<int> hideProduct(int productId, {String? callerKey}) =>
      updateProductVisibility(productId, 'HIDDEN', callerKey: callerKey);

  Future<int> toggleProductVisibility(
    int productId, {
    String? callerKey,
  }) async {
    final current = _fetch.getByIdSync(productId);
    final next = (current?.isVisible ?? true) ? 'HIDDEN' : 'VISIBLE';
    return updateProductVisibility(productId, next, callerKey: callerKey);
  }

  void _replaceInState(Product updated) {
    final index = _state.products.indexWhere(
      (p) => p.id_product == updated.id_product,
    );
    if (index >= 0) {
      _state.products[index] = updated;
    }
  }

  bool removeProductImage({
    required Product product,
    required ProductImage image,
  }) {
    final productId = product.id_product;
    if (productId == null) return false;

    final stateIndex =
        _state.products.indexWhere((item) => item.id_product == productId);
    final current = stateIndex >= 0
        ? _state.products[stateIndex]
        : _cache.getProduct(productId) ?? product;
    final images = current.product_images;
    final remaining = images.where((candidate) {
      if (image.id > 0) return candidate.id != image.id;
      return !identical(candidate, image);
    }).toList(growable: false);

    if (remaining.length == images.length) return false;

    final updated = current.copyWith(product_images: remaining);
    if (stateIndex >= 0) {
      _state.products[stateIndex] = updated;
    }
    _cache.cacheProduct(updated);

    final supplierId = updated.product_provider_id ?? 0;
    if (supplierId > 0) _cache.invalidateSupplierCacheAll(supplierId);

    _notify();
    return true;
  }

  // ============ FETCH OPERATIONS ============

  Future<void> fetchProducts({
    int categoryId = 0,
    int userId = 0,
    int providerId = 0,
    String? productBarcode,
    String query = "",
    bool reset = false,
    bool includeHidden = false,
    String? domain,
    String? subdomain,
  }) async {
    final cleanDomain = _cleanSegment(domain);
    var cleanSubdomain = _cleanSegment(subdomain);

    if (cleanSubdomain != null && cleanDomain == null) {
      debugPrint(
        '[ProductNotifier] fetchProducts: subdomain "$cleanSubdomain" '
        'ignored because domain is not set',
      );
      cleanSubdomain = null;
    }

    await _fetch.fetchProducts(
      categoryId: categoryId,
      userId: userId,
      providerId: providerId,
      productBarcode: productBarcode,
      query: query,
      reset: reset,
      includeHidden: includeHidden,
      domain: cleanDomain,
      subdomain: cleanSubdomain,
    );
    _notify();
  }

  Future<Product?> getProductById(int id, {bool forceRefresh = false}) async {
    return _fetch.getById(id, forceRefresh: forceRefresh);
  }

  Product? getProductByIdSync(int id) => _fetch.getByIdSync(id);

  List<Product> filterProductsByCategory(int categoryId) =>
      _fetch.filterByCategory(categoryId);

  List<Product> filterProductsBySupplier(int supplierId) =>
      _fetch.filterBySupplier(supplierId);

  Future<void> applyCategoryFilters({
    String? domain,
    String? subdomain,
    int categoryId = 0,
    bool reset = true,
  }) async {
    await fetchProducts(
      categoryId: categoryId,
      domain: domain,
      subdomain: subdomain,
      reset: reset,
    );
  }

  Future<void> searchProducts(
    String query, {
    bool reset = true,
    String? domain,
    String? subdomain,
  }) async {
    final cleanDomain = _cleanSegment(domain) ?? _state.currentDomain;
    var cleanSubdomain = _cleanSegment(subdomain) ?? _state.currentSubdomain;

    if (cleanSubdomain != null && cleanDomain == null) {
      debugPrint(
        '[ProductNotifier] searchProducts: subdomain "$cleanSubdomain" '
        'ignored because domain is not set',
      );
      cleanSubdomain = null;
    }

    await _fetch.fetchProducts(
      categoryId: _state.currentCategory,
      userId: _state.currentUserId,
      providerId: _state.currentProviderId,
      query: query,
      reset: reset,
      includeHidden: _state.includeHidden,
      domain: cleanDomain,
      subdomain: cleanSubdomain,
    );
    _notify();
  }

  // ============ SUPPLIER PRODUCTS ============

  bool isFetchingSupplierProducts(
    int supplierId, {
    bool includeHidden = false,
  }) =>
      _supplier.isFetching(supplierId, includeHidden: includeHidden);

  List<Product>? getCachedSupplierProducts(
    int supplierId, {
    bool includeHidden = false,
  }) =>
      _supplier.getCached(supplierId, includeHidden: includeHidden);

  Future<List<Product>> fetchSupplierProducts(
    int supplierId, {
    bool forceRefresh = false,
    bool includeHidden = false,
  }) async {
    final results = await _supplier.fetch(
      supplierId,
      forceRefresh: forceRefresh,
      includeHidden: includeHidden,
    );
    _notify();
    return results;
  }

  void invalidateSupplierCache(
    int supplierId, {
    bool includeHidden = false,
  }) {
    _supplier.invalidateCache(supplierId, includeHidden: includeHidden);
    _notify();
  }

  void invalidateSupplierCacheAll(int supplierId) {
    _cache.invalidateSupplierCacheAll(supplierId);
    _notify();
  }

  bool hasValidSupplierCache(
    int supplierId, {
    bool includeHidden = false,
  }) =>
      _supplier.hasValidCache(supplierId, includeHidden: includeHidden);

  // ============ POLLING ============

  void startPollingProductUpdates(Product product) {
    _polling.start(product);
  }

  void stopPollingProductUpdates() {
    _polling.stop();
  }

  // ============ CACHE MANAGEMENT ============

  void enableCaching(bool enable) {
    _cache.enable(enable);
    _notify();
  }

  void invalidateProductCache({int? productId}) {
    _cache.invalidateProduct(productId);
    _notify();
  }

  void refreshAllCaches() {
    _cache.clearAll();
    _notify();
  }

  // ============ ORDER SUCCESS ============

  Future<void> onOrderSuccess({
    List<int>? orderedProductIds,
    bool refreshProducts = true,
    bool clearCart = true,
  }) async {
    if (clearCart) {
      _cart.clear();
    }

    if (refreshProducts) {
      if (orderedProductIds != null && orderedProductIds.isNotEmpty) {
        for (final id in orderedProductIds) {
          _cache.invalidateProduct(id);
        }
      }
      await _fetch.fetchProducts(reset: true);
    }

    _notify();
  }

  // ============ STATE RESET ============

  void reset() {
    _state.reset();
    _cache.clearAll();
    _notify();
  }

  // ============ CACHE STATS ============

  Map<String, int> getCacheStats() {
    return {
      'productCache': _cache.productCacheSize,
      'listCache': _cache.listCacheSize,
    };
  }

  // ============ HELPERS ============

  String? _cleanSegment(String? value) {
    if (value == null) return null;
    final cleaned = value.trim().toLowerCase();
    return cleaned.isEmpty ? null : cleaned;
  }
}
