import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/json/json.dart';
import 'package:peso_shield/core/navigation/app_navigator.dart';
import 'package:peso_shield/core/navigation/app_routes.dart';
import 'package:peso_shield/core/push/push_route_coordinator.dart';
import 'package:peso_shield/providers/credit_orders_provider.dart';

Json _pushRoute(String url) =>
    Json(<String, Object?>{'type': 'push_route', 'url': url});

void main() {
  group('PushRouteCoordinator', () {
    test('queues push routes until navigation is attached', () async {
      final events = StreamController<Json>();
      final opened = <String>[];
      final coordinator = PushRouteCoordinator(
        events: () => events.stream,
        defer: (callback) => callback(),
      );
      coordinator.start();

      events.add(_pushRoute('ph://peso-shield/ios/PermutesLinotypes'));
      await Future<void>.delayed(Duration.zero);
      expect(opened, isEmpty);

      coordinator.attach((route) async => opened.add(route));
      await Future<void>.delayed(Duration.zero);

      expect(opened, ['ph://peso-shield/ios/PermutesLinotypes']);
      await coordinator.stop();
      await events.close();
    });

    test('ignores unrelated events and empty routes', () async {
      final events = StreamController<Json>();
      final opened = <String>[];
      final coordinator = PushRouteCoordinator(
        events: () => events.stream,
        defer: (callback) => callback(),
      );
      coordinator.start();
      coordinator.attach((route) async => opened.add(route));

      events.add(Json(<String, Object?>{'type': 'push_token', 'token': 'abc'}));
      events.add(_pushRoute('   '));
      events.add(Json(<String, Object?>{}));
      await Future<void>.delayed(Duration.zero);

      expect(opened, isEmpty);
      await coordinator.stop();
      await events.close();
    });

    test(
      'opens routes in arrival order without waiting for the page',
      () async {
        final events = StreamController<Json>();
        final opened = <String>[];
        final firstGate = Completer<void>();
        final coordinator = PushRouteCoordinator(
          events: () => events.stream,
          defer: (callback) => callback(),
        );
        coordinator.start();
        coordinator.attach((route) async {
          opened.add(route);
          if (route == 'first') await firstGate.future;
        });

        events.add(_pushRoute('first'));
        events.add(_pushRoute('second'));
        await Future<void>.delayed(Duration.zero);

        expect(opened, ['first', 'second']);

        firstGate.complete();
        await coordinator.stop();
        await events.close();
      },
    );

    test('keeps delivering after an opener failure', () async {
      final events = StreamController<Json>();
      final opened = <String>[];
      final coordinator = PushRouteCoordinator(
        events: () => events.stream,
        defer: (callback) => callback(),
      );
      coordinator.start();
      coordinator.attach((route) async {
        opened.add(route);
        if (route == 'broken') throw StateError('boom');
      });

      events.add(_pushRoute('broken'));
      events.add(_pushRoute('next'));
      await Future<void>.delayed(Duration.zero);

      expect(opened, ['broken', 'next']);
      await coordinator.stop();
      await events.close();
    });
  });

  testWidgets('push order link opens the order list with its status filter', (
    tester,
  ) async {
    RouteSettings? captured;
    late WidgetRef widgetRef;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          navigatorKey: AppNavigator.navigatorKey,
          onGenerateRoute: (settings) {
            captured = settings;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const SizedBox.shrink(),
            );
          },
          home: Consumer(
            builder: (context, ref, _) {
              widgetRef = ref;
              return const Scaffold(body: Text('home'));
            },
          ),
        ),
      ),
    );
    await tester.pump();

    // 导航 Future 在页面 pop 后才完成，先不 await。
    final navigation = AppNavigator.navigateRawTarget(
      context: tester.element(find.text('home')),
      ref: widgetRef,
      target: 'ph://peso-shield/ios/PermutesLinotypes?segregate=6',
    );
    await tester.pumpAndSettle();

    expect(captured?.name, AppRoutes.mineOrderList);
    expect(captured?.arguments, OrderFilter.overdue);

    AppNavigator.pop();
    await tester.pumpAndSettle();
    await navigation;
  });
}
