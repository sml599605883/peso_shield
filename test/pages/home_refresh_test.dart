import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/navigation/app_route_observer.dart';
import 'package:peso_shield/data/models/home_data.dart';
import 'package:peso_shield/data/models/home_popup_data.dart';
import 'package:peso_shield/pages/home_page.dart';
import 'package:peso_shield/providers/home_provider.dart';

void main() {
  testWidgets('initial, tab, pull and page return refresh; dialogs do not', (
    tester,
  ) async {
    var requests = 0;
    var active = true;
    late StateSetter update;
    final key = GlobalKey<NavigatorState>();
    final notifier = HomeDataNotifier(
      loadHome: () async {
        requests++;
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
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [homeDataProvider.overrideWith(() => notifier)],
        child: MaterialApp(
          navigatorKey: key,
          navigatorObservers: [appRouteObserver],
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Scaffold(body: HomePage(isActive: active));
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(requests, 1);
    update(() => active = false);
    await tester.pumpAndSettle();
    notifier.didChangeAppLifecycleState(AppLifecycleState.paused);
    notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(requests, 1);
    update(() => active = true);
    await tester.pumpAndSettle();
    expect(requests, 2);

    key.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Detail')),
      ),
    );
    await tester.pumpAndSettle();
    notifier.didChangeAppLifecycleState(AppLifecycleState.paused);
    notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(requests, 2);
    key.currentState!.pop();
    await tester.pumpAndSettle();
    expect(requests, 3);

    showDialog<void>(
      context: key.currentContext!,
      builder: (_) => const AlertDialog(content: Text('Dialog')),
    );
    await tester.pumpAndSettle();
    key.currentState!.pop();
    await tester.pumpAndSettle();
    expect(requests, 3);
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, 400),
    );
    await tester.pumpAndSettle();
    expect(requests, 4);
    expect(tester.takeException(), isNull);
  });
}
