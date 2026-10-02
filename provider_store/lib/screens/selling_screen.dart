import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/finance/ProvidedService.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:event/personnel_notifier.dart';
import 'package:event/product_change_notifier.dart';
import 'package:event/service_change_notifier.dart';
import 'package:provider_store/components/selling_point/config_sheet/product_configuration_sheet.dart';
import 'package:provider_store/components/selling_point/config_sheet/service_configuration_sheet.dart';
import 'package:provider_store/components/selling_point/selling_point_app_bar.dart';
import 'package:provider_store/components/selling_point/selling_point_tabs.dart';

import '../components/selling_point/cart_summary/cart_summary_screen.dart';

class SellingPointScreen extends StatefulWidget {
  final int userId;
  final int? selectedSupplierId;
  final List<int> accessibleSuppliers;
  final PersonnelNotifier personnelNotifier;
  final ServiceNotifier serviceNotifier;
  final CartChangeNotifier cartNotifier;
  final ProductNotifier productNotifier;
  final Function() onScanBarcode;
  final Function(String) onSearchChanged;
  final Function(int) onSupplierChanged;

  const SellingPointScreen({
    super.key,
    required this.userId,
    this.selectedSupplierId,
    required this.accessibleSuppliers,
    required this.personnelNotifier,
    required this.productNotifier,
    required this.serviceNotifier,
    required this.cartNotifier,
    required this.onScanBarcode,
    required this.onSearchChanged,
    required this.onSupplierChanged,
  });

  @override
  State<SellingPointScreen> createState() => _SellingPointScreenState();
}

class _SellingPointScreenState extends State<SellingPointScreen> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final id = widget.selectedSupplierId ?? 0;
      if (id > 0) _loadSupplierData(id);
    });
  }

  @override
  void didUpdateWidget(covariant SellingPointScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final supplierChanged =
        (oldWidget.selectedSupplierId ?? 0) != (widget.selectedSupplierId ?? 0);
    final userChanged = oldWidget.userId != widget.userId;

    if (!supplierChanged && !userChanged) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final newId = widget.selectedSupplierId ?? 0;
      if (newId > 0) {
        _loadSupplierData(newId);
      } else {
        widget.productNotifier.fetchProducts(reset: true);
        widget.serviceNotifier.fetchServices(reset: true);
      }
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query == _searchQuery) return;
    setState(() => _searchQuery = query);
    widget.onSearchChanged(query);
  }

  void _loadSupplierData(int supplierId) {
    developer.log(
      'Loading POS products and services for providerId=$supplierId',
      name: 'SellingPointScreen',
    );

    if (_searchQuery.isNotEmpty) {
      _searchController.clear();
      _searchQuery = '';
    }

    widget.productNotifier.fetchProducts(providerId: supplierId, reset: true);
    widget.serviceNotifier.fetchServices(providerId: supplierId, reset: true);
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return widget.productNotifier.products;

    final query = _searchQuery.toLowerCase();
    return widget.productNotifier.products.where((product) {
      final name = product.product_name?.toLowerCase() ?? '';
      final desc = product.product_description?.toLowerCase() ?? '';
      return name.contains(query) || desc.contains(query);
    }).toList();
  }

  List<ProvidedService> get _filteredServices {
    if (_searchQuery.isEmpty) return widget.serviceNotifier.services;

    final query = _searchQuery.toLowerCase();
    return widget.serviceNotifier.services.where((service) {
      final name = (service.name ?? '').toLowerCase();
      final desc = (service.description ?? '').toLowerCase();
      return name.contains(query) || desc.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSupplier =
        widget.selectedSupplierId != null && widget.selectedSupplierId! > 0;

    if (!hasSupplier) return _buildNoSupplierSelected(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            SellingPointAppBar(onScanBarcode: widget.onScanBarcode),
            _buildSearchBar(context),
            Expanded(
              child: SellingItemTabs(
                products: _filteredProducts,
                services: _filteredServices,
                isLoading: widget.productNotifier.isLoading ||
                    widget.serviceNotifier.isLoading,
                cartNotifier: widget.cartNotifier,
                onAddToCart: widget.cartNotifier.addProduct,
                onAddServiceToCart: widget.cartNotifier.addService,
                onRemoveFromCart: (product) =>
                    widget.cartNotifier.removeItem(product: product),
                onRemoveServiceFromCart: (service) =>
                    widget.cartNotifier.removeItem(service: service),
                onConfigureProduct: _showProductConfiguration,
                onConfigureService: _showServiceConfiguration,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ListenableBuilder(
        listenable: widget.cartNotifier,
        builder: (context, _) => _buildCartFAB(context),
      ),
    );
  }

  void _showProductConfiguration(Product product) {
    final currentQuantity =
        widget.cartNotifier.getProductCartItem(product)?.quantity ?? 1;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductConfigurationSheet(
        product: product,
        cartNotifier: widget.cartNotifier,
        currentQuantity: currentQuantity,
      ),
    );
  }

  void _showServiceConfiguration(ProvidedService service) {
    final currentItem = widget.cartNotifier.getServiceCartItem(service);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ServiceConfigurationSheet(
        service: service,
        initialQuantity: currentItem?.quantity ?? 1,
        initialScheduledDate: currentItem?.scheduledDate,
        initialScheduledTime: currentItem?.scheduledTime,
        onSave: ({
          required int quantity,
          String? scheduledDate,
          String? scheduledTime,
          String? notes,
          Map<String, dynamic>? parameters,
        }) {
          if (currentItem == null) {
            widget.cartNotifier.addService(service, quantity: quantity);
          } else {
            widget.cartNotifier.updateQuantity(
              service: service,
              newQuantity: quantity,
            );
          }
          widget.cartNotifier.updateServiceScheduling(
            service: service,
            scheduledDate: scheduledDate,
            scheduledTime: scheduledTime,
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.search,
          prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    widget.onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: colorScheme.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildNoSupplierSelected(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
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
      ),
    );
  }

  /// Returns `null` when the cart is empty so the FAB slot collapses
  /// instead of being occupied by an invisible Container.
  Widget _buildCartFAB(BuildContext context) {
    final count = widget.cartNotifier.cartItems.length;
    if (count == 0) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final total = widget.cartNotifier.cart.totalAmount;

    return FloatingActionButton.extended(
      onPressed: () {
        HapticFeedback.mediumImpact();
        _showCartSheet(context);
      },
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      elevation: 3,
      highlightElevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28), // pill, not square
      ),
      icon: const Icon(Icons.shopping_cart_rounded, size: 20),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: cs.onPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: cs.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${total.toStringAsFixed(2)} DA',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, sc) => CartSummarySheet(
          cart: widget.cartNotifier,
          scrollController: sc,
        ),
      ),
    );
  }
}
