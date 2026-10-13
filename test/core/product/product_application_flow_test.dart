import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/device/session_store.dart';
import 'package:peso_shield/core/device/user_session.dart';
import 'package:peso_shield/core/navigation/app_navigator.dart';
import 'package:peso_shield/core/navigation/app_route_generator.dart';
import 'package:peso_shield/core/navigation/app_routes.dart';
import 'package:peso_shield/core/network/api_response.dart';
import 'package:peso_shield/core/network/http_client.dart';
import 'package:peso_shield/core/network/network_config.dart';
import 'package:peso_shield/core/product/product_application_flow.dart';
import 'package:peso_shield/core/ui/toast_helper.dart';
import 'package:peso_shield/data/models/product_apply_result.dart';
import 'package:peso_shield/data/repositories/order_repository.dart';
import 'package:peso_shield/data/repositories/product_repository.dart';

import '../../support/fake_session_persistence.dart';

HttpClient _unusedHttpClient() => HttpClient(
  config: NetworkConfig(
    apiBase: Uri.parse('http://127.0.0.1/slushier'),
    signSecret: 'test-secret',
    marketIdentifier: 'test-market',
  ),
  getDeviceId: () => 'test-device',
  getUserToken: () => null,
  onAuthExpired: () {},
);

class _FakeProductRepository extends ProductRepository {
  _FakeProductRepository(this.result) : super(_unusedHttpClient());

  final ProductApplyResult result;
  int calls = 0;

  @override
  Future<ApiResponse<ProductApplyResult>> applyProduct({
    required String productId,
    int apiRemind = 0,
  }) async {
    calls += 1;
    return ApiResponse<ProductApplyResult>(
      code: 0,
      message: 'success',
      data: result,
    );
  }
}

/// 按调用顺序依次返回准入结果的仓储，用于复现「授信 loading 页 → 确认用款页」链路。
class _SequencedProductRepository extends ProductRepository {
  _SequencedProductRepository(this.results) : super(_unusedHttpClient());

  final List<ProductApplyResult> results;
  int calls = 0;

  @override
  Future<ApiResponse<ProductApplyResult>> applyProduct({
    required String productId,
    int apiRemind = 0,
  }) async {
    final index = calls < results.length ? calls : results.length - 1;
    calls += 1;
    return ApiResponse<ProductApplyResult>(
      code: 0,
      message: 'success',
      data: results[index],
    );
  }
}

void main() {
  testWidgets('跳转重新授信页后立即释放防重复提交锁', (tester) async {
    // 准入下发 gold://pocket/recredit（bellings=0 原生、loading 授信页）。
    final repository = _FakeProductRepository(
      const ProductApplyResult(
        statusCode: 302,
        jumpUrl: 'gold://pocket/recredit',
        jumpType: 0,
        message: '',
      ),
    );
    final flow = ProductApplicationFlow(
      repository: repository,
      orderRepository: OrderRepository(_unusedHttpClient()),
      userSession: const UserSession(isLoggedIn: true),
      sessionStore: SessionStore(FakeSessionPersistence()),
    );

    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: AppNavigator.navigatorKey,
        builder: BotToastInit(),
        navigatorObservers: [BotToastNavigatorObserver()],
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Scaffold(
            body: Text(
              settings.name == AppRoutes.recredit ? 'recredit' : 'home',
            ),
          ),
        ),
        home: Builder(
          builder: (value) {
            context = value;
            return const Scaffold(body: Text('home'));
          },
        ),
      ),
    );

    // 准入流程必须走到重新授信页后就返回，而不是等该页面被关闭。
    var firstFlowFinished = false;
    unawaited(
      flow
          .applyProduct(
            context: context,
            productId: '3',
            checkLocationAccess: false,
          )
          .then((_) => firstFlowFinished = true),
    );
    await tester.pumpAndSettle();

    expect(find.text('recredit'), findsOneWidget);
    expect(firstFlowFinished, isTrue, reason: '准入流程不应等待重新授信页关闭后才返回');

    // 重新授信页仍在栈顶，轮询到授信成功后的自动准入不能被静默丢弃。
    await flow.applyProduct(
      context: context,
      productId: '3',
      checkLocationAccess: false,
    );
    await tester.pumpAndSettle();
    expect(repository.calls, 2);

    ToastHelper.cancel();
  });

  testWidgets('重新授信 loading 页跳转确认用款页后被关闭，退出时回到首页', (tester) async {
    // 第一次准入下发重新授信 loading 页；授信成功后第二次准入下发确认用款页 H5。
    final repository = _SequencedProductRepository(const [
      ProductApplyResult(
        statusCode: 302,
        jumpUrl: 'gold://pocket/recredit',
        jumpType: 0,
        message: '',
      ),
      ProductApplyResult(
        statusCode: 200,
        jumpUrl: 'http://host/#/AmalgamatorsMarqueterie?polarimetric=3',
        jumpType: 1,
        message: '',
      ),
    ]);
    final flow = ProductApplicationFlow(
      repository: repository,
      orderRepository: OrderRepository(_unusedHttpClient()),
      userSession: const UserSession(isLoggedIn: true),
      sessionStore: SessionStore(FakeSessionPersistence()),
    );

    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: AppNavigator.navigatorKey,
        builder: BotToastInit(),
        navigatorObservers: [BotToastNavigatorObserver()],
        onGenerateRoute: (settings) {
          final label = settings.name == AppRoutes.webView
              ? (settings.arguments as WebViewPageArguments?)?.url ?? 'webview'
              : (settings.name ?? 'home');
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => Scaffold(body: Text(label)),
          );
        },
        home: Builder(
          builder: (value) {
            context = value;
            return const Scaffold(body: Text('home'));
          },
        ),
      ),
    );

    await flow.applyProduct(
      context: context,
      productId: '3',
      checkLocationAccess: false,
    );
    await tester.pumpAndSettle();
    expect(find.text(AppRoutes.recredit), findsOneWidget);

    // 轮询到授信成功后自动准入。
    await flow.applyProduct(
      context: context,
      productId: '3',
      checkLocationAccess: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('http://host/#/AmalgamatorsMarqueterie?polarimetric=3'),
      findsOneWidget,
    );
    // 授信 loading 页未关闭时，退出确认用款页会回到该页。
    expect(find.text(AppRoutes.recredit), findsNothing);

    AppNavigator.pop<void>();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);

    ToastHelper.cancel();
  });
}
