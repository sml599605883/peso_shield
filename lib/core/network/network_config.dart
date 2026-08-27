class NetworkConfig {
  const NetworkConfig({
    required this.apiBase,
    required this.signSecret,
    required this.marketIdentifier,
    this.aesKey = '',
    this.aesIv = '',
    this.connectionTimeout = const Duration(seconds: 30),
    this.requestTimeout = const Duration(seconds: 30),
    this.responseTimeout = const Duration(seconds: 30),
    this.proxyHost = '',
    this.proxyPort,
    this.allowInsecureProxy = false,
  });

  final Uri apiBase;
  final String signSecret;
  final String marketIdentifier;
  final String aesKey;
  final String aesIv;
  final Duration connectionTimeout;
  final Duration requestTimeout;
  final Duration responseTimeout;
  final String proxyHost;
  final int? proxyPort;
  final bool allowInsecureProxy;
}
