class TraceableResponse {
  final dynamic data;
  final int? statusCode;
  final String? responseCode;
  final bool isSuccess;
  final DateTime timestamp;

  TraceableResponse({
    required this.data,
    this.statusCode,
    this.responseCode,
    required this.isSuccess,
    required this.timestamp,
  });

  factory TraceableResponse.success(dynamic data,
      {int? statusCode, String? responseCode}) {
    return TraceableResponse(
      data: data,
      statusCode: statusCode,
      responseCode: responseCode,
      isSuccess: true,
      timestamp: DateTime.now(),
    );
  }

  factory TraceableResponse.failure({
    required dynamic data,
    int? statusCode,
    String? responseCode,
  }) {
    return TraceableResponse(
      data: data,
      statusCode: statusCode,
      responseCode: responseCode,
      isSuccess: false,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'TraceableResponse(isSuccess: $isSuccess, statusCode: $statusCode, responseCode: $responseCode)';
  }
}
