import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/device/device_metadata_store.dart';
import 'package:peso_shield/core/device/device_name_data.dart';
import 'package:peso_shield/core/device/device_name_sync.dart';
import 'package:peso_shield/core/network/device_params.dart';
import 'package:peso_shield/providers/network_provider.dart';

class _MemoryPersistence implements DeviceMetadataPersistence {
  String? deviceId;
  String? deviceName;
  String? physicalSize;

  @override
  Future<String?> readDeviceId() async => deviceId;

  @override
  Future<String?> readDeviceName() async => deviceName;

  @override
  Future<String?> readPhysicalSize() async => physicalSize;

  @override
  Future<void> writeDeviceId(String value) async => deviceId = value;

  @override
  Future<void> writeDeviceName(String value) async => deviceName = value;

  @override
  Future<void> writePhysicalSize(String value) async => physicalSize = value;
}

class _StubIosMetadataSource implements IosMetadataSource {
  @override
  Future<IosMetadata> fetch() async {
    return const IosMetadata(
      version: '1.0.0',
      model: 'iPhone14,2',
      vendorId: 'test-vendor-id',
      systemVersion: '17.0',
    );
  }
}

void main() {
  test('同步成功后公参设备名立即生效且不回落机型标识', () async {
    final store = DeviceMetadataStore(_MemoryPersistence());

    final container = ProviderContainer(
      overrides: [
        deviceMetadataStoreProvider.overrideWithValue(store),
        deviceParamsProvider.overrideWith((ref) {
          return DeviceDeviceParamsProvider(
            source: _StubIosMetadataSource(),
            metadataStore: ref.watch(deviceMetadataStoreProvider),
          ).fetch();
        }),
        systemProxyProvider.overrideWith((ref) async => null),
      ],
    );
    addTearDown(container.dispose);

    final client = await container.read(httpClientProvider.future);

    // 首次启动：本地还没有服务端设备名，公参发空而不是 iPhone14,2。
    expect(client.buildPublicParams('/outsmelled/mugg')['externalizes'], '');

    await DeviceNameSync.withLookup(
      paramsProvider: StaticDeviceParamsProvider(
        await container.read(deviceParamsProvider.future),
      ),
      metadataStore: store,
      lookup: (deviceCode) async {
        expect(deviceCode, 'iPhone14,2');
        return const DeviceNameData(
          deviceName: 'iPhone 13 Pro',
          screenSize: 6.1,
        );
      },
    ).sync();

    // 同一个客户端实例，无需重启或重建即可拿到服务端设备名。
    expect(
      client.buildPublicParams('/outsmelled/mugg')['externalizes'],
      'iPhone 13 Pro',
    );
  });
}
