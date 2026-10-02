import 'package:event/views/business_ops_notifier.dart';
import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/app/VerdeliaImage.dart';
import 'package:verdelia_core/app/Services/NotificationService.dart';
import 'package:verdelia_core/business/finance/services/InvoiceService.dart';
import 'package:verdelia_core/business/services/CartService.dart';
import 'package:verdelia_core/business/services/DeliveryService.dart';
import 'package:verdelia_core/business/services/ProvidedServiceManagementService.dart';
import 'package:event/assistant_change_notifier.dart';
import 'package:event/delivery_change_notifier.dart';
import 'package:event/finance_change_notifier.dart';
import 'package:event/notification_notifier.dart';
import 'package:event/order_change_notifier.dart';
import 'package:event/personnel_notifier.dart';
import 'package:event/service_change_notifier.dart';
import 'package:event/supplier_dashboard_provider.dart';
import 'package:event/views/checkout_view_model.dart';
import 'package:impl_app/impl_notification.dart';
import 'package:business/finance/impl_business_operation.dart';
import 'package:business/finance/verdelia_impl_invoice.dart';
import 'package:business/verdelia_impl_delivery.dart';
import 'package:io/VerdeliaImageImpl.dart';
import 'package:verdelia_core/app/Services/AuthService.dart';
import 'package:verdelia_core/app/Services/UserService.dart';
import 'package:verdelia_core/business/services/OrderService.dart';
import 'package:verdelia_core/business/services/ProductService.dart';
import 'package:verdelia_core/business/services/RecipeService.dart';
import 'package:verdelia_core/business/services/BusinessOperationService.dart';
import 'package:verdelia_core/business/services/SupplierService.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'package:tabbed_home/verdelia_router.dart';
import 'package:impl_app/impl_app.dart';
import 'package:impl_app/impl_auth.dart';
import 'package:event/user_change_notifier.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:business/verdelia_impl_order.dart';
import 'package:business/verdelia_impl_product.dart';
import 'package:business/verdelia_impl_cart.dart';
import 'package:business/verdelia_impl_recipe.dart';
import 'package:business/verdelia_impl_service.dart';
import 'package:business/verdelia_impl_supplier.dart';
import 'package:event/recipe_change_notifier.dart';
import 'package:event/product_change_notifier.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:impl_mediation/impl_mediation.dart';
import 'package:event/preferenceChangeNotifier.dart';
import 'package:login/screens/web_view.dart';
import 'package:locator/locator.dart';
import 'package:product_catalog/screens/components/form/pricing_state.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void setupLocator() {
  // Register your services or dependencies here
  AppLocator.registerSingletonService<StorageService>(StorageServiceImpl());
  AppLocator.registerSingletonService<AppUserService>(AppUserServiceImpl());
  AppLocator.registerSingletonService<DeliveryService>(DeliveryServiceImpl());
  AppLocator.registerSingletonService<RecipeService>(RecipeServiceImpl());
  AppLocator.registerSingletonService<SupplierService>(SupplierServiceImpl());
  AppLocator.registerSingletonService<NotificationService>(NotificationImpl());
  AppLocator.registerSingletonService<ProductService>(ProductServiceImpl());
  AppLocator.registerSingletonService<OrderService>(OrderServiceImpl());
  AppLocator.registerSingletonService<CartService>(CartServiceImpl());
  AppLocator.registerSingletonService<AuthService>(AuthServiceImpl());
  AppLocator.registerSingletonService<ProvidedServiceManagementService>(
      ProvidedServiceManagementImpl());
  AppLocator.registerSingletonService<BusinessOperationService>(
      BusinessOperationServiceImpl());

  AppLocator.registerSingletonService<InvoiceService>(InvoiceServiceImpl());

  AppLocator.registerFactory<VerdeliaImage>(() => VerdeliaImageImpl());
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeProvider = LocaleProvider();
  await localeProvider.loadSavedLocale();
  await localeProvider.getThemePreference();
  // await localeProvider.setLanguagePreference("ar");

  setupLocator();
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize GoogleLoginManager
  GoogleLoginManager.initialize();

  final appUserNotifier = AppUserNotifier();
  AppLocator.get<StorageService>().setTokenRefreshHandler(
    () => appUserNotifier.refreshTokenNow(callerKey: 'automatic_token_refresh'),
  );
  await appUserNotifier.initializeAuthState();
  FlutterError.onError = (details) {
    final msg = details.exception.toString();
    if (msg.contains('_debugDuringDeviceUpdate')) {
      return; // silence the Flutter framework bug
    }
    // Print the actual error + stack, once, in a readable form.
    debugPrint('─── FLUTTER ERROR ───');
    debugPrint(msg);
    if (details.stack != null) {
      debugPrint(details.stack.toString().split('\n').take(15).join('\n'));
    }
    debugPrint('─────────────────────');
  };

  runApp(VerdeliaApp(localeProvider, appUserNotifier));
}

class VerdeliaApp extends StatelessWidget {
  final LocaleProvider localeProvider;
  final AppUserNotifier appUserNotifier;

  const VerdeliaApp(this.localeProvider, this.appUserNotifier, {super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProductNotifier>(
            create: (_) => ProductNotifier()),
        ChangeNotifierProvider<RecipeNotifier>(create: (_) => RecipeNotifier()),
        ChangeNotifierProvider<AppUserNotifier>(create: (_) => appUserNotifier),
        ChangeNotifierProvider<CartChangeNotifier>(
            create: (_) => CartChangeNotifier()),
        ChangeNotifierProvider<AssistantNotifier>(
            create: (_) => AssistantNotifier()),
        ChangeNotifierProvider<DeliveryChangeNotifier>(
            create: (_) => DeliveryChangeNotifier(
                service: AppLocator.get<DeliveryService>())),
        ChangeNotifierProvider<SupplierChangeNotifier>(
            create: (_) => SupplierChangeNotifier()),
        ChangeNotifierProvider<SupplierDashboardProvider>(
            create: (_) => SupplierDashboardProvider()),
        ChangeNotifierProvider<NotificationNotifier>(
            create: (_) => NotificationNotifier()),
        ChangeNotifierProvider<OrderChangeNotifier>(
            create: (_) => OrderChangeNotifier()),
        ChangeNotifierProvider<PersonnelNotifier>(
            create: (_) => PersonnelNotifier()),
        ChangeNotifierProvider<ServiceNotifier>(
            create: (_) => ServiceNotifier()),
        ChangeNotifierProvider<FinanceChangeNotifier>(
            create: (_) => FinanceChangeNotifier()),
        ChangeNotifierProvider<CheckoutViewModel>(
            create: (_) => CheckoutViewModel()),
        ChangeNotifierProvider<BusinessOperationNotifier>(
            create: (_) => BusinessOperationNotifier(
                service: AppLocator.get<BusinessOperationService>())),
        ChangeNotifierProvider<PricingState>(create: (_) => PricingState()),
        ChangeNotifierProvider<LocaleProvider>(create: (_) => localeProvider),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            locale: localeProvider.locale,
            supportedLocales: const [
              Locale('ar'), // Arabic
              Locale('fr'), // French
              Locale('en'), // English
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // home: const HomePage(),
            navigatorKey: globalNavigatorKey,
            onGenerateRoute: AppRouter.generateRoute,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2C6E7F),
                brightness: Brightness.light,
              ).copyWith(
                primary: const Color(0xFF2C6E7F),
                onPrimary: Colors.white,
                primaryContainer: const Color(0xFFD6E8EC),
                onPrimaryContainer: const Color(0xFF0E3944),
                secondary: const Color(0xFFC9A227),
                onSecondary: Colors.white,
                secondaryContainer: const Color(0xFFF4E9C7),
                onSecondaryContainer: const Color(0xFF574300),
                tertiary: const Color(0xFF6B8F5E),
                onTertiary: Colors.white,
                tertiaryContainer: const Color(0xFFDDE9D4),
                onTertiaryContainer: const Color(0xFF243D1C),
                surface: const Color(0xFFFFFFFF),
                onSurface: const Color(0xFF1B2426),
                surfaceContainerLowest: const Color(0xFFFFFFFF),
                surfaceContainerLow: const Color(0xFFF8F7F4),
                surfaceContainer: const Color(0xFFF0EEE8),
                surfaceContainerHigh: const Color(0xFFE7E4DC),
                surfaceContainerHighest: const Color(0xFFDDD9CF),
                outline: const Color(0xFFC7C2B6),
                outlineVariant: const Color(0xFFDDD9CF),
                error: const Color(0xFFB3261E),
                onError: Colors.white,
              ),
              scaffoldBackgroundColor: const Color(0xFFF8F7F4),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF1B2426),
                elevation: 0,
                scrolledUnderElevation: 1,
              ),
              cardTheme: const CardThemeData(
                color: Colors.white,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                margin: EdgeInsets.zero,
              ),
              dividerTheme: const DividerThemeData(
                color: Color(0xFFDDD9CF),
                thickness: 1,
              ),
              inputDecorationTheme: const InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFFC7C2B6)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFFC7C2B6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFF2C6E7F), width: 2),
                ),
              ),
              navigationBarTheme: const NavigationBarThemeData(
                backgroundColor: Colors.white,
                indicatorColor: Color(0xFFD6E8EC),
                labelTextStyle: WidgetStatePropertyAll(
                  TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Color(0xFF2C6E7F),
                foregroundColor: Colors.white,
              ),
            ),

            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF7FB6C4),
                brightness: Brightness.dark,
              ).copyWith(
                primary: const Color(0xFF7FB6C4),
                onPrimary: const Color(0xFF00252F),
                primaryContainer: const Color(0xFF124250),
                onPrimaryContainer: const Color(0xFFB9E0E8),
                secondary: const Color(0xFFE0BE5A),
                onSecondary: const Color(0xFF3A2E00),
                secondaryContainer: const Color(0xFF574300),
                onSecondaryContainer: const Color(0xFFFFE9A8),
                tertiary: const Color(0xFFA3C191),
                onTertiary: const Color(0xFF1A2A12),
                tertiaryContainer: const Color(0xFF3A4E2E),
                onTertiaryContainer: const Color(0xFFDDE9D4),
                surface: const Color(0xFF12181A),
                onSurface: const Color(0xFFE2E5E3),
                surfaceContainerLowest: const Color(0xFF0B1011),
                surfaceContainerLow: const Color(0xFF181F21),
                surfaceContainer: const Color(0xFF1E2628),
                surfaceContainerHigh: const Color(0xFF252E30),
                surfaceContainerHighest: const Color(0xFF2C373A),
                outline: const Color(0xFF4F5A5C),
                outlineVariant: const Color(0xFF374143),
                error: const Color(0xFFFFB4AB),
                onError: const Color(0xFF690005),
              ),
              scaffoldBackgroundColor: const Color(0xFF12181A),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF12181A),
                foregroundColor: Color(0xFFE2E5E3),
                elevation: 0,
              ),
              cardTheme: const CardThemeData(
                color: Color(0xFF1E2628),
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                margin: EdgeInsets.zero,
              ),
              dividerTheme: const DividerThemeData(
                color: Color(0xFF374143),
                thickness: 1,
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Color(0xFFE0BE5A),
                foregroundColor: Color(0xFF3A2E00),
              ),
            ),
            themeMode: localeProvider.themeMode,
          );
        },
      ),
    );
  }
}
