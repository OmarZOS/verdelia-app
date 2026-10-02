// lib/event/components/product/product_state.dart

import 'package:verdelia_core/business/Product.dart';

class ProductState {
  final List<Product> products = [];
  final Map<int, int> cartQuantities = {};
  final List<Product> cartItems = [];
  List<ProductCategory> categories = [];

  bool isLoading = false;
  bool isCartLoading = false;
  bool hasMoreProducts = true;
  int currentPage = 0;
  int currentCategory = 0;
  int currentUserId = 0;
  int currentProviderId = 0;
  String currentSearchQuery = "";
  int itemsPerPage = 20;

  /// Whether the current product list includes hidden products.
  ///
  /// Set by [ProductFetch.fetchProducts] on every fetch. Defaults to
  /// `false` to match the service contract, where `getAllProducts`
  /// excludes hidden products for buyers unless told otherwise.
  ///
  /// This is a *mode*, not pagination state: [resetPagination] leaves
  /// it alone so that switching pages does not silently drop back to
  /// the buyer catalog. Only [reset] clears it.
  bool includeHidden = false;

  void reset() {
    products.clear();
    categories.clear();
    cartQuantities.clear();
    cartItems.clear();
    isLoading = false;
    isCartLoading = false;
    hasMoreProducts = true;
    currentPage = 0;
    currentCategory = 0;
    currentUserId = 0;
    currentProviderId = 0;
    currentSearchQuery = "";
    includeHidden = false;
  }

  void resetPagination() {
    currentPage = 0;
    hasMoreProducts = true;
    products.clear();
  }

  bool get supportsSupplierFilter => true;

  List<Product> filterByCategory(int categoryId) {
    if (categoryId == 0) return List.unmodifiable(products);
    return products
        .where((product) => product.product_category_id == categoryId)
        .toList();
  }

  List<Product> filterBySupplier(int supplierId) {
    return products
        .where((product) => product.product_provider_id == supplierId)
        .toList();
  }

  // ================================================================
  // Visibility-aware views
  // ================================================================

  /// Products currently visible in the buyer-facing catalog.
  List<Product> get visibleProducts =>
      products.where((p) => p.isVisible).toList();

  /// Products hidden from buyers but present in the current list.
  ///
  /// Only non-empty when [includeHidden] is true, since buyer fetches
  /// never return hidden products in the first place.
  List<Product> get hiddenProducts =>
      products.where((p) => !p.isVisible).toList();
}
