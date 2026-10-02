// lib/event/components/product/product_cache.dart

import 'package:verdelia_core/business/Product.dart';

class ProductCache {
  final Map<int, Product> _productCache = {};
  final Map<String, List<int>> _listCache = {};
  List<ProductCategory>? _categoriesCache;

  /// Supplier caches keyed by "<supplierId>:<mode>", where mode is
  /// "public" for buyer fetches and "all" for editor fetches. Keying
  /// this way lets the two lists coexist for the same supplier.
  final Map<String, List<Product>> _supplierProductsCache = {};
  final Map<String, DateTime> _supplierCacheTime = {};

  bool _enabled = true;
  static const _supplierCacheDuration = Duration(minutes: 5);

  bool get isEnabled => _enabled;
  int get productCacheSize => _productCache.length;
  int get listCacheSize => _listCache.length;

  void enable(bool enable) {
    _enabled = enable;
    if (!enable) clearAll();
  }

  void clearAll() {
    _productCache.clear();
    _listCache.clear();
    _categoriesCache = null;
    _supplierProductsCache.clear();
    _supplierCacheTime.clear();
  }

  // ==================== Category cache ====================

  void cacheCategories(List<ProductCategory> categories) {
    if (!_enabled) return;
    _categoriesCache = List.unmodifiable(categories);
  }

  List<ProductCategory>? getCategories() {
    if (!_enabled) return null;
    return _categoriesCache;
  }

  // ==================== Product cache ====================

  void cacheProduct(Product product) {
    if (!_enabled || product.id_product == null) return;
    _productCache[product.id_product!] = product;
  }

  Product? getProduct(int id) {
    if (!_enabled) return null;
    return _productCache[id];
  }

  void invalidateProduct(int? id) {
    if (id != null) {
      _productCache.remove(id);
    } else {
      _productCache.clear();
      _listCache.clear();
    }
  }

  // ==================== List cache ====================

  void cacheList(String key, List<Product> products) {
    if (!_enabled) return;
    _listCache[key] = products.map((p) => p.id_product!).toList();
    for (final p in products) {
      cacheProduct(p);
    }
  }

  List<Product>? getList(String key) {
    if (!_enabled) return null;
    final ids = _listCache[key];
    if (ids == null) return null;

    final products = <Product>[];
    for (final id in ids) {
      final cached = getProduct(id);
      if (cached == null) return null;
      products.add(cached);
    }
    return products;
  }

  void clearListCache() => _listCache.clear();

  // ==================== Supplier products cache ====================

  /// Composite cache key for the per-supplier caches. `includeHidden`
  /// selects between the buyer list ("public") and the editor list
  /// ("all") so the two never overwrite each other.
  String _supplierKey(int supplierId, bool includeHidden) =>
      '$supplierId:${includeHidden ? "all" : "public"}';

  void cacheSupplierProducts(
    int supplierId,
    List<Product> products, {
    bool includeHidden = false,
  }) {
    if (!_enabled) return;
    final key = _supplierKey(supplierId, includeHidden);
    _supplierProductsCache[key] = products;
    _supplierCacheTime[key] = DateTime.now();
    for (final p in products) {
      cacheProduct(p);
    }
  }

  List<Product>? getSupplierProducts(
    int supplierId, {
    bool includeHidden = false,
  }) {
    if (!_enabled) return null;
    final key = _supplierKey(supplierId, includeHidden);
    final cached = _supplierProductsCache[key];
    final time = _supplierCacheTime[key];
    if (cached != null && time != null) {
      if (DateTime.now().difference(time) < _supplierCacheDuration) {
        return cached;
      }
    }
    return null;
  }

  void invalidateSupplierCache(
    int supplierId, {
    bool includeHidden = false,
  }) {
    final key = _supplierKey(supplierId, includeHidden);
    _supplierProductsCache.remove(key);
    _supplierCacheTime.remove(key);
  }

  /// Drop every cached variant for a supplier (buyer + editor). Use
  /// this when a change to one product can invalidate both lists.
  void invalidateSupplierCacheAll(int supplierId) {
    _supplierProductsCache.removeWhere(
      (key, _) => key.startsWith('$supplierId:'),
    );
    _supplierCacheTime.removeWhere(
      (key, _) => key.startsWith('$supplierId:'),
    );
  }

  bool hasValidSupplierCache(
    int supplierId, {
    bool includeHidden = false,
  }) {
    final key = _supplierKey(supplierId, includeHidden);
    final time = _supplierCacheTime[key];
    if (time == null) return false;
    return DateTime.now().difference(time) < _supplierCacheDuration;
  }
}
