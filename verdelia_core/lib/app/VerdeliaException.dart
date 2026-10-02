// verdelia_core/lib/app/VerdeliaException.dart
class VerdeliaException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic error;
  final String? responseCode;
  final Map<String, dynamic>? details;

  VerdeliaException(
    this.message, {
    this.statusCode,
    this.error,
    this.responseCode,
    this.details,
  });

  @override
  String toString() {
    return 'VerdeliaException: $message (statusCode: $statusCode, responseCode: $responseCode)';
  }
}
