import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/device/session_store.dart';
import 'package:peso_shield/core/device/user_session.dart';
import 'package:peso_shield/core/navigation/app_navigator.dart';
import 'package:peso_shield/core/navigation/app_route_observer.dart';
import 'package:peso_shield/core/navigation/app_route_generator.dart';
import 'package:peso_shield/core/navigation/app_routes.dart';
import 'package:peso_shield/core/network/api_response.dart';
import 'package:peso_shield/data/models/home_data.dart';
import 'package:peso_shield/data/models/home_popup_data.dart';
import 'package:peso_shield/pages/recredit/recredit_polling_coordinator.dart';
import 'package:peso_shield/providers/credit_orders_provider.dart';
import 'package:peso_shield/providers/home_provider.dart';
import 'package:peso_shield/widgets/tab_bar/tab_item.dart';

import '../../support/fake_session_persistence.dart';

/// 从真实的 ProviderContainer 中取一个 [Ref]，用于构造协调器。
final _refProvider = Provider<Ref>((ref) => ref);

class _IdleCreditOrdersNotifier extends CreditOrdersNotifier {
  @override
  Future<void> loadOrders({OrderFilter? filter}) async {}

  @override
  Future<void> loadMore() async {}
}

Finder _tab(String label) => find.byWidgetPredicate(
  (widget) => widget is HomeTabItem && widget.label == label,
  skipOffstage: false,
);

void main() {
  testWidgets('重新授信完成只在首页 Tab 展示时刷新首页', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var homeRequests = 0;
    final container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(
          SessionStore(FakeSessionPersistence()),
        ),
        homeDataProvider.overrideWith(
          () => HomeDataNotifier(
            loadHome: () async {
              homeRequests += 1;
              return const HomeData(
                phoneIcon: PhoneIcon(imageUrl: '', jumpUrl: ''),
                sections: [],
                products: [],
              );
            },
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
          navigatorObservers: [appRouteObserver],
          onGenerateRoute: AppRouteGenerator.onGenerateRoute,
          initialRoute: AppRoutes.root,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await container
        .read(userSessionProvider.notifier)
        .setSession(token: 'token-1', userId: 'user-1', phone: '9000000000');
    await tester.pumpAndSettle();

    final ref = container.read(_refProvider);
    var refreshes = 0;
    RecreditPollingCoordinator buildCoordinator() => RecreditPollingCoordinator(
      ref: ref,
      interval: const Duration(milliseconds: 5),
      request: () async => const ApiResponse<Map<String, dynamic>>(
        code: 0,
        message: 'success',
        data: {'recklessly': 1},
      ),
      homeRefresher: () async => refreshes += 1,
      logger: (_) {},
    );

    // 首页 Tab 正在展示：授信完成刷新首页。
    var coordinator = buildCoordinator();
    coordinator.start('p1');
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump();

    expect(container.read(homeDataProvider.notifier).isVisible, isTrue);
    expect(refreshes, 1);

    // 切到「个人中心」Tab：当前路由仍是根路由，但展示的不是首页。
    await tester.tap(_tab('Mine'));
    await tester.pumpAndSettle();

    expect(AppNavigator.currentRoute, AppRoutes.root);
    expect(container.read(homeDataProvider.notifier).isVisible, isFalse);

    coordinator = buildCoordinator();
    coordinator.start('p2');
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump();

    expect(refreshes, 1);

    // 回到首页 Tab 时由首页自身重新拉取数据，补上授信结果。
    final requestsBeforeReturn = homeRequests;
    await tester.tap(_tab('Home'));
    await tester.pumpAndSettle();

    expect(container.read(homeDataProvider.notifier).isVisible, isTrue);
    expect(homeRequests, greaterThan(requestsBeforeReturn));
  });
}
