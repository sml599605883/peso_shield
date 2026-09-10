import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/credit_orders_provider.dart';
import '../product/product_providers.dart';
import '../ui/toast_helper.dart';
import 'app_deep_link.dart';
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

  // ==================== 认证流程路由管理 ====================

  /// 认证流程相关的路由集合
  ///
  /// 当跳转到新的顶层认证页面时，会清除路由栈中所有这些页面
  static const Set<String> _certificationRoutes = {
    AppRoutes.identityType,
    AppRoutes.identityUpload,
    AppRoutes.identityConfirmation,
    AppRoutes.faceRecognition,
    AppRoutes.personalInformation,
    AppRoutes.workInformation,
    AppRoutes.emergencyContact,
    AppRoutes.bindCard,
  };

  /// 跳转到顶层认证页面（清除之前的认证页面）
  ///
  /// 参考 dali_cash 的 _openTopLevelCertification 机制：
  /// - 移除路由栈中所有认证流程页面，直到遇到第一个非认证页面
  /// - 然后安装新的顶层认证页面
  /// - 这样确保认证页面不会堆积，用户返回时直接回到首页/入口页
  static Future<T?> _toTopLevelCertification<T>(
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

    _log('Opening top-level certification: $routeName');
    return navigator.pushNamedAndRemoveUntil<T>(routeName, (route) {
      final name = route.settings.name;
      // 保留非认证流程的页面
      return name != null &&
          name.isNotEmpty &&
          !_certificationRoutes.contains(name);
    }, arguments: arguments);
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

  static Future<void> toIdentityConfirmation({
    required String productId,
    required String cardType,
    Map<String, dynamic>? recognizedInfo,
    int? startedAtSeconds,
  }) async {
    await toNamed<void>(
      AppRoutes.identityConfirmation,
      arguments: IdentityConfirmationPageArguments(
        productId: productId,
        cardType: cardType,
        recognizedInfo: recognizedInfo,
        startedAtSeconds: startedAtSeconds,
      ),
    );
  }

  /// 跳转到人脸识别页（顶层认证页面，清除之前的认证页面）
  static Future<void> toFaceRecognition({required String productId}) async {
    await _toTopLevelCertification<void>(
      AppRoutes.faceRecognition,
      arguments: FaceRecognitionPageArguments(productId: productId),
    );
  }

  /// 跳转到个人信息页（顶层认证页面，清除之前的认证页面）
  static Future<void> toPersonalInformation({required String productId}) async {
    await _toTopLevelCertification<void>(
      AppRoutes.personalInformation,
      arguments: PersonalInformationPageArguments(productId: productId),
    );
  }

  /// 跳转到工作信息页（顶层认证页面，清除之前的认证页面）
  static Future<void> toWorkInformation({required String productId}) async {
    await _toTopLevelCertification<void>(
      AppRoutes.workInformation,
      arguments: WorkInformationPageArguments(productId: productId),
    );
  }

  /// 跳转到紧急联系人页（顶层认证页面，清除之前的认证页面）
  static Future<void> toEmergencyContact({required String productId}) async {
    await _toTopLevelCertification<void>(
      AppRoutes.emergencyContact,
      arguments: EmergencyContactPageArguments(productId: productId),
    );
  }

  /// 跳转到绑卡页（顶层认证页面，清除之前的认证页面）
  static Future<void> toBindCard({required String productId}) async {
    await _toTopLevelCertification<void>(
      AppRoutes.bindCard,
      arguments: BindCardPageArguments(productId: productId),
    );
  }

  /// 跳转到 WebView 页面
  static Future<void> toWebView({required String url, String? title}) async {
    await toNamed<void>(
      AppRoutes.webView,
      arguments: WebViewPageArguments(url: url, title: title),
    );
  }

  /// 跳转到订单列表页面
  static Future<void> toOrderList({OrderFilter? initialFilter}) async {
    await toNamed<void>(
      AppRoutes.mineOrderList,
      arguments: initialFilter,
    );
  }

  /// 跳转到重新授信页面
  static Future<void> toRecredit({required String productId}) async {
    await toNamed<void>(
      AppRoutes.recredit,
      arguments: {'productId': productId, 'highlands': productId},
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

  /// 重新授信后的产品申请流程
  ///
  /// 当重新授信完成后，自动跳转到产品申请流程
  static Future<void> applyProductAfterRecredit(String productId) async {
    final context = _context;
    if (context == null || !context.mounted) {
      _log('Error: Context not available for applyProductAfterRecredit');
      return;
    }

    // 需要从 context 获取 WidgetRef，暂时简化处理
    // 实际应该通过 ProviderScope 或其他方式获取
    _log('applyProductAfterRecredit called with productId: $productId');
    
    // 这里应该调用产品申请流程，暂时留空待后续实现
    // TODO: 实现重新授信后的产品申请逻辑
  }

  /// 获取当前路由名称
  static String get currentRoute {
    final context = _context;
    if (context == null) return '';
    return ModalRoute.of(context)?.settings.name ?? '';
  }

  // ==================== 工具方法 ====================

  static Future<void> navigateRawTarget({
    required BuildContext context,
    required WidgetRef ref,
    required String target,
    String productId = '',
    int apiRemind = 1,
  }) async {
    final link = const AppDeepLinkParser().parse(
      target,
      arguments: {'productId': productId},
    );
    switch (link.kind) {
      case AppDeepLinkKind.webView:
        if (link.uri?.host.isEmpty ?? true) {
          ToastHelper.showError('Invalid link');
          return;
        }
        await toWebView(url: link.rawTarget);
      case AppDeepLinkKind.home:
        await toRoot();
      case AppDeepLinkKind.settings:
        await toNamed<void>(AppRoutes.settings);
      case AppDeepLinkKind.login:
        await toLogin();
      case AppDeepLinkKind.order:
        // 根据 segregate 参数跳转到对应的订单状态
        final segregate = link.segregate;
        OrderFilter? filter;
        if (segregate.isNotEmpty) {
          // 根据 segregate 值匹配对应的 OrderFilter
          filter = OrderFilter.values.cast<OrderFilter?>().firstWhere(
                (f) => f?.segregateValue == segregate,
                orElse: () => null,
              );
        }
        await toOrderList(initialFilter: filter);
      case AppDeepLinkKind.admission:
      case AppDeepLinkKind.productDetail:
        final productId = link.productId;
        if (productId.isEmpty) {
          ToastHelper.showError('Invalid link');
          return;
        }
        final flow = await ref.read(productApplicationFlowProvider.future);
        if (!context.mounted) return;
        if (link.kind == AppDeepLinkKind.admission) {
          await flow.applyProduct(
            context: context,
            productId: productId,
            apiRemind: apiRemind,
          );
        } else {
          await flow.continueProductDetailFlow(
            context: context,
            productId: productId,
          );
        }
      case AppDeepLinkKind.creditReview:
        final productId = link.productId;
        if (productId.isEmpty) {
          ToastHelper.showError('Invalid link');
          return;
        }
        await toRecredit(productId: productId);
      case AppDeepLinkKind.unsupported:
        ToastHelper.showError('Unable to open link');
    }
  }

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
