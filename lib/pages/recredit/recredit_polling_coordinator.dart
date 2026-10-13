import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/product/product_providers.dart';
import '../../providers/network_provider.dart';
import '../../core/network/api_response.dart';
import '../../providers/home_provider.dart';

typedef RecreditRequest = Future<ApiResponse<Map<String, dynamic>>> Function();
typedef RecreditRouteProvider = String Function();
typedef RecreditHomeVisibility = bool Function();
typedef RecreditHomeRefresher = Future<void> Function();
typedef RecreditAdmissionRunner = Future<void> Function(String productId);
typedef RecreditLogger = void Function(String message);

class RecreditPollingCoordinator {
  RecreditPollingCoordinator({
    required Ref ref,
    RecreditRequest? request,
    RecreditRouteProvider? currentRoute,
    RecreditHomeVisibility? isHomeVisible,
    RecreditHomeRefresher? homeRefresher,
    RecreditAdmissionRunner? admissionRunner,
    RecreditLogger? logger,
    this.interval = const Duration(seconds: 10),
  }) : _request = request ?? (() => _defaultRequest(ref)),
       _currentRoute = currentRoute ?? _defaultCurrentRoute,
       _isHomeVisible = isHomeVisible ?? (() => _defaultHomeVisibility(ref)),
       _homeRefresher = homeRefresher ?? (() => _defaultHomeRefresher(ref)),
       _admissionRunner =
           admissionRunner ??
           ((productId) => _defaultAdmissionRunner(ref, productId)),
       _logger = logger ?? _defaultLogger;

  final RecreditRequest _request;
  final RecreditRouteProvider _currentRoute;
  final RecreditHomeVisibility _isHomeVisible;
  final RecreditHomeRefresher _homeRefresher;
  final RecreditAdmissionRunner _admissionRunner;
  final RecreditLogger _logger;
  final Duration interval;

  Timer? _timer;
  String _productId = '';
  bool _isRequesting = false;
  bool _isRunning = false;
  int _generation = 0;

  bool get isRunning => _isRunning;

  void start(String productId) {
    final normalizedProductId = productId.trim();
    if (normalizedProductId.isEmpty) {
      return;
    }
    _generation += 1;
    final generation = _generation;
    _productId = normalizedProductId;
    _isRunning = true;
    _isRequesting = false;
    _timer?.cancel();
    _timer = Timer(Duration.zero, () => _poll(generation));
  }

  void stop() {
    _generation += 1;
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _isRequesting = false;
  }

  Future<void> _poll(int generation) async {
    if (!_isActive(generation) || _isRequesting) {
      return;
    }
    _isRequesting = true;
    late final ApiResponse<Map<String, dynamic>> response;
    try {
      response = await _request();
    } catch (_) {
      _scheduleRetry(generation);
      return;
    }
    if (!_isActive(generation)) {
      return;
    }
    // 重新授信完成标记：服务端在 mugg.recklessly 返回 1 表示授信成功。
    final recklessly = response.data['recklessly'];
    if (recklessly == 1 || recklessly == '1') {
      await _complete(generation);
      return;
    }
    _scheduleRetry(generation);
  }

  Future<void> _complete(int generation) async {
    if (!_isActive(generation)) {
      return;
    }
    late final String route;
    late final String productId;
    late final bool homeVisible;
    try {
      route = _currentRoute();
      productId = _productId;
      homeVisible = _isHomeVisible();
    } catch (error) {
      stop();
      _logger('recredit completion failed: $error');
      return;
    }
    stop();
    try {
      if (route == AppRoutes.recredit) {
        await _admissionRunner(productId);
      } else if (homeVisible) {
        // 只有首页 Tab（TabBar 第一项）真正展示时才刷新首页。根路由下停留在
        // 其他 Tab 时当前路由同样是根路由，不能据此当作首页。
        await _homeRefresher();
      }
    } catch (error) {
      _logger('recredit completion failed: $error');
    }
  }

  void _scheduleRetry(int generation) {
    if (!_isActive(generation)) {
      return;
    }
    _isRequesting = false;
    _timer?.cancel();
    _timer = Timer(interval, () => _poll(generation));
  }

  bool _isActive(int generation) {
    return _isRunning && generation == _generation;
  }

  static Future<ApiResponse<Map<String, dynamic>>> _defaultRequest(
    Ref ref,
  ) async {
    final apiService = await ref.read(apiServiceProvider.future);
    return apiService.product.reCredit();
  }

  static String _defaultCurrentRoute() {
    return AppNavigator.currentRoute;
  }

  static bool _defaultHomeVisibility(Ref ref) {
    return ref.read(homeDataProvider.notifier).isVisible;
  }

  static Future<void> _defaultHomeRefresher(Ref ref) async {
    // 必须走 notifier.refresh()：invalidate 只会重建 build()，而 build() 返回
    // null，会清空首页数据（大小卡直接消失）且不会重新请求首页+弹窗接口。
    await ref.read(homeDataProvider.notifier).refresh();
  }

  static Future<void> _defaultAdmissionRunner(Ref ref, String productId) async {
    final context = AppNavigator.navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return;
    }
    final flow = await ref.read(productApplicationFlowProvider.future);
    if (!context.mounted) {
      return;
    }
    await flow.applyProduct(
      context: context,
      productId: productId,
      checkLocationAccess: false,
    );
  }

  static void _defaultLogger(String message) {
    // Log recredit events if needed
  }
}

/// 重新授信轮询协调器（常驻单例）。
///
/// 与 dali_cash 一致：协调器不随重新授信页面销毁，用户返回首页后仍会继续轮询，
/// 完成时若首页 Tab 正在展示则刷新首页数据，仍在重新授信页则自动触发准入流程；
/// 停留在其他 Tab（如「我的」）时不做处理，回到首页 Tab 时由首页自行刷新。
final recreditPollingCoordinatorProvider = Provider<RecreditPollingCoordinator>(
  (ref) => RecreditPollingCoordinator(ref: ref),
);
