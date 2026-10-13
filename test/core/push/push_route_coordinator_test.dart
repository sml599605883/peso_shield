import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/json/json.dart';
import 'package:peso_shield/core/push/push_route_coordinator.dart';

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

    test('default dispatch runs without waiting for a frame', () async {
      var dispatched = false;
      dispatchPendingPushRoute(() => dispatched = true);
      expect(dispatched, isFalse);

      // 只等事件循环、不 pump 帧：空闲 App 没有新帧时也必须完成派发。
      await Future<void>.delayed(Duration.zero);

      expect(dispatched, isTrue);
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
}
