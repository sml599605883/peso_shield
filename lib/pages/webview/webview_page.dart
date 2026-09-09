import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/navigation/app_navigator.dart';
import '../../providers/report_provider.dart';
import '../../theme/app_colors.dart';
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

String? webViewCallbackScript(WebViewRequest request, WebViewResult result) {
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
        // 打开新的 WebView 页面
        await AppNavigator.toWebView(url: url);
      },
      navigateInternal: (rawTarget) async {
        // 处理内部协议跳转（例如 ph:// 协议）
        debugPrint('[WebView] Navigate internal: $rawTarget');
        // TODO: 根据实际需求实现内部路由跳转
      },
      openExternal: (uri) async {
        // 打开外部链接（使用系统浏览器或其他应用）
        try {
          if (await canLaunchUrl(uri)) {
            final launched = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
            debugPrint('[WebView] Open external: $uri - $launched');
            return launched;
          }
          debugPrint('[WebView] Cannot launch external: $uri');
          return false;
        } catch (e) {
          debugPrint('[WebView] Failed to open external: $e');
          return false;
        }
      },
      closePage: () async => AppNavigator.pop<void>(),
      jumpHome: () async {
        // 跳转到首页
        await AppNavigator.toRoot();
      },
      requestAppReview: () async {
        // TODO: 接入应用评分
        debugPrint('[WebView] Request app review');
      },
      buildPublicParams: (path) async {
        // TODO: 接入公共参数构建
        debugPrint('[WebView] Build public params: $path');
        return <String, dynamic>{};
      },
      retryOrder: (orderNo) async {
        // TODO: 接入订单重试
        debugPrint('[WebView] Retry order: $orderNo');
        return '';
      },
      reloadOrOpenWebView: _reloadOrOpenWebView,
      changeAccount: ({required productId, required orderNo}) async {
        // TODO: 接入切换账号
        debugPrint(
          '[WebView] Change account: productId=$productId, orderNo=$orderNo',
        );
      },
      showLoading: () async {
        // TODO: 接入 loading 显示
        debugPrint('[WebView] Show loading');
      },
      dismissLoading: () async {
        // TODO: 接入 loading 隐藏
        debugPrint('[WebView] Dismiss loading');
      },
      showError: (message) async {
        // TODO: 接入错误提示
        debugPrint('[WebView] Show error: $message');
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

    await _completeBack(controller: controller, canGoBack: canGoBack);
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
        body: InAppWebView(
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
      ),
    );
  }
}

class _WebViewFailure extends StatelessWidget {
  const _WebViewFailure({this.message = 'Page failed to load', this.onRetry});

  final String message;
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
            Text(
              message,
              style: const TextStyle(color: AppColors.identityText),
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
