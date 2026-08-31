import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/capture_proxy.dart';
import '../network/device_params.dart';
import '../network/http_client.dart';
import '../network/network_config.dart';
import 'device_metadata_store.dart';
import 'user_session.dart';

final networkConfigProvider = Provider<NetworkConfig>((ref) {
  return NetworkConfig(
    apiBase: Uri.parse('http://8.212.131.176/slushier/'),
    signSecret: 'cf938da7bebcecccd5563ca28d7f1fbd',
    marketIdentifier: 'ph_peso_shield_ios',
    aesKey: 'ea0deb3b9018009f',
    aesIv: '031dcd3b521e5cf6',
    proxyHost: '',
    proxyPort: null,
  );
});

final deviceMetadataStoreProvider = Provider<DeviceMetadataStore>((ref) {
  return DeviceMetadataStore.persistent();
});

final deviceParamsProvider = FutureProvider<DeviceParams>((ref) async {
  final metadataStore = ref.watch(deviceMetadataStoreProvider);
  final provider = DeviceDeviceParamsProvider(
    source: PluginIosMetadataSource(),
    metadataStore: metadataStore,
  );
  return provider.fetch();
});

final systemProxyProvider = FutureProvider<CaptureProxySettings?>((ref) async {
  return CaptureProxyDiscovery.systemSettings();
});

final httpClientProvider = FutureProvider<HttpClient>((ref) async {
  final config = ref.watch(networkConfigProvider);
  final deviceParamsAsync = ref.watch(deviceParamsProvider);
  final systemProxy = await ref.watch(systemProxyProvider.future);
  final deviceParams = deviceParamsAsync.value;

  return HttpClient(
    config: config,
    getDeviceId: () => deviceParams?.deviceId ?? '',
    getAppVersion: () => deviceParams?.appVersion ?? '',
    getDeviceName: () => deviceParams?.modelName ?? '',
    getOsVersion: () => deviceParams?.systemVersion ?? '',
    getGpsAdId: () => deviceParams?.advertisingId ?? '',
    getUserToken: () => ref.read(userSessionProvider).accessToken,
    onAuthExpired: () {
      unawaited(ref.read(userSessionProvider.notifier).clearSession());
    },
    systemProxy: systemProxy,
  );
});
