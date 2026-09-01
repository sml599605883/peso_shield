import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../product/product_providers.dart';
import 'app_route_generator.dart';
import 'app_routes.dart';

/// 应用导航器 - 提供全局导航功能
class AppNavigator {
  AppNavigator._();

  /// 全局导航键，用于在无 context 的情况下进行导航
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// 获取当前导航器的 context
  static BuildContext? get _context => navigatorKey.currentContext;

  /// 获取当前导航器
  static NavigatorState? get _navigator => navigatorKey.currentState;

  /// 日志输出
  static void _log(String message) {
    debugPrint('[AppNavigator] $message');
  }

  // ==================== 通用导航方法 ====================

  /// 通过路由名称跳转页面
  static Future<T?> toNamed<T>(String routeName, {Object? arguments}) async {
    if (!AppRoutes.isValid(routeName)) {
      _log('Warning: Invalid route name: $routeName');
    }

    final navigator = _navigator;
    if (navigator == null) {
      _log('Error: Navigator not available');
      return null;
    }

    _log('Navigating to: $routeName');
    return navigator.pushNamed<T>(routeName, arguments: arguments);
  }

  /// 替换当前页面
  static Future<T?> toNamedAndReplace<T, TO>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) async {
    if (!AppRoutes.isValid(routeName)) {
      _log('Warning: Invalid route name: $routeName');
    }

    final navigator = _navigator;
    if (navigator == null) {
      _log('Error: Navigator not available');
      return null;
    }

    _log('Replacing with: $routeName');
    return navigator.pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  /// 清除所有页面并跳转到新页面
  static Future<T?> toNamedAndRemoveAll<T>(
    String routeName, {
    Object? arguments,
  }) async {
    if (!AppRoutes.isValid(routeName)) {
      _log('Warning: Invalid route name: $routeName');
    }

    final navigator = _navigator;
    if (navigator == null) {
      _log('Error: Navigator not available');
      return null;
    }

    _log('Removing all and navigating to: $routeName');
    return navigator.pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// 返回上一页
  static void pop<T>([T? result]) {
    final navigator = _navigator;
    if (navigator == null) {
      _log('Error: Navigator not available');
      return;
    }

    if (navigator.canPop()) {
      _log('Popping page');
      navigator.pop<T>(result);
    } else {
      _log('Warning: Cannot pop - no previous page');
    }
  }

  /// 返回到指定路由
  static void popUntil(String routeName) {
    final navigator = _navigator;
    if (navigator == null) {
      _log('Error: Navigator not available');
      return;
    }

    _log('Popping until: $routeName');
    navigator.popUntil((route) => route.settings.name == routeName);
  }

  /// 返回到根页面
  static void popToRoot() {
    final navigator = _navigator;
    if (navigator == null) {
      _log('Error: Navigator not available');
      return;
    }

    _log('Popping to root');
    navigator.popUntil((route) => route.isFirst);
  }

  /// 检查是否可以返回
  static bool canPop() {
    return _navigator?.canPop() ?? false;
  }

  // ==================== 具体页面跳转方法 ====================

  /// 跳转到登录页
  static Future<bool?> toLogin({
    Future<void> Function()? onLoginSuccess,
  }) async {
    return toNamed<bool>(
      AppRoutes.login,
      arguments: LoginPageArguments(onLoginSuccess: onLoginSuccess),
    );
  }

  /// 跳转到首页（Tab 页面）
  static Future<void> toRoot() async {
    return toNamedAndRemoveAll(AppRoutes.root);
  }

  /// 跳转到首页 Tab
  static Future<void> toHome() async {
    return toNamed(AppRoutes.home);
  }

  /// 跳转到证件类型选择页
  ///
  /// 返回用户选择的证件类型字符串，用户点击返回按钮则返回 null
  static Future<String?> toIdentityType({required String productId}) async {
    return toNamed<String>(
      AppRoutes.identityType,
      arguments: IdentityTypePageArguments(productId: productId),
    );
  }

  /// 跳转到证件上传页，接口接入前保留静态上传页面。
  static Future<void> toIdentityUpload({
    required String productId,
    required String cardType,
  }) async {
    await toNamed<void>(
      AppRoutes.identityUpload,
      arguments: IdentityUploadPageArguments(
        productId: productId,
        cardType: cardType,
      ),
    );
  }

  // ==================== 产品申请相关 ====================

  /// 执行产品申请流程（统一入口）
  ///
  /// 所有页面调用产品申请都应该使用这个方法
  ///
  /// 使用示例：
  /// ```dart
  /// await AppNavigator.applyProduct(
  ///   context: context,
  ///   ref: ref,
  ///   productId: '1',
  /// );
  /// ```
  static Future<void> applyProduct({
    required BuildContext context,
    required WidgetRef ref,
    required String productId,
    int apiRemind = 0,
  }) async {
    final flow = await ref.read(productApplicationFlowProvider.future);

    if (!context.mounted) return;

    await flow.applyProduct(
      context: context,
      productId: productId,
      apiRemind: apiRemind,
    );
  }

  // ==================== 工具方法 ====================

  /// 显示对话框
  static Future<T?> showDialogWidget<T>({
    required Widget dialog,
    bool barrierDismissible = true,
  }) async {
    final context = _context;
    if (context == null) {
      _log('Error: Context not available for dialog');
      return null;
    }

    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => dialog,
    );
  }

  /// 显示底部弹窗
  static Future<T?> showBottomSheetWidget<T>({
    required Widget sheet,
    bool isDismissible = true,
  }) async {
    final context = _context;
    if (context == null) {
      _log('Error: Context not available for bottom sheet');
      return null;
    }

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      builder: (_) => sheet,
    );
  }
}
