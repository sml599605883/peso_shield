class ResponseProtocol {
  const ResponseProtocol({
    required this.code,
    required this.message,
    required this.data,
  });

  factory ResponseProtocol.parse(Object? json) {
    if (json is! Map<String, Object?>) {
      return const ResponseProtocol(
        code: -1,
        message: 'Invalid response format',
        data: null,
      );
    }

    final codeValue = json['coffees'];
    int parsedCode;
    if (codeValue is int) {
      parsedCode = codeValue;
    } else if (codeValue is String) {
      parsedCode = int.tryParse(codeValue) ?? -1;
    } else {
      parsedCode = -1;
    }

    return ResponseProtocol(
      code: parsedCode,
      message: json['closets']?.toString() ?? '',
      data: json['mugg'],
    );
  }

  final int code;
  final String message;
  final Object? data;

  /// 成功码：0（正常成功）或 20000（特殊成功状态）
  bool get isSuccess => code == 0 || code == 20000;

  /// 会话过期错误码
  /// 根据实际 API 约定，常见的会话过期码包括：
  /// - `-2`: 业务层会话过期（fund_nexus 使用）
  /// - `401`: HTTP 标准未授权状态码
  /// - `20000`: 某些 API 的自定义会话过期码
  bool get isAuthError => code == -2;
}
