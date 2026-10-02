library impl_app;

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/VerdeliaException.dart';
import 'package:verdelia_core/app/Services/AuthService.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'package:locator/locator.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthServiceImpl extends AuthService {
  final StorageService _storageService = AppLocator.get<StorageService>();

  // ============ RESPONSE TRACKING METHODS ============

  void _storeSuccessResponse(String callerKey, dynamic data,
      {int? statusCode, String? responseCode}) {
    _storageService.setSuccessResponse(callerKey, data,
        statusCode: statusCode ?? 200, responseCode: responseCode ?? 'SUCCESS');
    debugPrint('✅ Stored SUCCESS: $callerKey - ${responseCode ?? 'SUCCESS'}');
  }

  void _storeFailureResponse(String callerKey, dynamic data,
      {int? statusCode,
      String? errorCode,
      String? message,
      String? responseCode}) {
    final finalResponseCode = responseCode ?? 'FAILED';
    _storageService.setFailureResponse(callerKey,
        data: data,
        statusCode: statusCode ?? 500,
        errorCode: errorCode,
        message: message,
        responseCode: finalResponseCode);
    debugPrint('❌ Auth Stored FAILURE: $callerKey - $finalResponseCode');
  }

  // ============ AUTH METHODS ============

  @override
  Future<AppUser?> signInWithFacebook({String? callerKey}) async {
    final key = callerKey ?? getCallerKey('signInWithFacebook');

    try {
      // TODO: Implement Facebook sign in
      throw UnimplementedError();
    } catch (e, stackTrace) {
      debugPrint('Facebook sign in error: $e - AuthServiceImpl');
      debugPrint('Stacktrace: $stackTrace - AuthServiceImpl');

      String errorCode = 'FACEBOOK_SIGNIN_ERROR';
      String message = 'Facebook sign in failed: $e';
      String responseCode = 'FACEBOOK_SIGNIN_ERROR';
      int statusCode = 500;

      if (e is VerdeliaException) {
        statusCode = e.statusCode ?? statusCode;
        errorCode = e.message;
        message = e.message;
        responseCode = e.message;
      }

      _storeFailureResponse(key, e.toString(),
          statusCode: statusCode,
          errorCode: errorCode,
          message: message,
          responseCode: responseCode);
      rethrow;
    }
  }

  @override
  Future<void> signOut({String? callerKey}) async {
    final key = callerKey ?? getCallerKey('signOut');

    try {
      final GoogleSignIn _googleSignIn = GoogleSignIn();
      await _googleSignIn.signOut();

      _storeSuccessResponse(key, true,
          statusCode: 200, responseCode: 'SIGNOUT_SUCCESS');
    } catch (e, stackTrace) {
      debugPrint('Sign out error: $e - AuthServiceImpl');
      debugPrint('Stacktrace: $stackTrace - AuthServiceImpl');

      String errorCode = 'SIGNOUT_ERROR';
      String message = 'Sign out failed: $e';
      String responseCode = 'SIGNOUT_ERROR';
      int statusCode = 500;

      if (e is VerdeliaException) {
        statusCode = e.statusCode ?? statusCode;
        errorCode = e.message;
        message = e.message;
        responseCode = e.message;
      }

      _storeFailureResponse(key, e.toString(),
          statusCode: statusCode,
          errorCode: errorCode,
          message: message,
          responseCode: responseCode);
      rethrow;
    }
  }

  @override
  Future<dynamic> signUpWithData(Map<String, dynamic> data,
      {String? callerKey}) async {
    final key = callerKey ??
        getCallerKey('signUpWithData',
            suffix: data['app_user_name']?.toString());

    const String destination =
        '${AppConstants.apiBaseUrl}${AppConstants.signUpEndpoint}';

    try {
      debugPrint('Signing up user: ${data['app_user_name']} - AuthServiceImpl');

      final result = await _storageService
          .signUpUsingUsernameAndPassword(destination, data, callerKey: key);

      final statusCode = _storageService.getStatusCode(key);
      String responseCode = _storageService.getResponseCode(key) ?? 'SUCCESS';

      if (result != null) {
        _storeSuccessResponse(key, result,
            statusCode: statusCode ?? 200, responseCode: responseCode);
        debugPrint('Sign up successful - AuthServiceImpl');
      } else {
        _storeFailureResponse(key, null,
            statusCode: statusCode ?? 500,
            errorCode: 'SIGNUP_FAILED',
            message: 'Sign up failed',
            responseCode: responseCode);
      }

      if (result['access_token'] != null) {
        _storageService.setAuthToken(result['access_token']);
      }

      return result;
    } catch (e, stackTrace) {
      debugPrint('Sign up error: $e - AuthServiceImpl');
      debugPrint('Stacktrace: $stackTrace - AuthServiceImpl');

      String errorCode = 'SIGNUP_ERROR';
      String message = 'Sign up failed: $e';
      String responseCode = 'SIGNUP_ERROR';
      int statusCode = 500;

      if (e is VerdeliaException) {
        statusCode = e.statusCode ?? statusCode;
        errorCode = e.message;
        message = e.message;
        responseCode = e.message;
      }

      _storeFailureResponse(key, e.toString(),
          statusCode: statusCode,
          errorCode: errorCode,
          message: message,
          responseCode: responseCode);
      rethrow;
    }
  }

  @override
  Future<dynamic> signInWithUsernameAndPassword(
      String username, String password,
      {String? callerKey}) async {
    final key = callerKey ??
        getCallerKey('signInWithUsernameAndPassword', suffix: username);

    const String destination =
        '${AppConstants.apiBaseUrl}${AppConstants.loginEndpoint}';

    final Map<String, dynamic> data = {
      "id_app_user": 0,
      "app_user_name": username,
      "app_user_password": password,
    };

    try {
      debugPrint('Signing in user: $username - AuthServiceImpl');

      final result = await _storageService
          .signInUsingUsernameAndPassword(destination, data, callerKey: key);

      final statusCode = _storageService.getStatusCode(key);
      String responseCode = _storageService.getResponseCode(key) ?? 'SUCCESS';

      if (result != null) {
        _storeSuccessResponse(key, result,
            statusCode: statusCode ?? 200, responseCode: responseCode);
        debugPrint('Sign in successful for user: $username - AuthServiceImpl');
      } else {
        _storeFailureResponse(key, null,
            statusCode: statusCode ?? 401,
            errorCode: 'SIGNIN_FAILED',
            message: 'Invalid username or password',
            responseCode: responseCode);
      }

      return result;
    } catch (e, stackTrace) {
      debugPrint('Sign in error: $e - AuthServiceImpl');
      debugPrint('Stacktrace: $stackTrace - AuthServiceImpl');

      String errorCode = 'SIGNIN_ERROR';
      String message = 'Sign in failed: $e';
      String responseCode = 'SIGNIN_ERROR';
      int statusCode = 500;

      if (e is VerdeliaException) {
        statusCode = e.statusCode ?? statusCode;
        errorCode = e.message;
        message = e.message;
        responseCode = e.message;
      }

      _storeFailureResponse(key, e.toString(),
          statusCode: statusCode,
          errorCode: errorCode,
          message: message,
          responseCode: responseCode);
      rethrow;
    }
  }

  @override
  Future<dynamic> refreshTokenNow(String refreshToken,
      {String? callerKey}) async {
    final key = callerKey ?? getCallerKey('refreshTokenNow');

    const String destination =
        '${AppConstants.apiBaseUrl}${AppConstants.refreshTokenEndpoint}';

    final Map<String, dynamic> data = {
      "refresh_token": refreshToken,
    };

    try {
      debugPrint('🔄 Refreshing token... - AuthServiceImpl');

      final result =
          await _storageService.insert(destination, data, callerKey: key);

      final statusCode = _storageService.getStatusCode(key);
      String responseCode = _storageService.getResponseCode(key) ?? 'SUCCESS';

      if (result != null) {
        _storeSuccessResponse(key, result,
            statusCode: statusCode ?? 200, responseCode: responseCode);
        debugPrint('✅ Token refreshed successfully - AuthServiceImpl');

        return result;
      } else {
        // Refresh failed - clear stored tokens

        _storeFailureResponse(key, null,
            statusCode: statusCode ?? 401,
            errorCode: 'REFRESH_FAILED',
            message: 'Token refresh failed',
            responseCode: responseCode);
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Token refresh error: $e - AuthServiceImpl');
      debugPrint('Stacktrace: $stackTrace - AuthServiceImpl');

      String errorCode = 'REFRESH_ERROR';
      String message = 'Token refresh failed: $e';
      String responseCode = 'REFRESH_ERROR';
      int statusCode = 500;

      if (e is VerdeliaException) {
        statusCode = e.statusCode ?? statusCode;
        errorCode = e.message;
        message = e.message;
        responseCode = e.message;
      }

      _storeFailureResponse(key, e.toString(),
          statusCode: statusCode,
          errorCode: errorCode,
          message: message,
          responseCode: responseCode);
      rethrow;
    }
  }
}
