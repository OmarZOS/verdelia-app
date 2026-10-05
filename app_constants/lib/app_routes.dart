class AppRoutes {
  static const String root = '/';
  static const String login = '/login';
  static const String registration = '/registration';
  static const String home = '/home';
  static const String productDetails = '/product/details';
  static const String supplierDetails = '/suppliers/details';
  static const String recipeDetails = '/recipe/details';
  static const String productCreate = '/product/create';
  static const String recipeCreate = '/recipe/create';
  static const String providerCreate = '/provider/create';
  static const String userEdit = '/user/edit';
  static const String imageUpload = '/image/upload';
  static const String plans = '/plans';

  static const String manageSubscription = '/subscription/manage';
  static const String cartPage = '/cart';
  static const String ordersPage = '/orders';
  static const String productScanPage = '/product/scan';
  static const String QRScanPage = '/qr/scan';
  static const String productCapturePage = '/product/capture';

  /// Owner's own profile. Loads the user from the auth notifier.
  static const String profile = '/profile';

  /// Another user's profile, rendered in visitor mode.
  /// Arguments: `{'user': AppUser, 'visitorUserId': int?}`.
  static const String profileVisitor = '/profile/visitor';

  static const String mapPicker = '/map-picker';

  static const String ingredientManagement = '/ingredient/management';

  static const String supplierEntitiesPage = '/suppliers/entities';
  static const String dashboardPage = '/dashboard/business';

  static const String productCatalog = '/productCatalog';
  static const String suppliersMap = '/suppliersMap';
  static const String recipeCatalog = '/recipeCatalog';
  static const String games = '/games';
  static const String supplierManage = '/manage';
  static const String storeManage = '/store';
  static const String serviceForm = '/service/form';
}
