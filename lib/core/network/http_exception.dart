enum HttpFailureType {
  noNetwork,
  timeout,
  serverError,
  invalidResponse,
  businessLogic,
  authentication,
  cancelled,
  unexpected,
}

class HttpException implements Exception {
  const HttpException({
    required this.type,
    required this.message,
    this.code,
    this.statusCode,
    this.cause,
  });

  final HttpFailureType type;
  final String message;
  final int? code;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() {
    final buffer = StringBuffer('HttpException: $message');
    if (code != null) buffer.write(' (code: $code)');
    if (statusCode != null) buffer.write(' (status: $statusCode)');
    if (cause != null) buffer.write(' | Caused by: $cause');
    return buffer.toString();
  }
}
