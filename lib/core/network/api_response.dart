class ApiResponse<T> {
  const ApiResponse({
    required this.code,
    required this.message,
    required this.data,
  });

  final int code;
  final String message;
  final T data;

  /// 成功码：0（正常成功）或 20000（特殊成功状态）
  bool get isSuccess => code == 0 || code == 20000;
}
