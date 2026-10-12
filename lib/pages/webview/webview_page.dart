import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/ui/toast_helper.dart';
import '../../core/device/user_session.dart';
import '../../data/models/certification_data.dart';
import '../../data/repositories/certification_repository.dart';
import '../../providers/repository_provider.dart';
import '../account_list_page.dart';
import '../bind_card_page.dart';
import '../../providers/report_provider.dart';
import '../../providers/network_provider.dart';
import '../../theme/app_colors.dart';
import '../../data/models/retention_popup_data.dart';
import '../widgets/retention_popup_dialog.dart';
import 'webview_action_coordinator.dart';
import 'webview_contract.dart';

bool isInlineWebViewScheme(String scheme) => switch (scheme.toLowerCase()) {
  'http' || 'https' || 'about' || 'data' || 'javascript' || 'file' => true,
  _ => false,
};

bool shouldCloseWebView({required bool canGoBack}) => !canGoBack;

bool shouldDisableWebViewContextMenu(TargetPlatform platform) =>
    platform == TargetPlatform.iOS;

const String iosImageLongPressPreventionScript = r'''
(() => {
  const style = document.createElement('style');
  style.textContent = `
    img {
      -webkit-touch-callout: none !important;
      -webkit-user-select: none !important;
      user-select: none !important;
    }
  `;
  (document.head || document.documentElement).appendChild(style);

  document.addEventListener('contextmenu', (event) => {
    const target = event.target;
    if (target instanceof Element && target.closest('img')) {
      event.preventDefault();
    }
  }, true);
})();
''';

UnmodifiableListView<UserScript>? webViewInitialUserScripts(
  TargetPlatform platform,
) {
  if (platform != TargetPlatform.iOS) return null;
  return UnmodifiableListView<UserScript>([
    UserScript(
      source: iosImageLongPressPreventionScript,
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      forMainFrameOnly: false,
    ),
  ]);
}

class WebViewBackHistory {
  WebViewBackHistory._();

  static bool shouldUsePageHistoryGo(WebHistory? history) {
    final currentItem = _currentItem(history);
    final previousItem = _previousItem(history);
    if (currentItem == null || previousItem == null) {
      return false;
    }
    final currentUri = Uri.tryParse(currentItem.url?.toString() ?? '');
    final previousUri = Uri.tryParse(previousItem.url?.toString() ?? '');
    if (currentUri == null || previousUri == null) {
      return false;
    }
    return currentUri.fragment.isNotEmpty &&
        previousUri.fragment.isNotEmpty &&
        currentUri.removeFragment() == previousUri.removeFragment();
  }

  static WebHistoryItem? _currentItem(WebHistory? history) {
    final currentIndex = history?.currentIndex;
    final items = history?.list;
    if (currentIndex == null ||
        items == null ||
        currentIndex < 0 ||
        currentIndex >= items.length) {
      return null;
    }
    return items[currentIndex];
  }

  static WebHistoryItem? _previousItem(WebHistory? history) {
    final currentIndex = history?.currentIndex;
    final items = history?.list;
    if (currentIndex == null ||
        items == null ||
        currentIndex <= 0 ||
        currentIndex >= items.length) {
      return null;
    }
    return items[currentIndex - 1];
  }
}

bool shouldShowWebViewLoadError({required bool? isForMainFrame}) =>
    isForMainFrame == true;

bool shouldShowWebViewLoading({required bool loading, required int progress}) =>
    loading && progress < 100;

String resolveWebViewTitle({
  required String? pageTitle,
  required String fallback,
}) {
  final value = pageTitle?.trim() ?? '';
  return value.isNotEmpty ? value : fallback.trim();
}

bool canUseWebViewController({
  required bool mounted,
  required Object? activeController,
  required Object? controller,
}) =>
    mounted &&
    activeController != null &&
    identical(activeController, controller);

String? webViewCallbackScript(
  WebViewRequest request,
  WebViewResult result,
) {
  if (!request.expectsCallback) return null;
  final payload = jsonEncode(<String, Object?>{
    'callbackId': request.callbackId,
    'data': result.data,
  });
  return 'window.${WebViewContract.handler}.handleMessage($payload);';
}

/// 打开 H5 桥接下发的 http(s) 页面（网页 → 网页跳转）。
///
/// 对齐 dali_cash / kaibigan_loan：H5 跳转到新的 H5 页面时要关闭来源 H5 页面，
/// 否则用户退出新页面（如确认用款页）时会再次回到旧 H5（推荐列表页/订单详情页）。
Future<void> openH5WebView(String url) =>
    AppNavigator.toWebView(url: url, removeWebViewPages: true);

/// 确认用款页在 H5 中的路由别名（API 文档 Scheme: confirmUrl =>
/// '/#/AmalgamatorsMarqueterie'，即待确认用款页）。
const String confirmPagePathSegment = 'AmalgamatorsMarqueterie';

/// 确认用款页返回时的挽留弹窗类型（获取挽留弹窗 forgets: 5=确认用款）。
const String confirmPageRetentionPopupType = '5';

/// 从 H5 地址中解析确认用款页的产品 ID，非确认用款页或缺少产品 ID 时返回空串。
///
/// 该页面地址形如
/// `http://host/#/AmalgamatorsMarqueterie?cointerring=1&polarimetric=3&...`，
/// 路由与查询参数都在 `#` 之后，因此别名既可能出现在路径段也可能出现在
/// fragment 中，产品 ID 需要依次从直接查询和 fragment 查询中读取。
String confirmProductIdFromUrl(String rawUrl) {
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null) return '';

  final fragment = uri.fragment.isEmpty ? null : Uri.tryParse(uri.fragment);
  final isConfirmPage =
      uri.pathSegments.contains(confirmPagePathSegment) ||
      (fragment != null
          ? fragment.pathSegments.contains(confirmPagePathSegment)
          : uri.fragment.contains(confirmPagePathSegment));
  if (!isConfirmPage) return '';

  for (final key in _confirmProductIdKeys) {
    final direct = uri.queryParameters[key]?.trim() ?? '';
    if (direct.isNotEmpty) return direct;
    final nested = fragment?.queryParameters[key]?.trim() ?? '';
    if (nested.isNotEmpty) return nested;
  }
  return '';
}

const List<String> _confirmProductIdKeys = <String>['polarimetric', 'productId'];

/// 请求确认用款页返回时的挽留弹窗数据。
///
/// 接口失败、非确认用款页或缺少产品 ID 时返回 null，由调用方放行返回。
Future<RetentionPopupData?> fetchConfirmPageRetentionPopup({
  required CertificationRepository repository,
  required String rawUrl,
}) async {
  final productId = confirmProductIdFromUrl(rawUrl);
  if (productId.isEmpty) return null;

  final response = await repository.getRetentionPopup(
    productId: productId,
    popupType: confirmPageRetentionPopupType,
  );
  return response.isSuccess ? response.data : null;
}

class WebViewBridgeGate {
  WebViewBridgeGate({required this.addHandler, required this.removeHandler});

  final void Function(Object controller) addHandler;
  final void Function(Object controller) removeHandler;
  Object? _controller;
  bool _foreground = true;
  bool _registered = false;

  void attach(Object controller) {
    detach();
    _controller = controller;
    _sync();
  }

  void setForeground(bool value) {
    if (_foreground == value) return;
    _foreground = value;
    _sync();
  }

  void detach() {
    final controller = _controller;
    if (controller != null && _registered) {
      removeHandler(controller);
    }
    _registered = false;
    _controller = null;
  }

  void _sync() {
    final controller = _controller;
    if (controller == null || _foreground == _registered) return;
    if (_foreground) {
      addHandler(controller);
      _registered = true;
    } else {
      removeHandler(controller);
      _registered = false;
    }
  }
}

class WebViewPage extends ConsumerStatefulWidget {
  const WebViewPage({super.key, required this.initialUrl, this.initialTitle});

  final String initialUrl;
  final String? initialTitle;

  @override
  ConsumerState<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends ConsumerState<WebViewPage>
    with WidgetsBindingObserver {
  InAppWebViewController? _controller;
  late final WebViewActionCoordinator _coordinator;
  late final WebViewBridgeGate _bridgeGate;
  late String _title;
  bool _loading = true;
  bool _loadFailed = false;
  bool _isLoadingRetention = false;

  Uri? get _initialUri {
    final uri = Uri.tryParse(widget.initialUrl.trim());
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return null;
    }
    return uri;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _title = resolveWebViewTitle(
      pageTitle: widget.initialTitle,
      fallback: 'Details',
    );
    _bridgeGate = WebViewBridgeGate(
      addHandler: (value) {
        (value as InAppWebViewController).addJavaScriptHandler(
          handlerName: WebViewContract.handler,
          callback: _handleBridgeCall,
        );
      },
      removeHandler: (value) {
        (value as InAppWebViewController).removeJavaScriptHandler(
          handlerName: WebViewContract.handler,
        );
      },
    );
    _coordinator = _buildCoordinator();
  }

  WebViewActionCoordinator _buildCoordinator() {
    return WebViewActionCoordinator(
      reportRisk:
          ({required productId, required orderNo, required startedAtSeconds}) {
            final reportService = ref.read(reportServiceProvider);
            return reportService.reportRisk(
              productId: productId,
              scene: '10',
              orderNo: orderNo,
              startedAtSeconds: startedAtSeconds,
            );
          },
      openWebView: (url) async {
        await openH5WebView(url);
      },
      navigateInternal: (rawTarget) async {
        await AppNavigator.navigateRawTarget(
          context: context,
          ref: ref,
          target: rawTarget.trim(),
        );
      },
      openExternal: (uri) async {
        try {
          if (await canLaunchUrl(uri)) {
            return await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
          }
          return false;
        } catch (e) {
          debugPrint('[WebView] Failed to open external: $e');
          return false;
        }
      },
      closePage: () async => AppNavigator.pop<void>(),
      jumpHome: () async {
        await AppNavigator.toRoot();
      },
      requestAppReview: () async {
        // 使用原生桥接调用应用评分
        try {
          await ref.read(clientBridgeProvider).requestAppReview();
        } catch (e) {
          debugPrint('[WebView] Request app review failed: $e');
        }
      },
      buildPublicParams: (path) async {
        try {
          final httpClient = await ref.read(httpClientProvider.future);
          return httpClient.buildPublicParams(path);
        } catch (e) {
          debugPrint('[WebView] Build public params failed: $e');
          return <String, dynamic>{};
        }
      },
      retryOrder: (orderNo) async {
        try {
          final orderRepo = await ref.read(orderRepositoryProvider.future);
          final response = await orderRepo.retryOriginalAccount(orderNo);
          return response.data;
        } catch (e) {
          debugPrint('[WebView] Retry order failed: $e');
          rethrow;
        }
      },
      reloadOrOpenWebView: _reloadOrOpenWebView,
      changeAccount: ({required productId, required orderNo}) async {
        final closeLoading = ToastHelper.showLoading();
        try {
          final certRepo = await ref.read(certificationRepositoryProvider.future);
          final response = await certRepo.getUserBankAccounts(
            productId: productId,
          );
          if (!response.isSuccess) {
            throw StateError(response.message);
          }
          // 数据请求完成后立即关闭 loading，避免遮罩覆盖账户列表/绑卡页面。
          closeLoading();

          // 如果有账户列表，跳转到账户列表页面；否则直接跳转到绑卡页面
          if (!response.data.isEmpty) {
            await _navigateToAccountList(
              productId: productId,
              orderNo: orderNo,
              accounts: response.data,
            );
          } else {
            await _navigateToBindCard(
              productId: productId,
              orderNo: orderNo,
            );
          }
        } catch (e) {
          debugPrint('[WebView] Change account failed: $e');
          rethrow;
        } finally {
          closeLoading();
        }
      },
      showLoading: () async {
        ToastHelper.showLoading();
      },
      dismissLoading: () async {
        ToastHelper.hideLoading();
      },
      showError: (message) async {
        ToastHelper.showError(message);
      },
      logger: (message) => debugPrint('[WebView] $message'),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _bridgeGate.setForeground(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    _bridgeGate.detach();
    _controller = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<dynamic> _handleBridgeCall(List<dynamic> arguments) async {
    final controller = _controller;
    if (!canUseWebViewController(
      mounted: mounted,
      activeController: _controller,
      controller: controller,
    )) {
      return const WebViewResult.failure('WebView is inactive').toJson();
    }
    final request = WebViewRequest.decode(
      arguments.isEmpty ? null : arguments.first,
    );
    final result = await _coordinator.dispatch(request);
    final script = webViewCallbackScript(request, result);
    if (script != null &&
        canUseWebViewController(
          mounted: mounted,
          activeController: _controller,
          controller: controller,
        )) {
      await controller!.evaluateJavascript(source: script);
    }
    return result.toJson();
  }

  Future<void> _handleBack() async {
    // 如果正在加载挽留弹窗，阻止返回
    if (_isLoadingRetention) return;

    final controller = _controller;
    var canGoBack = false;
    if (controller != null &&
        canUseWebViewController(
          mounted: mounted,
          activeController: _controller,
          controller: controller,
        )) {
      canGoBack = await controller.canGoBack();
      if (!canUseWebViewController(
        mounted: mounted,
        activeController: _controller,
        controller: controller,
      )) {
        return;
      }
    }

    // 检查是否需要显示挽留弹窗
    final shouldShowRetention = await _checkAndShowRetentionPopup(controller);
    if (shouldShowRetention) {
      return; // 用户选择继续，不执行返回
    }

    await _completeBack(controller: controller, canGoBack: canGoBack);
  }

  /// 检查当前 URL 是否需要展示挽留弹窗，返回 true 表示用户选择继续留下。
  ///
  /// 每次返回都会重新请求挽留弹窗配置（不做负缓存）；请求失败或接口不可用时
  /// 不阻塞返回。
  Future<bool> _checkAndShowRetentionPopup(
    InAppWebViewController? controller,
  ) async {
    // 正在请求或弹窗已展示时不再重复触发，避免连续点击返回叠加弹窗。
    if (_isLoadingRetention) return false;
    _isLoadingRetention = true;

    RetentionPopupData? popupData;
    try {
      popupData = await _loadConfirmPageRetentionPopup(controller);
    } catch (e) {
      debugPrint('[WebView] Load retention popup failed: $e');
    } finally {
      _isLoadingRetention = false;
    }

    if (!mounted || popupData == null || !popupData.shouldShow) return false;

    _isLoadingRetention = true;
    try {
      // true=继续留下，false=退出并放行返回。
      return await RetentionPopupDialog.show(context, popupData);
    } finally {
      _isLoadingRetention = false;
    }
  }

  /// 请求确认用款页的挽留弹窗配置，非确认用款页直接跳过（返回 null）。
  Future<RetentionPopupData?> _loadConfirmPageRetentionPopup(
    InAppWebViewController? controller,
  ) async {
    if (controller == null ||
        !canUseWebViewController(
          mounted: mounted,
          activeController: _controller,
          controller: controller,
        )) {
      return null;
    }

    final currentUrl = await controller.getUrl();
    if (!canUseWebViewController(
      mounted: mounted,
      activeController: _controller,
      controller: controller,
    )) {
      return null;
    }

    final urlString = currentUrl?.toString() ?? '';
    if (confirmProductIdFromUrl(urlString).isEmpty) return null;

    // 接口返回前先展示 loading，避免点击返回后页面看起来无响应。
    final closeLoading = ToastHelper.showLoading();
    try {
      final repository = await ref.read(certificationRepositoryProvider.future);
      return await fetchConfirmPageRetentionPopup(
        repository: repository,
        rawUrl: urlString,
      );
    } finally {
      closeLoading();
    }
  }

  Future<void> _completeBack({
    required InAppWebViewController? controller,
    required bool canGoBack,
  }) async {
    if (!shouldCloseWebView(canGoBack: canGoBack) && controller != null) {
      await _goBackOneHistoryEntry(controller);
      return;
    }
    if (mounted) AppNavigator.pop<void>();
  }

  Future<void> _goBackOneHistoryEntry(InAppWebViewController controller) async {
    if (!canUseWebViewController(
      mounted: mounted,
      activeController: _controller,
      controller: controller,
    )) {
      return;
    }
    final history = await controller.getCopyBackForwardList();
    if (!canUseWebViewController(
      mounted: mounted,
      activeController: _controller,
      controller: controller,
    )) {
      return;
    }
    if (WebViewBackHistory.shouldUsePageHistoryGo(history)) {
      await controller.evaluateJavascript(source: 'window.history.go(-1);');
      return;
    }
    await controller.goBack();
  }

  Future<NavigationActionPolicy> _handleNavigation(
    InAppWebViewController controller,
    NavigationAction action,
  ) async {
    final uri = action.request.url;
    if (uri == null) return NavigationActionPolicy.CANCEL;

    // 允许 WebView 内联加载的协议
    if (isInlineWebViewScheme(uri.scheme)) {
      return NavigationActionPolicy.ALLOW;
    }

    // 处理内部协议跳转（如 ph:// 等自定义协议）
    if (uri.scheme == 'ph') {
      await _coordinator.navigateInternal?.call(uri.toString());
      return NavigationActionPolicy.CANCEL;
    }

    // 处理外部链接（其他非 http/https 协议）
    await _coordinator.openExternal?.call(uri);
    return NavigationActionPolicy.CANCEL;
  }

  Future<void> _retry() async {
    final uri = _initialUri;
    final controller = _controller;
    if (uri == null || controller == null) return;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    await controller.loadUrl(urlRequest: URLRequest(url: WebUri.uri(uri)));
  }

  Future<void> _reloadOrOpenWebView(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    final controller = _controller;
    if (uri == null ||
        !canUseWebViewController(
          mounted: mounted,
          activeController: _controller,
          controller: controller,
        )) {
      return;
    }
    final currentUri = await controller!.getUrl();
    if (!canUseWebViewController(
      mounted: mounted,
      activeController: _controller,
      controller: controller,
    )) {
      return;
    }
    if (currentUri?.toString().trim() == uri.toString()) {
      await controller.reload();
      return;
    }
    await controller.loadUrl(urlRequest: URLRequest(url: WebUri.uri(uri)));
  }

  /// 登录态恢复后重新加载 H5。
  ///
  /// H5 页面在会话失效时会停留在自身的“登录态失效”视图；用户重新登录后
  /// 若仅 pop 回该页面会继续用旧状态请求并再次跳转登录。这里在检测到从未
  /// 登录变为已登录时重载页面，让 H5 用新的登录态重新初始化。
  Future<void> _reloadAfterLogin() async {
    final controller = _controller;
    if (!canUseWebViewController(
      mounted: mounted,
      activeController: _controller,
      controller: controller,
    )) {
      return;
    }
    if (mounted) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }
    await controller!.reload();
  }

  Future<void> _navigateToAccountList({
    required String productId,
    required String orderNo,
    required BankAccountList accounts,
  }) async {
    final context = this.context;
    if (!mounted) return;
    
    final result = await Navigator.of(context).push<AccountListResult>(
      MaterialPageRoute(
        builder: (_) => AccountListPage(
          groups: accounts.groups,
          // 提交时保持账户列表页可见，成功后再替换为新的 WebView，
          // 避免先短暂露出旧的订单详情页再跳转。
          onSubmit: (pageContext, bindId) =>
              _submitAccountChange(orderNo: orderNo, bindId: bindId),
        ),
      ),
    );
    
    if (!mounted || result == null) return;
    
    if (result is AccountListAddPaymentMethod) {
      // 用户选择添加新支付方式
      await _navigateToBindCard(productId: productId, orderNo: orderNo);
    }
  }

  Future<void> _navigateToBindCard({
    required String productId,
    required String orderNo,
  }) async {
    final context = this.context;
    if (!mounted) return;
    
    final certRepo = await ref.read(certificationRepositoryProvider.future);
    final resultUrl = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (pageContext) => BindCardPage(
          productId: productId,
          orderNo: orderNo,
          isAccountChange: true,
          changeAccount: (order, bindId) async {
            final response = await certRepo.changeBindCard(
              orderNo: order,
              bindId: bindId,
            );
            if (!response.isSuccess || response.data.trim().isEmpty) {
              throw StateError(response.message);
            }
            if (pageContext.mounted) {
              Navigator.pop(pageContext, response.data);
            }
            return response.data;
          },
        ),
      ),
    );
    
    if (!mounted || resultUrl == null || resultUrl.trim().isEmpty) return;
    
    // 绑卡页面已经pop了，现在需要替换当前WebView
    await _replaceCurrentWebView(resultUrl.trim());
  }

  Future<void> _submitAccountChange({
    required String orderNo,
    required String bindId,
  }) async {
    final cancelFunc = ToastHelper.showLoading();
    try {
      final certRepo = await ref.read(certificationRepositoryProvider.future);
      final response = await certRepo.changeBindCard(
        orderNo: orderNo,
        bindId: bindId,
      );
      
      if (!response.isSuccess || response.data.trim().isEmpty) {
        throw StateError(
          response.message.isNotEmpty
              ? response.message
              : 'Unable to change account, please try again',
        );
      }
      
      cancelFunc();
      
      if (!mounted) return;
      
      // 账户列表页仍在栈顶，这里将其替换为新的 WebView。
      await _replaceCurrentWebView(response.data.trim());
    } catch (e) {
      cancelFunc();
      ToastHelper.showError(
        e is StateError ? e.message : 'Unable to change account, please try again',
      );
    }
  }

  Future<void> _replaceCurrentWebView(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      debugPrint('[WebView] Invalid result URL: $url');
      return;
    }
    
    if (!mounted) return;
    // 清空当前业务流程页面（账户列表/旧订单详情 WebView），直接以新的
    // WebView 作为终点，避免退出时回退到旧的订单详情页。
    await AppNavigator.toWebViewResettingFlow(url: url);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userSessionProvider, (previous, next) {
      final wasLoggedIn = previous?.isLoggedIn ?? false;
      if (!wasLoggedIn && next.isLoggedIn) {
        unawaited(_reloadAfterLogin());
      }
    });
    final uri = _initialUri;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_handleBack());
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.black,
          elevation: 0,
          title: Text(_title),
          leading: IconButton(
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri.uri(uri!)),
              initialUserScripts: webViewInitialUserScripts(defaultTargetPlatform),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                useShouldOverrideUrlLoading: true,
                useHybridComposition: true,
                isInspectable: kDebugMode,
                disableContextMenu: shouldDisableWebViewContextMenu(
                  defaultTargetPlatform,
                ),
                allowsLinkPreview: !shouldDisableWebViewContextMenu(
                  defaultTargetPlatform,
                ),
                mixedContentMode: MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
              ),
              onWebViewCreated: (controller) {
                _controller = controller;
                _bridgeGate.attach(controller);
              },
              shouldOverrideUrlLoading: _handleNavigation,
              onPermissionRequest: (controller, request) async {
                return PermissionResponse(
                  resources: request.resources,
                  action: PermissionResponseAction.DENY,
                );
              },
              onLoadStart: (controller, url) {
                if (mounted) {
                  setState(() {
                    _loading = true;
                    _loadFailed = false;
                  });
                }
              },
              onLoadStop: (controller, url) async {
                if (mounted) {
                  final title = await controller.getTitle();
                  if (!mounted) return;
                  setState(() {
                    _loading = false;
                    _title = resolveWebViewTitle(
                      pageTitle: title,
                      fallback: _title,
                    );
                  });
                }
              },
              onProgressChanged: (controller, progress) {
                if (mounted) {
                  setState(() {
                    _loading = progress < 100;
                  });
                }
              },
              onReceivedError: (controller, request, error) {
                if (mounted &&
                    shouldShowWebViewLoadError(
                      isForMainFrame: request.isForMainFrame,
                    )) {
                  setState(() {
                    _loading = false;
                    _loadFailed = true;
                  });
                }
              },
              onTitleChanged: (controller, title) {
                final value = title?.trim() ?? '';
                if (mounted && value.isNotEmpty) {
                  setState(() => _title = value);
                }
              },
            ),
            if (_loadFailed)
              _WebViewFailure(onRetry: _retry)
            else if (shouldShowWebViewLoading(loading: _loading, progress: 100))
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.coral),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WebViewFailure extends StatelessWidget {
  const _WebViewFailure({this.onRetry});

  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.coral,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Page failed to load',
              style: TextStyle(color: AppColors.identityText),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => unawaited(onRetry!()),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
