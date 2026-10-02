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
import 'package:event/views/finance_view_model.dart';
import 'package:verdelia_core/app/Services/AuthService.dart';
import 'package:verdelia_core/app/Services/UserService.dart';
import 'package:verdelia_core/business/services/OrderService.dart';
import 'package:verdelia_core/business/services/ProductService.dart';
import 'package:verdelia_core/business/services/RecipeService.dart';
import 'package:verdelia_core/business/services/BusinessOperationService.dart';
import 'package:verdelia_core/business/services/SupplierService.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'package:event/user_change_notifier.dart';
import 'package:event/cart_change_notifier.dart';
import 'package:event/recipe_change_notifier.dart';
import 'package:event/product_change_notifier.dart';
import 'package:event/supplier_change_notifier.dart';
import 'package:event/preferenceChangeNotifier.dart';
import 'package:impl_mediation/impl_mediation.dart';
import 'package:locator/locator.dart';
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
        ChangeNotifierProvider<FinanceViewModel>(
            create: (_) => FinanceViewModel(
                businessOperationService:
                    AppLocator.get<BusinessOperationService>())),
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
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2ECC71),
                primary: const Color.fromRGBO(46, 204, 113, 1),
                secondary: const Color(0xFF3498DB), // Complementary blue
                tertiary: const Color.fromARGB(255, 255, 128, 43), // Accent red
                onPrimaryFixed: Colors.white,
                // background: const Color(0xFFF8F9FA), // Light background
                // onBackground: const Color(0xFF212121), // Main text color
                // surface: Colors.white, // Card surfaces
                onPrimary: Colors.white, // Text on primary
                onSecondary: Colors.white, // Text on secondary
                onSurface: const Color(0xFF212121), // Text on surfaces
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2ECC71),
                primary: const Color(0xFF2ECC71), // Your primary green
                primaryContainer: const Color(0xFF27AE60), // Darker green
                secondary: const Color(0xFF3498DB), // Blue
                secondaryContainer: const Color(0xFF2980B9), // Darker blue
                tertiary: const Color.fromARGB(255, 255, 128, 43), // Red accent
                background: const Color(0xFF121212), // Dark background
                surface: const Color(0xFF1E1E1E), // Card surfaces
                surfaceVariant: const Color(0xFF2D2D2D), // Lighter surfaces
                onPrimary: Colors.white,
                onPrimaryFixed: const Color(0xFF1E1E1E),
                onSecondary: Colors.white,
                onBackground: Colors.white.withOpacity(0.87),
                onSurface: Colors.white.withOpacity(0.87),
                onSurfaceVariant: Colors.white.withOpacity(0.6),
                outline: const Color(0xFF404040), // Borders
                outlineVariant: const Color(0xFF2D2D2D), // Subtle borders
                brightness: Brightness.dark,
              ),
            ),
            themeMode: localeProvider.themeMode,
          );
        },
      ),
    );
  }
}
