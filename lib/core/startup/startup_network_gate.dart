import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peso_shield/core/config/runtime_config.dart';
import 'package:peso_shield/core/device/device_name_sync.dart';
import 'package:peso_shield/core/device/user_session.dart';
import 'package:peso_shield/core/network/device_params.dart';
import 'package:peso_shield/pages/network_error_page.dart';
import 'package:peso_shield/providers/network_provider.dart';
import 'package:peso_shield/providers/report_provider.dart';

class StartupNetworkGate extends StatefulWidget {
  const StartupNetworkGate({
    required this.ref,
    required this.child,
    this.retryOnResume = true,
    super.key,
  });

  final WidgetRef ref;
  final Widget child;
  final bool retryOnResume;

  @override
  State<StartupNetworkGate> createState() => _StartupNetworkGateState();
}

class _StartupNetworkGateState extends State<StartupNetworkGate>
    with WidgetsBindingObserver {
  bool _checking = false;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.retryOnResume && state == AppLifecycleState.resumed && _failed) {
      unawaited(_check());
    }
  }

  Future<void> _check() async {
    if (_checking || _ready) return;
    setState(() {
      _checking = true;
      _failed = false;
    });
    try {
      // 先恢复本地会话，保证首帧渲染时登录态已就绪，
      // 且随后创建的 HttpClient 能立即读到 token。
      await widget.ref.read(userSessionProvider.notifier).restore();

      final httpClient = await widget.ref.read(httpClientProvider.future);
      var available = await httpClient.probeTransport();
      if (!available) {
        final fallback = await _loadFallbackConfig();
        if (fallback != null && fallback.isValid) {
          // 同时更新 API 和 Web 基础地址
          widget.ref.read(runtimeApiBaseProvider.notifier).update(
            Uri.tryParse(fallback.apiBase),
          );
          widget.ref.read(runtimeWebBaseProvider.notifier).update(
            fallback.webBase,
          );
          
          widget.ref.invalidate(httpClientProvider);
          final fallbackClient = await widget.ref.read(
            httpClientProvider.future,
          );
          available = await fallbackClient.probeTransport();
        }
      }

      if (available) {
        // Sync device name in background after network is available
        try {
          final deviceParams = await widget.ref.read(
            deviceParamsProvider.future,
          );
          final metadataStore = widget.ref.read(deviceMetadataStoreProvider);

          await DeviceNameSync(
            httpClient: httpClient,
            paramsProvider: StaticDeviceParamsProvider(deviceParams),
            metadataStore: metadataStore,
          ).sync();
          // The client captures public parameters when it is created. Rebuild
          // it so subsequent requests use the newly cached server device name.
          widget.ref.invalidate(httpClientProvider);
          await widget.ref.read(httpClientProvider.future);
        } catch (_) {
          // Ignore device name sync errors, continue to app
        }

        // 初始化数据上报服务
        try {
          widget.ref.read(reportLifecycleProvider).start();
        } catch (_) {
          // 上报服务初始化失败不影响应用启动
        }
      }

      if (!mounted) return;
      setState(() {
        _checking = false;
        _ready = available;
        _failed = !available;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _failed = true;
      });
    }
  }

  Future<RuntimeConfig?> _loadFallbackConfig() async {
    const source =
        'https://raw.githubusercontent.com/ninelife442/TulongPera/refs/heads/main/spareList';
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final response = await (await client.getUrl(Uri.parse(source))).close();
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final body = await response.transform(utf8.decoder).join();
      final decoded = base64.decode(body.trim());
      final json = jsonDecode(utf8.decode(decoded));
      
      if (json is! Map<String, dynamic>) return null;
      
      final config = RuntimeConfig.fromJson(json);
      return config.isValid ? config : null;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NetworkErrorPage(onRetry: _check, checking: _checking),
    );
  }
}
