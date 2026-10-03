// lib/event/components/product/product_state.dart

import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/CategoryHierarchyIndex.dart';

class ProductState {
  final List<Product> products = [];
  final Map<int, int> cartQuantities = {};
  final List<Product> cartItems = [];
  List<ProductCategory> categories = [];
  CategoryHierarchyIndex<ProductCategory> categoryHierarchy =
      CategoryHierarchyIndex.fromItems(
    <ProductCategory>[],
    (category) => category.productCategoryDesc,
  );

  bool isLoading = false;
  bool isCartLoading = false;
  bool hasMoreProducts = true;
  int currentPage = 0;
  int currentCategory = 0;
  int currentUserId = 0;
  int currentProviderId = 0;
  String currentSearchQuery = "";
  int itemsPerPage = 20;

  /// Active top-level domain filter, if any (e.g. `'food'`, `'retail'`).
  ///
  /// Matches the first segment of a product category key
  /// (`domain.subdomain.category`). Null means "no domain filter".
  String? currentDomain;

  /// Active subdomain filter inside [currentDomain] (e.g. `'alimentary'`).
  ///
  /// Only meaningful when [currentDomain] is set; [ProductFetch] drops
  /// it silently if a fetch arrives with a subdomain but no domain.
  String? currentSubdomain;

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
    categoryHierarchy = CategoryHierarchyIndex.fromItems(
      <ProductCategory>[],
      (category) => category.productCategoryDesc,
    );
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
    currentDomain = null;
    currentSubdomain = null;
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

  // ================================================================
  // Hierarchy helpers
  // ================================================================

  /// True when a domain filter is currently active.
  bool get hasDomainFilter =>
      currentDomain != null && currentDomain!.isNotEmpty;

  /// True when both a domain and a subdomain filter are active.
  bool get hasSubdomainFilter =>
      hasDomainFilter &&
      currentSubdomain != null &&
      currentSubdomain!.isNotEmpty;
}
