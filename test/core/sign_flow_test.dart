import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/network/common_params.dart';
import 'package:peso_shield/core/network/request_signer.dart';

void main() {
  group('完整签名流程测试', () {
    test('GET 请求签名流程 - /outsmelled/mugg', () {
      // 1. 公共参数
      final commonParams = CommonParams.create(
        deviceId: 'test-idfv-12345',
        market: 'ph_peso_shield_ios',
        appVersion: '1.0.0',
        deviceName: 'iPhone15,2',
        osVersion: '17.1',
        gpsAdId: 'test-adid-67890',
        token: '',
      );

      print('=== 公共参数 ===');
      commonParams.forEach((key, value) {
        print('$key: $value');
      });

      // 2. 业务参数
      final businessParams = {
        'hierarchies': '',
        'borohydrides': '',
      };

      // 3. 签名输入：公共参数 + path（不含业务参数）
      final signInput = {
        ...commonParams,
        'mitogenic': '/outsmelled/mugg',
      };

      print('\n=== 签名输入（${signInput.length}个参数）===');
      final sortedKeys = signInput.keys.toList()..sort();
      sortedKeys.forEach((key) {
        print('$key: ${signInput[key]}');
      });

      // 4. 生成签名
      final signer = RequestSigner('cf938da7bebcecccd5563ca28d7f1fbd');
      final signature = signer.sign(signInput);

      print('\n=== 签名结果 ===');
      print('签名算法: HMAC-SHA256');
      print('签名值: $signature');

      // 5. 最终请求参数
      final finalParams = {
        ...commonParams,
        ...businessParams,
        'arboured': signature,
      };

      print('\n=== GET 最终请求参数（${finalParams.length}个）===');
      finalParams.forEach((key, value) {
        print('$key: $value');
      });

      expect(signature.length, 64);
      expect(commonParams['dissuaders'], 'test-idfv-12345');
      expect(commonParams['longicorn'], '1.0.0');
    });

    test('POST 请求签名流程 - /outsmelled/bloodlust', () {
      // 1. 公共参数
      final commonParams = CommonParams.create(
        deviceId: 'test-idfv-12345',
        market: 'ph_peso_shield_ios',
        appVersion: '1.0.0',
        deviceName: 'iPhone15,2',
        osVersion: '17.1',
        gpsAdId: 'test-adid-67890',
        token: '',
      );

      // 2. 业务参数（将被加密放在 body）
      final businessParams = {
        'bloodlust': '09123456789',
        'curricular': 'sms',
        'taxidermic': '123456',
      };

      // 3. 签名输入：只有公共参数 + path（不含业务参数）
      final signInput = {
        ...commonParams,
        'mitogenic': '/outsmelled/bloodlust',
      };

      print('\n=== POST 签名输入（${signInput.length}个参数）===');
      signInput.forEach((key, value) {
        print('$key: $value');
      });

      // 4. 生成签名
      final signer = RequestSigner('cf938da7bebcecccd5563ca28d7f1fbd');
      final signature = signer.sign(signInput);

      print('\n=== POST 签名结果 ===');
      print('签名值: $signature');

      // 5. 最终 query 参数（不含业务参数）
      final queryParams = {
        ...commonParams,
        'arboured': signature,
      };

      print('\n=== POST Query 参数（${queryParams.length}个）===');
      queryParams.forEach((key, value) {
        print('$key: $value');
      });

      print('\n=== POST Body 参数（将被加密）===');
      businessParams.forEach((key, value) {
        print('$key: $value');
      });

      expect(signature.length, 64);
      expect(queryParams.containsKey('bloodlust'), false); // 业务参数不在 query
    });
  });
}
