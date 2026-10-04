import 'package:app_constants/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:provider_geo/screens/map_picker_screen.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/business/Supplier.dart';
import 'package:event/order_change_notifier.dart';
import 'package:tabbed_home/screens/app_user_update_form_screen.dart';
import 'package:tabbed_home/screens/home_screen.dart';
import 'package:event/user_change_notifier.dart';
import 'package:event/personnel_notifier.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:event/extensions/personnel_access_manager.dart';
import 'package:provider_geo/screens/supplier_form_page.dart';
import 'package:provider_geo/screens/suppliers_map_screen.dart';
import 'package:login/screens/login_screen.dart';
import 'package:login/screens/registration_screen.dart';
import 'package:provider_personnel/personnel_management_screen.dart';
import 'package:provider_personnel/supplier_entities_screen.dart';
import 'package:scanner/screens/qr_scanner.dart';
import 'package:scanner/screens/barcode_scanner.dart';
import 'package:scanner/screens/product_scanner.dart';
import 'package:provider_store/components/service/form/provided_service_form_screen.dart';
import 'package:provider_store/screens/dashboard_screen.dart';
import 'package:product_catalog/screens/cart_screen.dart';
import 'package:product_catalog/screens/orders_screen.dart';
import 'package:product_catalog/screens/product_catalog_screen.dart';
import 'package:product_catalog/screens/product_form_screen.dart';
import 'package:product_catalog/screens/product_screen.dart';
import 'package:provider/provider.dart';
import 'screens/image_upload_screen.dart';

class AppRouter {
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    debugPrint('=== GENERATING ROUTE ===');
    debugPrint('Route name: ${settings.name}');
    debugPrint('Route arguments: ${settings.arguments}');

    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        return Consumer<AppUserNotifier>(
          builder: (context, authProvider, child) {
            final appUser = authProvider.appUser;
            final isAuthenticated = authProvider.isAuthenticated;

            debugPrint(
                'Router - appUser: ${appUser?.idAppUser}, isAuthenticated: $isAuthenticated');

            final args = settings.arguments as Map<String, dynamic>?;

            switch (settings.name) {
              case AppRoutes.home:
                return _buildGuardedRoute(
                    isAuthenticated, const HomePage(), const LoginScreen());

              case AppRoutes.productCreate:
                return _buildGuardedRoute(
                  isAuthenticated,
                  const ProductFormScreen(),
                  const ProductCatalogScreen(),
                );

              case AppRoutes.productScanPage:
                return _buildGuardedRoute(
                  isAuthenticated,
                  BarcodeScannerScreen(
                    onBarcodeScanned: (String code) {},
                  ),
                  const ProductCatalogScreen(),
                );

              case AppRoutes.mapPicker:
                return _buildGuardedRoute(
                  isAuthenticated,
                  MapPicker(
                    initialPosition: args?['initialPosition'],
                    initialPin: args?['initialPin'],
                    initialZoom: args?['initialZoom'] as double? ?? 15.0,
                  ),
                  const LoginScreen(),
                );

              case AppRoutes.QRScanPage:
                return _buildGuardedRoute(
                  isAuthenticated,
                  QRScannerScreen(
                    onQRcodeScanned: (String code) {},
                  ),
                  const ProductCatalogScreen(),
                );

              case AppRoutes.productCapturePage:
                return _buildGuardedRoute(
                  isAuthenticated,
                  const ProductCaptureScreen(),
                  const ProductCatalogScreen(),
                );

              case AppRoutes.cartPage:
                return _buildGuardedRoute(
                    isAuthenticated, const CartScreen(), const HomePage());

              case AppRoutes.providerCreate:
                return _buildGuardedRoute(
                  isAuthenticated,
                  const SupplierFormScreen(),
                  const SuppliersMapScreen(),
                );

              case AppRoutes.supplierManage:
                final supplierId = args?['supplierId'] as int? ?? 0;
                final currentUserId = appUser?.idAppUser ?? 0;
                final personnelNotifier = context.read<PersonnelNotifier>();
                final supplierNotifier = context.read<SupplierChangeNotifier>();
                final accessManager = PersonnelAccessManager(
                  personnelNotifier: personnelNotifier,
                  supplierNotifier: supplierNotifier,
                );
                final accessType = currentUserId > 0 && supplierId > 0
                    ? accessManager.getAccessType(currentUserId, supplierId)
                    : SupplierAccessType.none;
                final canView = supplierId == 0 ||
                    accessType == SupplierAccessType.owner ||
                    personnelNotifier.hasPrivilege(
                        currentUserId, supplierId, 'personnel_view') ||
                    personnelNotifier.hasPrivilege(
                        currentUserId, supplierId, 'personnel_manage');
                final canManage = supplierId == 0 ||
                    accessType == SupplierAccessType.owner ||
                    personnelNotifier.hasPrivilege(
                        currentUserId, supplierId, 'personnel_manage');
                return _buildGuardedRoute(
                  isAuthenticated && canView,
                  PersonnelManagementScreen(
                    supplierName: args?['supplierName'],
                    orgId: args?['orgId'],
                    supplierId: supplierId,
                    canManagePersonnel: canManage,
                  ),
                  const SuppliersMapScreen(),
                );

              // ✅ NEW: Supplier Entities Screen
              case AppRoutes.supplierEntitiesPage:
                final userId =
                    args?['userId'] as int? ?? appUser?.idAppUser ?? 0;
                final accessibleSuppliers =
                    args?['accessibleSuppliers'] as List<int>? ?? [];
                final userRules =
                    args?['userRules'] as List<ManagementRule>? ?? [];
                final suppliers = args?['suppliers'] as List<Supplier>? ?? [];
                final suppliersWithAccess =
                    args?['suppliersWithAccess'] as List<AccessibleSupplier>? ??
                        [];

                final personnelNotifier = context.read<PersonnelNotifier>();
                final supplierNotifier = context.read<SupplierChangeNotifier>();
                final accessManager = PersonnelAccessManager(
                  personnelNotifier: personnelNotifier,
                  supplierNotifier: supplierNotifier,
                );

                return _buildGuardedRoute(
                  isAuthenticated,
                  SupplierEntitiesScreen(
                    key: ValueKey(
                        'personnel_${userId}_${accessibleSuppliers.length}'),
                    userId: userId,
                    accessibleSuppliers: accessibleSuppliers,
                    userRules: userRules,
                    suppliers: suppliers,
                    suppliersWithAccess: suppliersWithAccess,
                    personnelNotifier: personnelNotifier,
                    supplierNotifier: supplierNotifier,
                    accessManager: accessManager,
                  ),
                  const LoginScreen(),
                );

              case AppRoutes.serviceForm:
                return _buildGuardedRoute(
                  isAuthenticated,
                  const ProvidedServiceFormScreen(),
                  const HomePage(),
                );

              case AppRoutes.storeManage:
                return const DashboardScreen();

              case AppRoutes.login:
                if (isAuthenticated) {
                  return const HomePage();
                }
                return const LoginScreen();

              case AppRoutes.registration:
                return const RegistrationForm();

              case AppRoutes.imageUpload:
                return const UploadImagePage();

              case AppRoutes.productDetails:
                return const ProductDetailsScreen();

              case AppRoutes.userEdit:
                return _buildGuardedRoute(
                  isAuthenticated,
                  const AppUserEditFormScreen(),
                  const LoginScreen(),
                );

              case AppRoutes.ordersPage:
                return _buildGuardedRoute(
                  isAuthenticated,
                  OrdersScreen(
                    cartChangeNotifier: context.read<OrderChangeNotifier>(),
                  ),
                  const LoginScreen(),
                );

              default:
                return _buildGuardedRoute(
                  isAuthenticated,
                  const HomePage(),
                  const LoginScreen(),
                );
            }
          },
        );
      },
    );
  }

  static Widget _buildGuardedRoute(
    bool isAuthenticated,
    Widget authorizedScreen,
    Widget unauthorizedScreen,
  ) {
    return isAuthenticated
        ? SizedBox(
            key: Key('authorized_${authorizedScreen.runtimeType}'),
            child: authorizedScreen,
          )
        : SizedBox(
            key: Key('unauthorized_${unauthorizedScreen.runtimeType}'),
            child: unauthorizedScreen,
          );
  }
}
