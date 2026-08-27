import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/network/request_signer.dart';

void main() {
  group('RequestSigner HMAC-SHA256', () {
    test('sign with HMAC-SHA256 algorithm', () {
      final signer = RequestSigner('cf938da7bebcecccd5563ca28d7f1fbd');

      final params = {
        'pathbreaking': '1.0.0',
        'nutlike': 'iPhone14,2',
        'cockatoos': 'test-device-id',
        'advocation': '17.0',
        'semipious': 'ph_peso_shield_ios',
        'coccolith': '',
        'reformer': 'test-ad-id',
        'antipoles': '1735286400000',
        'begloom': '/viler/foresight',
      };

      final signature = signer.sign(params);

      print('Params sorted: ${params.keys.toList()..sort()}');
      print('Sign input: ${params.keys.toList()..sort()..map((k) => '$k${params[k]}')}');
      print('Generated signature (HMAC-SHA256): $signature');

      expect(signature, isNotEmpty);
      expect(signature.length, 64); // SHA256 hash length
    });
  });
}
