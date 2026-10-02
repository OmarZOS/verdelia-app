import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/privileges/Privileges.dart';
import 'package:verdelia_core/business/privileges/role_bit_mapper.dart';
import 'package:provider_store/components/inventory/inventory_app_bar.dart';
import 'package:provider_store/components/inventory/product_list.dart';
import 'package:provider_store/components/inventory/search_bar.dart';
import 'package:ui/components/store/StoreDashboardHeader.dart';

class InventoryScreen extends StatefulWidget {
  final PrivilegeLevel privilegeLevel;
  final int userId;
  final List<int> accessibleSuppliers;
  final List<ManagementRule> userRules;
  final List<Product> products;
  final bool isLoading;
  final String searchQuery;
  final int? currentProviderId;
  final Function(int) onSupplierChanged;
  final Function(String) onSearchChanged;
  final Function(int) onProductTap;
  final Function() onRefresh;
  final Function() onAddProduct;

  const InventoryScreen({
    super.key,
    required this.privilegeLevel,
    required this.userId,
    required this.accessibleSuppliers,
    required this.userRules,
    required this.products,
    required this.isLoading,
    required this.searchQuery,
    required this.currentProviderId,
    required this.onSupplierChanged,
    required this.onSearchChanged,
    required this.onProductTap,
    required this.onRefresh,
    required this.onAddProduct,
  });

  bool get _canManage => privilegeLevel == PrivilegeLevel.manage;
  bool get _canView => privilegeLevel == PrivilegeLevel.view;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late List<Product> _filteredProducts;
  late bool _hasInventoryAccess;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadSelectedSupplierProducts();
  }

  @override
  void didUpdateWidget(InventoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentProviderId != widget.currentProviderId) {
      _loadSelectedSupplierProducts();
    }
    if (_shouldRebuild(oldWidget)) {
      _initializeData();
    }
  }

  void _loadSelectedSupplierProducts() {
    final providerId = widget.currentProviderId;
    if (providerId == null || providerId <= 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onRefresh();
    });
  }

  bool _shouldRebuild(InventoryScreen oldWidget) {
    // Compare list contents (not just identity) to detect in-place mutations
    final productsChanged = !listEquals(oldWidget.products, widget.products);
    return productsChanged ||
        oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.privilegeLevel != widget.privilegeLevel ||
        oldWidget.currentProviderId != widget.currentProviderId;
  }

  void _initializeData() {
    _hasInventoryAccess = true;
    _filteredProducts = _filterProducts();
    log('InventoryScreen._initializeData: currentProviderId=${widget.currentProviderId} products=${widget.products.length} filtered=${_filteredProducts.length}');
  }

  bool _checkInventoryAccess() {
    return widget.userRules.any((rule) {
      if (!rule.isActive) return false;
      final ruleCode = rule.managementRuleCode;
      return RoleBitMapper.hasPrivilege(ruleCode, 'inventory_view') ||
          RoleBitMapper.hasPrivilege(ruleCode, 'inventory_manage');
    });
  }

  List<Product> _filterProducts() {
    List<Product> products = widget.products;

    // Then filter by search query
    if (widget.searchQuery.isNotEmpty) {
      products = products.where((product) {
        return product.product_name != null &&
            product.product_name!
                .toLowerCase()
                .contains(widget.searchQuery.toLowerCase());
      }).toList();
    }

    return products;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasInventoryAccess) {
      return _buildNoAccessState(context);
    }

    if (widget.currentProviderId == null || widget.currentProviderId == 0) {
      return _buildNoSupplierSelected(context);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            DashboardHeader(
              leadingIcon: Icons.inventory_2_rounded,
              title: AppLocalizations.of(context)!.inventory, // or a fallback
              subtitle: '${_filteredProducts.length} items',
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: widget.onRefresh,
                  tooltip: AppLocalizations.of(context)!.refresh,
                ),
              ],
              searchBar: InventorySearchBar(
                searchQuery: widget.searchQuery,
                onSearchChanged: widget.onSearchChanged,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildProductList(context)),
          ],
        ),
      ),
      floatingActionButton: _buildAddProductButton(context),
    );
  }

  Widget _buildProductList(BuildContext context) {
    if (widget.isLoading && widget.products.isEmpty) {
      return _buildLoadingState(context);
    }

    if (_filteredProducts.isEmpty) {
      return _buildEmptyState(context);
    }

    return ProductList(
      selectedSupplierId: widget.currentProviderId!,
      searchQuery: widget.searchQuery,
      // products: _filteredProducts,
      isLoading: widget.isLoading,
      onProductTap: widget.onProductTap,
      privilegeLevel: widget.privilegeLevel,
      onAddFirstProduct: () => widget.onAddProduct(),
      onManageSuppliers: () {
        // Navigate to supplier management
        // Could be passed from DashboardScreen
      },
    );
  }

  Widget _buildNoAccessState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: colorScheme.onSurfaceVariant.withOpacity(0.3),
              ),
              const SizedBox(height: 24),
              Text(
                localizations.noInventoryPrivilegesText,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                localizations.noInventoryPrivilegesText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoSupplierSelected(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 64,
                color: colorScheme.onSurfaceVariant.withOpacity(0.3),
              ),
              const SizedBox(height: 24),
              Text(
                localizations.selectSupplierFirstText,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                localizations.selectSupplierToViewText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            localizations.loading,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              widget.searchQuery.isNotEmpty
                  ? localizations.noResultsTitle
                  : localizations.noProductsFound,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.searchQuery.isNotEmpty
                  ? localizations.adjustSearchFiltersText
                  : localizations.addFirstProduct,
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

  Widget? _buildAddProductButton(BuildContext context) {
    if (!widget._canManage || widget.currentProviderId == null) return null;

    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return FloatingActionButton.extended(
      onPressed: () => widget.onAddProduct(),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        localizations.addProduct,
        // style: theme.textTheme.labelLarge?.copyWith(
        //   fontWeight: FontWeight.w600,
        // ),
      ),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      heroTag: 'inventory_add_product_fab',
    );
  }
}
