/// 运行时动态配置
///
/// 支持从远程加载备用地址配置，包括API地址和Web页面地址
class RuntimeConfig {
  const RuntimeConfig({
    required this.apiBase,
    required this.webBase,
  });

  /// API 基础地址（例如：http://8.212.131.176/slushier）
  final String apiBase;

  /// Web 页面基础地址（例如：http://8.212.131.176）
  final String webBase;

  factory RuntimeConfig.fromJson(Map<String, dynamic> json) {
    final api = json['api'] as String?;
    final web = json['web'] as String?;

    return RuntimeConfig(
      apiBase: api ?? '',
      webBase: web ?? '',
    );
  }

  bool get isValid => apiBase.isNotEmpty && webBase.isNotEmpty;
}
