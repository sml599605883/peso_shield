import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/device/session_store.dart';
import 'package:peso_shield/core/device/user_session.dart';
import 'package:peso_shield/core/network/api_response.dart';
import 'package:peso_shield/core/network/http_client.dart';
import 'package:peso_shield/core/ui/toast_helper.dart';
import 'package:peso_shield/data/repositories/auth_repository.dart';
import 'package:peso_shield/pages/settings_page.dart';
import 'package:peso_shield/providers/repository_provider.dart';

import '../support/fake_session_persistence.dart';

/// 固定返回码的假客户端：用于覆盖接口返回业务失败的场景，避免真实请求。
class _StubClient implements HttpClient {
  _StubClient({required this.code, required this.message});

  final int code;
  final String message;
  final List<String> paths = <String>[];

  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, Object?>? params,
    required T Function(Object?) parse,
  }) async {
    paths.add(path);
    return ApiResponse<T>(code: code, message: message, data: parse(null));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Setting 页的固定宽度文案（`xxxxxxxxxxxxxxxx`、弹窗标题）在测试字体
/// Ahem（每个字符都是等宽方块）下必然溢出，属于测试环境限制；这里只过滤
/// RenderFlex 溢出，其它异常照旧让用例失败。
void _ignoreRenderOverflow() {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('RenderFlex overflowed')) return;
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}

void main() {
  Future<ProviderContainer> pumpSettings(
    WidgetTester tester,
    _StubClient client,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(
          SessionStore(FakeSessionPersistence()),
        ),
        authRepositoryProvider.overrideWith(
          (ref) async => AuthRepository(client),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(userSessionProvider.notifier)
        .setSession(token: 'token-1', userId: 'user-1', phone: '9000000000');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: BotToastInit(),
          navigatorObservers: [BotToastNavigatorObserver()],
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('注销接口返回失败时关闭弹窗、不清登录态、不跳首页，并提示错误', (tester) async {
    _ignoreRenderOverflow();
    final client = _StubClient(code: 10001, message: 'Deletion failed');
    final container = await pumpSettings(tester, client);

    await tester.tap(find.text('Deactivate Account'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(client.paths, ['/outsmelled/closets']);
    // 登录态必须保留，仅关闭弹窗并给出失败提示。
    expect(container.read(userSessionProvider).isLoggedIn, isTrue);
    expect(container.read(userSessionProvider).accessToken, 'token-1');
    expect(find.text('Permanently Delete Your Account?'), findsNothing);
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('Deletion failed'), findsOneWidget);

    ToastHelper.cancel();
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('退出接口返回失败时同样关闭弹窗、保留登录态并提示错误', (tester) async {
    _ignoreRenderOverflow();
    final client = _StubClient(code: 10002, message: 'Logout failed');
    final container = await pumpSettings(tester, client);

    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log Out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(client.paths, ['/outsmelled/coffees']);
    expect(container.read(userSessionProvider).isLoggedIn, isTrue);
    expect(find.text('Log out?'), findsNothing);
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('Logout failed'), findsOneWidget);

    ToastHelper.cancel();
    await tester.pump(const Duration(seconds: 3));
  });
}
