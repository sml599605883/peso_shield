import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/navigation/app_route_observer.dart';
import 'package:peso_shield/data/models/home_data.dart';
import 'package:peso_shield/data/models/home_popup_data.dart';
import 'package:peso_shield/pages/home_page.dart';
import 'package:peso_shield/providers/home_provider.dart';

void main() {
  testWidgets('route refresh is skipped while a refresh is in flight', (
    tester,
  ) async {
    final requests = <Completer<HomeData>>[];
    final notifier = HomeDataNotifier(
      loadHome: () {
        final request = Completer<HomeData>();
        requests.add(request);
        return request.future;
      },
      loadPopup: () async => const HomePopupData(),
      showLoading: () => () {},
      showError: (_) {},
      presentPopup: (_) async {},
    );
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [homeDataProvider.overrideWith(() => notifier)],
        child: MaterialApp(
          navigatorKey: key,
          navigatorObservers: [appRouteObserver],
          home: const HomePage(isActive: true),
        ),
      ),
    );
    await tester.pump();
    expect(requests, hasLength(1));

    key.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Detail')),
      ),
    );
    await tester.pumpAndSettle();
    key.currentState!.pop();
    await tester.pumpAndSettle();

    // 首个刷新仍在进行，返回页面不应再叠加一次首页/弹窗请求。
    expect(requests, hasLength(1));

    requests.first.complete(
      const HomeData(
        phoneIcon: PhoneIcon(imageUrl: '', jumpUrl: ''),
        sections: [],
        products: [],
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
