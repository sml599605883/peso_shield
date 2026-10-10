import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/device/user_session.dart';
import 'core/navigation/app_navigator.dart';
import 'pages/credit_page.dart';
import 'pages/home/home_popup.dart';
import 'pages/home_page.dart';
import 'pages/mine_page.dart';
import 'providers/network_provider.dart';
import 'providers/repository_provider.dart';
import 'widgets/tab_bar/home_tab_bar.dart';

class RootTabPage extends ConsumerStatefulWidget {
  const RootTabPage({super.key});

  @override
  ConsumerState<RootTabPage> createState() => _RootTabPageState();
}

class _RootTabPageState extends ConsumerState<RootTabPage> {
  int _currentIndex = 0;

  /// 已访问过的 Tab；未访问的 Tab 不构建，避免启动时就触发其接口请求
  final Set<int> _visitedTabs = {0};

  /// 防止重复点击 Tab 时叠加打开多个登录页
  bool _openingLogin = false;

  StreamSubscription<void>? _sessionExpirySubscription;

  /// 首页可游客浏览，其余 Tab 需要登录
  static bool _requiresLogin(int index) => index != 0;

  @override
  void initState() {
    super.initState();
    _sessionExpirySubscription = ref
        .read(sessionExpiryCoordinatorProvider)
        .events
        .listen((_) => _openLoginAfterSessionExpiry());
  }

  @override
  void dispose() {
    _sessionExpirySubscription?.cancel();
    super.dispose();
  }

  Future<void> _selectTab(int index) async {
    if (index == _currentIndex) return;

    if (_requiresLogin(index) && !ref.read(userSessionProvider).isLoggedIn) {
      if (_openingLogin) return;
      _openingLogin = true;
      try {
        await AppNavigator.toLogin();
      } finally {
        _openingLogin = false;
      }

      if (!mounted) return;
      return;
    }

    setState(() {
      _currentIndex = index;
      _visitedTabs.add(index);
    });
    // 进入个人中心时调用弹窗接口（feting=2），与首页弹窗保持一致。
    if (index == 2) unawaited(_loadAndShowMinePopup());
  }

  Future<void> _loadAndShowMinePopup() async {
    if (!ref.read(userSessionProvider).isLoggedIn) return;
    try {
      final repository = await ref.read(appRepositoryProvider.future);
      final response = await repository.getHomePopup(feting: 2);
      if (response.isSuccess) await HomePopup.show(response.data);
    } catch (_) {
      // 弹窗接口失败不影响个人中心功能。
    }
  }

  /// 会话过期后的处理：切换到首页并打开登录页
  Future<void> _openLoginAfterSessionExpiry() async {
    if (_openingLogin || !mounted) return;
    _openingLogin = true;

    // 切换到首页 Tab
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
    }
    _visitedTabs.add(0);

    try {
      await AppNavigator.toLogin();
    } finally {
      _openingLogin = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    ref.listen(userSessionProvider, (previous, next) {
      if (previous?.isLoggedIn != next.isLoggedIn && _currentIndex != 0) {
        setState(() => _currentIndex = 0);
      }
    });

    // 退出登录后需要登录的 Tab 不再可见，回落到首页
    if (!session.isLoggedIn && _requiresLogin(_currentIndex)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _requiresLogin(_currentIndex)) {
          setState(() {
            _currentIndex = 0;
            _visitedTabs.add(0);
          });
        }
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 仅在 Tab 首次访问后构建，避免启动时同时请求首页/订单/我的接口。
          HomePage(isActive: _currentIndex == 0),
          _visitedTabs.contains(1)
              ? CreditPage(isActive: _currentIndex == 1)
              : const SizedBox.shrink(),
          _visitedTabs.contains(2)
              ? MinePage(phone: session.phone)
              : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: HomeTabBar(
        currentIndex: _currentIndex,
        onSelected: _selectTab,
      ),
    );
  }
}
