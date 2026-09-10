import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/navigation/app_routes.dart';
import '../../providers/network_provider.dart';
import '../../core/network/api_response.dart';
import '../../providers/home_provider.dart';

typedef RecreditRequest = Future<ApiResponse<Map<String, dynamic>>> Function();
typedef RecreditRouteProvider = String Function();
typedef RecreditHomeRefresher = Future<void> Function();
typedef RecreditAdmissionRunner = Future<void> Function(String productId);
typedef RecreditLogger = void Function(String message);

class RecreditPollingCoordinator {
  RecreditPollingCoordinator({
    required WidgetRef ref,
    RecreditRequest? request,
    RecreditRouteProvider? currentRoute,
    RecreditHomeRefresher? homeRefresher,
    RecreditAdmissionRunner? admissionRunner,
    RecreditLogger? logger,
    this.interval = const Duration(seconds: 10),
  })  : _ref = ref,
        _request = request ?? (() => _defaultRequest(ref)),
        _currentRoute = currentRoute ?? _defaultCurrentRoute,
        _homeRefresher = homeRefresher ?? (() => _defaultHomeRefresher(ref)),
        _admissionRunner =
            admissionRunner ?? ((productId) => _defaultAdmissionRunner(productId)),
        _logger = logger ?? _defaultLogger;

  final WidgetRef _ref;
  final RecreditRequest _request;
  final RecreditRouteProvider _currentRoute;
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
    // Check if recredit is complete (tucking == 1)
    final tucking = response.data?['tucking'];
    if (tucking == 1 || tucking == '1') {
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
    try {
      route = _currentRoute();
      productId = _productId;
    } catch (error) {
      stop();
      _logger('recredit completion failed: $error');
      return;
    }
    stop();
    try {
      if (route == AppRoutes.home || route == AppRoutes.root) {
        await _homeRefresher();
      } else if (route == AppRoutes.recredit) {
        await _admissionRunner(productId);
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

  static Future<ApiResponse<Map<String, dynamic>>> _defaultRequest(WidgetRef ref) async {
    final apiService = await ref.read(apiServiceProvider.future);
    return apiService.product.reCredit();
  }

  static String _defaultCurrentRoute() {
    return AppNavigator.currentRoute;
  }

  static Future<void> _defaultHomeRefresher(WidgetRef ref) async {
    ref.invalidate(homeDataProvider);
  }

  static Future<void> _defaultAdmissionRunner(String productId) {
    return AppNavigator.applyProductAfterRecredit(productId);
  }

  static void _defaultLogger(String message) {
    // Log recredit events if needed
  }
}
