enum NetworkErrorType {
  business,
  unauthorized,
  configuration,
  timeout,
  connectivity,
  cancelled,
  serverError,
  malformedResponse,
  unknown,
}

class NetworkError implements Exception {
  const NetworkError({
    required this.type,
    required this.message,
    this.errorCode,
    this.httpStatus,
    this.underlyingError,
  });

  final NetworkErrorType type;
  final String message;
  final String? errorCode;
  final int? httpStatus;
  final Object? underlyingError;

  @override
  String toString() => 'NetworkError($type, $message)';
}
