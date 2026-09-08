import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/pages/webview/webview_contract.dart';

void main() {
  group('WebViewContract', () {
    test('handler should match the web bridge namespace', () {
      expect(WebViewContract.handler, 'ph_peso_shield_ios');
    });

    test('all actions should use the current web contract', () {
      expect(WebViewActions.uploadRisk, 'peso_shield_WVfjTuCRJGSqjIT');
      expect(WebViewActions.openGooglePlay, 'peso_shield_9Rov8it6VzmyqBB');
      expect(WebViewActions.openUrl, 'peso_shield_fVPjxOZ6Bw3LyQa');
      expect(WebViewActions.close, 'peso_shield_a65wTdBVcctiFNh');
      expect(WebViewActions.home, 'peso_shield_PPHwPq2wr2Zy3kX');
      expect(WebViewActions.grade, 'peso_shield_bfhPVzF4iYNTXuF');
      expect(WebViewActions.retryOrder, 'peso_shield_pKX7FGFmmsw0ztX');
      expect(WebViewActions.changeAccount, 'peso_shield_jYHEviKaMFiBgvV');
      expect(WebViewActions.publicParams, 'peso_shield_Hr6CywDtTBdnKoS');
    });
  });

  group('WebViewRequest', () {
    test('decode should parse action from message', () {
      final message = {
        'action': WebViewActions.close,
        'callbackId': 'cb_123',
        'data': {'key': 'value'},
      };

      final request = WebViewRequest.decode(message);

      expect(request.action, WebViewActions.close);
      expect(request.callbackId, 'cb_123');
      expect(request.data['key'], 'value');
    });

    test('decode should handle JSON string message', () {
      final message =
          '{"action":"${WebViewActions.home}","callbackId":"cb_456"}';

      final request = WebViewRequest.decode(message);

      expect(request.action, WebViewActions.home);
      expect(request.callbackId, 'cb_456');
    });

    test('decode should support alternative field names', () {
      final message = {
        'name': WebViewActions.openUrl,
        'callback': 'cb_789',
        'payload': {'url': 'https://example.com'},
      };

      final request = WebViewRequest.decode(message);

      expect(request.action, WebViewActions.openUrl);
      expect(request.callbackId, 'cb_789');
      expect(request.data['url'], 'https://example.com');
    });

    test('expectsCallback should return true when callbackId is not empty', () {
      final request = WebViewRequest.decode({
        'action': 'bridge_test',
        'callbackId': 'cb_123',
      });

      expect(request.expectsCallback, true);
    });

    test('expectsCallback should return false when callbackId is empty', () {
      final request = WebViewRequest.decode({
        'action': 'bridge_test',
        'callbackId': '',
      });

      expect(request.expectsCallback, false);
    });

    test('rawDataString should return string data as-is', () {
      final request = WebViewRequest.decode({
        'action': 'bridge_test',
        'callbackId': '',
        'data': '  test data  ',
      });

      expect(request.rawDataString, 'test data');
    });
  });

  group('WebViewResult', () {
    test('success should create result with code 0', () {
      const result = WebViewResult.success({'result': 'ok'});

      expect(result.code, 0);
      expect(result.message, 'success');
      expect(result.data, {'result': 'ok'});
    });

    test('success without data should create result with code 0', () {
      const result = WebViewResult.success();

      expect(result.code, 0);
      expect(result.message, 'success');
      expect(result.data, null);
    });

    test('failure should create result with code -1 by default', () {
      const result = WebViewResult.failure('Error occurred');

      expect(result.code, -1);
      expect(result.message, 'Error occurred');
      expect(result.data, null);
    });

    test('failure should accept custom error code', () {
      const result = WebViewResult.failure('Not found', code: -404);

      expect(result.code, -404);
      expect(result.message, 'Not found');
    });

    test('toJson should serialize result correctly', () {
      const result = WebViewResult.success({'key': 'value'});

      final json = result.toJson();

      expect(json['code'], 0);
      expect(json['message'], 'success');
      expect(json['data'], {'key': 'value'});
    });

    test('toJson should use empty map when data is null', () {
      const result = WebViewResult.success();

      final json = result.toJson();

      expect(json['data'], <String, dynamic>{});
    });
  });
}
