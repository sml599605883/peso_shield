import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/pages/webview/webview_action_coordinator.dart';
import 'package:peso_shield/pages/webview/webview_contract.dart';

void main() {
  WebViewRequest request(String action, Object? data) =>
      WebViewRequest.decode({'action': action, 'data': data});

  test('risk accepts web fields and an optional numeric order', () async {
    final orders = <String>[];
    final coordinator = WebViewActionCoordinator(
      nowSeconds: () => 123,
      reportRisk:
          ({
            required productId,
            required orderNo,
            required startedAtSeconds,
          }) async {
            expect(productId, 'p1');
            expect(startedAtSeconds, 123);
            orders.add(orderNo);
          },
    );
    for (final order in [42, null]) {
      final result = await coordinator.dispatch(
        request('peso_shield_WVfjTuCRJGSqjIT', {
          'polarimetric': 'p1',
          'cysticercosis': order,
        }),
      );
      expect(result.code, 0);
    }
    expect(orders, ['42', '']);
  });

  test('retry and account actions decode web identifiers', () async {
    final calls = <String>[];
    final coordinator = WebViewActionCoordinator(
      retryOrder: (order) async {
        calls.add(order);
        return 'https://example.com/retry';
      },
      reloadOrOpenWebView: (url) async => calls.add(url),
      changeAccount: ({required productId, required orderNo}) async {
        calls.add('$productId:$orderNo');
      },
    );
    expect(
      (await coordinator.dispatch(
        request('peso_shield_pKX7FGFmmsw0ztX', {'cysticercosis': 42}),
      )).code,
      0,
    );
    expect(
      (await coordinator.dispatch(
        request('peso_shield_jYHEviKaMFiBgvV', {
          'polarimetric': 'p1',
          'cysticercosis': 'order1',
        }),
      )).code,
      0,
    );
    expect(calls, ['42', 'https://example.com/retry', 'p1:order1']);
  });

  test('browser action launches the raw URL externally', () async {
    final urls = <Uri>[];
    final coordinator = WebViewActionCoordinator(
      openExternal: (uri) async {
        urls.add(uri);
        return true;
      },
    );
    expect(
      (await coordinator.dispatch(
        request('peso_shield_9Rov8it6VzmyqBB', 'https://example.com'),
      )).code,
      0,
    );
    expect(urls.single.toString(), 'https://example.com');
    expect(
      (await coordinator.dispatch(
        request('peso_shield_9Rov8it6VzmyqBB', ''),
      )).code,
      -1,
    );
    expect(urls, hasLength(1));
  });

  test(
    'public params receives the raw URL and returns callback data',
    () async {
      final coordinator = WebViewActionCoordinator(
        buildPublicParams: (path) async {
          expect(path, '/api/path');
          return {'value': 'result'};
        },
      );
      final result = await coordinator.dispatch(
        WebViewRequest.decode({
          'action': 'peso_shield_Hr6CywDtTBdnKoS',
          'data': '/api/path',
          'callbackId': 'cb1',
        }),
      );
      expect(result.code, 0);
      expect(result.data, {'value': 'result'});
    },
  );
}
