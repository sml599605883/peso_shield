import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/data/models/home_data.dart';
import 'package:peso_shield/data/models/home_popup_data.dart';
import 'package:peso_shield/providers/home_provider.dart';

HomeData data(String label) => HomeData(
  phoneIcon: PhoneIcon(imageUrl: label, jumpUrl: ''),
  sections: const [],
  products: const [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('latest response wins and failure retains delivered home', () async {
    final requests = <Completer<HomeData>>[];
    final errors = <String>[];
    var activeLoading = 0;
    final notifier = HomeDataNotifier(
      loadHome: () {
        final request = Completer<HomeData>();
        requests.add(request);
        return request.future;
      },
      loadPopup: () async => const HomePopupData(),
      showLoading: () {
        activeLoading++;
        var closed = false;
        return () {
          if (!closed) activeLoading--;
          closed = true;
        };
      },
      showError: errors.add,
    );
    final container = ProviderContainer(
      overrides: [homeDataProvider.overrideWith(() => notifier)],
    );
    addTearDown(container.dispose);
    container.read(homeDataProvider);
    final old = notifier.refresh();
    final recent = notifier.refresh();
    requests[1].complete(data('new'));
    await recent;
    expect(activeLoading, 0);
    requests[0].complete(data('old'));
    await old;
    expect(container.read(homeDataProvider).value?.phoneIcon.imageUrl, 'new');
    final failed = notifier.refresh();
    requests[2].completeError(Exception('offline'));
    await failed;
    expect(container.read(homeDataProvider).value?.phoneIcon.imageUrl, 'new');
    expect(errors, hasLength(1));
    expect(activeLoading, 0);
  });

  test(
    'resume requires visible home and filters repeated inactive and location',
    () async {
      var count = 0;
      final notifier = HomeDataNotifier(
        loadHome: () async {
          count++;
          return data('');
        },
        loadPopup: () async => const HomePopupData(),
        showLoading: () => () {},
        showError: (_) {},
      );
      final container = ProviderContainer(
        overrides: [homeDataProvider.overrideWith(() => notifier)],
      );
      addTearDown(container.dispose);
      container.read(homeDataProvider);
      notifier.setVisible(true);
      notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(count, 0);
      notifier.beginLocationPermissionRequest();
      notifier.didChangeAppLifecycleState(AppLifecycleState.inactive);
      notifier.endLocationPermissionRequest();
      notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(count, 0);
      notifier.didChangeAppLifecycleState(AppLifecycleState.inactive);
      notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(count, 1);
      notifier.didChangeAppLifecycleState(AppLifecycleState.inactive);
      notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(count, 1);
      notifier.didChangeAppLifecycleState(AppLifecycleState.paused);
      notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(count, 2);
      notifier.setVisible(false);
      notifier.didChangeAppLifecycleState(AppLifecycleState.paused);
      notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
      notifier.setVisible(true);
      notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(count, 2);
      await Future<void>.delayed(Duration.zero);
    },
  );

  test(
    'popup waits for home loading and hidden stale results are dropped',
    () async {
      final home = Completer<HomeData>();
      final events = <String>[];
      final notifier = HomeDataNotifier(
        loadHome: () => home.future,
        loadPopup: () async =>
            const HomePopupData(type: HomePopupType.appUpgrade, version: '2'),
        showLoading: () {
          events.add('loading');
          return () => events.add('closed');
        },
        showError: (_) {},
        presentPopup: (_) async => events.add('popup'),
      );
      final container = ProviderContainer(
        overrides: [homeDataProvider.overrideWith(() => notifier)],
      );
      addTearDown(container.dispose);
      container.read(homeDataProvider);
      notifier.setVisible(true);
      final refresh = notifier.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(events, ['loading']);
      home.complete(data(''));
      await refresh;
      await Future<void>.delayed(Duration.zero);
      expect(events, ['loading', 'closed', 'popup']);
      notifier.setVisible(false);
      await notifier.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(events.where((event) => event == 'popup'), hasLength(1));
    },
  );

  test('popup failure does not fail or delay home refresh', () async {
    final popup = Completer<HomePopupData>();
    final notifier = HomeDataNotifier(
      loadHome: () async => data('ok'),
      loadPopup: () => popup.future,
      showLoading: () => () {},
      showError: (_) => fail('unexpected error'),
    );
    final container = ProviderContainer(
      overrides: [homeDataProvider.overrideWith(() => notifier)],
    );
    addTearDown(container.dispose);
    container.read(homeDataProvider);
    await notifier.refresh();
    expect(container.read(homeDataProvider).value?.phoneIcon.imageUrl, 'ok');
    popup.completeError(Exception('popup failed'));
    await Future<void>.delayed(Duration.zero);
  });
}
