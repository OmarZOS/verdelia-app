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
        '${AppConstants.apiBaseUrl}${AppConstants.addProductEndpoint}',
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

  @override
  Future<int?> deleteProduct(String productId, {String? callerKey}) async {
    final key = callerKey ?? _getCallerKey('deleteProduct', id: productId);
    try {
      final result = await _storageService.delete(
        '${AppConstants.apiBaseUrl}'
        '${AppConstants.deleteProductEndpoint}',
        productId,
        callerKey: key,
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
        '${AppConstants.apiBaseUrl}'
        '${AppConstants.updateProductEndpoint ?? AppConstants.productEndpoint}',
        updatedProduct.id_product?.toString() ?? '',
        {"product_id": updatedProduct.id_product?.toString() ?? ''},
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
  /// Calls `PATCH /products/{id}/visibility?visibility=...`. The router
  /// validates the value; this method sends it as sent and lets the
  /// server reject anything unexpected.
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
        // Base route: PATCH /products/{id}/visibility
        '${AppConstants.apiBaseUrl}'
        '${AppConstants.productEndpoint}/visibility',
        // Path id used by the storage service to build the URL.
        productId,
        // Query parameters.
        {'visibility': normalized},
        // Body: empty. The server reads everything it needs from the
        // path and the query string.
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

  @override
  Future<Product?> getProduct(
    String id, {
    bool includeHidden = true,
    String? callerKey,
  }) async {
    final key = callerKey ?? _getCallerKey('getProduct', id: id);
    try {
      final data = await _storageService.get(
        '${AppConstants.apiBaseUrl}${AppConstants.productEndpoint}',
        id,
        callerKey: key,
        parameters: {'include_hidden': includeHidden.toString()},
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

  @override
  Future<List<Product>?> getAllProducts({
    int userId = 0,
    int providerId = 0,
    int category = 0,
    String query = "",
    int page = 1,
    int limit = 10,
    bool includeHidden = false,
    String? callerKey,
  }) async {
    final key = callerKey ?? _getCallerKey('getAllProducts');

    try {
      if (query.isNotEmpty) {
        return await _searchProductsByToken(
          query,
          page,
          limit,
          callerKey: key,
        );
      }

      final route =
          '${AppConstants.apiBaseUrl}${AppConstants.getAllProductsEndpoint}'
          '/$userId/$providerId/$category/$page/$limit';

      final responseData = await _storageService.getAll(
        route,
        callerKey: key,
        params: {'include_hidden': includeHidden.toString()},
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
    int page = 1,
    int limit = 10,
    bool includeHidden = false,
    String? callerKey,
  }) async {
    final key = callerKey ??
        _getCallerKey(
          'getProductsByCategory',
          id: categoryId.toString(),
        );
    try {
      final route = '${AppConstants.apiBaseUrl}'
          '${AppConstants.getAllProductsByCategoryEndpoint}'
          '/$categoryId/$page/$limit';

      final responseData = await _storageService.getAll(
        route,
        callerKey: key,
        params: {'include_hidden': includeHidden.toString()},
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
  Future<Product?> focusOnProduct(
    String idProduct, {
    bool includeHidden = true,
    String? callerKey,
  }) async {
    final key = callerKey ?? _getCallerKey('focusOnProduct', id: idProduct);
    try {
      final responseData = await _storageService.get(
        '${AppConstants.apiBaseUrl}${AppConstants.productEndpoint}',
        idProduct,
        callerKey: key,
        parameters: {'include_hidden': includeHidden.toString()},
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
      final route = '${AppConstants.apiBaseUrl}'
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
        '${AppConstants.apiBaseUrl}'
        '${AppConstants.productSearchEndpoint}/$token/$offset/$itemsPerPage',
        callerKey: key,
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

  /// Parse the shape a listing endpoint returns into a `List<Product>`.
  /// Handles three cases: bare list, `{"data": [...]}`, and a single
  /// object returned instead of a list.
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
