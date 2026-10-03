import 'dart:async';

import 'package:app_constants/app_routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/iProduct.dart';
import 'package:event/user_change_notifier.dart';
import 'package:event/product_change_notifier.dart';
import 'package:event/preferenceChangeNotifier.dart';
import 'package:product_catalog/screens/components/ProductCard.dart';
import 'package:ui/components/floating_buttons.dart';
import 'package:ui/components/hierarchical_category_picker.dart';
import 'package:product_catalog/screens/iproduct_details_screen.dart';
import 'package:provider/provider.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({Key? key}) : super(key: key);

  @override
  ProductCatalogScreenState createState() => ProductCatalogScreenState();
}

class ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocus = FocusNode();

  int _selectedCategoryId = 0;
  String? _selectedDomain;
  String? _selectedSubdomain;

  late ProductNotifier _productNotifier;

  Timer? _searchTimer;
  static const _searchDelay = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _productNotifier = Provider.of<ProductNotifier>(context, listen: false);
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _productNotifier.fetchCategories();
      _productNotifier.fetchProducts(reset: true);
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchTimer?.cancel();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  // Derived state
  // ══════════════════════════════════════════════════════════════

  /// True when any filter or search term is active, i.e. the user is
  /// not looking at the plain buyer catalog. Drives the visibility of
  /// the "clear filters" button.
  bool get _hasActiveFilters =>
      _selectedCategoryId != 0 ||
      _selectedDomain != null ||
      _selectedSubdomain != null ||
      _searchController.text.trim().isNotEmpty;

  // ══════════════════════════════════════════════════════════════
  // Search
  // ══════════════════════════════════════════════════════════════

  void _onSearchChanged() {
    if (_searchTimer?.isActive ?? false) _searchTimer?.cancel();
    _searchTimer = Timer(_searchDelay, () {
      if (mounted) _filterProducts();
    });
    // Force a rebuild so the clear-filters button shows/hides as the
    // search term becomes non-empty.
    if (mounted) setState(() {});
  }

  void _filterProducts() {
    _productNotifier.searchProducts(
      _searchController.text,
      domain: _selectedDomain,
      subdomain: _selectedSubdomain,
    );
    if (mounted) setState(() {});
  }

  // ══════════════════════════════════════════════════════════════
  // Category selection
  // ══════════════════════════════════════════════════════════════

  void _onCategoryChanged(CategorySelection selection) {
    if (_selectedCategoryId == selection.leafId &&
        _selectedDomain == selection.domain &&
        _selectedSubdomain == selection.subdomain) {
      return;
    }

    setState(() {
      _selectedCategoryId = selection.leafId;
      _selectedDomain = selection.domain;
      _selectedSubdomain = selection.subdomain;
    });

    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
    }

    _productNotifier.fetchProducts(
      categoryId: selection.leafId,
      domain: selection.domain,
      subdomain: selection.subdomain,
      reset: true,
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Refresh + clear
  // ══════════════════════════════════════════════════════════════

  /// Force-reload the current view from the backend, bypassing cache.
  /// Used by the header's refresh button and by pull-to-refresh.
  Future<void> _refreshProducts() async {
    _productNotifier.invalidateProductCache();
    await _productNotifier.fetchProducts(
      categoryId: _selectedCategoryId,
      domain: _selectedDomain,
      subdomain: _selectedSubdomain,
      reset: true,
    );
  }

  /// Reload categories and products from scratch. Useful when the
  /// user taps refresh expecting "everything, fresh".
  Future<void> _refreshAll() async {
    await _productNotifier.fetchCategories(forceRefresh: true);
    await _refreshProducts();
  }

  /// Reset every filter and search term, then fetch the unfiltered
  /// catalog.
  void _clearFilters() {
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
    }

    setState(() {
      _selectedCategoryId = 0;
      _selectedDomain = null;
      _selectedSubdomain = null;
    });

    _productNotifier.fetchProducts(
      categoryId: 0,
      domain: null,
      subdomain: null,
      reset: true,
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Pagination
  // ══════════════════════════════════════════════════════════════

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 260 &&
        !_productNotifier.isLoading &&
        _productNotifier.hasMoreProducts) {
      _productNotifier.fetchProducts(
        categoryId: _selectedCategoryId,
        domain: _selectedDomain,
        subdomain: _selectedSubdomain,
      );
    }
  }

  // ══════════════════════════════════════════════════════════════
  // Build
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      floatingActionButton: _buildFab(context),
      body: SafeArea(
        bottom: false,
        child: Consumer<ProductNotifier>(
          builder: (context, productNotifier, _) {
            final products =
                productNotifier.filterProductsByCategory(_selectedCategoryId);

            final query = _searchController.text.toLowerCase();
            var filtered = products;
            if (query.isNotEmpty) {
              filtered = products.where((p) {
                return (p.product_name?.toLowerCase().contains(query) ??
                        false) ||
                    (p.product_brand?.toLowerCase().contains(query) ?? false);
              }).toList();
            }

            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: _CatalogHeader(
                    searchController: _searchController,
                    searchFocus: _searchFocus,
                    onClearSearch: () {
                      _searchController.clear();
                      _filterProducts();
                    },
                    onSubmitted: (_) => _filterProducts(),
                    onRefresh: _refreshAll,
                    onClearFilters: _hasActiveFilters ? _clearFilters : null,
                    isLoading: productNotifier.isLoading,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: _buildCategoryRow(productNotifier),
                  ),
                ),
                if (filtered.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Row(
                        children: [
                          Text(
                            '${filtered.length} '
                            '${AppLocalizations.of(context)!.itemsText.toLowerCase()}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.onSurface.withOpacity(0.55),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const Spacer(),
                          if (productNotifier.hasMoreProducts)
                            Text(
                              AppLocalizations.of(context)!
                                  .loadingMore
                                  .toLowerCase(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.onSurface.withOpacity(0.45),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                _buildContent(filtered, productNotifier),
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // FAB
  // ══════════════════════════════════════════════════════════════

  Widget _buildFab(BuildContext context) {
    return CustomSpeedDial(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      uniqueId: 'product_fab',
      horizontalButtons: [
        SpeedDialButton(
          icon: const Icon(CupertinoIcons.barcode_viewfinder),
          label: AppLocalizations.of(context)!.scannerTxt,
          onTap: () async {
            final barcode = await Navigator.pushNamed(
              context,
              AppRoutes.productScanPage,
            ) as String?;

            if (barcode != null && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IProductDetailsScreen(barcode: barcode),
                ),
              );
            }
          },
        ),
      ],
      verticalButtons: [
        SpeedDialButton(
          icon: const Icon(CupertinoIcons.list_dash),
          label: AppLocalizations.of(context)!.ordersText,
          onTap: () => Navigator.pushNamed(context, AppRoutes.ordersPage),
        ),
        SpeedDialButton(
          icon: const Icon(Icons.shopping_cart_outlined),
          label: AppLocalizations.of(context)!.cartText,
          onTap: () => Navigator.pushNamed(context, AppRoutes.cartPage),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Category picker row
  // ══════════════════════════════════════════════════════════════

  Widget _buildCategoryRow(ProductNotifier productNotifier) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final categories = productNotifier.productCategories;
    final l10n = AppLocalizations.of(context)!;

    return HierarchicalCategoryPicker(
      label: l10n.categoryText,
      options: categories
          .map(
            (c) => HierarchicalCategoryOption(
              id: c.productCategoryId,
              path: c.productCategoryDesc,
              leafLabel: c.nameFor(languageCode),
            ),
          )
          .toList(),
      selectedId: _selectedCategoryId,
      selectedDomain: _selectedDomain,
      selectedSubdomain: _selectedSubdomain,
      allowAllOption: true,
      allLabel: l10n.allText,
      onChanged: _onCategoryChanged,
      iconAsset: _selectedCategoryId == 0
          ? null
          : 'assets/icons/$_selectedCategoryId.svg',
      package: 'product_catalog',
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Content
  // ══════════════════════════════════════════════════════════════

  Widget _buildContent(
    List<Product> products,
    ProductNotifier productNotifier,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (productNotifier.isLoading && products.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)?.loadingProducts ??
                    'Loading products…',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (products.isEmpty && !productNotifier.isLoading) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(
          onClearSearch: _hasActiveFilters
              ? () {
                  _clearFilters();
                }
              : null,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.70,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= products.length) return null;
            final product = products[index];
            return _FadeSlideIn(
              delay: Duration(milliseconds: (index % 10) * 30),
              child: ProductCard(
                product: product,
                key: ValueKey(product.id_product),
              ),
            );
          },
          childCount: products.length,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Header with search + actions
// ══════════════════════════════════════════════════════════════════

class _CatalogHeader extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onSubmitted;

  /// Refresh the whole catalog — categories + products, bypassing cache.
  final Future<void> Function() onRefresh;

  /// Clear all filters. Null when no filter is active, which hides the
  /// button.
  final VoidCallback? onClearFilters;

  /// Show a small spinner in the refresh button while a reload is in
  /// flight, and disable both buttons to prevent double taps.
  final bool isLoading;

  const _CatalogHeader({
    required this.searchController,
    required this.searchFocus,
    required this.onClearSearch,
    required this.onSubmitted,
    required this.onRefresh,
    required this.onClearFilters,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Title row with actions ─────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.productsText,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: colors.onSurface,
                  ),
                ),
              ),

              // Clear filters — only when something is filtered
              if (onClearFilters != null) ...[
                _HeaderIconButton(
                  icon: Icons.filter_alt_off_rounded,
                  tooltip: l10n.clearFilters,
                  onPressed: isLoading ? null : onClearFilters,
                ),
                const SizedBox(width: 4),
              ],

              // Refresh
              _HeaderIconButton(
                icon: Icons.refresh_rounded,
                tooltip: l10n.refreshTxt,
                onPressed: isLoading ? null : () => onRefresh(),
                isBusy: isLoading,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ─── Search field ──────────────────────────────────────
          AnimatedBuilder(
            animation: searchFocus,
            builder: (context, _) {
              final focused = searchFocus.hasFocus;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: focused
                        ? colors.primary.withOpacity(0.6)
                        : colors.outlineVariant,
                    width: focused ? 1.6 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withOpacity(
                        focused ? 0.08 : 0.03,
                      ),
                      blurRadius: focused ? 16 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  focusNode: searchFocus,
                  textInputAction: TextInputAction.search,
                  onSubmitted: onSubmitted,
                  decoration: InputDecoration(
                    hintText: l10n.searchTxt,
                    hintStyle: TextStyle(
                      color: colors.onSurface.withOpacity(0.4),
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colors.onSurface.withOpacity(0.55),
                    ),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: searchController,
                      builder: (_, value, __) {
                        if (value.text.isEmpty) return const SizedBox.shrink();
                        return IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: colors.onSurface.withOpacity(0.55),
                          ),
                          onPressed: onClearSearch,
                        );
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Small header action button with optional busy state
// ══════════════════════════════════════════════════════════════════

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isBusy;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final disabled = onPressed == null;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: disabled ? null : onPressed,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.outlineVariant.withOpacity(0.7),
                width: 1,
              ),
            ),
            child: isBusy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: colors.primary.withOpacity(0.7),
                    ),
                  )
                : Icon(
                    icon,
                    size: 20,
                    color: disabled
                        ? colors.onSurface.withOpacity(0.3)
                        : colors.onSurface.withOpacity(0.75),
                  ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Empty state
// ══════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final VoidCallback? onClearSearch;

  const _EmptyState({this.onClearSearch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 44,
              color: colors.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.noProductsFound,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.adjustSearchFiltersText,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withOpacity(0.6),
            ),
          ),
          if (onClearSearch != null) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onClearSearch,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
              label: Text(l10n.clearFilters),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Fade + slide in animation
// ══════════════════════════════════════════════════════════════════

class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _FadeSlideIn({required this.child, this.delay = Duration.zero});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _opacity = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
