import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/device/user_session.dart';
import 'core/navigation/app_navigator.dart';
import 'pages/credit_page.dart';
import 'pages/home_page.dart';
import 'pages/mine_page.dart';
import 'providers/network_provider.dart';
import 'widgets/tab_bar/home_tab_bar.dart';

class RootTabPage extends ConsumerStatefulWidget {
  const RootTabPage({super.key});

  @override
  ConsumerState<RootTabPage> createState() => _RootTabPageState();
}

class _RootTabPageState extends ConsumerState<RootTabPage> {
  int _currentIndex = 0;

  /// 防止重复点击 Tab 时叠加打开多个登录页
  bool _openingLogin = false;

  StreamSubscription<void>? _sessionExpirySubscription;

  static const _pages = [HomePage(), CreditPage(), MinePage()];

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
      // 登录成功后才落到目标 Tab，取消登录则停留在当前 Tab
      if (ref.read(userSessionProvider).isLoggedIn) {
        setState(() => _currentIndex = index);
      }
      return;
    }

    setState(() => _currentIndex = index);
  }

  /// 会话过期后的处理：切换到首页并打开登录页
  Future<void> _openLoginAfterSessionExpiry() async {
    if (_openingLogin || !mounted) return;
    _openingLogin = true;

    // 切换到首页 Tab
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
    }

    try {
      await AppNavigator.toLogin();
    } finally {
      _openingLogin = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: HomeTabBar(
        currentIndex: _currentIndex,
        onSelected: _selectTab,
      ),
    );
  }
}
