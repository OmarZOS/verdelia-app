library app_constants;

import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

class AppConstants {
  static List<String> recipeUnits = [
    'g',
    'kg',
    'mg',
    'lb',
    'oz',
    'ml',
    'l',
    'cup',
    'tbsp',
    'tsp',
    'pinch',
  ];

  static List<String> productUnits = [
    'g',
    'kg',
    'mg',
    'L',
    'mL',
    'pc',
    'pkg',
    'box',
    'bag',
    'slice',
    'cup',
  ];

  static Color get backgroundColor => const Color(0xFF2ECC71);
  static Color get backgroundDarkColor => const Color(0xFF186A3B);

  static const String apiBaseUrl = 'http://192.168.1.31:9000/api/v1';
  static const String fsBaseUrl = 'http://192.168.1.31:9099/fs';

  static const String postImageEndpoint = '/upload';

  // ==================== Authentication Endpoints ====================
  static const String loginEndpoint = '/authentication/token';
  static const String logoutEndpoint = '/logout';
  static const String oauthLoginEndpoint = '/login'; // /login/{provider}
  static const String oauthCallbackEndpoint = '/auth'; // /auth/{provider}
  static const String signUpEndpoint = '/app_user';
  static const String refreshTokenEndpoint = '/authentication/refresh';

  // ==================== User/AppUser Endpoints ====================
  static const String getAppUserCategoriesEndpoint = '/app_user/categorie/all';
  static const String addAppUserEndpoint = '/app_user';
  static const String deleteAppUserEndpoint = '/app_user';
  static const String getAllAppUsersEndpoint = '/app_user';
  static const String appUserEndpoint = '/app_user';
  static const String updateAppUserImageEndpoint = '/app_user/update_image_url';
  static const String updateAppUserEndpoint = '/app_user';
  static const String updateAppUserPasswordEndpoint =
      '/app_user/update_password';
  static const String searchAppUserEndpoint = '/search/personnel';
  static const String getUserByEmailEndpoint = '/app_user/by-email';

  static const String getPlansEndpoint = '/plans';
  static const String getPlanEndpoint = '/plans';

// ==================== Subscription endpoints ====================
//
// These share the `/api/v1/app_user/{id}/subscription` prefix; the
// constant stores the prefix and the method body appends the suffix
// that varies per call. Keeping the prefix in one place means a
// router rename only changes one line.

  static const String subscriptionBaseEndpoint = '/app_user';
  static const String subscriptionSuffix = '/subscription';
  static const String subscriptionStatusSuffix = '/subscription/status';
  static const String subscriptionInitiateSuffix = '/subscription/initiate';
  static const String subscriptionLinkFreeSuffix = '/subscription/link-free';

  // ==================== Person Endpoints ====================
  static const String personEndpoint = '/person';
  static const String createOrUpdatePersonEndpoint = '/'; // POST /api/v1/
  static const String getAllPersonsEndpoint = '/'; // GET /api/v1/
  static const String searchPersonsByNameEndpoint = '/search/people';
  static const String getAllBloodTypesEndpoint = '/blood-types/all';
  static const String getBloodTypeEndpoint = '/blood-type';

  // ==================== Staff/Management Rule Endpoints ====================
  static const String addRuleEndpoint = '/staff';
  static const String getStaffEndpoint = '/staff';
  static const String updateStaffEndpoint = '/staff';
  static const String deleteStaffEndpoint = '/staff/delete';
  static const String answerStaffInvitationEndpoint = '/staff/answer';
  static const String getUserStaffEndpoint = '/staff/user';
  static const String getProviderStaffEndpoint = '/staff/provider';
  static const String getPendingInvitationsEndpoint = '/staff/pending';

  // ==================== Notification Endpoints ====================

  static const String searchServiceEndpoint = "";
  static const String deliveryEndpoint = "";
  static const String orderEndpoint = "";

  static const String notificationsBaseEndpoint = '/notifications';
  static const String getNotificationsEndpoint = '/notifications/user/read-all';
  static const String getNotificationByIdEndpoint = '/notifications';
  static const String createNotificationEndpoint = '/notifications/create';
  static const String readNotificationEndpoint = '/notifications/read';
  static const String readAllNotificationsEndpoint =
      '/notifications/user/read-all';
  static const String deleteNotificationEndpoint = '/notifications';
  static const String deleteAllNotificationsEndpoint = '/notifications/user';
  static const String unreadCountEndpoint = '/notifications/user';
  static const String sendInvitationEndpoint = '/notifications/invitation/send';
  static const String bulkCreateNotificationsEndpoint =
      '/notifications/bulk/create';

  static const String notificationEndpoint = '/'; // /{notification_id}
  static const String userNotificationsEndpoint = '/user'; // /user/{user_ref}
  static const String userReadAllEndpoint =
      '/read-all'; // /user/{user_ref}/read-all
  static const String userAllEndpoint = '/all'; // /user/{user_ref}/all
  static const String userUnreadCountEndpoint =
      '/unread-count'; // /user/{user_ref}/unread-count

  // ==================== Product Endpoints ====================
  static const String addProductEndpoint = '/products';
  static const String deleteProductEndpoint = '/products/delete';
  static const getAllProductsEndpoint = '/products';
  static const String productEndpoint = '/products';
  static const String updateProductEndpoint =
      '/products'; // /products/{product_id}
  static const String getProductCategoriesEndpoint = '/products/categories';
  static const String getAllProductsByCategoryEndpoint = '/products/category';
  static const String getProductImageEndpoint = '/products/image';
  static const String getProductFeedEndpoint = '/products/observer';
  static const String getProductSearchByBarcodeEndpoint = '/products/barcode';
  static const String getProductDBSearchByBarcodeEndpoint =
      '/products/db/barcode';
  static const String getProductSearchByImageEndpoint =
      '/products/search/image';
  static const String getProductByIdEndpoint =
      '/products'; // /products/{product_id}

  // ==================== Recipe Endpoints ====================
  static const String addRecipeEndpoint = '/recipes';
  static const String deleteRecipeEndpoint = '/recipes';
  static const String getAllRecipesEndpoint = '/recipes';
  static const String recipeEndpoint = '/recipes';
  static const String updateRecipeEndpoint = '/recipes'; // /recipes/{recipe_id}
  static const String getRecipeCategoriesEndpoint = '/recipes/categories';
  static const String getRecipeImageEndpoint =
      '/recipes/image'; // Adjust based on your API
  static const String getRecipeSearchByTokenEndpoint =
      '/recipes/search'; // Adjust
  static const String getAllIngredientEndpoint = '/recipes/ingredients/all';
  static const String deleteIngredientEndpoint = '/recipes/ingredients';
  static const String getIngredientEndpoint = "/recipes/ingredients";
  static const String addIngredientEndpoint = "/recipes/ingredients";
  static const String updateIngredientEndpoint = "/recipes/ingredients";

  // ==================== Supplier Endpoints ====================

  static const String addSupplierEndpoint = '/suppliers';
  static const String updateSupplierEndpoint = '/suppliers';
  static const String deleteSupplierEndpoint = '/suppliers';
  static const String getAllSuppliersEndpoint = '/suppliers';
  static const String getSuppliersByIdsEndpoint = '/suppliers/ids';
  static const String supplierEndpoint = '/suppliers';
  static const String getSupplierCategoriesEndpoint = '/supplier-types';
  static const String getSupplierSearchByTokenEndpoint =
      '/suppliers/search'; // Adjust
  static const String getSupplierSearchByGeoEndpoint =
      '/search/position/supplier';
  static const String getSupplierByIdEndpoint =
      '/suppliers'; // /suppliers/{provider_id}
  // ==================== Organisation Endpoints ====================

  static const String getOrganisationsEndpoint = '/organisations';
  static const String createOrganisationEndpoint = '/organisations';
  static const String updateOrganisationEndpoint = '/organisations';
  static const String deleteOrganisationEndpoint = '/organisations';
  static const String getOrganisationByIdEndpoint = '/organisations';

  // ==================== Order Endpoints ====================
  static const String addOrderEndpoint = '/business/orders';
  static const String getAllOrdersEndpoint = '/business/orders/user';
  static const String getOrderDetailsEndpoint = '/business/orders';
  static const String updateOrderEndpoint = '/business/orders';
  static const String deleteOrderEndpoint = '/business/orders';
  static const String updateOrderStatusEndpoint = '/business/orders/status';
  static const String getOrderItemsEndpoint = '/business/orders/items';

  // ==================== Cart Endpoints ====================
  static const String getCartsEndpoint = '/business/carts';
  static const String cartEndpoint = '/business/carts';
  static const String postCartEndpoint = '/business/carts';
  static const String getCartDetailsEndpoint = '/business/carts';
  static const String deleteCartEndpoint = '/business/carts';
  static const String updateCartStatusEndpoint = '/business/carts/status';
  static const String getCartItemsEndpoint = '/business/carts/items';
  static const String getCartServicesEndpoint = '/business/carts/services';
  static const String getCartSummaryEndpoint = '/business/carts/summary';

  // ==================== Delivery Endpoints ====================
  static const String addDeliveryEndpoint = '/business/delivery';
  static const String getAllDeliveriesEndpoint = '/business/delivery';
  static const String getDeliveryDetailsEndpoint = '/business/delivery';
  static const String updateDeliveryEndpoint = '/business/delivery';
  static const String deleteDeliveryEndpoint = '/business/delivery';
  static const String updateDeliveryStatusEndpoint =
      '/business/deliveries/status';
  static const String updateDeliveryAddressEndpoint =
      '/business/deliveries/address';
  static const String updateDeliveryTrackingEndpoint =
      '/business/deliveries/tracking';
  static const String getDeliveriesByStatusEndpoint =
      '/business/deliveries/status';
  static const String bulkDeleteDeliveriesEndpoint =
      '/business/deliveries/bulk/delete';
  static const String bulkUpdateDeliveryStatusEndpoint =
      '/business/deliveries/bulk/update-status';
  static const String getDeliveryStatsEndpoint = '/business/deliveries/stats';

  // ==================== Service Endpoints ====================
  static const String addServiceEndpoint = '/business/services';
  static const String deleteServiceEndpoint = '/business/services';
  static const String serviceEndpoint = '/business/services';
  static const String updateServiceEndpoint = '/business/services';
  static const String getServicesByCategoryEndpoint =
      '/business/services/category';
  static const String getServicesByProviderEndpoint =
      '/business/services/provider';
  static const String toggleServiceStatusEndpoint = '/business/services/toggle';
  static const String getServiceRequirementsEndpoint =
      '/business/services/requirements';
  static const String getServiceStaffRequirementsEndpoint =
      '/business/services/staff-requirements';
  static const String getServiceCategoriesEndpoint =
      '/business/services/categories';
  static const String getServiceCategoryRolesEndpoint =
      '/business/services/category';

  // ==================== Financial Endpoints ====================
  static const String postPaymentEndpoint = '/business/payments';
  static const String getPaymentsEndpoint = '/business/payments';
  static const String getPaymentByIdEndpoint = '/business/payments';
  static const String createDepositEndpoint = '/business/deposits';
  static const String getDepositsEndpoint = '/business/deposits';
  static const String getDepositByIdEndpoint = '/business/deposits';
  static const String createFeeEndpoint = '/business/fees';
  static const String getFeesEndpoint = '/business/fees';
  static const String getFeeByIdEndpoint = '/business/fees';
  static const String getFinancialDocsEndpoint = '/invoices'; // Adjust

  // ==================== Business Operations Endpoints ====================
  static const String getBusinessOperationsEndpoint = '/business/operations';

  // ==================== Health/Medical Endpoints ====================
  static const String getSerologyHistoryEndpoint = '/patient/serology/history';
  static const String getSerologyIndicatorsEndpoint = '/serology/indicators';
  static const String getSerologyIndicatorEndpoint = '/serology/indicator';
  static const String getSerologyRecordEndpoint = '/serology';
  static const String addSerologyRecordEndpoint = '/patient/serology';
  static const String updateSerologyRecordEndpoint = '/patient/serology/update';
  static const String deleteSerologyRecordEndpoint = '/patient/serology/delete';
  static const String getAllSymptomsEndpoint = '/symptoms/all';
  static const String getSymptomEndpoint = '/symptoms';
  static const String addSymptomOccurrenceEndpoint = '/patient/symptoms';
  static const String getSymptomHistoryEndpoint = '/patient/symptoms/history';
  static const String getSymptomOccurrenceEndpoint =
      '/patient/symptoms/occurrence';
  static const String deleteSymptomOccurrenceEndpoint =
      '/patient/symptoms/delete';

  // ==================== Reaction Endpoints ====================
  static const String reactionEndpoint = '/reaction';

  // ==================== Search Endpoints ====================
  static const productSearchEndpoint = '/search/product';
  static const String recipeSearchEndpoint = '/recipes/search';
  static const String supplierSearchEndpoint = '/suppliers/search';
  static const String multiSearchEndpoint = '/search/multi';
  static const String quickSearchEndpoint = '/search/quick';

  // ==================== Document Endpoints ====================
  static const String cartInvoiceEndpoint = '/cart/invoice';
  static const String cartReceiptEndpoint = '/cart/receipt';
  static const String cartInvoicePdfEndpoint = '/cart/invoice/pdf';
  static const String cartReceiptPdfEndpoint = '/cart/receipt/pdf';
  static const String cartDataEndpoint = '/cart/data';

  static const int adminCategoryId = 3;

  static const int itemsPerPage = 6;

  static const String cookingRecipeCatalogDBId = "provider";
  static const int supplierDBId = 4;

  // Texts
  static const String notFoundError = 'Object not found';
  static const String getFailure = 'Failed to load item';
  static const String serverError = 'Failed to connect to the server';

  // Fonts
  static const String defaultFontFamily = 'Roboto';
  static const kTextColor = Color(0xFF535353);
  static const kTextLightColor = Color(0xFFACACAC);

  static const kDefaultPaddin = 20.0;
}

class VerdeliaPageIndex {
  static const int catalog = 0;
  static const int suppliers = 1;
  static const int recipes = 2;
  static const int games = 3;
  static const int profile = 4;
}

class ProductAssistedFields {
  static const String IPRODUCT_NAME = "iproduct_name";
  static const String IPRODUCT_BRAND = "iproduct_brand";
  static const String IPRODUCT_BARCODE = "iproduct_barcode";
  static const String IPRODUCT_ESTIMATED_PRICE_DA =
      "iproduct_estimated_price_DA";
  static const String IPRODUCT_BASE_PRICE = "iproduct_base_price";

  static const String IPRODUCT_GLUTEN_STATUS = "iproduct_gluten_status";
  static const String DESCRIPTION = "iproduct_desc";
  static const String QUANTIFIER = "iproduct_quantifier";
  static const String QUANTITY = "iproduct_quantity";
}

class OrderStates {
  static const String COMPLETED_ORDER_STATE = "COMPLETED";
  static const String DELIVERED_ORDER_STATE = "DELIVERED";
  static const String PENDING_ORDER_STATE = "PENDING";
  static const String CANCELLED_ORDER_STATE = "CANCELLED";
  static const String PROCESSING_ORDER_STATE = "PROCESSING";
}

class RuleStates {
  static const String pending = 'PENDING';
  static const String rejected = 'REJECTED';
  static const String suspended = 'SUSPENDED';
  static const String obsolete = 'OBSOLETE';
  static const String active = 'ACTIVE';
}

class RoleTypes {
  static const String inventory_view = 'inventory_view';
  static const String inventory_manage = 'inventory_manage';
  static const String orders_view = 'orders_view';
  static const String orders_manage = 'orders_manage';
  static const String personnel_view = 'personnel_view';
  static const String personnel_manage = 'personnel_manage';
}

enum ProductDetailsMode { customer, editor }

enum PricingMode { byProfit, byFinalPrice }
