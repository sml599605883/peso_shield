import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:peso_shield/core/device/device_metadata_store.dart';

abstract interface class DeviceParamsProvider {
  Future<DeviceParams> fetch();
}

abstract interface class IosMetadataSource {
  Future<IosMetadata> fetch();
}

class PluginIosMetadataSource implements IosMetadataSource {
  PluginIosMetadataSource({DeviceInfoPlugin? deviceInfo})
      : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _deviceInfo;

  @override
  Future<IosMetadata> fetch() async {
    if (!Platform.isIOS) {
      throw UnsupportedError('This provider only supports iOS');
    }

    final futures = await Future.wait<Object>([
      _deviceInfo.iosInfo,
      PackageInfo.fromPlatform(),
    ]);
    final iosInfo = futures[0] as IosDeviceInfo;
    final pkgInfo = futures[1] as PackageInfo;
    final model = iosInfo.utsname.machine.trim().isNotEmpty
        ? iosInfo.utsname.machine.trim()
        : iosInfo.model.trim();

    return IosMetadata(
      version: pkgInfo.version.trim(),
      model: model,
      vendorId: iosInfo.identifierForVendor?.trim() ?? '',
      systemVersion: iosInfo.systemVersion.trim(),
    );
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
    final deviceName = await metadataStore.deviceName() ?? metadata.model;

    return DeviceParams(
      appVersion: metadata.version,
      modelCode: metadata.model,
      modelName: deviceName,
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
