import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peso_shield/core/device/device_name_sync.dart';
import 'package:peso_shield/core/network/device_params.dart';
import 'package:peso_shield/pages/network_error_page.dart';
import 'package:peso_shield/providers/network_provider.dart';

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
      final httpClient = await widget.ref.read(httpClientProvider.future);
      final available = await httpClient.probeTransport();

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

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NetworkErrorPage(onRetry: _check, checking: _checking),
    );
  }
}
