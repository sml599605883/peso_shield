import '../../core/json/json.dart';

abstract final class WebViewContract {
  static const handler = 'bridge_peso_shield';
}

abstract final class WebViewActions {
  static const uploadRisk = 'bridge_uploadRisk';
  static const openGooglePlay = 'bridge_openGooglePlay';
  static const openUrl = 'bridge_openUrl';
  static const close = 'bridge_close';
  static const home = 'bridge_home';
  static const grade = 'bridge_grade';
  static const retryOrder = 'bridge_retryOrder';
  static const changeAccount = 'bridge_changeAccount';
  static const publicParams = 'bridge_publicParams';
}

class WebViewRequest {
  const WebViewRequest({
    required this.action,
    required this.callbackId,
    required this.data,
    required this.rawData,
  });

  factory WebViewRequest.decode(Object? message) {
    final decoded = message is String ? Json.parse(message).value : message;
    final source = Json(decoded).rawMapValue;
    final rawData = source['data'] ?? source['payload'] ?? source['params'];
    return WebViewRequest(
      action: _firstString(source, const ['action', 'name']),
      callbackId: _firstString(source, const ['callbackId', 'callback', 'id']),
      data: _dataMap(rawData),
      rawData: rawData,
    );
  }

  final String action;
  final String callbackId;
  final Map<String, dynamic> data;
  final Object? rawData;

  bool get expectsCallback => callbackId.isNotEmpty;

  String get rawDataString {
    final value = rawData;
    return value is String ? value.trim() : Json(value).stringValue.trim();
  }

  static String _firstString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = Json(source[key]).stringValue.trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static Map<String, dynamic> _dataMap(Object? rawData) {
    if (rawData is String) {
      return Json.parse(rawData).rawMapValue;
    }
    return Json(rawData).rawMapValue;
  }
}

class WebViewResult {
  const WebViewResult({
    required this.code,
    required this.message,
    this.data,
  });

  const WebViewResult.success([Object? data])
      : this(code: 0, message: 'success', data: data);

  const WebViewResult.failure(String message, {int code = -1})
      : this(code: code, message: message);

  final int code;
  final String message;
  final Object? data;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code,
        'message': message,
        'data': data ?? <String, dynamic>{},
      };
}
