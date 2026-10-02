import 'dart:developer';
import 'package:verdelia_core/mediation/StorageService.dart';
import 'package:flutter/foundation.dart';

class AuthResponseManager {
  final StorageService _storageService;
  final Map<String, CallerResponse> _responses = {};

  AuthResponseManager(this._storageService);

  String generateKey(String method, {String? id, String? suffix}) {
    final parts = [method];
    if (id != null) parts.add(id);
    if (suffix != null) parts.add(suffix);
    parts.add(DateTime.now().millisecondsSinceEpoch.toString());
    return parts.join('_');
  }

  void storeSuccess(String key, dynamic data,
      {int? statusCode, String? responseCode}) {
    _storageService.setSuccessResponse(key, data,
        statusCode: statusCode ?? 200, responseCode: responseCode);
    _responses[key] = CallerResponse.success(
      data,
      statusCode: statusCode ?? 200,
      responseCode: responseCode,
    );
    debugPrint('✅ Stored SUCCESS: $key - $responseCode');
  }

  void storeFailure(String key, dynamic data,
      {int? statusCode,
      String? errorCode,
      String? message,
      String? responseCode}) {
    _storageService.setFailureResponse(key,
        data: data,
        statusCode: statusCode ?? 500,
        errorCode: errorCode,
        message: message,
        responseCode: responseCode);
    _responses[key] = CallerResponse.failure(
      data: data,
      statusCode: statusCode ?? 500,
      errorCode: errorCode,
      message: message,
      responseCode: responseCode,
    );
    debugPrint('❌ Stored FAILURE: $key - $responseCode');
  }

  CallerResponse? getResponse(String key) {
    return _responses[key] ?? _storageService.getResponse(key);
  }

  bool isSuccess(String key) {
    return _storageService.isCallerSuccess(key);
  }

  dynamic getData(String key) {
    return _storageService.getResponseData(key);
  }

  int? getStatusCode(String key) {
    return _storageService.getStatusCode(key);
  }

  String? getResponseCode(String key) {
    return _storageService.getResponseCode(key);
  }

  String? getErrorMessage(String key) {
    return _storageService.getErrorMessage(key);
  }

  void clearResponse(String key) {
    _responses.remove(key);
    _storageService.clearResponse(key);
  }

  void clearAllResponses() {
    _responses.clear();
    _storageService.clearAllResponses();
  }
}
