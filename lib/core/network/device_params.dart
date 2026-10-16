import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:peso_shield/core/client/client_bridge.dart';
import 'package:peso_shield/core/device/device_metadata_store.dart';

abstract interface class DeviceParamsProvider {
  Future<DeviceParams> fetch();
}

abstract interface class IosMetadataSource {
  Future<IosMetadata> fetch();
}

class PluginIosMetadataSource implements IosMetadataSource {
  PluginIosMetadataSource({
    DeviceInfoPlugin? deviceInfo,
    Future<String> Function()? stableDeviceId,
  }) : _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
       _stableDeviceId =
           stableDeviceId ?? ClientBridge.shared.getStableDeviceId;

  final DeviceInfoPlugin _deviceInfo;
  final Future<String> Function() _stableDeviceId;

  @override
  Future<IosMetadata> fetch() async {
    if (!Platform.isIOS) {
      throw UnsupportedError('This provider only supports iOS');
    }

    final futures = await Future.wait<Object>([
      _deviceInfo.iosInfo,
      PackageInfo.fromPlatform(),
      _stableDeviceId(),
    ]);
    final iosInfo = futures[0] as IosDeviceInfo;
    final pkgInfo = futures[1] as PackageInfo;
    final model = iosInfo.utsname.machine.trim().isNotEmpty
        ? iosInfo.utsname.machine.trim()
        : iosInfo.model.trim();

    return IosMetadata(
      version: pkgInfo.version.trim(),
      model: model,
      // IDFV 卸载重装后会变，原生侧已把首次取值持久化到 Keychain；
      // 公共参数与设备上报必须取同一来源，避免两个标识对不上。
      vendorId: resolveVendorId(
        futures[2] as String,
        iosInfo.identifierForVendor ?? '',
      ),
      systemVersion: iosInfo.systemVersion.trim(),
    );
  }

  /// 原生稳定标识优先，缺失时回落到插件读取到的 IDFV。
  static String resolveVendorId(String stableDeviceId, String pluginVendorId) {
    final stable = stableDeviceId.trim();
    return stable.isNotEmpty ? stable : pluginVendorId.trim();
  }
}

class DeviceDeviceParamsProvider implements DeviceParamsProvider {
  DeviceDeviceParamsProvider({
    required this.source,
    required this.metadataStore,
  });

  final IosMetadataSource source;
  final DeviceMetadataStore metadataStore;

  @override
  Future<DeviceParams> fetch() async {
    final metadata = await source.fetch();
    final deviceId = await metadataStore.resolveStableDeviceId(
      metadata.vendorId,
    );
    // 设备名只使用服务端返回的展示名，未同步成功时保持为空；
    // 机型标识（如 iPhone14,2）仅作为查询入参，不作为公参里的设备名。
    await metadataStore.loadCachedDeviceName();

    return DeviceParams(
      appVersion: metadata.version,
      modelCode: metadata.model,
      modelName: metadataStore.cachedDeviceName,
      deviceId: deviceId,
      systemVersion: metadata.systemVersion,
      advertisingId: deviceId,
    );
  }
}

class IosMetadata {
  const IosMetadata({
    required this.version,
    required this.model,
    required this.vendorId,
    required this.systemVersion,
  });

  final String version;
  final String model;
  final String vendorId;
  final String systemVersion;
}

class DeviceParams {
  const DeviceParams({
    required this.appVersion,
    required this.modelCode,
    required this.modelName,
    required this.deviceId,
    required this.systemVersion,
    required this.advertisingId,
  });

  final String appVersion;
  final String modelCode;
  final String modelName;
  final String deviceId;
  final String systemVersion;
  final String advertisingId;
}

class StaticDeviceParamsProvider implements DeviceParamsProvider {
  const StaticDeviceParamsProvider(this.params);

  final DeviceParams params;

  @override
  Future<DeviceParams> fetch() async => params;
}
