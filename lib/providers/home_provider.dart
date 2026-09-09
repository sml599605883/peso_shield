import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/ui/toast_helper.dart';
import '../data/models/home_data.dart';
import '../data/models/home_popup_data.dart';
import '../pages/home/home_popup.dart';
import 'repository_provider.dart';

final homeDataProvider = AsyncNotifierProvider<HomeDataNotifier, HomeData?>(
  HomeDataNotifier.new,
);

class HomeDataNotifier extends AsyncNotifier<HomeData?>
    with WidgetsBindingObserver {
  HomeDataNotifier({
    this.loadHome,
    this.loadPopup,
    this.presentPopup = HomePopup.show,
    this.showLoading = ToastHelper.showLoading,
    this.showError = ToastHelper.showError,
  });

  final Future<HomeData> Function()? loadHome;
  final Future<HomePopupData> Function()? loadPopup;
  final Future<void> Function(HomePopupData) presentPopup;
  final VoidCallback Function() showLoading;
  final void Function(String) showError;
  int _requestId = 0;
  bool _visible = false;
  bool _inactive = false;
  bool _background = false;
  bool _inactiveResumeConsumed = false;
  bool _locationRequesting = false;
  bool _ignoreLocationResume = false;
  bool _foreground = true;
  VoidCallback? _closeLoading;

  @override
  HomeData? build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      _requestId++;
      _closeLoading?.call();
      WidgetsBinding.instance.removeObserver(this);
    });
    return null;
  }

  Future<HomeData> _load() async {
    if (loadHome != null) return loadHome!();
    final repository = await ref.read(appRepositoryProvider.future);
    final response = await repository.getHomePage();
    if (!response.isSuccess) {
      throw ApiException(
        type: ApiFailureType.business,
        message: response.message,
      );
    }
    return response.data;
  }

  Future<void> refresh() async {
    final requestId = ++_requestId;
    final previous = state;
    _closeLoading?.call();
    final closeLoading = showLoading();
    _closeLoading = closeLoading;
    final homeFinished = Completer<void>();
    unawaited(_refreshPopup(requestId, homeFinished.future));
    if (!previous.hasValue) state = const AsyncLoading<HomeData?>();
    Object? failure;
    try {
      final data = await _load().timeout(const Duration(seconds: 20));
      if (ref.mounted && requestId == _requestId) state = AsyncData(data);
    } catch (error, stack) {
      if (ref.mounted && requestId == _requestId) {
        state = previous.hasValue && previous.value != null
            ? AsyncData(previous.value)
            : AsyncError<HomeData?>(error, stack);
        failure = error;
      }
    } finally {
      closeLoading();
      if (requestId == _requestId) _closeLoading = null;
      homeFinished.complete();
    }
    if (failure != null && ref.mounted && requestId == _requestId) {
      showError(switch (failure) {
        ApiException(:final message) => message,
        TimeoutException() => 'Request timed out',
        _ => 'Request failed, please try again',
      });
    }
  }

  Future<void> _refreshPopup(int requestId, Future<void> homeFinished) async {
    try {
      final popup = await _loadPopup().timeout(const Duration(seconds: 20));
      await homeFinished;
      if (ref.mounted && _visible && _foreground && requestId == _requestId) {
        await presentPopup(popup);
      }
    } catch (_) {
      // Optional popup failures must not affect home data or loading.
    }
  }

  Future<HomePopupData> _loadPopup() async {
    if (loadPopup != null) return loadPopup!();
    final repository = await ref.read(appRepositoryProvider.future);
    final response = await repository.getHomePopup();
    return response.isSuccess ? response.data : const HomePopupData();
  }

  void setVisible(bool visible) => _visible = visible;
  void beginLocationPermissionRequest() => _locationRequesting = true;
  void endLocationPermissionRequest() => _locationRequesting = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.inactive) {
      _inactive = true;
      if (_locationRequesting) _ignoreLocationResume = true;
      return;
    }
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _background = true;
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    final background = _background;
    final firstInactive = _inactive && !_inactiveResumeConsumed;
    _inactive = false;
    _background = false;
    final ignore = _ignoreLocationResume && !background;
    _ignoreLocationResume = false;
    if (ignore || (!background && !firstInactive)) return;
    if (!background) _inactiveResumeConsumed = true;
    if (_visible) unawaited(refresh());
  }
}
