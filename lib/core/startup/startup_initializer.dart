import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peso_shield/core/device/device_name_sync.dart';
import 'package:peso_shield/core/device/providers.dart';
import 'package:peso_shield/core/network/device_params.dart';

class StartupInitializer extends ConsumerWidget {
  const StartupInitializer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceParamsAsync = ref.watch(deviceParamsProvider);
    final httpClientAsync = ref.watch(httpClientProvider);
    final metadataStore = ref.watch(deviceMetadataStoreProvider);

    return deviceParamsAsync.when(
      data: (deviceParams) {
        return httpClientAsync.when(
          data: (httpClient) {
            // Trigger device name sync in the background
            Future.microtask(() async {
              try {
                await DeviceNameSync(
                  httpClient: httpClient,
                  paramsProvider: StaticDeviceParamsProvider(deviceParams),
                  metadataStore: metadataStore,
                ).sync();
              } catch (_) {
                // Silently fail, app can continue without device name
              }
            });

            return child;
          },
          loading: () => const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          ),
          error: (error, stack) => child, // Continue even if http client fails
        );
      },
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (error, stack) => child, // Continue even if device params fail
    );
  }
}
