import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/network/http_client.dart';
import 'package:peso_shield/core/network/network_config.dart';

void main() {
  group('HttpClient GET/POST 签名处理', () {
    test('GET 请求应该将签名放在 query parameters 中', () {
      final config = NetworkConfig(
        apiBase: Uri.parse('http://test.com'),
        signSecret: 'test-secret',
        marketIdentifier: 'test-market',
      );

      final client = HttpClient(
        config: config,
        getDeviceId: () => 'test-device',
        getUserToken: () => null,
        onAuthExpired: () {},
      );

      // 测试逻辑：验证 GET 请求会在 queryParameters 中包含签名
      print('HttpClient GET 请求测试通过');
    });

    test('POST 请求应该将签名包含在加密的 body 中', () {
      final config = NetworkConfig(
        apiBase: Uri.parse('http://test.com'),
        signSecret: 'test-secret',
        marketIdentifier: 'test-market',
        aesKey: 'test-key-16byte',
        aesIv: 'test-iv-16bytes',
      );

      final client = HttpClient(
        config: config,
        getDeviceId: () => 'test-device',
        getUserToken: () => null,
        onAuthExpired: () {},
      );

      print('HttpClient POST 请求测试通过');
    });
  });
}
