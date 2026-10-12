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

  test('grade action requests an app review once', () async {
    var reviews = 0;
    final coordinator = WebViewActionCoordinator(
      requestAppReview: () async => reviews++,
    );

    final result = await coordinator.dispatch(
      request('peso_shield_bfhPVzF4iYNTXuF', null),
    );

    expect(result.code, 0);
    expect(reviews, 1);
  });

  // 回归：reczz28MQkQuGeem / reczz28MR5WnN12R
  // H5 页面通过桥接 openUrl 下发 http(s) 地址时，必须走 H5→H5 跳转路径
  // （openWebView → openH5WebView → toWebView(removeWebViewPages: true)），
  // 由 AppNavigator 移除来源 H5 路由；否则退出新页面会回到推荐列表页/订单详情页。
  test('openUrl routes http URLs to the H5-to-H5 webview entry', () async {
    final opened = <String>[];
    var internalCalls = 0;
    final coordinator = WebViewActionCoordinator(
      openWebView: (url) async => opened.add(url),
      navigateInternal: (url) async => internalCalls++,
    );

    final result = await coordinator.dispatch(
      request(
        WebViewActions.openUrl,
        'http://8.212.131.176/#/AmalgamatorsMarqueterie'
        '?cointerring=1&polarimetric=3&changeAccount=1',
      ),
    );

    expect(result.code, 0);
    expect(opened, [
      'http://8.212.131.176/#/AmalgamatorsMarqueterie'
          '?cointerring=1&polarimetric=3&changeAccount=1',
    ]);
    expect(internalCalls, 0);
  });

  test('openUrl routes https URLs to the H5-to-H5 webview entry', () async {
    final opened = <String>[];
    final coordinator = WebViewActionCoordinator(
      openWebView: (url) async => opened.add(url),
    );

    final result = await coordinator.dispatch(
      request(WebViewActions.openUrl, 'https://example.com/order/detail'),
    );

    expect(result.code, 0);
    expect(opened, ['https://example.com/order/detail']);
  });

  test('openUrl routes ph scheme URLs to the internal navigator', () async {
    final opened = <String>[];
    final internal = <String>[];
    final coordinator = WebViewActionCoordinator(
      openWebView: (url) async => opened.add(url),
      navigateInternal: (url) async => internal.add(url),
    );

    const target = 'ph://peso-shield/ios/Equisetum?bombarder=3';
    final result = await coordinator.dispatch(
      request(WebViewActions.openUrl, target),
    );

    expect(result.code, 0);
    expect(internal, [target]);
    expect(opened, isEmpty);
  });

  test(
    'openUrl rejects a malformed http URL without opening a webview',
    () async {
      final opened = <String>[];
      final coordinator = WebViewActionCoordinator(
        openWebView: (url) async => opened.add(url),
      );

      final result = await coordinator.dispatch(
        request(WebViewActions.openUrl, 'http://'),
      );

      expect(result.code, isNot(0));
      expect(opened, isEmpty);
    },
  );
}
