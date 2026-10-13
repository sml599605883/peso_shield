import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/network/api_response.dart';
import 'package:peso_shield/core/navigation/app_routes.dart';
import 'package:peso_shield/pages/recredit/recredit_polling_coordinator.dart';
import 'package:peso_shield/providers/home_provider.dart';

/// 从真实的 ProviderContainer 中取一个 [Ref]，用于构造协调器。
final _refProvider = Provider<Ref>((ref) => ref);

/// 记录默认首页刷新器是否走 notifier.refresh()（而不是 invalidate 清空首页）。
class _SpyHomeNotifier extends HomeDataNotifier {
  int refreshCount = 0;

  @override
  Future<void> refresh() async {
    refreshCount += 1;
  }
}

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

  testWidgets('停留在首页 Tab 时完成授信只刷新首页、不触发准入', (tester) async {
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
      isHomeVisible: () => true,
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

  testWidgets('停留在根路由下的其他 Tab 时完成授信不刷新首页也不准入', (tester) async {
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
      // 根路由下选中「我的」Tab：路由名仍是根路由，但当前展示的不是首页。
      currentRoute: () => AppRoutes.root,
      isHomeVisible: () => false,
      homeRefresher: () async => refreshed += 1,
      admissionRunner: (productId) async => admissions.add(productId),
      logger: (_) {},
    );

    coordinator.start('p1');
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump();

    expect(refreshed, 0);
    expect(admissions, isEmpty);
    expect(coordinator.isRunning, isFalse);
  });

  testWidgets('默认首页刷新走 notifier.refresh 而不是 invalidate', (tester) async {
    final container = ProviderContainer(
      overrides: [homeDataProvider.overrideWith(_SpyHomeNotifier.new)],
    );
    addTearDown(container.dispose);
    final spy = container.read(homeDataProvider.notifier) as _SpyHomeNotifier;
    spy.setVisible(true);
    final coordinator = RecreditPollingCoordinator(
      ref: container.read(_refProvider),
      interval: const Duration(milliseconds: 5),
      request: () async => const ApiResponse<Map<String, dynamic>>(
        code: 0,
        message: 'success',
        data: {'recklessly': 1},
      ),
      currentRoute: () => AppRoutes.root,
      logger: (_) {},
    );

    coordinator.start('p1');
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump();

    // invalidate 会重建 build() 返回 null，导致首页大小卡直接消失且不请求
    // 首页+弹窗接口；这里必须调用 refresh() 重新拉取数据。
    expect(spy.refreshCount, 1);
    expect(coordinator.isRunning, isFalse);
  });

  testWidgets('默认可见性取自首页可见状态：首页不在前台时不刷新', (tester) async {
    final container = ProviderContainer(
      overrides: [homeDataProvider.overrideWith(_SpyHomeNotifier.new)],
    );
    addTearDown(container.dispose);
    final spy = container.read(homeDataProvider.notifier) as _SpyHomeNotifier;
    final coordinator = RecreditPollingCoordinator(
      ref: container.read(_refProvider),
      interval: const Duration(milliseconds: 5),
      request: () async => const ApiResponse<Map<String, dynamic>>(
        code: 0,
        message: 'success',
        data: {'recklessly': 1},
      ),
      currentRoute: () => AppRoutes.root,
      logger: (_) {},
    );

    coordinator.start('p1');
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump();

    expect(spy.isVisible, isFalse);
    expect(spy.refreshCount, 0);
    expect(coordinator.isRunning, isFalse);
  });
}
