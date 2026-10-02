// traceable_notifier.dart
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:verdelia_core/app/VerdeliaException.dart';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'package:locator/locator.dart';

/// A base class for notifiers that provides traceability through StorageService
abstract class TraceableNotifier extends ChangeNotifier {
  final StorageService _storageService = AppLocator.get<StorageService>();

  /// Generate a unique caller key for tracking operations
  String getCallerKey(String method, {String? id, String? suffix}) {
    final parts = [method];
    if (id != null) parts.add(id);
    if (suffix != null) parts.add(suffix);
    parts.add(DateTime.now().millisecondsSinceEpoch.toString());
    return parts.join('_');
  }

  /// Store a success response in the StorageService
  void storeSuccess(String key, dynamic data,
      {int? code, String? responseCode}) {
    _storageService.setSuccessResponse(key, data,
        statusCode: code ?? 200, responseCode: responseCode ?? 'SUCCESS');
  }

  /// Store a failure response in the StorageService
  void storeFailure(String key, dynamic data,
      {int? code, String? errorCode, String? message}) {
    _storageService.setFailureResponse(key,
        data: data,
        statusCode: code ?? 500,
        errorCode: errorCode,
        message: message);
  }

  /// Get the stored response from StorageService
  CallerResponse? getResponse(String callerKey) {
    return _storageService.getResponse(callerKey);
  }

  /// Check if a call was successful
  bool isSuccess(String callerKey) {
    return _storageService.isCallerSuccess(callerKey);
  }

  /// Get response data
  dynamic getResponseData(String callerKey) {
    return _storageService.getResponseData(callerKey);
  }

  /// Get status code
  int? getStatusCode(String callerKey) {
    return _storageService.getStatusCode(callerKey);
  }

  /// Get response code
  String? getResponseCode(String callerKey) {
    return _storageService.getResponseCode(callerKey);
  }

  /// Get error message
  String? getErrorMessage(String callerKey) {
    return _storageService.getErrorMessage(callerKey);
  }

  /// Clear response for a caller key
  void clearResponse(String callerKey) {
    _storageService.clearResponse(callerKey);
  }

  /// Clear all responses
  void clearAllResponses() {
    _storageService.clearAllResponses();
  }

  /// Log an error with context
  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    log('$message${error != null ? ': $error' : ''}',
        name: runtimeType.toString(), error: error, stackTrace: stackTrace);
  }

  /// Log an info message
  void logInfo(String message) {
    log(message, name: runtimeType.toString());
  }

  /// Handle an exception with proper tracing
  T? handleException<T>(String key, dynamic e, {T? fallback}) {
    storeFailure(key, e.toString(),
        errorCode: e is VerdeliaException ? e.message : 'ERROR');
    logError('Operation failed', error: e);
    return fallback;
  }
}
