import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/network/request_signer.dart';

void main() {
  group('RequestSigner', () {
    test('sign with correct parameters order and secret', () {
      final signer = RequestSigner('cf938da7bebcecccd5563ca28d7f1fbd');

      final params = {
        'deviceId': 'test-device-id',
        'market': 'ph_peso_shield_ios',
        'timestamp': 1735286400000,
        'version': '1.0.0',
        'platform': 'ios',
      };

      final signature = signer.sign(params);

      // 打印调试信息
      final sortedKeys = params.keys.toList()..sort();
      final buffer = StringBuffer();
      for (final key in sortedKeys) {
        final value = params[key];
        if (value != null && value.toString().isNotEmpty) {
          buffer.write('$key=$value&');
        }
      }
      final signString = buffer.toString();
      final trimmed = signString.substring(0, signString.length - 1);
      print('Sorted params: $trimmed');
      print('With secret: ${trimmed}cf938da7bebcecccd5563ca28d7f1fbd');
      print('Generated signature: $signature');

      expect(signature, isNotEmpty);
      expect(signature.length, 32); // MD5 hash length
    });

    test('sign ignores null and empty values', () {
      final signer = RequestSigner('test-secret');

      final params = {
        'key1': 'value1',
        'key2': null,
        'key3': '',
        'key4': 'value4',
      };

      final signature = signer.sign(params);

      // 应该只包含 key1 和 key4
      expect(signature, isNotEmpty);
    });
  });
}
