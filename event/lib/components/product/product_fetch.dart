// lib/event/components/product/product_fetch.dart

import 'dart:developer';

import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/services/ProductService.dart';

import 'product_cache.dart';
import 'product_state.dart';

class ProductFetch {
  final ProductService _service;
  final ProductCache _cache;
  final ProductState _state;
  final Map<int, Future<Product?>> _pendingRequests = {};

  ProductFetch({
    required ProductService service,
    required ProductCache cache,
    required ProductState state,
  })  : _service = service,
        _cache = cache,
        _state = state;

  // ================================================================
  // Single product
  // ================================================================

  /// Fetch a single product by id.
  ///
  /// [includeHidden] defaults to `true` to match the service contract:
  /// `focusOnProduct` returns hidden products so editors can open any
  /// product by id regardless of visibility.
  Future<Product?> getById(
    int id, {
    bool forceRefresh = false,
    bool includeHidden = true,
  }) async {
    if (!forceRefresh) {
      final cached = _cache.getProduct(id);
      if (cached != null) return cached;
    }

    if (_pendingRequests.containsKey(id)) {
      return _pendingRequests[id];
    }

    final future = _fetchProduct(id, includeHidden: includeHidden);
    _pendingRequests[id] = future;
    return future;
  }

  Future<Product?> _fetchProduct(
    int id, {
    bool includeHidden = true,
  }) async {
    try {
      final product = await _service.focusOnProduct(
        id.toString(),
        includeHidden: includeHidden,
      );
      if (product != null && product.id_product != null) {
        _cache.cacheProduct(product);
      }
      return product;
    } catch (e) {
      log("Failed to fetch product $id: $e");
      return null;
    } finally {
      _pendingRequests.remove(id);
    }
  }

  // ================================================================
  // Product lists
  // ================================================================

  /// Fetch a page of products.
  ///
  /// [includeHidden] controls whether the backend returns hidden
  /// products. It defaults to `false` (buyer catalog) and is part of
  /// the cache key, so a buyer fetch and an editor fetch never collide
  /// in the list cache.
  ///
  /// [domain] and [subdomain] filter by the category hierarchy
  /// (`domain.subdomain.category`). [subdomain] without [domain] is
  /// dropped with a warning.
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
    // Normalise the incoming filter pair.
    final cleanDomain = _cleanSegment(domain);
    var cleanSubdomain = _cleanSegment(subdomain);

    if (cleanSubdomain != null && cleanDomain == null) {
      log(
        'ProductFetch.fetchProducts: subdomain "$cleanSubdomain" '
        'ignored because domain is not set',
      );
      cleanSubdomain = null;
    }

    log(
      'ProductFetch.fetchProducts called: '
      'providerId=$providerId reset=$reset query="$query" '
      'includeHidden=$includeHidden domain=$cleanDomain '
      'subdomain=$cleanSubdomain '
      'currentProviderId=${_state.currentProviderId}',
    );

    if (_state.isLoading) return;

    final paramsChanged = reset ||
        _state.currentCategory != categoryId ||
        _state.currentUserId != userId ||
        _state.currentProviderId != providerId ||
        _state.currentSearchQuery != query ||
        _state.includeHidden != includeHidden ||
        _state.currentDomain != cleanDomain ||
        _state.currentSubdomain != cleanSubdomain;

    if (paramsChanged) {
      _state.currentCategory = categoryId;
      _state.currentUserId = userId;
      _state.currentProviderId = providerId;
      _state.currentSearchQuery = query;
      _state.includeHidden = includeHidden;
      _state.currentDomain = cleanDomain;
      _state.currentSubdomain = cleanSubdomain;
      _state.resetPagination();
      if (reset) _cache.clearListCache();
    }

    if (!_state.hasMoreProducts) return;

    // Check cache for first page. Only buyer-catalog fetches are cached
    // in the list cache; editor fetches (includeHidden == true) always
    // go to the network so visibility changes are picked up promptly.
    if (_state.currentPage == 0 && providerId == 0 && !includeHidden) {
      final cacheKey = _listCacheKey(
        categoryId: categoryId,
        userId: userId,
        providerId: providerId,
        query: query,
        includeHidden: includeHidden,
        domain: cleanDomain,
        subdomain: cleanSubdomain,
      );
      final cached = _cache.getList(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        _state.products.addAll(cached);
        _state.currentPage++;
        return;
      }
    }

    _state.isLoading = true;

    try {
      final fetched = await _service.getAllProducts(
        userId: _state.currentUserId,
        category: _state.currentCategory,
        providerId: _state.currentProviderId,
        query: _state.currentSearchQuery,
        productBarcode: productBarcode,
        offset: _state.currentPage * _state.itemsPerPage,
        limit: _state.itemsPerPage,
        includeHidden: includeHidden,
        domain: cleanDomain,
        subdomain: cleanSubdomain,
      );

      if (fetched != null && fetched.isNotEmpty) {
        if (_state.currentPage == 0 && providerId == 0 && !includeHidden) {
          final cacheKey = _listCacheKey(
            categoryId: categoryId,
            userId: userId,
            providerId: providerId,
            query: query,
            includeHidden: includeHidden,
            domain: cleanDomain,
            subdomain: cleanSubdomain,
          );
          _cache.cacheList(cacheKey, fetched);
        }

        _state.products.addAll(fetched);
        _state.currentPage++;

        if (fetched.length < _state.itemsPerPage) {
          _state.hasMoreProducts = false;
        }
      } else {
        _state.hasMoreProducts = false;
      }

      log(
        'ProductFetch.fetchProducts result: '
        'fetched=${fetched?.length ?? 0} '
        'total=${_state.products.length} '
        'hasMore=${_state.hasMoreProducts} '
        'includeHidden=$includeHidden '
        'domain=$cleanDomain subdomain=$cleanSubdomain',
      );
    } catch (e) {
      log("Failed to fetch products: $e");
      rethrow;
    } finally {
      _state.isLoading = false;
    }
  }

  // ================================================================
  // Category-scoped fetch
  // ================================================================

  /// Fetch a single category page using `getProductsByCategory`.
  ///
  /// Separate from [fetchProducts] because the service exposes a
  /// dedicated endpoint for this; it does not participate in the list
  /// cache (category pages are usually small and short-lived).
  Future<List<Product>> fetchByCategory({
    required int categoryId,
    int offset = 0, // ← was: int page = 1
    int limit = 10,
    bool includeHidden = false,
  }) async {
    try {
      final fetched = await _service.getProductsByCategory(
        categoryId: categoryId,
        offset: offset,
        limit: limit,
        includeHidden: includeHidden,
      );
      return fetched ?? const <Product>[];
    } catch (e) {
      log("Failed to fetch category $categoryId: $e");
      return const <Product>[];
    }
  }

  // ================================================================
  // Sync / filter helpers
  // ================================================================

  Product? getByIdSync(int id) {
    return _cache.getProduct(id) ??
        _state.products.firstWhere(
          (p) => p.id_product == id,
          orElse: () => null as Product,
        );
  }

  List<Product> filterByCategory(int categoryId) {
    return _state.filterByCategory(categoryId);
  }

  List<Product> filterBySupplier(int supplierId) {
    return _state.filterBySupplier(supplierId);
  }

  // ================================================================
  // Internal
  // ================================================================

  /// Cache key for the list cache.
  ///
  /// `includeHidden`, `domain`, and `subdomain` are part of the key so
  /// buyer fetches, editor fetches, and different hierarchy branches
  /// are all stored under distinct entries.
  String _listCacheKey({
    required int categoryId,
    required int userId,
    required int providerId,
    required String query,
    required bool includeHidden,
    String? domain,
    String? subdomain,
  }) {
    final visibility = includeHidden ? 'all' : 'public';
    final domainSegment = domain ?? '_';
    final subdomainSegment = subdomain ?? '_';
    return 'p_${categoryId}_${userId}_${providerId}_'
        '${visibility}_${domainSegment}_${subdomainSegment}_$query';
  }

  /// Trim + lowercase a domain / subdomain segment. Returns null when
  /// the input is null or blank, so downstream calls skip the filter.
  String? _cleanSegment(String? value) {
    if (value == null) return null;
    final cleaned = value.trim().toLowerCase();
    return cleaned.isEmpty ? null : cleaned;
  }
}
