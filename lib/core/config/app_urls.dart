import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/network_provider.dart';

/// 应用静态页面URL配置
///
/// 管理所有H5静态页面的URL，包括客服、隐私协议等。
/// 支持动态地址切换，当备用地址下发时自动使用新的 base URL。
class AppUrls {
  AppUrls._();

  /// H5页面基础URL（默认地址）
  static const String _defaultWebBaseUrl = 'http://8.212.131.176';

  /// 获取当前有效的 Web 基础地址
  /// 
  /// 优先使用运行时动态地址，如果没有则使用默认地址
  static String webBaseUrl(WidgetRef ref) {
    return ref.watch(runtimeWebBaseProvider) ?? _defaultWebBaseUrl;
  }

  /// 在线客服页面
  static String customerService(WidgetRef ref) => 
      '${webBaseUrl(ref)}/#/Staining';

  /// 隐私协议页面
  static String privacyPolicy(WidgetRef ref) => 
      '${webBaseUrl(ref)}/#/Waterside';

  // 未来可以添加更多静态页面URL：
  // static String userAgreement(WidgetRef ref) => '${webBaseUrl(ref)}/#/Agreement';
  // static String aboutUs(WidgetRef ref) => '${webBaseUrl(ref)}/#/About';
}
