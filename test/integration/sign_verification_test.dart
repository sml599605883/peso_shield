import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/network/common_params.dart';
import 'package:peso_shield/core/network/request_signer.dart';

void main() {
  group('签名验证 - 最终测试', () {
    test('完整的公共参数和签名生成', () {
      // 公共参数
      final commonParams = CommonParams.create(
        deviceId: 'test-device-12345',
        market: 'ph_peso_shield_ios',
        appVersion: '1.0.0',
        deviceName: 'iPhone14,2',
        osVersion: '17.0',
        gpsAdId: 'test-ad-id-67890',
        token: 'test-token-abc',
      );

      print('=== 公共参数 ===');
      commonParams.forEach((key, value) {
        print('$key: $value');
      });

      expect(commonParams['longicorn'], '1.0.0');
      expect(commonParams['externalizes'], 'iPhone14,2');
      expect(commonParams['dissuaders'], 'test-device-12345');
      expect(commonParams['cognizable'], '17.0');
      expect(commonParams['wazoos'], 'ph_peso_shield_ios');
      expect(commonParams['pachysandra'], 'test-token-abc');
      expect(commonParams['sorboses'], 'test-ad-id-67890');
      expect(commonParams['suasion'], isNotEmpty);
    });

    test('HMAC-SHA256 签名算法验证', () {
      final signer = RequestSigner('cf938da7bebcecccd5563ca28d7f1fbd');

      final signInput = {
        'longicorn': '1.0.0',
        'externalizes': 'iPhone14,2',
        'dissuaders': 'test-device-id',
        'cognizable': '17.0',
        'wazoos': 'ph_peso_shield_ios',
        'pachysandra': '',
        'sorboses': 'test-ad-id',
        'suasion': '1735286400000',
        'mitogenic': '/outsmelled/mugg',
        'hierarchies': '123456',
        'borohydrides': '789012',
      };

      final signature = signer.sign(signInput);

      print('\n=== 签名信息 ===');
      print('签名算法: HMAC-SHA256');
      print('签名密钥: cf938da7bebcecccd5563ca28d7f1fbd');
      print('生成签名: $signature');
      print('签名长度: ${signature.length}');

      expect(signature, isNotEmpty);
      expect(signature.length, 64); // SHA256 = 64 hex chars
    });

    test('随机数生成', () {
      final random1 = CommonParams.randomDigits(6);
      final random2 = CommonParams.randomDigits(6);

      print('\n=== 随机数 ===');
      print('随机数1: $random1');
      print('随机数2: $random2');

      expect(random1.length, 6);
      expect(random2.length, 6);
      expect(random1, isNot(equals(random2))); // 应该不同
    });

    test('完整请求参数模拟 - peso_shield', () {
      final commonParams = CommonParams.create(
        deviceId: 'ABC123',
        market: 'ph_peso_shield_ios',
        appVersion: '1.0.0',
        deviceName: 'iPhone15,2',
        osVersion: '17.1',
        gpsAdId: 'DEF456',
        token: '',
      );

      final businessParams = {
        'hierarchies': '111111',
        'borohydrides': '222222',
      };

      final randomParam = '123456';

      final signInput = {
        ...commonParams,
        'mitogenic': '/outsmelled/mugg',
        ...businessParams,
        'endoparasites': randomParam,
      };

      final signer = RequestSigner('cf938da7bebcecccd5563ca28d7f1fbd');
      final signature = signer.sign(signInput);

      final queryParams = {
        ...commonParams,
        ...businessParams,
        'endoparasites': randomParam,
        'arboured': signature,
      };

      print('\n=== 完整请求参数 (GET /outsmelled/mugg) ===');
      print('Query 参数数量: ${queryParams.length}');
      queryParams.forEach((key, value) {
        print('  $key: $value');
      });

      expect(queryParams.containsKey('arboured'), true);
      expect(queryParams.containsKey('endoparasites'), true);
      expect(queryParams.containsKey('longicorn'), true);
      expect(queryParams.containsKey('dissuaders'), true);

      print('\n=== 签名验证 ===');
      print('随机数是否参与签名: 是');
      print('签名输入参数数量: ${signInput.length}');
    });
  });
}
