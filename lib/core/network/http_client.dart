import 'dart:io' as io;

import 'package:dio/dio.dart';

import 'api_response.dart';
import 'capture_proxy.dart';
import 'common_params.dart';
import 'http_exception.dart';
import 'network_config.dart';
import 'proxy_configurer.dart';
import 'request_signer.dart';
import 'response_protocol.dart';

class HttpClient {
  HttpClient({
    required NetworkConfig config,
    required String Function() getDeviceId,
    String Function()? getAppVersion,
    String Function()? getDeviceName,
    String Function()? getOsVersion,
    String Function()? getGpsAdId,
    required String? Function() getUserToken,
    required void Function() onAuthExpired,
    CaptureProxySettings? systemProxy,
  }) : _config = config,
       _getDeviceId = getDeviceId,
       _getAppVersion = getAppVersion ?? (() => ''),
       _getDeviceName = getDeviceName ?? (() => ''),
       _getOsVersion = getOsVersion ?? (() => ''),
       _getGpsAdId = getGpsAdId ?? (() => ''),
       _getUserToken = getUserToken,
       _onAuthExpired = onAuthExpired,
       _signer = RequestSigner(config.signSecret) {
    _dio = _createDio(systemProxy);
  }

  final NetworkConfig _config;
  final String Function() _getDeviceId;
  final String Function() _getAppVersion;
  final String Function() _getDeviceName;
  final String Function() _getOsVersion;
  final String Function() _getGpsAdId;
  final String? Function() _getUserToken;
  final void Function() _onAuthExpired;
  final RequestSigner _signer;

  late final Dio _dio;

  Dio _createDio(CaptureProxySettings? systemProxy) {
    final options = BaseOptions(
      baseUrl: _config.apiBase.toString(),
      connectTimeout: _config.connectionTimeout,
      receiveTimeout: _config.responseTimeout,
      sendTimeout: _config.requestTimeout,
      contentType: Headers.formUrlEncodedContentType,
      validateStatus: (status) => status != null && status < 500,
    );

    final dio = Dio(options);

    // Use system proxy if available, otherwise use config proxy
    if (systemProxy != null && systemProxy.isValid) {
      print(
        '[HttpClient] Using system proxy: ${systemProxy.host}:${systemProxy.port}',
      );
      ProxyConfigurer.configure(
        dio,
        host: systemProxy.host,
        port: systemProxy.port,
        allowInsecure: true, // System proxy is typically trusted
      );
    } else if (_config.proxyHost.isNotEmpty && _config.proxyPort != null) {
      print(
        '[HttpClient] Using config proxy: ${_config.proxyHost}:${_config.proxyPort}',
      );
      ProxyConfigurer.configure(
        dio,
        host: _config.proxyHost,
        port: _config.proxyPort!,
        allowInsecure: _config.allowInsecureProxy,
      );
    } else {
      print('[HttpClient] No proxy configured');
    }

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    return dio;
  }

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 公共参数
    final commonParams = CommonParams.create(
      deviceId: _getDeviceId(),
      market: _config.marketIdentifier,
      appVersion: _getAppVersion(),
      deviceName: _getDeviceName(),
      osVersion: _getOsVersion(),
      gpsAdId: _getGpsAdId(),
      token: _getUserToken(),
    );

    print('[HttpClient] 公共参数:');
    commonParams.forEach((key, value) {
      print('  $key: $value');
    });

    // 提取业务参数
    final businessParams = <String, Object?>{
      if (options.method == 'GET' && options.queryParameters.isNotEmpty)
        ...options.queryParameters,
      if (options.method == 'POST' && options.data is Map)
        ...options.data as Map<String, Object?>,
    };

    print('[HttpClient] 业务参数: $businessParams');

    // 签名计算：仅公共参数 + path（不含业务参数）
    final signInput = <String, Object?>{
      ...commonParams,
      'mitogenic': _clearPath(options.path),
    };

    print('[HttpClient] 签名输入:');
    signInput.forEach((key, value) {
      print('  $key: $value');
    });

    final signature = _signer.sign(signInput);
    print('[HttpClient] 生成签名: $signature');

    // 区分 GET 和 POST 的参数处理
    if (options.method == 'GET') {
      // GET 请求：公共参数 + 业务参数 + 签名 → queryParameters
      options.queryParameters = <String, Object?>{
        ...commonParams,
        ...businessParams,
        'arboured': signature,
      };
      options.data = null;
      print('[HttpClient] GET 请求最终 URL: ${options.uri}');
    } else if (options.method == 'POST') {
      // POST 请求：公共参数 + 签名 → queryParameters，业务参数 → form body。
      // AES is reserved for repository methods whose endpoint documents an
      // encrypted payload; wrapping every POST as {data: ...} breaks forms.
      options.queryParameters = <String, Object?>{
        ...commonParams,
        'arboured': signature,
      };

      if (businessParams.isNotEmpty) {
        options.data = businessParams;
        print('[HttpClient] POST body (form): ${options.data}');
      } else {
        options.data = null;
      }
      print('[HttpClient] POST 请求 URL: ${options.uri}');
    }

    handler.next(options);
  }

  static String _clearPath(String path) {
    final uri = Uri.tryParse(path);
    if (uri != null && uri.hasScheme) {
      return uri.path;
    }
    return path.split('?').first;
  }

  void _onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final protocol = ResponseProtocol.parse(response.data);

    // 会话过期：触发协调器清理，同时让请求失败以便 UI 可以处理
    if (protocol.isAuthError) {
      _onAuthExpired();
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          error: HttpException(
            type: HttpFailureType.authentication,
            message: protocol.message,
            code: protocol.code,
          ),
        ),
      );
      return;
    }

    // 其他业务错误（包括成功）都正常返回，由 UI 层检查 isSuccess
    handler.next(response);
  }

  void _onError(DioException error, ErrorInterceptorHandler handler) {
    if (error.error is HttpException) {
      handler.next(error);
      return;
    }

    HttpFailureType type;
    String message;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      type = HttpFailureType.timeout;
      message = 'Request timeout';
    } else if (error.type == DioExceptionType.cancel) {
      type = HttpFailureType.cancelled;
      message = 'Request cancelled';
    } else if (error.error is io.SocketException) {
      type = HttpFailureType.noNetwork;
      message = 'Network connection failed';
    } else if (error.response?.statusCode != null) {
      type = HttpFailureType.serverError;
      message = 'Server error: ${error.response!.statusCode}';
    } else {
      type = HttpFailureType.unexpected;
      message = 'Unexpected error occurred';
    }

    handler.next(
      DioException(
        requestOptions: error.requestOptions,
        error: HttpException(
          type: type,
          message: message,
          statusCode: error.response?.statusCode,
          cause: error.error,
        ),
      ),
    );
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    required Map<String, Object?> params,
    required T Function(Object?) parse,
  }) async {
    try {
      final response = await _dio.post<Map<String, Object?>>(
        path,
        data: params,
      );

      final protocol = ResponseProtocol.parse(response.data);
      return ApiResponse<T>(
        code: protocol.code,
        message: protocol.message,
        data: parse(protocol.data),
      );
    } on DioException catch (e) {
      if (e.error is HttpException) {
        rethrow;
      }
      throw HttpException(
        type: HttpFailureType.unexpected,
        message: 'Request failed',
        cause: e,
      );
    }
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, Object?>? params,
    required T Function(Object?) parse,
  }) async {
    try {
      final response = await _dio.get<Map<String, Object?>>(
        path,
        queryParameters: params,
      );

      final protocol = ResponseProtocol.parse(response.data);
      return ApiResponse<T>(
        code: protocol.code,
        message: protocol.message,
        data: parse(protocol.data),
      );
    } on DioException catch (e) {
      if (e.error is HttpException) {
        rethrow;
      }
      throw HttpException(
        type: HttpFailureType.unexpected,
        message: 'Request failed',
        cause: e,
      );
    }
  }

  Future<bool> probeTransport() async {
    try {
      final baseUrl = _dio.options.baseUrl;
      print('[ProbeTransport] Testing connection to: $baseUrl');

      // Use native HttpClient for more lenient checking
      final uri = Uri.parse(baseUrl);
      final nativeClient = io.HttpClient();
      nativeClient.connectionTimeout = const Duration(seconds: 10);

      try {
        print('[ProbeTransport] Opening connection...');
        final request = await nativeClient.getUrl(uri);
        print('[ProbeTransport] Sending request...');

        final response = await request.close();
        final statusCode = response.statusCode;
        print('[ProbeTransport] Got response: statusCode=$statusCode');

        // Consume response to avoid connection leak
        await response.drain<void>();
        nativeClient.close();

        // Any HTTP response means network is available
        return true;
      } catch (e) {
        print('[ProbeTransport] Native HttpClient error: $e');
        nativeClient.close(force: true);

        // Even if we got an error, check if it's a format error (means server responded)
        if (e.toString().contains('Invalid response')) {
          print(
            '[ProbeTransport] Invalid response format, but server is reachable',
          );
          return true;
        }

        return false;
      }
    } catch (e) {
      print('[ProbeTransport] Unexpected error: $e');
      return false;
    }
  }
}
