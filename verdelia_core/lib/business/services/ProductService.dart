// lib/business/services/ProductService.dart

import '../../app/TraceableService.dart';
import '../Product.dart';

/// Contract for all product-related operations.
///
/// Visibility semantics:
///   - `getAllProducts` and `getProductsByCategory` default to excluding
///     hidden products. Buyers see the public catalog only.
///   - `getProduct` and `focusOnProduct` default to returning hidden
///     products, so editors can open a product by id regardless of
///     visibility.
///   - `updateProductVisibility` is the dedicated path for flipping a
///     product between visible and hidden.
///
/// Domain / subdomain filtering follows the `domain.subdomain.category`
/// convention used by product categories. `subdomain` requires `domain`.
abstract class ProductService extends TraceableService {
  Future<List<ProductCategory>?> getCategories({
    bool forceRefresh = false,
    String? callerKey,
  }) async {
    return null;
  }

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
    return null;
  }

  Future<List<Product>?> getProductsByCategory({
    required int categoryId,
    int offset = 0,
    int limit = 10,
    bool includeHidden = false,
    String? callerKey,
  }) async {
    return null;
  }

  Future<Product?> getProduct(
    String idProduct, {
    bool includeHidden = true,
    String? callerKey,
  }) async {
    return null;
  }

  Future<Product?> focusOnProduct(
    String idProduct, {
    bool includeHidden = true,
    String? callerKey,
  }) async {
    return null;
  }

  Future<Product?> addProduct(Product product, {String? callerKey}) async {
    return null;
  }

  Future<Product?> updateProduct(
    Product updatedProduct, {
    String? callerKey,
  }) async {
    return null;
  }

  /// Flip a product's visibility between `VISIBLE` and `HIDDEN`.
  ///
  /// Returns the updated product on success, or null when the request
  /// fails. Accepts only the two canonical values.
  Future<Product?> updateProductVisibility(
    String productId,
    String visibility, {
    String? callerKey,
  }) async {
    return null;
  }

  Future<int?> deleteProduct(String productId, {String? callerKey}) async {
    return null;
  }
}
