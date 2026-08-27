class HttpResult<T> {
  const HttpResult({
    required this.statusCode,
    required this.statusMessage,
    required this.payload,
  });

  final String statusCode;
  final String statusMessage;
  final T payload;
}
