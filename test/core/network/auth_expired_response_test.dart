import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/network/http_client.dart';
import 'package:peso_shield/core/network/http_exception.dart';
import 'package:peso_shield/core/network/network_config.dart';

void main() {
  // flutter_test 默认拦截真实网络请求，这里放行回环地址上的本地服务。
  setUp(() => HttpOverrides.global = null);

  test('接口返回 -2 时触发登录态失效回调，并让请求以鉴权失败结束', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode(<String, Object?>{
            'coffees': -2,
            'closets': 'not logged in',
            'mugg': <String, Object?>{},
          }),
        );
      await request.response.close();
    });

    var expired = 0;
    final client = HttpClient(
      config: NetworkConfig(
        apiBase: Uri.parse('http://127.0.0.1:${server.port}'),
        signSecret: 'test-secret',
        marketIdentifier: 'ph_peso_shield_ios',
      ),
      getDeviceId: () => 'test-device',
      getUserToken: () => 'test-token',
      onAuthExpired: () => expired++,
    );

    await expectLater(
      client.post<Object?>(
        '/viler/soreness',
        params: const <String, Object?>{},
        parse: (data) => data,
      ),
      throwsA(
        isA<DioException>().having(
          (error) => error.error,
          'error',
          isA<HttpException>().having(
            (inner) => inner.type,
            'type',
            HttpFailureType.authentication,
          ),
        ),
      ),
    );
    expect(expired, 1);
  });
}
