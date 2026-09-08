import 'dart:convert';

/// JSON 值包装器，提供类型安全的访问方法
class Json {
  const Json(this._value);

  final Object? _value;

  /// 解析 JSON 字符串
  static Json parse(String source) {
    try {
      return Json(jsonDecode(source));
    } catch (_) {
      return const Json(null);
    }
  }

  /// 获取原始值
  Object? get value => _value;

  /// 获取 Map 值
  Map<String, dynamic>? get mapOrNull =>
      _value is Map<String, dynamic> ? _value as Map<String, dynamic> : null;

  /// 获取 Map 值（非空版本）
  Map<String, dynamic> get rawMapValue {
    final map = _value;
    if (map is! Map) return <String, dynamic>{};
    return map.map((key, value) => MapEntry(key.toString(), value));
  }

  /// 获取 List 值
  List<dynamic> get listValue =>
      _value is List<dynamic> ? _value as List<dynamic> : [];

  /// 获取 String 值
  String get stringValue => _value?.toString() ?? '';

  /// 获取 int 值
  int get intValue {
    if (_value is int) return _value as int;
    if (_value is num) return (_value as num).toInt();
    final str = _value?.toString() ?? '';
    return int.tryParse(str) ?? 0;
  }

  /// 获取 double 值
  double get doubleValue {
    if (_value is double) return _value as double;
    if (_value is num) return (_value as num).toDouble();
    final str = _value?.toString() ?? '';
    return double.tryParse(str) ?? 0.0;
  }

  /// 获取 bool 值
  bool get boolValue {
    if (_value is bool) return _value as bool;
    if (_value is int) return _value != 0;
    return false;
  }

  /// 获取可空的 String 值
  String? get stringOrNull {
    final str = _value?.toString();
    return (str == null || str.isEmpty || str == 'null') ? null : str;
  }

  /// 获取可空的 int 值
  int? get intOrNull {
    if (_value is int) return _value as int;
    if (_value is num) return (_value as num).toInt();
    final str = _value?.toString() ?? '';
    return int.tryParse(str);
  }

  /// 获取可空的 bool 值
  bool? get boolOrNull {
    if (_value is bool) return _value as bool;
    if (_value is int) return _value != 0;
    return null;
  }

  /// 通过键访问子值
  Json operator [](String key) {
    final map = mapOrNull;
    return Json(map?[key]);
  }
}
