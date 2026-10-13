import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/device/session_store.dart';
import 'package:peso_shield/core/device/user_session.dart';
import 'package:peso_shield/core/navigation/app_navigator.dart';
import 'package:peso_shield/core/navigation/app_route_generator.dart';
import 'package:peso_shield/data/models/home_data.dart';
import 'package:peso_shield/data/models/home_popup_data.dart';
import 'package:peso_shield/pages/login_page.dart';
import 'package:peso_shield/providers/credit_orders_provider.dart';
import 'package:peso_shield/providers/home_provider.dart';
import 'package:peso_shield/providers/network_provider.dart';
import 'package:peso_shield/root_tab_page.dart';
import 'package:peso_shield/widgets/tab_bar/tab_item.dart';

import '../support/fake_session_persistence.dart';

/// H5 判定登录态失效后下发的 login 深链（Scheme 别名 UndertaxGrain）。
const String _loginDeepLink = 'ph://peso-shield/ios/UndertaxGrain';

class _IdleCreditOrdersNotifier extends CreditOrdersNotifier {
  @override
  Future<void> loadOrders({OrderFilter? filter}) async {}

  @override
  Future<void> loadMore() async {}
}

Finder _tab(String label) => find.byWidgetPredicate(
  (widget) => widget is HomeTabItem && widget.label == label,
  // 登录页盖在根 Tab 上时，根 Tab 会被标记为 offstage。
  skipOffstage: false,
);

bool _isTabSelected(WidgetTester tester, String label) =>
    tester.widget<HomeTabItem>(_tab(label)).selected;

/// 关闭登录页，避免静态的登录页去重状态泄漏到下一个用例。
Future<void> _closeLoginPage(WidgetTester tester) async {
  if (find.byType(LoginPage).evaluate().isEmpty) return;
  AppNavigator.pop(true);
  await tester.pumpAndSettle();
}

void main() {
  late ProviderContainer container;
  late WidgetRef navRef;
  late BuildContext navContext;

  Future<void> pumpRootTab(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(
          SessionStore(FakeSessionPersistence()),
        ),
        homeDataProvider.overrideWith(
          () => HomeDataNotifier(
            loadHome: () async => const HomeData(
              phoneIcon: PhoneIcon(imageUrl: '', jumpUrl: ''),
              sections: [],
              products: [],
            ),
            loadPopup: () async => const HomePopupData(),
            showLoading: () => () {},
            showError: (_) {},
            presentPopup: (_) async {},
          ),
        ),
        creditOrdersProvider.overrideWith(_IdleCreditOrdersNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: AppNavigator.navigatorKey,
          onGenerateRoute: AppRouteGenerator.onGenerateRoute,
          home: Consumer(
            builder: (context, ref, _) {
              navRef = ref;
              navContext = context;
              return const RootTabPage();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 用例断言失败时登录页可能仍留在栈上，兜底出栈。
    addTearDown(() => _closeLoginPage(tester));
  }

  Future<void> login(WidgetTester tester, {required String token}) async {
    await container
        .read(userSessionProvider.notifier)
        .setSession(token: token, userId: 'user-1', phone: '9000000000');
    await tester.pumpAndSettle();
  }

  Future<void> selectCreditTab(WidgetTester tester) async {
    await tester.tap(_tab('Credit'));
    await tester.pumpAndSettle();
    expect(_isTabSelected(tester, 'Credit'), isTrue);
  }

  Future<void> sendLoginDeepLink() async {
    unawaited(
      AppNavigator.navigateRawTarget(
        context: navContext,
        ref: navRef,
        target: _loginDeepLink,
      ),
    );
  }

  testWidgets('login deep link from a web page lands on the home tab', (
    tester,
  ) async {
    await pumpRootTab(tester);
    await login(tester, token: 'token-1');
    await selectCreditTab(tester);

    await sendLoginDeepLink();
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(_isTabSelected(tester, 'Home'), isTrue);

    // 重新登录成功后应停留在首页 Tab。
    await login(tester, token: 'token-2');
    AppNavigator.pop(true);
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsNothing);
    expect(_isTabSelected(tester, 'Home'), isTrue);
    expect(_isTabSelected(tester, 'Credit'), isFalse);
  });

  testWidgets('expired session returns to the home tab before login', (
    tester,
  ) async {
    await pumpRootTab(tester);
    await login(tester, token: 'token-1');
    await selectCreditTab(tester);

    await container
        .read(sessionExpiryCoordinatorProvider)
        .handleExpiredSession();
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(_isTabSelected(tester, 'Home'), isTrue);

    await _closeLoginPage(tester);
  });

  testWidgets('login deep link opens login without a local session', (
    tester,
  ) async {
    await pumpRootTab(tester);

    await sendLoginDeepLink();
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(_isTabSelected(tester, 'Home'), isTrue);

    await _closeLoginPage(tester);
  });
}
