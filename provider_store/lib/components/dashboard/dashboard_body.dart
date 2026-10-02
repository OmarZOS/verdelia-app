import 'package:app_constants/app_routes.dart';
import 'package:event/delivery_change_notifier.dart';
import 'package:event/extensions/personnel_access_manager.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:event/views/business_ops_notifier.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/business/Product.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:verdelia_core/business/privileges/Privileges.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:event/finance_change_notifier.dart';
import 'package:event/personnel_notifier.dart';
import 'package:event/product_change_notifier.dart';
import 'package:event/service_change_notifier.dart';
import 'package:event/user_change_notifier.dart';
import 'package:provider_personnel/personnel_management_screen.dart';
import 'package:provider_store/screens/business_operations_screen.dart';
import 'package:provider_store/screens/finance_screen.dart';
import 'package:provider_store/screens/inventory_screen.dart';
import 'package:provider_store/screens/deliveries_screen.dart';
import 'package:provider_store/screens/selling_screen.dart';
import 'package:provider_store/screens/services_screen.dart';
import 'package:provider/provider.dart';
import 'dashboard_item.dart';

class DashboardBody extends StatelessWidget {
  final int selectedIndex;
  final List<DashboardItem> items;
  final int selectedSupplierId;
  final ValueChanged<int>? onSupplierChanged;

  const DashboardBody({
    super.key,
    required this.selectedIndex,
    required this.items,
    this.selectedSupplierId = 0,
    this.onSupplierChanged,
  });

  @override
  Widget build(BuildContext context) {
    final index = selectedIndex.clamp(0, items.length - 1);

    // ✅ Get data from providers - NO FETCHING HERE
    final personnelNotifier = context.watch<PersonnelNotifier>();
    final supplierNotifier = context.watch<SupplierChangeNotifier>();
    final userNotifier = context.watch<AppUserNotifier>();

    final userId = userNotifier.appUser?.idAppUser ?? 0;

    // ✅ Use sync version - NO API CALLS
    final accessManager = PersonnelAccessManager(
      personnelNotifier: personnelNotifier,
      supplierNotifier: supplierNotifier,
    );

    final suppliersWithAccess =
        accessManager.getAccessibleSuppliersWithAccessTypeSync(userId);
    final suppliers = suppliersWithAccess.map((s) => s.supplier).toList();
    final supplierIds = selectedSupplierId > 0
        ? [selectedSupplierId]
        : suppliersWithAccess.map((s) => s.id).toList();
    final userRules = personnelNotifier.getRulesForUser(userId);

    return IndexedStack(
      index: index,
      children: List.generate(items.length, (childIndex) {
        final item = items[childIndex];
        return HeroMode(
          enabled: childIndex == index,
          child: _buildScreenWithData(
            context,
            item,
            userId,
            supplierIds,
            userRules,
            suppliers,
            suppliersWithAccess,
            accessManager,
          ),
        );
      }),
    );
  }

  Widget _buildScreenWithData(
    BuildContext context,
    DashboardItem item,
    int userId,
    List<int> supplierIds,
    List<ManagementRule> userRules,
    List<Supplier> suppliers,
    List<AccessibleSupplier> suppliersWithAccess,
    PersonnelAccessManager accessManager,
  ) {
    switch (item.type) {
      case DashboardScreenType.inventory:
        return _buildInventoryScreen(context, item, userId, supplierIds,
            userRules, suppliers, accessManager);

      case DashboardScreenType.orders:
        return _buildOrdersScreen(context);

      case DashboardScreenType.operations:
        return _buildOperationsScreen(context);

      case DashboardScreenType.pos:
        return _buildPosScreen(context, userId, supplierIds);

      case DashboardScreenType.finance:
        return _buildFinanceScreen(context);

      case DashboardScreenType.suppliersPersonnel:
        return _buildSuppliersPersonnelScreen(context, userId, supplierIds,
            userRules, suppliers, suppliersWithAccess, accessManager);

      case DashboardScreenType.services:
        return _buildServicesScreen(
            context, item, userId, supplierIds, userRules, accessManager);
    }
  }

  // ============================================================
  // SCREEN BUILDERS
  // ============================================================

  Widget _buildInventoryScreen(
    BuildContext context,
    DashboardItem item,
    int userId,
    List<int> supplierIds,
    List<ManagementRule> userRules,
    List<Supplier> suppliers,
    PersonnelAccessManager accessManager,
  ) {
    final privilegeLevel = item.privilegeLevel ?? PrivilegeLevel.view;

    return Consumer<ProductNotifier>(
      builder: (context, productNotifier, child) => InventoryScreen(
        privilegeLevel: privilegeLevel,
        userId: userId,
        accessibleSuppliers: supplierIds,
        userRules: userRules,
        products: List<Product>.from(productNotifier.products),
        isLoading: productNotifier.isLoading,
        searchQuery: productNotifier.currentSearchQuery,
        currentProviderId: selectedSupplierId > 0
            ? selectedSupplierId
            : productNotifier.currentProviderId,
        onSupplierChanged: (supplierId) {
          productNotifier.fetchProducts(providerId: supplierId);
          onSupplierChanged?.call(supplierId);
        },
        onSearchChanged: productNotifier.searchProducts,
        onProductTap: (productId) {
          Navigator.pushNamed(
            context,
            AppRoutes.productDetails,
            arguments: {'productId': productId},
          );
        },
        onRefresh: () => productNotifier.fetchProducts(
          providerId: selectedSupplierId,
          includeHidden: true,
          reset: true,
        ),
        onAddProduct: () => Navigator.pushNamed(
          context,
          AppRoutes.productCreate,
          arguments: {
            'providerId': selectedSupplierId,
            'lockProvider': true,
          },
        ),
      ),
    );
  }

  Widget _buildOrdersScreen(BuildContext context) {
    return Consumer<DeliveryChangeNotifier>(
      builder: (context, deliveryNotifier, child) => DeliveryTabbedView(
        notifier: deliveryNotifier,
        selectedSupplierId: selectedSupplierId,
        isLoading: deliveryNotifier.isLoading,
        onRefresh: deliveryNotifier.refreshDeliveries,
        onSearch: deliveryNotifier.searchDeliveries,
      ),
    );
  }

  Widget _buildOperationsScreen(BuildContext context) {
    return Consumer2<PersonnelNotifier, BusinessOperationNotifier>(
      builder: (context, personnelNotifier, businessNotifier, child) {
        final supplierId = selectedSupplierId;

        // Key on the supplier so switching suppliers rebuilds the screen
        // (and therefore rebuilds the notifier) with fresh state.
        return BusinessOperationsScreen(
          key: ValueKey('operations_$supplierId'),
          supplierId: supplierId,
          lockToSupplier: supplierId > 0,
        );
      },
    );
  }

  Widget _buildPosScreen(
      BuildContext context, int userId, List<int> supplierIds) {
    return Consumer4<ServiceNotifier, PersonnelNotifier, CartChangeNotifier,
        ProductNotifier>(
      builder: (context, serviceNotifier, personnelNotifier, cartNotifier,
          productNotifier, child) {
        return SellingPointScreen(
          userId: userId,
          selectedSupplierId: selectedSupplierId,
          accessibleSuppliers: supplierIds,
          personnelNotifier: personnelNotifier,
          productNotifier: productNotifier,
          serviceNotifier: serviceNotifier,
          cartNotifier: cartNotifier,
          onScanBarcode: () => _handleBarcodeScan(context),
          onSearchChanged: (query) => _handleSearch(context, query),
          onSupplierChanged: (supplierId) {
            productNotifier.fetchProducts(providerId: supplierId, reset: true);
            serviceNotifier.fetchServices(providerId: supplierId, reset: true);
            onSupplierChanged?.call(supplierId);
          },
        );
      },
    );
  }

  Widget _buildFinanceScreen(BuildContext context) {
    return Consumer3<ProductNotifier, CartChangeNotifier,
        FinanceChangeNotifier>(
      builder:
          (context, productNotifier, cartNotifier, financeNotifier, child) {
        return FinanceScreen(
          key: ValueKey('finance_$selectedSupplierId'),
          financeNotifier: financeNotifier,
          // onSupplierChanged: (supplierId) {
          //   // productNotifier.fetchProducts(providerId: supplierId, reset: true);
          //   financeNotifier.setProvider(supplierId);
          //   onSupplierChanged?.call(supplierId);
          // },
        );
      },
    );
  }

  Widget _buildSuppliersPersonnelScreen(
    BuildContext context,
    int userId,
    List<int> supplierIds,
    List<ManagementRule> userRules,
    List<Supplier> suppliers,
    List<AccessibleSupplier> suppliersWithAccess,
    PersonnelAccessManager accessManager,
  ) {
    if (selectedSupplierId <= 0) return const SizedBox.shrink();

    final selectedSupplier = suppliers.firstWhere(
      (s) => s.idProductProvider == selectedSupplierId,
      orElse: () => suppliers.isNotEmpty ? suppliers.first : Supplier.empty(),
    );
    final supplierName = selectedSupplier.providerName ?? 'Unnamed Business';

    // 👇 Read the already-computed access type instead of re-checking.
    SupplierAccessType accessType = SupplierAccessType.none;
    for (final a in suppliersWithAccess) {
      if (a.id == selectedSupplierId) {
        accessType = a.accessType;
        break;
      }
    }

    final personnelNotifier = context.read<PersonnelNotifier>();
    final isOwner = accessType == SupplierAccessType.owner;
    final hasPriv = personnelNotifier.hasPrivilege(
        userId, selectedSupplierId, 'personnel_manage');
    final canManage = isOwner || hasPriv;

    debugPrint('PERSONNEL canManage=$canManage '
        '(owner=$isOwner, priv=$hasPriv, accessType=$accessType)');

    return PersonnelManagementScreen(
      key: ValueKey('personnel_${selectedSupplierId}_${userId}'),
      supplierId: selectedSupplierId,
      supplierName: supplierName,
      orgId: selectedSupplier.idProviderOrganisation ?? 0,
      canManagePersonnel: canManage,
      userId: userId,
      accessibleSuppliers: supplierIds,
      userRules: userRules,
      accessManager: accessManager,
    );
  }

  Widget _buildServicesScreen(
    BuildContext context,
    DashboardItem item,
    int userId,
    List<int> supplierIds,
    List<ManagementRule> userRules,
    PersonnelAccessManager accessManager,
  ) {
    final privilegeLevel = item.privilegeLevel ?? PrivilegeLevel.view;

    return Consumer2<PersonnelNotifier, ServiceNotifier>(
      builder: (context, personnelNotifier, serviceNotifier, child) {
        return ServicesScreen(
          key: ValueKey('services_$selectedSupplierId'),
          privilegeLevel: privilegeLevel,
          userId: userId,
          accessibleSuppliers: supplierIds,
          userRules: userRules,
          personnelNotifier: personnelNotifier,
          serviceNotifier: serviceNotifier,
          selectedSupplierId: selectedSupplierId,
        );
      },
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _handleBarcodeScan(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Barcode scanning coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleSearch(BuildContext context, String query) {
    debugPrint('Searching: $query');
  }
}
