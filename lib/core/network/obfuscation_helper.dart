import 'dart:math';

class ObfuscationHelper {
  ObfuscationHelper._();

  static final _random = Random();

  /// 生成指定长度的随机数字字符串
  static String randomDigits(int length) {
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(_random.nextInt(10));
    }
    return buffer.toString();
  }

  /// 生成随机混淆参数（默认6位数字）
  static String randomParam() => randomDigits(6);
}
