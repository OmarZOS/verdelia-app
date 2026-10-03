// lib/business/services/ProductServiceImpl.dart

library business;

import 'dart:developer';

import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/app/VerdeliaException.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/services/ProductService.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'package:locator/locator.dart';

class ProductServiceImpl extends ProductService {
  final StorageService _storageService = AppLocator.get<StorageService>();
  List<ProductCategory> _categories = [];

  static const _visibilityVisible = 'VISIBLE';
  static const _visibilityHidden = 'HIDDEN';

  // ==================== Traceability helpers ====================

  String _getCallerKey(String method, {String? id, String? suffix}) {
    final parts = [method];
    if (id != null) parts.add(id);
    if (suffix != null) parts.add(suffix);
    if (parts.length == 1) {
      parts.add(DateTime.now().millisecondsSinceEpoch.toString());
    }
    return parts.join('_');
  }

  void _storeSuccess(
    String key,
    dynamic data, {
    int? code,
    String? responseCode,
  }) {
    _storageService.setSuccessResponse(
      key,
      data,
      statusCode: code ?? 200,
      responseCode: responseCode ?? 'SUCCESS',
    );
  }

  void _storeFailure(
    String key,
    dynamic data, {
    int? code,
    String? errorCode,
    String? message,
  }) {
    _storageService.setFailureResponse(
      key,
      data: data,
      statusCode: code ?? 500,
      errorCode: errorCode,
      message: message,
    );
  }

  String _base() => AppConstants.apiBaseUrl;

  // ==================== Create ====================

  @override
  Future<Product?> addProduct(Product product, {String? callerKey}) async {
    final key = callerKey ??
        _getCallerKey(
          'addProduct',
          suffix: product.product_name ?? 'unnamed',
        );
    try {
      final result = await _storageService.insert(
        '${_base()}${AppConstants.addProductEndpoint}',
        product.toJson(),
        callerKey: key,
      );

      if (result == null) {
        _storeFailure(key, null, code: 500, errorCode: 'ADD_FAILED');
        return null;
      }

      final newProduct = Product.fromJson(result as Map<String, dynamic>);
      _storeSuccess(key, newProduct);
      return newProduct;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return null;
    }
  }

  // ==================== Delete ====================

  /// DELETE /products?product_id=...&force_delete=...
  @override
  Future<int?> deleteProduct(String productId, {String? callerKey}) async {
    final key = callerKey ?? _getCallerKey('deleteProduct', id: productId);
    try {
      final result = await _storageService.delete(
        '${_base()}${AppConstants.productEndpoint}',
        // Path segment is now empty; the id goes through the query map.
        '',
        callerKey: key,
        // params: {'product_id': productId, 'force_delete': 'false'},
      );

      if (result == 200 || result == 204) {
        _storeSuccess(key, true);
      } else {
        _storeFailure(key, false, code: result);
      }
      return result;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return null;
    }
  }

  // ==================== Update ====================

  /// PUT /products?product_id=...
  @override
  Future<Product?> updateProduct(
    Product updatedProduct, {
    String? callerKey,
  }) async {
    final key = callerKey ??
        _getCallerKey(
          'updateProduct',
          id: updatedProduct.id_product?.toString() ?? 'unknown',
        );
    try {
      final result = await _storageService.update(
        '${_base()}${AppConstants.updateProductEndpoint}',
        // Path segment is empty; id goes through the query map.
        '',
        {'product_id': updatedProduct.id_product?.toString() ?? ''},
        updatedProduct.toJson(),
        callerKey: key,
      );

      if (result == null) {
        _storeFailure(key, null, code: 500, errorCode: 'UPDATE_FAILED');
        return null;
      }

      final product = Product.fromJson(result as Map<String, dynamic>);
      _storeSuccess(key, product);
      return product;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return null;
    }
  }

  /// Flip a product's visibility between VISIBLE and HIDDEN.
  ///
  /// PATCH /products/visibility?product_id=...&visibility=...
  @override
  Future<Product?> updateProductVisibility(
    String productId,
    String visibility, {
    String? callerKey,
  }) async {
    final normalized = visibility.trim().toUpperCase();
    if (normalized != _visibilityVisible && normalized != _visibilityHidden) {
      log(
        'updateProductVisibility rejected invalid value: $visibility',
        name: 'ProductServiceImpl',
      );
      return null;
    }

    final key = callerKey ??
        _getCallerKey(
          'updateProductVisibility',
          id: productId,
          suffix: normalized,
        );

    try {
      final result = await _storageService.update(
        '${_base()}${AppConstants.productEndpoint}/visibility',
        // No path id anymore.
        '',
        {
          'product_id': productId,
          'visibility': normalized,
        },
        // Empty body: the server reads everything from the query.
        {},
        callerKey: key,
        method: 'PATCH',
      );

      if (result == null) {
        _storeFailure(
          key,
          null,
          code: 500,
          errorCode: 'VISIBILITY_UPDATE_FAILED',
        );
        return null;
      }

      final product = Product.fromJson(result as Map<String, dynamic>);
      _storeSuccess(key, product);
      return product;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return null;
    }
  }

  // ==================== Reads ====================

  /// GET /products/by-id?product_id=...&include_hidden=...
  @override
  Future<Product?> getProduct(
    String id, {
    bool includeHidden = true,
    String? callerKey,
  }) async {
    final key = callerKey ?? _getCallerKey('getProduct', id: id);
    try {
      final data = await _storageService.get(
        '${_base()}${AppConstants.productEndpoint}/by-id',
        // Path id no longer used; id travels in the query.
        '',
        callerKey: key,
        parameters: {
          'product_id': id,
          'include_hidden': includeHidden.toString(),
        },
      );

      if (data == null) {
        _storeFailure(key, null, code: 404, errorCode: 'NOT_FOUND');
        return null;
      }

      final product = Product.fromJson(data as Map<String, dynamic>);
      _storeSuccess(key, product);
      return product;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return null;
    }
  }

  /// GET /products?user_id=...&provider_id=...&category_id=...
  ///      &offset=...&limit=...&domain=...&subdomain=...&include_hidden=...
  @override
  Future<List<Product>?> getAllProducts({
    int userId = 0,
    int providerId = 0,
    int category = 0,
    String query = "",
    int offset = 0,
    int limit = 10,
    bool includeHidden = false,
    String? domain,
    String? subdomain,
    String? callerKey,
  }) async {
    final key = callerKey ?? _getCallerKey('getAllProducts');
    try {
      if (query.isNotEmpty) {
        return await _searchProductsByToken(
          query,
          offset,
          limit,
          callerKey: key,
        );
      }

      final params = <String, String>{
        'user_id': userId.toString(),
        'provider_id': providerId.toString(),
        'category_id': category.toString(),
        'offset': offset.toString(),
        'limit': limit.toString(),
        'include_hidden': includeHidden.toString(),
        if (domain != null && domain.isNotEmpty) 'domain': domain,
        if (subdomain != null && subdomain.isNotEmpty) 'subdomain': subdomain,
      };

      final responseData = await _storageService.getAll(
        '${_base()}${AppConstants.getAllProductsEndpoint}',
        callerKey: key,
        params: params,
      );

      return _parseProductList(responseData, key);
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return [];
    }
  }

  @override
  Future<List<Product>?> getProductsByCategory({
    required int categoryId,
    int offset = 0,
    int limit = 10,
    bool includeHidden = false,
    String? callerKey,
  }) async {
    final key = callerKey ??
        _getCallerKey('getProductsByCategory', id: categoryId.toString());
    try {
      final responseData = await _storageService.getAll(
        '${_base()}${AppConstants.getAllProductsByCategoryEndpoint}',
        callerKey: key,
        params: {
          'category_id': categoryId.toString(),
          'offset': offset.toString(),
          'limit': limit.toString(),
          'include_hidden': includeHidden.toString(),
        },
      );
      return _parseProductList(responseData, key);
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return [];
    }
  }

  /// Same call as `getProduct`; kept as a distinct method for API
  /// symmetry with the older client contract.
  @override
  Future<Product?> focusOnProduct(
    String idProduct, {
    bool includeHidden = true,
    String? callerKey,
  }) async {
    final key = callerKey ?? _getCallerKey('focusOnProduct', id: idProduct);
    try {
      final responseData = await _storageService.get(
        '${_base()}${AppConstants.productEndpoint}/by-id',
        '',
        callerKey: key,
        parameters: {
          'product_id': idProduct,
          'include_hidden': includeHidden.toString(),
        },
      );

      if (responseData == null) {
        _storeFailure(key, null, code: 404, errorCode: 'NOT_FOUND');
        return null;
      }

      final product = Product.fromJson(responseData as Map<String, dynamic>);
      _storeSuccess(key, product);
      return product;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return null;
    }
  }

  // ==================== Categories ====================

  @override
  Future<List<ProductCategory>?> getCategories({String? callerKey}) async {
    final key = callerKey ?? _getCallerKey('getCategories');
    if (_categories.isNotEmpty) {
      _storeSuccess(key, _categories, responseCode: 'CACHED');
      return _categories;
    }

    try {
      final route = '${_base()}'
          '${AppConstants.getProductCategoriesEndpoint}';

      final responseData = await _storageService.getAll(
        route,
        callerKey: key,
      );

      if (responseData == null) {
        _storeSuccess(key, [], responseCode: 'EMPTY');
        return [];
      }

      List<ProductCategory> categoriesList = [];

      if (responseData is List) {
        categoriesList = responseData
            .map((data) =>
                ProductCategory.fromJson(data as Map<String, dynamic>))
            .toList();
      } else if (responseData is Map && responseData.containsKey('data')) {
        final dataList = responseData['data'];
        if (dataList is List) {
          categoriesList = dataList
              .map((data) =>
                  ProductCategory.fromJson(data as Map<String, dynamic>))
              .toList();
        }
      }

      _categories = categoriesList;
      _storeSuccess(key, categoriesList);
      return categoriesList;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return [];
    }
  }

  // ==================== Search ====================

  /// Kept for the token-search path.
  ///
  /// The router now expects `/search/product?token=...&offset=...&limit=...`.
  /// If your `AppConstants.productSearchEndpoint` still points at the
  /// legacy `/search/product/{token}/{offset}/{limit}` route, either
  /// update the constant or use the query-string variant below.
  Future<List<Product>> _searchProductsByToken(
    String token,
    int offset,
    int itemsPerPage, {
    String? callerKey,
  }) async {
    final key =
        callerKey ?? _getCallerKey('searchProductsByToken', suffix: token);
    try {
      final data = await _storageService.getAll(
        '${_base()}${AppConstants.productSearchEndpoint}',
        callerKey: key,
        params: {
          'token': token,
          'offset': offset.toString(),
          'limit': itemsPerPage.toString(),
        },
      );

      if (data == null || data.isEmpty) {
        _storeSuccess(key, [], responseCode: 'EMPTY');
        return [];
      }

      List<Product> products = [];

      if (data is List) {
        products = data
            .map((item) => Product.fromSearchJson(item as Map<String, dynamic>))
            .toList();
      } else if (data is Map && data.containsKey('data')) {
        products = (data['data'] as List)
            .map((item) => Product.fromSearchJson(item as Map<String, dynamic>))
            .toList();
      }

      _storeSuccess(key, products);
      return products;
    } catch (e) {
      _storeFailure(
        key,
        e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR',
      );
      return [];
    }
  }

  // ==================== Cache ====================

  void clearCache() {
    _categories.clear();
    log('Product service cache cleared', name: 'ProductServiceImpl');
  }

  Future<List<ProductCategory>> refreshCategories({String? callerKey}) async {
    _categories.clear();
    return await getCategories(callerKey: callerKey) ?? [];
  }

  // ==================== Private helpers ====================

  List<Product> _parseProductList(dynamic responseData, String key) {
    if (responseData == null) {
      _storeSuccess(key, [], responseCode: 'EMPTY');
      return [];
    }

    List<Product> products = [];

    if (responseData is List) {
      products = responseData
          .map((data) => Product.fromJson(data as Map<String, dynamic>))
          .toList();
    } else if (responseData is Map && responseData.containsKey('data')) {
      final dataList = responseData['data'];
      if (dataList is List) {
        products = dataList
            .map((data) => Product.fromJson(data as Map<String, dynamic>))
            .toList();
      }
    } else if (responseData is Map) {
      products = [Product.fromJson(responseData)];
    }

    _storeSuccess(key, products);
    return products;
  }
}
