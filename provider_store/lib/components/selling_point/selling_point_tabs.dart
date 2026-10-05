import 'package:flutter/material.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';
import 'package:provider_store/components/selling_point/selling_items/item_card_with_controls.dart';
import 'package:provider_store/components/selling_point/selling_items/tab_selector.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class SellingItemTabs extends StatefulWidget {
  final List<Product> products;
  final List<ProvidedService> services;
  final bool isLoading;
  final CartChangeNotifier cartNotifier;
  final Function(Product) onAddToCart;
  final Function(ProvidedService) onAddServiceToCart;
  final Function(Product) onRemoveFromCart;
  final Function(ProvidedService) onRemoveServiceFromCart;
  final Function(Product) onConfigureProduct;
  final Function(ProvidedService) onConfigureService;

  const SellingItemTabs({
    super.key,
    required this.products,
    required this.services,
    required this.isLoading,
    required this.cartNotifier,
    required this.onAddToCart,
    required this.onAddServiceToCart,
    required this.onRemoveFromCart,
    required this.onRemoveServiceFromCart,
    required this.onConfigureProduct,
    required this.onConfigureService,
  });

  @override
  State<SellingItemTabs> createState() => _SellingItemTabsState();
}

class _SellingItemTabsState extends State<SellingItemTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChanged);
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging ||
        _selectedTab == _tabController.index) {
      return;
    }
    setState(() => _selectedTab = _tabController.index);
  }

  void _selectTab(int index) {
    if (_selectedTab == index) return;
    setState(() => _selectedTab = index);
    _tabController.animateTo(index);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabSelector(
          selectedTab: _selectedTab,
          onTabChanged: _selectTab,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              ListenableBuilder(
                listenable: widget.cartNotifier,
                builder: (context, _) => _buildProductGrid(context),
              ),
              ListenableBuilder(
                listenable: widget.cartNotifier,
                builder: (context, _) => _buildServiceGrid(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================================================================
  // Product grid
  // ==================================================================

  Widget _buildProductGrid(BuildContext context) {
    if (widget.isLoading && widget.products.isEmpty) {
      return _buildLoadingState(context);
    }

    if (widget.products.isEmpty) {
      return _buildEmptyState(context, isProduct: true);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: _responsiveGridDelegate(
            availableWidth: constraints.maxWidth,
            context: context,
          ),
          itemCount: widget.products.length,
          itemBuilder: (context, index) {
            final product = widget.products[index];
            final quantity = _getProductQuantity(product.id_product ?? 0);

            return ItemCardWithConfiguration(
              item: product,
              isProduct: true,
              quantity: quantity,
              onAddToCart: () => widget.cartNotifier.addProduct(product),
              onRemoveFromCart: () {
                final qty =
                    widget.cartNotifier.getProductCartItem(product)?.quantity ??
                        0;
                if (qty <= 1) {
                  widget.cartNotifier.removeItem(product: product);
                } else {
                  widget.cartNotifier.updateQuantity(
                    product: product,
                    newQuantity: qty - 1,
                  );
                }
              },
              onRemoveAll: () =>
                  widget.cartNotifier.removeItem(product: product),
              onConfigure: () => widget.onConfigureProduct(product),
            );
          },
        );
      },
    );
  }

  // ==================================================================
  // Service grid
  // ==================================================================

  Widget _buildServiceGrid(BuildContext context) {
    if (widget.isLoading && widget.services.isEmpty) {
      return _buildLoadingState(context);
    }

    if (widget.services.isEmpty) {
      return _buildEmptyState(context, isProduct: false);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: _responsiveGridDelegate(
            availableWidth: constraints.maxWidth,
            context: context,
          ),
          itemCount: widget.services.length,
          itemBuilder: (context, index) {
            final service = widget.services[index];
            final quantity = _getServiceQuantity(service.id);

            return ItemCardWithConfiguration(
              item: service,
              isProduct: false,
              quantity: quantity,
              onAddToCart: () => widget.onAddServiceToCart(service),
              onConfigure: () => widget.onConfigureService(service),
              onRemoveFromCart: () {
                final qty =
                    widget.cartNotifier.getServiceCartItem(service)?.quantity ??
                        0;
                if (qty <= 1) {
                  widget.cartNotifier.removeItem(service: service);
                } else {
                  widget.cartNotifier.updateQuantity(
                    service: service,
                    newQuantity: qty - 1,
                  );
                }
              },
              onRemoveAll: () =>
                  widget.cartNotifier.removeItem(service: service),
            );
          },
        );
      },
    );
  }

  // ==================================================================
  // Responsive grid delegate
  // ==================================================================

  /// Pick a column count and aspect ratio that keep tiles a sensible
  /// size at every screen width.
  ///
  /// Column count is derived from the widest acceptable tile:
  /// `usableWidth / (maxTileWidth + spacing)`, rounded up so the last
  /// column isn't chopped. Clamped to 1..6 so extremes (folded phones,
  /// ultra-wide desktops) don't produce absurd counts.
  ///
  /// Aspect ratio widens with the column count so a single-column
  /// phone tile is a squat banner rather than a tall strip, and a
  /// six-column desktop tile is a compact card.
  SliverGridDelegate _responsiveGridDelegate({
    required double availableWidth,
    required BuildContext context,
    double maxTileWidth = 220,
    double spacing = 12,
    double padding = 12,
  }) {
    final usable = availableWidth - (padding * 2);
    final columns = (usable / (maxTileWidth + spacing)).ceil().clamp(1, 6);
    final tileWidth = (usable - (spacing * (columns - 1))) / columns;

    // Scale everything by the ambient text scale so tiles stay
    // proportional when the user cranks font size up.
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(0.8, 1.6);

    // Image scales with tile width, bounded.
    final imageHeight = (tileWidth * 0.45).clamp(64.0, 120.0);

    // Info block: title (2 lines) + optional brand + price + stock row.
    // At textScale = 1 this is ~86dp; scale it linearly and add a small
    // cushion for line-height variation.
    final infoHeight = (86.0 * textScale).clamp(86.0, 140.0);

    // Controls bar (with insets) — only relevant for in-cart tiles, but
    // we always size for it so the layout doesn't jump when items are
    // added. If you'd rather cards shrink when out of cart, use the
    // max of (in-cart, out-of-cart) here and let the card fill.
    final controlsHeight = (52.0 * textScale).clamp(44.0, 76.0);

    const paddingTotal = 24.0;

    final tileHeight = imageHeight + infoHeight + controlsHeight + paddingTotal;

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      mainAxisExtent: tileHeight, // ← exact height, no aspect ratio
    );
  }
  // ==================================================================
  // Cart quantity lookups
  // ==================================================================

  int _getProductQuantity(int productId) {
    if (productId <= 0) return 0;
    return widget.cartNotifier.cartItems
        .where((item) => (item.product?.id_product ?? 0) == productId)
        .fold(0, (sum, item) => sum + item.quantity);
  }

  int _getServiceQuantity(int serviceId) {
    if (serviceId <= 0) return 0;
    return widget.cartNotifier.cartItems
        .where((item) => (item.service?.id ?? 0) == serviceId)
        .fold(0, (sum, item) => sum + item.quantity);
  }

  // ==================================================================
  // Loading / empty states
  // ==================================================================

  Widget _buildLoadingState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            localizations.loading,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isProduct}) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isProduct ? Icons.inventory_outlined : Icons.handyman_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            isProduct
                ? localizations.noProductsFound
                : localizations.noServicesFound,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isProduct
                ? localizations.addProductsToGetStarted
                : localizations.addServicesToGetStarted,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
