import 'package:flutter/material.dart';
import 'package:peso_shield/core/device/session_store.dart';
import 'package:peso_shield/core/device/user_session.dart';
import 'package:peso_shield/core/navigation/app_deep_link.dart';
import 'package:peso_shield/core/navigation/app_navigator.dart';
import 'package:peso_shield/core/ui/toast_helper.dart';
import 'package:peso_shield/data/models/product_apply_result.dart';
import 'package:peso_shield/data/models/product_detail.dart';
import 'package:peso_shield/data/repositories/product_repository.dart';

/// 产品申请流程协调器
///
/// 统一管理产品准入、产品详情等流程，供各个页面复用
class ProductApplicationFlow {
  ProductApplicationFlow({
    required this.repository,
    required this.userSession,
    required this.sessionStore,
  });

  final ProductRepository repository;
  final UserSession userSession;
  final SessionStore sessionStore;
  final AppDeepLinkParser _deepLinkParser = const AppDeepLinkParser();
  bool _isProcessing = false;

  /// 执行产品申请流程
  ///
  /// [context] - 当前 context
  /// [productId] - 产品 ID
  /// [apiRemind] - 来源标识（0: 默认，1: 首页banner，2: 首页弹窗等）
  Future<void> applyProduct({
    required BuildContext context,
    required String productId,
    int apiRemind = 0,
  }) async {
    if (_isProcessing) return;

    _isProcessing = true;
    try {
      // 1. 检查登录状态
      if (!userSession.isLoggedIn) {
        final loginSuccess = await AppNavigator.toLogin();
        if (loginSuccess != true) {
          return;
        }
      }

      if (!context.mounted) return;

      // 2. 调用准入接口
      ToastHelper.showLoading();

      final response = await repository.applyProduct(
        productId: productId,
        apiRemind: apiRemind,
      );

      ToastHelper.hideLoading();

      if (!context.mounted) return;

      // 3. 检查业务状态码
      if (!response.isSuccess) {
        ToastHelper.showError(response.message);
        return;
      }

      final result = response.data;

      // 4. 根据准入结果进行处理
      await _handleAdmissionResult(context, result, productId);
    } catch (e) {
      ToastHelper.hideLoading();
      if (context.mounted) {
        ToastHelper.showError('Request failed, please try again');
      }
      debugPrint('Apply product error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// 获取产品详情
  ///
  /// [context] - 当前 context
  /// [productId] - 产品 ID
  Future<ProductDetail?> fetchProductDetail({
    required BuildContext context,
    required String productId,
  }) async {
    try {
      ToastHelper.showLoading();

      final response = await repository.getProductDetail(productId: productId);

      ToastHelper.hideLoading();

      if (!context.mounted) return null;

      if (!response.isSuccess) {
        ToastHelper.showError(response.message);
        return null;
      }

      final detail = response.data;
      // 保存产品详情相关字段到 SessionStore（参考 dali_cash）
      await sessionStore.saveProductDetail(
        prompt: detail.tips.identity,
        identitySuccessPrompt: detail.tips.identitySuccess,
        facePrompt: detail.tips.liveness,
        orderNo: detail.basicInfo.orderNo,
      );

      return detail;
    } catch (e) {
      ToastHelper.hideLoading();
      if (context.mounted) {
        ToastHelper.showError('Failed to load product details');
      }
      debugPrint('Fetch product detail error: $e');
      return null;
    }
  }

  /// Refresh product detail and dispatch the next certification step.
  Future<void> continueProductDetailFlow({
    required BuildContext context,
    required String productId,
  }) async {
    final detail = await fetchProductDetail(
      context: context,
      productId: productId,
    );
    if (detail != null && context.mounted) {
      await _continueFromDetail(context, detail, productId);
    }
  }

  /// 处理准入结果（参考 dali_cash 的 DeepLink 机制）
  Future<void> _handleAdmissionResult(
    BuildContext context,
    ProductApplyResult result,
    String productId,
  ) async {
    // 使用 DeepLink 解析器统一处理所有跳转
    if (result.jumpUrl.isNotEmpty) {
      // 有 jumpUrl，通过 DeepLink 机制统一处理
      await _navigateRawTarget(context, result.jumpUrl, productId);
      return;
    }

    if (result.statusCode == 200) {
      // statusCode == 200 且 jumpUrl 为空，继续获取产品详情
      final detail = await fetchProductDetail(
        context: context,
        productId: productId,
      );

      if (!context.mounted || detail == null) return;

      // 根据产品详情的 nextStep 继续处理
      await _continueFromDetail(context, detail, productId);
      return;
    }

    // 其他情况：准入失败
    ToastHelper.showError(
      result.message.isNotEmpty
          ? result.message
          : 'Admission failed, please try again',
    );
  }

  /// 通过 DeepLink 统一导航（参考 dali_cash）
  Future<void> _navigateRawTarget(
    BuildContext context,
    String rawTarget,
    String productId,
  ) async {
    ToastHelper.hideLoading();

    final deepLink = _deepLinkParser.parse(rawTarget);

    switch (deepLink.kind) {
      case AppDeepLinkKind.webView:
        // HTTP/HTTPS → 打开 WebView
        debugPrint('Open WebView: ${deepLink.uri}');
        // TODO: await AppNavigator.toWebView(url: rawTarget);
        break;

      case AppDeepLinkKind.creditReview:
        // ph://peso-shield/ios/Umbrages 或 gold://pocket/recredit → 打开授信审核页
        debugPrint('Open credit review: $rawTarget');
        // TODO: await AppNavigator.toCreditReview(productId: productId);
        break;

      case AppDeepLinkKind.productDetail:
        // ph://peso-shield/ios/Conscribes → 打开产品详情
        debugPrint('Open product detail: $rawTarget');
        final detail = await fetchProductDetail(
          context: context,
          productId: productId,
        );
        if (context.mounted && detail != null) {
          await _continueFromDetail(context, detail, productId);
        }
        break;

      case AppDeepLinkKind.home:
        // ph://peso-shield/ios/Refineries → 回到首页
        debugPrint('Navigate to home');
        await AppNavigator.toHome();
        break;

      case AppDeepLinkKind.settings:
        // ph://peso-shield/ios/Tweet → 跳转到设置页
        debugPrint('Navigate to settings');
        // TODO: await AppNavigator.toSettings();
        break;

      case AppDeepLinkKind.order:
        // ph://peso-shield/ios/PermutesLinotypes → 跳转到订单列表
        debugPrint('Navigate to orders');
        // TODO: await AppNavigator.toOrders();
        break;

      case AppDeepLinkKind.login:
        // ph://peso-shield/ios/UndertaxGrain → 跳转到登录页
        debugPrint('Navigate to login');
        await AppNavigator.toLogin();
        break;

      case AppDeepLinkKind.admission:
        // ph://peso-shield/ios/Equisetum → 准入流程
        debugPrint('Start admission flow: productId=$productId');
        // 递归调用准入流程（通常不会到这里）
        break;

      case AppDeepLinkKind.unsupported:
        debugPrint('Unsupported link: $rawTarget');
        ToastHelper.showError('Invalid link format');
        break;
    }
  }

  /// 根据产品详情继续处理
  Future<void> _continueFromDetail(
    BuildContext context,
    ProductDetail detail,
    String productId,
  ) async {
    // 检查是否有下一步认证项
    if (detail.nextStep.taskType.isNotEmpty) {
      // 有未完成的认证项，跳转到对应认证页
      debugPrint(
        'Navigate to certification: ${detail.nextStep.taskType} - ${detail.nextStep.title}',
      );

      // 接口返回的是混淆后的值（histolyses 字段）
      // public -> Outpulls, face -> ViscosimeterDollop, personal -> Unconcernedness
      // work -> Jammable, ext -> Pip, bank -> Reentrance
      switch (detail.nextStep.taskType) {
        case 'Outpulls':
          // 身份认证 - 选择证件类型
          final identityType = await AppNavigator.toIdentityType(
            productId: productId,
          );
          if (identityType == null) return; // 用户取消

          debugPrint('Selected identity type: $identityType');
          // TODO: 跳转到证件拍照/上传页面
          ToastHelper.showMessage('Please upload your $identityType');
          break;

        case 'ViscosimeterDollop':
          // TODO: 活体认证页
          ToastHelper.showMessage('Please complete ${detail.nextStep.title}');
          break;

        case 'Unconcernedness':
          // TODO: 个人信息页
          ToastHelper.showMessage('Please complete ${detail.nextStep.title}');
          break;

        case 'Jammable':
          // TODO: 工作信息页
          ToastHelper.showMessage('Please complete ${detail.nextStep.title}');
          break;

        case 'Pip':
          // TODO: 紧急联系人页
          ToastHelper.showMessage('Please complete ${detail.nextStep.title}');
          break;

        case 'Reentrance':
          // TODO: 绑卡页
          ToastHelper.showMessage('Please complete ${detail.nextStep.title}');
          break;

        default:
          ToastHelper.showMessage('Please complete ${detail.nextStep.title}');
      }
      return;
    }

    // 所有认证都已完成，可以进入借款确认流程
    debugPrint('All certifications completed, ready for loan confirmation');
    // TODO: 调用借款目标接口，获取确认页 URL
    // final destination = await repository.fetchLoanDestination(...);
    // await AppNavigator.toWebView(url: destination.target);
    ToastHelper.showSuccess('Certification completed');
  }
}
