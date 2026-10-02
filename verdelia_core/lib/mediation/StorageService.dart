// storage_service.dart

// import 'package:dio/dio.dart';

class CallerResponse {
  final dynamic data;
  final int? statusCode;
  final String? errorCode;
  final String? message;
  final String? responseCode;
  final bool isSuccess;
  final DateTime timestamp;

  CallerResponse({
    required this.data,
    this.statusCode,
    this.errorCode,
    this.message,
    this.responseCode,
    required this.isSuccess,
    required this.timestamp,
  });

  factory CallerResponse.success(dynamic data,
      {int? statusCode, String? responseCode}) {
    return CallerResponse(
      data: data,
      statusCode: statusCode ?? 200,
      responseCode: responseCode,
      isSuccess: true,
      timestamp: DateTime.now(),
    );
  }

  factory CallerResponse.failure({
    required dynamic data,
    int? statusCode,
    String? errorCode,
    String? message,
    String? responseCode,
  }) {
    return CallerResponse(
      data: data,
      statusCode: statusCode ?? 500,
      errorCode: errorCode,
      message: message,
      responseCode: responseCode,
      isSuccess: false,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'CallerResponse(isSuccess: $isSuccess, statusCode: $statusCode, responseCode: $responseCode, errorCode: $errorCode)';
  }
}

abstract class StorageService<T> {
  // Map to store latest response for each caller key
  final Map<String, CallerResponse> _callerResponses = {};

  // ==================== Token Management ====================

  String? _authToken;

  /// Set the authentication token (Bearer token or Cookie)
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Get the current authentication token
  String? getAuthToken() {
    return _authToken;
  }

  /// Clear the authentication token
  void clearAuthToken() {
    _authToken = null;
  }

  /// Check if token is set
  bool hasAuthToken() {
    return _authToken != null && _authToken!.isNotEmpty;
  }

  /// Get token for request (internal use)
  String? getTokenForRequest(String? providedToken) {
    return providedToken ?? _authToken;
  }

  /// Register the app-level callback used to renew an expired access token.
  void setTokenRefreshHandler(Future<bool> Function() handler);

  // ==================== Response Storage Methods ====================

  /// Store a successful response for a caller key
  void setSuccessResponse(String callerKey, dynamic data,
      {int? statusCode, String? responseCode}) {
    _callerResponses[callerKey] = CallerResponse.success(
      data,
      statusCode: statusCode,
      responseCode: responseCode,
    );
  }

  /// Store a failure response for a caller key
  void setFailureResponse(
    String callerKey, {
    required dynamic data,
    int? statusCode,
    String? errorCode,
    String? message,
    String? responseCode,
  }) {
    _callerResponses[callerKey] = CallerResponse.failure(
      data: data,
      statusCode: statusCode,
      errorCode: errorCode,
      message: message,
      responseCode: responseCode,
    );
  }

  /// Get the latest response for a caller key
  CallerResponse? getResponse(String callerKey) {
    return _callerResponses[callerKey];
  }

  /// Get the latest response data for a caller key
  dynamic getResponseData(String callerKey) {
    return _callerResponses[callerKey]?.data;
  }

  /// Get the latest status code for a caller key
  int? getStatusCode(String callerKey) {
    return _callerResponses[callerKey]?.statusCode;
  }

  /// Get the response code for a caller key
  String? getResponseCode(String callerKey) {
    return _callerResponses[callerKey]?.responseCode;
  }

  /// Set the response code for a caller key (updates existing response)
  void setResponseCode(String callerKey, String responseCode) {
    final existing = _callerResponses[callerKey];
    if (existing != null) {
      if (existing.isSuccess) {
        _callerResponses[callerKey] = CallerResponse.success(
          existing.data,
          statusCode: existing.statusCode,
          responseCode: responseCode,
        );
      } else {
        _callerResponses[callerKey] = CallerResponse.failure(
          data: existing.data,
          statusCode: existing.statusCode,
          errorCode: existing.errorCode,
          message: existing.message,
          responseCode: responseCode,
        );
      }
    }
  }

  /// Get error code for a caller key
  String? getErrorCode(String callerKey) {
    return _callerResponses[callerKey]?.errorCode;
  }

  /// Set error code for a caller key (updates existing response)
  void setErrorCode(String callerKey, String errorCode) {
    final existing = _callerResponses[callerKey];
    if (existing != null && !existing.isSuccess) {
      _callerResponses[callerKey] = CallerResponse.failure(
        data: existing.data,
        statusCode: existing.statusCode,
        errorCode: errorCode,
        message: existing.message,
        responseCode: existing.responseCode,
      );
    }
  }

  /// Get error message for a caller key
  String? getErrorMessage(String callerKey) {
    return _callerResponses[callerKey]?.message;
  }

  /// Set error message for a caller key (updates existing response)
  void setErrorMessage(String callerKey, String message) {
    final existing = _callerResponses[callerKey];
    if (existing != null && !existing.isSuccess) {
      _callerResponses[callerKey] = CallerResponse.failure(
        data: existing.data,
        statusCode: existing.statusCode,
        errorCode: existing.errorCode,
        message: message,
        responseCode: existing.responseCode,
      );
    }
  }

  /// Check if the latest call for a caller key was successful
  bool isCallerSuccess(String callerKey) {
    return _callerResponses[callerKey]?.isSuccess ?? false;
  }

  /// Remove response for a caller key
  void clearResponse(String callerKey) {
    _callerResponses.remove(callerKey);
  }

  /// Clear all stored responses
  void clearAllResponses() {
    _callerResponses.clear();
  }

  /// Get all stored responses (for debugging)
  Map<String, CallerResponse> getAllResponses() {
    return Map.unmodifiable(_callerResponses);
  }

  // ==================== Existing Abstract Methods ====================

  Future<dynamic> getAll(String destination,
      {params, String? callerKey, String? token}) async {
    return null;
  }

  Future<dynamic> insert(String destination, Map<String, dynamic> data,
      {params, String? callerKey, String? token}) async {
    return null;
  }

  T toFormData(T data) {
    throw UnimplementedError();
  }

  Future<dynamic> insertBinary(String destination, T data,
      {String? callerKey, String? token}) async {
    return null;
  }

  Future<dynamic> get(String destination, String id,
      {String? callerKey,
      String? token,
      Map<String, dynamic>? parameters}) async {
    return null;
  }

  Future<int?> delete(String destination, String id,
      {String? callerKey, String? token}) async {
    return null;
  }

  Future<dynamic> update(String destination, String id,
      Map<String, dynamic> parameters, Map<String, dynamic> data,
      {String? callerKey, String? token, String method = "PUT"}) async {
    return null;
  }

  Future<dynamic> signUpUsingUsernameAndPassword(
      String destination, Map<String, dynamic> data,
      {String? callerKey, String? token}) async {
    return null;
  }

  Future<dynamic> signInUsingUsernameAndPassword(
      String destination, Map<String, dynamic> data,
      {String? callerKey, String? token}) async {
    return null;
  }

  Future<dynamic> signInUsingProvider(
      String destination, String providerName, Map<String, dynamic> data,
      {String? callerKey, String? token}) async {
    return null;
  }
}
