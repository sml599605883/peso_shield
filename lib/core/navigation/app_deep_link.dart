/// DeepLink 类型
enum AppDeepLinkKind {
  /// 首页
  home,

  /// 设置页
  settings,

  /// 登录页
  login,

  /// 订单列表
  order,

  /// 产品详情（认证流程）
  productDetail,

  /// 准入流程
  admission,

  /// 授信审核页（重新授信 loading 页）
  creditReview,

  /// WebView（HTTP/HTTPS）
  webView,

  /// 不支持的链接
  unsupported,
}

/// DeepLink 对象
class AppDeepLink {
  const AppDeepLink({
    required this.kind,
    required this.rawTarget,
    this.uri,
    this.arguments,
  });

  final AppDeepLinkKind kind;
  final String rawTarget;
  final Uri? uri;
  final Object? arguments;

  /// 获取产品 ID
  String get productId {
    // 从 query 参数获取
    final fromQuery = uri?.queryParameters['bombarder']?.trim() ?? '';
    if (fromQuery.isNotEmpty) return fromQuery;

    // 从调用方上下文获取
    if (arguments is Map) {
      final value = (arguments as Map)['productId'];
      return value?.toString().trim() ?? '';
    }
    return '';
  }

  /// 获取订单状态
  String get orderStatus {
    final fromQuery = uri?.queryParameters['status']?.trim() ?? '';
    if (fromQuery.isNotEmpty) return fromQuery;

    if (arguments is Map) {
      final value = (arguments as Map)['status'];
      return value?.toString().trim() ?? '';
    }
    return '';
  }
}

/// DeepLink 解析器
///
/// 根据 API 文档 Scheme 定义：
/// - ph://peso-shield/ios/Refineries → 首页
/// - ph://peso-shield/ios/Tweet → 设置页
/// - ph://peso-shield/ios/UndertaxGrain → 登录
/// - ph://peso-shield/ios/PermutesLinotypes → 订单列表
/// - ph://peso-shield/ios/Conscribes → 产品详情
/// - ph://peso-shield/ios/Umbrages → 重新授信
/// - ph://peso-shield/ios/Equisetum → 准入
class AppDeepLinkParser {
  const AppDeepLinkParser();

  static const _scheme = 'ph';
  static const _host = 'peso-shield';

  /// 解析 rawTarget 为 DeepLink
  AppDeepLink parse(String rawTarget, {Object? arguments}) {
    final target = rawTarget.trim();
    if (target.isEmpty) {
      return const AppDeepLink(
        kind: AppDeepLinkKind.unsupported,
        rawTarget: '',
      );
    }

    // 尝试解析为 URI
    final uri = Uri.tryParse(target);
    if (uri == null) {
      return AppDeepLink(kind: AppDeepLinkKind.unsupported, rawTarget: target);
    }

    // HTTP/HTTPS → WebView
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return AppDeepLink(
        kind: AppDeepLinkKind.webView,
        rawTarget: target,
        uri: uri,
        arguments: arguments,
      );
    }

    // ph://peso-shield/ios/xxx → 根据混淆名称判断
    if (uri.scheme == _scheme && uri.host == _host) {
      final segments = uri.pathSegments;
      if (segments.length < 2 || segments.first != 'ios') {
        return AppDeepLink(
          kind: AppDeepLinkKind.unsupported,
          rawTarget: target,
          uri: uri,
        );
      }

      // The documented path is /ios/<alias>.
      final alias = segments.last;
      final kind = _kindFromAlias(alias);

      return AppDeepLink(
        kind: kind,
        rawTarget: target,
        uri: uri,
        arguments: arguments,
      );
    }

    // 其他情况
    return AppDeepLink(
      kind: AppDeepLinkKind.unsupported,
      rawTarget: target,
      uri: uri,
      arguments: arguments,
    );
  }

  /// 根据混淆名称获取 kind
  static AppDeepLinkKind _kindFromAlias(String alias) {
    switch (alias) {
      case 'Refineries':
        return AppDeepLinkKind.home;
      case 'Tweet':
        return AppDeepLinkKind.settings;
      case 'UndertaxGrain':
        return AppDeepLinkKind.login;
      case 'PermutesLinotypes':
        return AppDeepLinkKind.order;
      case 'Conscribes':
        return AppDeepLinkKind.productDetail;
      case 'Umbrages':
        return AppDeepLinkKind.creditReview;
      case 'Equisetum':
        return AppDeepLinkKind.admission;
      default:
        return AppDeepLinkKind.unsupported;
    }
  }
}
