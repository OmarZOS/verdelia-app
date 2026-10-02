// ResponseHandler.dart
import 'package:flutter/material.dart';
import 'SnackbarService.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';
import 'package:verdelia_core/mediation/StorageService.dart';

class ResponseHandler {
  // Response message mapping
  static String _getLocalizedMessage(
    BuildContext context,
    int? statusCode,
    String? responseCode,
    String? defaultMessage,
  ) {
    final loc = AppLocalizations.of(context)!;

    // First, try to match by responseCode (error_code from backend)
    if (responseCode != null && responseCode.isNotEmpty) {
      final message = _getMessageByErrorCode(loc, responseCode);
      if (message != null) return message;
    }

    // Then try to match by status code
    if (statusCode != null) {
      final message = _getMessageByStatusCode(loc, statusCode);
      if (message != null) return message;
    }

    // Fallback to default message
    return defaultMessage ?? loc.something_went_wrong;
  }

  static String? _getMessageByErrorCode(
      AppLocalizations loc, String errorCode) {
    // Map backend error codes to localized messages
    switch (errorCode) {
      // Authentication Errors
      case 'AUTH_REQUIRED':
        return loc.auth_required;
      case 'INCORRECT_CREDENTIALS':
        return loc.incorrect_credentials;
      case 'AUTH_DECODE_FAILED':
        return loc.auth_decode_failed;
      case 'AUTH_UNAUTHORIZED':
        return loc.auth_unauthorized;
      case 'USER_AUTH_CREATION_FAILED':
        return loc.user_auth_creation_failed;
      case 'USER_NET_FAILED':
        return loc.user_net_failed;

      // User Errors
      case 'APPUSER_NOT_EXISTS':
        return loc.appuser_not_exists;
      case 'APPUSER_ALREADY_EXISTS':
        return loc.appuser_already_exists;
      case 'APPUSERTYPE_NOT_EXISTS':
        return loc.appusertype_not_exists;
      case 'USER_FETCH_NOT_FOUND':
        return loc.user_fetch_not_found;
      case 'USER_INSERT_FAILED':
        return loc.user_insert_failed;
      case 'USER_UPDATE_FAILED':
        return loc.user_update_failed;
      case 'USER_DELETE_FAILED':
        return loc.user_delete_failed;

      // Person Errors
      case 'PERSON_NOT_EXISTS':
        return loc.person_not_exists;
      case 'PERSON_INSERT_FAILED':
        return loc.person_insert_failed;
      case 'PERSON_UPDATE_FAILED':
        return loc.person_update_failed;
      case 'PERSON_DELETE_FAILED':
        return loc.person_delete_failed;
      case 'PERSON_DETAIL_INSERT_FAILED':
        return loc.person_detail_insert_failed;
      case 'PERSON_DETAILS_NOT_FOUND':
        return loc.person_details_not_found;
      case 'PERSON_FETCH_NOT_FOUND':
        return loc.person_fetch_not_found;

      // Product Errors
      case 'PRODUCT_NOT_EXISTS':
        return loc.product_not_exists;
      case 'PRODUCT_ALREADY_EXISTS':
        return loc.product_already_exists;
      case 'PRODUCT_CATEGORY_NOT_EXISTS':
        return loc.product_category_not_exists;
      case 'PRODUCT_QUANTITY_NOT_ENOUGH':
        return loc.product_quantity_not_enough;
      case 'PRODUCT_QUANTITY_RESTORE_FAILED':
        return loc.product_quantity_restore_failed;
      case 'PRODUCT_SUPPLIER_NOT_EXISTS':
        return loc.product_supplier_not_exists;
      case 'PRODUCT_SUPPLIER_ALREADY_EXISTS':
        return loc.product_supplier_already_exists;
      case 'PRODUCT_FETCH_NOT_FOUND':
        return loc.product_fetch_not_found;
      case 'PRODUCT_INSERT_FAILED':
        return loc.product_insert_failed;
      case 'PRODUCT_UPDATE_FAILED':
        return loc.product_update_failed;
      case 'PRODUCT_DELETE_FAILED':
        return loc.product_delete_failed;
      case 'PRODUCT_SEARCH_NOT_FOUND':
        return loc.product_search_not_found;
      case 'PRODUCT_IMAGE_NOT_FOUND':
        return loc.product_image_not_found;

      // Supplier Errors
      case 'SUPPLIER_NOT_EXISTS':
        return loc.supplier_not_exists;
      case 'SUPPLIER_TYPE_NOT_EXISTS':
        return loc.supplier_type_not_exists;
      case 'SUPPLIER_FETCH_NOT_FOUND':
        return loc.supplier_fetch_not_found;
      case 'SUPPLIER_INSERT_FAILED':
        return loc.supplier_insert_failed;
      case 'SUPPLIER_UPDATE_FAILED':
        return loc.supplier_update_failed;
      case 'SUPPLIER_DELETE_FAILED':
        return loc.supplier_delete_failed;

      // Organisation Errors
      case 'ORGANISATION_NOT_FOUND':
        return loc.organisation_not_found;
      case 'ORGANISATION_NAME_USED':
        return loc.organisation_name_used;
      case 'ORG_ALREADY_EXISTS':
        return loc.org_already_exists;
      case 'ORG_INSERT_FAILED':
        return loc.org_insert_failed;
      case 'ORG_UPDATE_FAILED':
        return loc.org_update_failed;
      case 'ORG_DELETE_FAILED':
        return loc.org_delete_failed;

      // Recipe Errors
      case 'RECIPE_NOT_EXISTS':
        return loc.recipe_not_exists;
      case 'RECIPE_UPDATE_FAILED':
        return loc.recipe_update_failed;
      case 'RECIPE_DELETE_FAILED':
        return loc.recipe_delete_failed;
      case 'RECIPE_FETCH_NOT_FOUND':
        return loc.recipe_fetch_not_found;
      case 'RECIPE_CATEGORY_NOT_EXISTS':
        return loc.recipe_category_not_exists;
      case 'RECIPE_ALREADY_EXISTS':
        return loc.recipe_already_exists;
      case 'RECIPE_INSERT_FAILED':
        return loc.recipe_insert_failed;
      case 'RECIPE_IMAGE_NOT_FOUND':
        return loc.recipe_image_not_found;
      case 'RECIPE_SEARCH_NOT_FOUND':
        return loc.recipe_search_not_found;

      // Ingredient Errors
      case 'INGREDIENT_NOT_EXISTS':
        return loc.ingredient_not_exists;
      case 'INGREDIENT_ALREADY_EXISTS':
        return loc.ingredient_already_exists;
      case 'INGREDIENT_INSERT_FAILED':
        return loc.ingredient_insert_failed;
      case 'INGREDIENT_UPDATE_FAILED':
        return loc.ingredient_update_failed;
      case 'INGREDIENT_DELETE_FAILED':
        return loc.ingredient_delete_failed;

      // Order Errors
      case 'ORDER_NOT_EXISTS':
        return loc.order_not_exists;
      case 'ORDER_FETCH_NOT_FOUND':
        return loc.order_fetch_not_found;
      case 'ORDER_INSERT_FAILED':
        return loc.order_insert_failed;
      case 'ORDER_INSERT_CONFLICT':
        return loc.order_insert_conflict;
      case 'ORDER_UPDATE_FAILED':
        return loc.order_update_failed;
      case 'ORDER_DELETE_FAILED':
        return loc.order_delete_failed;
      case 'INVALID_ORDER_STATUS':
        return loc.invalid_order_status;
      case 'ORDER_ITEMS_DELETE_FAILED':
        return loc.order_items_delete_failed;
      case 'ORDER_ITEM_INSERT_FAILED':
        return loc.order_item_insert_failed;

      // Cart Errors
      case 'CART_NOT_EXISTS':
        return loc.cart_not_exists;
      case 'CART_INSERT_FAILED':
        return loc.cart_insert_failed;

      // Delivery Errors
      case 'DELIVERY_NOT_EXISTS':
        return loc.delivery_not_exists;
      case 'DELIVERY_UPDATE_FAILED':
        return loc.delivery_update_failed;
      case 'DELIVERY_CANNOT_BE_UPDATED':
        return loc.delivery_cannot_be_updated;
      case 'DELIVERY_BULK_UPDATE_FAILED':
        return loc.delivery_bulk_update_failed;
      case 'DELIVERY_DELETE_FAILED':
        return loc.delivery_delete_failed;
      case 'DELIVERY_BULK_DELETE_FAILED':
        return loc.delivery_bulk_delete_failed;
      case 'DELIVERY_INSERT_FAILED':
        return loc.delivery_insert_failed;
      case 'DELIVERY_VALIDATION_FAILED':
        return loc.delivery_validation_failed;

      // Service Errors
      case 'SERVICE_NOT_FOUND':
        return loc.service_not_found;
      case 'SERVICE_INSERT_CONFLICT':
        return loc.service_insert_conflict;
      case 'SERVICE_CATEGORY_NOT_FOUND':
        return loc.service_category_not_found;

      // Rule/Staff Errors
      case 'RULE_ALREADY_EXISTS':
        return loc.rule_already_exists;
      case 'RULE_NOT_EXISTS':
        return loc.rule_not_exists;
      case 'RULE_INSERT_FAILED':
        return loc.rule_insert_failed;
      case 'RULE_UPDATE_FAILED':
        return loc.rule_update_failed;
      case 'RULE_DELETE_FAILED':
        return loc.rule_delete_failed;
      case 'RULE_INVALID_STATUS':
        return loc.rule_invalid_status;

      // Notification Errors
      case 'NOTIFICATION_NOT_EXISTS':
        return loc.notification_not_exists;
      case 'NOTIFICATION_ALREADY_EXISTS':
        return loc.notification_already_exists;
      case 'NOTIFICATION_INSERT_FAILED':
        return loc.notification_insert_failed;
      case 'NOTIFICATION_UPDATE_FAILED':
        return loc.notification_update_failed;
      case 'NOTIFICATION_DELETE_FAILED':
        return loc.notification_delete_failed;
      case 'NOTIFICATION_BULK_INSERT_FAILED':
        return loc.notification_bulk_insert_failed;

      // Location Errors
      case 'LOCATION_NOT_FOUND':
      case 'LOCATION_NOT_EXISTS':
        return loc.location_not_exists;
      case 'LOCATION_UPDATE_FAILED':
        return loc.location_update_failed;
      case 'LOCATION_FETCH_NOT_FOUND':
        return loc.location_fetch_not_found;
      case 'LOCATION_INSERT_FAILED':
        return loc.location_insert_failed;
      case 'LOCATION_DELETE_FAILED':
        return loc.location_delete_failed;
      case 'ADDRESS_NOT_FOUND':
        return loc.address_not_found;

      // Payment Errors
      case 'PAYMENT_FAILED':
        return loc.payment_failed;
      case 'DEPOSIT_CREATION_FAILED':
        return loc.deposit_creation_failed;

      // Image Errors
      case 'IMAGE_INSERT_FAILED':
        return loc.image_insert_failed;
      case 'IMAGE_UPDATE_FAILED':
        return loc.image_update_failed;

      // Database Errors
      case 'DATABASE_ERROR':
        return loc.database_error;
      case 'INTEGRITY_ERROR':
        return loc.integrity_error;
      case 'DATA_ERROR':
        return loc.data_error;
      case 'OPERATIONAL_ERROR':
        return loc.operational_error;
      case 'PROGRAMMING_ERROR':
        return loc.programming_error;
      case 'INTERNAL_ERROR':
        return loc.internal_error;
      case 'INTERFACE_ERROR':
        return loc.interface_error;
      case 'STATEMENT_ERROR':
        return loc.statement_error;
      case 'SQLALCHEMY_ERROR':
        return loc.sqlalchemy_error;

      // General Errors
      case 'SUCCESS':
        return loc.success;
      case 'FAILED':
        return loc.failed;
      case 'NOT_FOUND':
        return loc.not_found;
      case 'TIMEOUT':
      case 'NETWORK_TIMEOUT':
        return loc.network_timeout;
      case 'VALIDATION_ERROR':
        return loc.validation_error;
      case 'RATE_LIMITED':
        return loc.rate_limited;
      case 'PERMISSION_DENIED':
        return loc.permission_denied;
      case 'CLIENT_NOT_EXISTS':
        return loc.client_not_exists;

      default:
        return null;
    }
  }

  static String? _getMessageByStatusCode(AppLocalizations loc, int statusCode) {
    switch (statusCode) {
      case 200:
        return loc.success;
      case 201:
        return loc.created_successfully;
      case 400:
        return loc.bad_request;
      case 401:
        return loc.unauthorized;
      case 403:
        return loc.forbidden;
      case 404:
        return loc.not_found;
      case 409:
        return loc.conflict;
      case 410:
        return loc.gone;
      case 422:
        return loc.validation_error;
      case 429:
        return loc.rate_limited;
      case 500:
        return loc.internal_server_error;
      case 502:
        return loc.bad_gateway;
      case 503:
        return loc.service_unavailable;
      case 504:
        return loc.gateway_timeout;
      case 511:
        return loc.network_authentication_required;
      default:
        return null;
    }
  }

  // ============ MAIN HANDLER METHODS ============

  static void handleStoredResponse({
    required BuildContext context,
    required String callerKey,
    required StorageService storageService,
    VoidCallback? onRetry,
    String? customSuccessMessage,
    String? customErrorMessage,
  }) {
    final response = storageService.getResponse(callerKey);

    if (response == null) {
      debugPrint('⚠️ No response found for key: $callerKey');
      SnackbarService.showSnackbar(
        context: context,
        message: AppLocalizations.of(context)!.no_response_data,
        backgroundColor: Colors.orange,
      );
      return;
    }

    final statusCode = response.statusCode;
    final responseCode = response.responseCode;
    final isSuccess = response.isSuccess;
    final message = response.message;

    debugPrint('📦 Processing stored response for: $callerKey');
    debugPrint('   Status: ${isSuccess ? "SUCCESS" : "FAILURE"}');
    debugPrint('   StatusCode: $statusCode');
    debugPrint('   ResponseCode: $responseCode');

    if (isSuccess) {
      final successMessage = customSuccessMessage ??
          _getLocalizedMessage(context, statusCode, responseCode, message);
      _showSnackbarWithStyle(
        context: context,
        message: successMessage,
        isSuccess: true,
        onRetry: null,
      );
    } else {
      final errorMessage = customErrorMessage ??
          _getLocalizedMessage(context, statusCode, responseCode, message);
      _showSnackbarWithStyle(
        context: context,
        message: errorMessage,
        isSuccess: false,
        onRetry: onRetry,
      );
    }
  }

  static void handleNotifierResponse({
    required BuildContext context,
    required String callerKey,
    required dynamic notifier,
    VoidCallback? onRetry,
    String? customSuccessMessage,
    String? customErrorMessage,
  }) {
    final response = notifier.getResponse(callerKey);

    if (response == null) {
      debugPrint('⚠️ No response found for key: $callerKey');
      SnackbarService.showSnackbar(
        context: context,
        message: AppLocalizations.of(context)!.no_response_data,
        backgroundColor: Colors.orange,
      );
      return;
    }

    final statusCode = response.statusCode;
    final responseCode = response.responseCode;
    final isSuccess = response.isSuccess;
    final message = response.message;

    debugPrint('📦 Processing response for: $callerKey');
    debugPrint('   Status: ${isSuccess ? "SUCCESS" : "FAILURE"}');
    debugPrint('   StatusCode: $statusCode');
    debugPrint('   ResponseCode: $responseCode');

    if (isSuccess) {
      final successMessage = customSuccessMessage ??
          _getLocalizedMessage(context, statusCode, responseCode, message);
      _showSnackbarWithStyle(
        context: context,
        message: successMessage,
        isSuccess: true,
        onRetry: null,
      );
    } else {
      final errorMessage = customErrorMessage ??
          _getLocalizedMessage(context, statusCode, responseCode, message);
      _showSnackbarWithStyle(
        context: context,
        message: errorMessage,
        isSuccess: false,
        onRetry: onRetry,
      );
    }
  }

  static void handleResponse({
    required BuildContext context,
    required int statusCode,
    required String responseCode,
    required String finalMessage,
    VoidCallback? onRetry,
  }) {
    final message =
        _getLocalizedMessage(context, statusCode, responseCode, finalMessage);
    final isSuccess = statusCode >= 200 && statusCode < 300;

    _showSnackbarWithStyle(
      context: context,
      message: message,
      isSuccess: isSuccess,
      onRetry: statusCode == 408 ||
              statusCode == 504 ||
              responseCode == 'NETWORK_TIMEOUT'
          ? onRetry
          : null,
    );
  }

  static void _showSnackbarWithStyle({
    required BuildContext context,
    required String message,
    required bool isSuccess,
    VoidCallback? onRetry,
  }) {
    if (message.isEmpty) return;

    final snackbarColor = isSuccess
        ? Colors.green
        : SnackbarService.getSnackbarColorFromStatusCode(isSuccess ? 200 : 500);

    if (onRetry != null) {
      SnackbarService.showSnackbarWithAction(
        context: context,
        message: message,
        backgroundColor: snackbarColor,
        actionLabel: 'Retry',
        onAction: onRetry,
      );
    } else {
      SnackbarService.showSnackbar(
        context: context,
        message: message,
        backgroundColor: snackbarColor,
      );
    }
  }
}
