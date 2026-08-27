import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_service.dart';
import '../core/device/device_metadata_store.dart';
import '../core/network/device_params.dart';
import '../core/network/capture_proxy.dart';
import '../core/network/http_client.dart';
import '../core/network/network_config.dart';

final networkConfigProvider = Provider<NetworkConfig>((ref) {
  return NetworkConfig(
    apiBase: Uri.parse('http://8.212.131.176/slushier'),
    signSecret: 'cf938da7bebcecccd5563ca28d7f1fbd',
    marketIdentifier: 'ph_peso_shield_ios',
    aesKey: 'ea0deb3b9018009f',
    aesIv: '031dcd3b521e5cf6',
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

  // 等待设备参数加载完成
  final deviceParams = await ref.watch(deviceParamsProvider.future);
  final systemProxy = await ref.watch(systemProxyProvider.future);

  return HttpClient(
    config: config,
    getDeviceId: () => deviceParams.deviceId,
    getAppVersion: () => deviceParams.appVersion,
    getDeviceName: () => deviceParams.modelName,
    getOsVersion: () => deviceParams.systemVersion,
    getGpsAdId: () => deviceParams.advertisingId,
    getUserToken: () {
      return null;
    },
    onAuthExpired: () {},
    systemProxy: systemProxy,
  );
});

/// 统一的API服务提供者
final apiServiceProvider = FutureProvider<ApiService>((ref) async {
  final client = await ref.watch(httpClientProvider.future);
  return ApiService(client);
});
