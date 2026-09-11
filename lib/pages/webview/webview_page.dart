import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/navigation/app_deep_link.dart';
import '../../core/ui/toast_helper.dart';
import '../../data/models/certification_data.dart';
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
  RetentionPopupData? _retentionData;
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
        await AppNavigator.toWebView(url: url);
      },
      navigateInternal: (rawTarget) async {
        final target = AppDeepLinkParser().parse(rawTarget.trim());
        await _handleDeepLink(target);
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
          if (defaultTargetPlatform == TargetPlatform.iOS) {
            await MethodChannel('peso_shield/client_bridge')
                .invokeMethod<void>('requestAppReview');
          }
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
        try {
          final certRepo = await ref.read(certificationRepositoryProvider.future);
          final response = await certRepo.getUserBankAccounts(
            productId: productId,
          );
          if (!response.isSuccess) {
            throw StateError(response.message);
          }
          
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

  Future<void> _handleDeepLink(AppDeepLink target) async {
    switch (target.kind) {
      case AppDeepLinkKind.webView:
        if (target.uri != null) {
          await AppNavigator.toWebView(url: target.uri.toString());
        }
      case AppDeepLinkKind.home:
        await AppNavigator.toRoot();
      case AppDeepLinkKind.creditReview:
        // 授信审核页
        debugPrint('[WebView] Navigate to credit review');
      case AppDeepLinkKind.admission:
        // 准入流程
        debugPrint('[WebView] Navigate to admission');
      case AppDeepLinkKind.login:
        await AppNavigator.toLogin();
      case AppDeepLinkKind.order:
        // 订单列表
        debugPrint('[WebView] Navigate to order list');
      case AppDeepLinkKind.productDetail:
        // 产品详情
        debugPrint('[WebView] Navigate to product detail');
      case AppDeepLinkKind.settings:
        // 设置页
        debugPrint('[WebView] Navigate to settings');
      case AppDeepLinkKind.unsupported:
        debugPrint('[WebView] Unsupported deep link: ${target.rawTarget}');
    }
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

  /// 检查当前URL是否需要显示挽留弹窗，返回true表示用户选择继续留下
  Future<bool> _checkAndShowRetentionPopup(
    InAppWebViewController? controller,
  ) async {
    // 如果已经加载过挽留数据且不需要展示，直接返回false（允许返回）
    if (_retentionData != null && !_retentionData!.shouldShow) {
      return false;
    }

    // 获取当前URL
    if (controller == null ||
        !canUseWebViewController(
          mounted: mounted,
          activeController: _controller,
          controller: controller,
        )) {
      return false;
    }

    final currentUrl = await controller.getUrl();
    if (!canUseWebViewController(
      mounted: mounted,
      activeController: _controller,
      controller: controller,
    )) {
      return false;
    }

    final urlString = currentUrl?.toString() ?? '';
    
    // 检查URL是否包含 AmalgamatorsMarqueterie
    if (!urlString.contains('AmalgamatorsMarqueterie')) {
      return false;
    }

    // 首次返回时请求挽留弹窗配置
    if (_retentionData == null) {
      setState(() => _isLoadingRetention = true);
      try {
        // 从URL中提取productId参数
        final uri = Uri.tryParse(urlString);
        final productId = uri?.queryParameters['polarimetric'] ?? 
                         uri?.queryParameters['productId'] ?? '';
        
        if (productId.isEmpty) {
          // 没有productId，不展示挽留弹窗
          return false;
        }

        final repository = await ref.read(certificationRepositoryProvider.future);
        final response = await repository.getRetentionPopup(
          productId: productId,
          popupType: '1', // 1=认证流程WebView页面
        );

        if (response.isSuccess && mounted) {
          _retentionData = response.data;
          
          // 如果需要展示挽留弹窗
          if (_retentionData!.shouldShow) {
            final shouldStay = await RetentionPopupDialog.show(
              context,
              _retentionData!,
            );
            setState(() => _isLoadingRetention = false);
            return shouldStay; // true=留下, false=离开
          }
        }
      } catch (e) {
        debugPrint('[WebView] Load retention popup failed: $e');
        // 请求失败，允许返回
      } finally {
        if (mounted) {
          setState(() => _isLoadingRetention = false);
        }
      }
    }

    return false;
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

  Future<void> _navigateToAccountList({
    required String productId,
    required String orderNo,
    required BankAccountList accounts,
  }) async {
    final context = this.context;
    if (!mounted) return;
    
    final result = await Navigator.of(context).push<AccountListResult>(
      MaterialPageRoute(
        builder: (_) => AccountListPage(groups: accounts.groups),
      ),
    );
    
    if (!mounted || result == null) return;
    
    if (result is AccountListAddPaymentMethod) {
      // 用户选择添加新支付方式
      await _navigateToBindCard(productId: productId, orderNo: orderNo);
      return;
    }
    
    if (result is AccountListSelection) {
      // 用户选择了账户，账户列表页面已经pop了，现在提交并替换WebView
      await _submitAccountChange(orderNo: orderNo, bindId: result.bindId);
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
        throw StateError(response.message);
      }
      
      cancelFunc();
      
      if (!mounted) return;
      
      // 替换当前WebView为新的WebView
      await _replaceCurrentWebView(response.data.trim());
    } catch (e) {
      cancelFunc();
      ToastHelper.showError(e.toString());
      rethrow;
    }
  }

  Future<void> _replaceCurrentWebView(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      debugPrint('[WebView] Invalid result URL: $url');
      return;
    }
    
    if (!mounted) return;
    final context = this.context;
    
    // 使用pushReplacement替换当前WebView
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WebViewPage(initialUrl: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
