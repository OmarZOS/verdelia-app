import 'package:flutter/material.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/privileges/Privileges.dart';
import 'package:event/product_change_notifier.dart';
import 'package:product_catalog/screens/components/ProductCard.dart';
import 'package:provider/provider.dart';

class ProductList extends StatelessWidget {
  final int selectedSupplierId;
  final String searchQuery;
  final ValueChanged<int> onProductTap;
  final PrivilegeLevel privilegeLevel;
  final bool isLoading;
  final VoidCallback onAddFirstProduct;
  final VoidCallback onManageSuppliers;

  /// When true, hidden products are filtered out of the grid even if the
  /// notifier is holding them. Defaults to false so editors see the full
  /// catalog; buyers should pass true (or, better, fetch with
  /// `includeHidden: false` so hidden products never arrive).
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

  bool get _canManage => privilegeLevel == PrivilegeLevel.manage;
  bool get _canView => privilegeLevel == PrivilegeLevel.view;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (isLoading) {
      return _buildLoadingState(context);
    }

    return Consumer<ProductNotifier>(
      builder: (context, notifier, _) {
        // Prefer the notifier's list, but fall back to the empty state
        // while it's still loading so the screen never renders a stale
        // spinner after data has arrived.
        final source = notifier.products;

        final filtered = _filterProducts(source);

        if (filtered.isEmpty) {
          return _buildEmptyState(
            context,
            localizations,
            searchQuery.isNotEmpty,
          );
        }

        return _buildProductGrid(context, filtered);
      },
    );
  }

  /// Apply search + visibility + supplier filters.
  ///
  /// Order matters: visibility filter is cheapest and removes the most
  /// items in the buyer view, so it runs first.
  List<Product> _filterProducts(List<Product> source) {
    Iterable<Product> result = source;

    if (hideHiddenProducts) {
      result = result.where((p) => p.isVisible);
    }

    if (selectedSupplierId > 0) {
      result = result.where(
        (p) => p.product_provider_id == selectedSupplierId,
      );
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
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

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
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
  }

  void _handleProductTap(Product product) {
    if (!_canView) return;
    onProductTap(product.id_product ?? 0);
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
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching
                  ? Icons.search_off_rounded
                  : Icons.inventory_2_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching
                  ? localizations.noProductsFoundText
                  : localizations.noProductsText,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? localizations.tryDifferentSearchText
                  : localizations.addFirstProductText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (_canManage && !isSearching) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAddFirstProduct,
                icon: const Icon(Icons.add_rounded),
                label: Text(localizations.addFirstProduct),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
