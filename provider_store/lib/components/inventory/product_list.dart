import 'package:flutter/material.dart';
import 'package:provider_store/components/inventory/category_tile.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/privileges/Privileges.dart';
import 'package:event/product_change_notifier.dart';
import 'package:product_catalog/screens/components/ProductCard.dart';
import 'package:ui/components/utils/responsive_grid.dart';
import 'package:provider/provider.dart';

class ProductList extends StatefulWidget {
  final int selectedSupplierId;
  final String searchQuery;
  final ValueChanged<int> onProductTap;
  final PrivilegeLevel privilegeLevel;
  final bool isLoading;
  final VoidCallback onAddFirstProduct;
  final VoidCallback onManageSuppliers;
  final bool hideHiddenProducts;

  const ProductList({
    super.key,
    required this.selectedSupplierId,
    required this.searchQuery,
    required this.onProductTap,
    required this.privilegeLevel,
    this.isLoading = false,
    required this.onAddFirstProduct,
    required this.onManageSuppliers,
    this.hideHiddenProducts = false,
  });

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  /// Currently selected category id, or 0 for "All".
  ///
  /// Reset whenever the supplier changes — a category that exists for
  /// supplier A may not exist for supplier B, and keeping the selection
  /// would filter the grid down to nothing.
  int _selectedCategoryId = 0;

  @override
  void didUpdateWidget(ProductList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSupplierId != widget.selectedSupplierId) {
      _selectedCategoryId = 0;
    }
  }

  bool get _canManage => widget.privilegeLevel == PrivilegeLevel.manage;
  bool get _canView => widget.privilegeLevel == PrivilegeLevel.view;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (widget.isLoading) {
      return _buildLoadingState(context);
    }

    return Consumer<ProductNotifier>(
      builder: (context, notifier, _) {
        final source = notifier.products;

        // Products matching the supplier (before category filter).
        final supplierProducts = widget.selectedSupplierId > 0
            ? source
                .where(
                    (p) => p.product_provider_id == widget.selectedSupplierId)
                .toList(growable: false)
            : source;

        // Categories that actually exist for this supplier's products.
        final presence = CategoryPresence.fromProducts(
          products: supplierProducts,
          allCategories: notifier.productCategories,
        );

        // Apply the category filter on top of the supplier set.
        final filtered = _filterProducts(supplierProducts);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category strip — collapses to nothing when there's only
            // one category or none.
            CategoryTile(
              categories: presence.categories,
              selectedCategoryId: _selectedCategoryId,
              productCounts: presence.counts,
              onCategorySelected: (id) {
                setState(() => _selectedCategoryId = id);
              },
            ),
            const SizedBox(height: 4),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState(
                      context,
                      localizations,
                      widget.searchQuery.isNotEmpty,
                      source.isNotEmpty && widget.hideHiddenProducts,
                    )
                  : _buildProductGrid(context, filtered),
            ),
          ],
        );
      },
    );
  }

  List<Product> _filterProducts(List<Product> source) {
    Iterable<Product> result = source;

    if (widget.hideHiddenProducts) {
      result = result.where((p) => p.isVisible);
    }

    // Category filter — applied before search so the empty-state copy
    // can distinguish "no products in this category" from "no search
    // results".
    if (_selectedCategoryId > 0) {
      result = result.where(
        (p) => p.product_category_id == _selectedCategoryId,
      );
    }

    if (widget.searchQuery.isNotEmpty) {
      final query = widget.searchQuery.toLowerCase();
      result = result.where((product) {
        return product.product_name?.toLowerCase().contains(query) == true ||
            product.product_brand?.toLowerCase().contains(query) == true ||
            product.product_barcode?.toLowerCase().contains(query) == true;
      });
    }

    return result.toList();
  }

  Widget _buildProductGrid(
    BuildContext context,
    List<Product> filteredProducts,
  ) {
    final hiddenLabel = AppLocalizations.of(context)!.productHiddenLabel;

    return LayoutBuilder(builder: (context, constraints) {
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: responsiveGridDelegate(
          availableWidth: constraints.maxWidth,
        ),
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          // Keyed by product id so Flutter preserves scroll state and
          // widget identity across list rebuilds when items are
          // added/removed/reordered.
          final product = filteredProducts[index];
          return Stack(
            key: ValueKey(product.id_product),
            children: [
              ProductCard(
                mode: ProductDetailsMode.editor,
                product: product,
                // onTap: () => _handleProductTap(product),
              ),
              if (!product.isVisible)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _HiddenBadge(label: hiddenLabel),
                ),
            ],
          );
        },
      );
    });
  }

  Widget _buildLoadingState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.loading,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations localizations,
    bool isSearching,
    bool hiddenByVisibilityFilter,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // If the only reason the grid is empty is that every product is
    // hidden, say so instead of showing the "no products yet" copy.
    final isHiddenOnly = hiddenByVisibilityFilter && !isSearching;

    final IconData icon;
    final String title;
    final String subtitle;

    if (isSearching) {
      icon = Icons.search_off_rounded;
      title = localizations.noProductsFoundText;
      subtitle = localizations.tryDifferentSearchText;
    } else if (isHiddenOnly) {
      icon = Icons.visibility_off_outlined;
      title = localizations.noVisibleProductsText;
      subtitle = localizations.noVisibleProductsText;
    } else {
      icon = Icons.inventory_2_outlined;
      title = localizations.noProductsText;
      subtitle = localizations.addFirstProductText;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // _buildProductGrid, _buildLoadingState, _buildEmptyState — unchanged
  // from your current version, but the empty-state helper now also
  // takes whether a category filter is active.
}

class _HiddenBadge extends StatelessWidget {
  final String label;

  const _HiddenBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility_off_outlined,
            size: 12,
            color: cs.onErrorContainer,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cs.onErrorContainer,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// In ProductList (or a shared helper file)
class CategoryPresence {
  final List<ProductCategory> categories;
  final Map<int, int> counts;

  const CategoryPresence({required this.categories, required this.counts});

  static const empty = CategoryPresence(categories: [], counts: {});

  /// Build the presence map for a supplier's product set.
  ///
  /// Only categories that appear on at least one product are returned.
  /// Ordering follows the notifier's category order so the strip is
  /// stable across rebuilds.
  static CategoryPresence fromProducts({
    required List<Product> products,
    required List<ProductCategory> allCategories,
  }) {
    final counts = <int, int>{};
    for (final product in products) {
      final id = product.product_category_id;
      if (id == null || id <= 0) continue;
      counts[id] = (counts[id] ?? 0) + 1;
    }

    // Preserve the notifier's order so the strip doesn't reshuffle
    // when the user changes supplier or search.
    final present = allCategories
        .where((c) => counts.containsKey(c.productCategoryId))
        .toList(growable: false);

    return CategoryPresence(categories: present, counts: counts);
  }
}
