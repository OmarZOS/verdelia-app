// TraceableService.dart

import 'package:verdelia_core/app/ApiResponse.dart';

abstract class TraceableService {
  // Store responses by caller key
  final Map<String, TraceableResponse> _responses = {};

  // ==================== Response Storage Methods ====================

  /// Store a successful response
  void setSuccessResponse(String callerKey, dynamic data,
      {int? statusCode, String? responseCode}) {
    _responses[callerKey] = TraceableResponse.success(
      data,
      statusCode: statusCode,
      responseCode: responseCode,
    );
  }

  /// Store a failure response
  void setFailureResponse(String callerKey, dynamic data,
      {int? statusCode, String? responseCode}) {
    _responses[callerKey] = TraceableResponse.failure(
      data: data,
      statusCode: statusCode,
      responseCode: responseCode,
    );
  }

  /// Get stored response for a caller key
  TraceableResponse? getResponse(String callerKey) {
    return _responses[callerKey];
  }

  /// Get response data for a caller key
  dynamic getResponseData(String callerKey) {
    return _responses[callerKey]?.data;
  }

  /// Get status code for a caller key
  int? getStatusCode(String callerKey) {
    return _responses[callerKey]?.statusCode;
  }

  /// Get response code for a caller key
  String? getResponseCode(String callerKey) {
    return _responses[callerKey]?.responseCode;
  }

  /// Check if a call was successful
  bool isSuccess(String callerKey) {
    return _responses[callerKey]?.isSuccess ?? false;
  }

  /// Clear response for a specific caller
  void clearResponse(String callerKey) {
    _responses.remove(callerKey);
  }

  /// Clear all responses
  void clearAllResponses() {
    _responses.clear();
  }

  /// Get all responses (for debugging)
  Map<String, TraceableResponse> getAllResponses() {
    return Map.unmodifiable(_responses);
  }

  // Helper method to generate caller key
  String getCallerKey(String method, {String? id, String? suffix}) {
    final parts = [method];
    if (id != null) parts.add(id);
    if (suffix != null) parts.add(suffix);
    return parts.join('_');
  }
}
