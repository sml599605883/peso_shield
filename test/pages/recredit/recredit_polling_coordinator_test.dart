import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/network/api_response.dart';
import 'package:peso_shield/pages/recredit/recredit_polling_coordinator.dart';

/// 从真实的 ProviderContainer 中取一个 [Ref]，用于构造协调器。
final _refProvider = Provider<Ref>((ref) => ref);

({ProviderContainer container, Ref ref}) _createRef() {
  final container = ProviderContainer();
  return (container: container, ref: container.read(_refProvider));
}

void main() {
  testWidgets('授信成功后停止轮询并自动触发准入接口', (tester) async {
    final setup = _createRef();
    addTearDown(setup.container.dispose);
    final admissions = <String>[];
    var polls = 0;
    final coordinator = RecreditPollingCoordinator(
      ref: setup.ref,
      interval: const Duration(milliseconds: 5),
      request: () async {
        polls += 1;
        return ApiResponse<Map<String, dynamic>>(
          code: 0,
          message: 'success',
          data: {'recklessly': polls >= 2 ? 1 : 0},
        );
      },
      currentRoute: () => '/recredit',
      homeRefresher: () async {},
      admissionRunner: (productId) async => admissions.add(productId),
      logger: (_) {},
    );

    coordinator.start('p1');
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();

    expect(polls, greaterThanOrEqualTo(2));
    expect(admissions, ['p1']);
    expect(coordinator.isRunning, isFalse);
  });

  testWidgets('未返回授信成功标记时持续轮询且不触发准入', (tester) async {
    final setup = _createRef();
    addTearDown(setup.container.dispose);
    final admissions = <String>[];
    var polls = 0;
    final coordinator = RecreditPollingCoordinator(
      ref: setup.ref,
      interval: const Duration(milliseconds: 5),
      request: () async {
        polls += 1;
        return const ApiResponse<Map<String, dynamic>>(
          code: 0,
          message: 'success',
          data: {'recklessly': 0},
        );
      },
      currentRoute: () => '/recredit',
      homeRefresher: () async {},
      admissionRunner: (productId) async => admissions.add(productId),
      logger: (_) {},
    );

    coordinator.start('p1');
    await tester.pump(const Duration(milliseconds: 40));

    expect(polls, greaterThanOrEqualTo(2));
    expect(admissions, isEmpty);
    expect(coordinator.isRunning, isTrue);
    coordinator.stop();
  });

  testWidgets('已回到首页时完成授信只刷新首页、不触发准入', (tester) async {
    final setup = _createRef();
    addTearDown(setup.container.dispose);
    final admissions = <String>[];
    var refreshed = 0;
    final coordinator = RecreditPollingCoordinator(
      ref: setup.ref,
      interval: const Duration(milliseconds: 5),
      request: () async => const ApiResponse<Map<String, dynamic>>(
        code: 0,
        message: 'success',
        data: {'recklessly': 1},
      ),
      currentRoute: () => '/',
      homeRefresher: () async => refreshed += 1,
      admissionRunner: (productId) async => admissions.add(productId),
      logger: (_) {},
    );

    coordinator.start('p1');
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump();

    expect(refreshed, 1);
    expect(admissions, isEmpty);
    expect(coordinator.isRunning, isFalse);
  });
}
