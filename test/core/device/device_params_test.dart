import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/device/device_name_data.dart';
import 'package:peso_shield/core/device/device_name_sync.dart';
import 'package:peso_shield/core/device/device_metadata_store.dart';
import 'package:peso_shield/core/network/device_params.dart';

class MockDeviceMetadataPersistence implements DeviceMetadataPersistence {
  int readDeviceNameCalls = 0;
  String? _deviceId;
  String? _deviceName;
  String? _physicalSize;

  @override
  Future<String?> readDeviceId() async => _deviceId;

  @override
  Future<String?> readDeviceName() async {
    readDeviceNameCalls++;
    return _deviceName;
  }

  @override
  Future<String?> readPhysicalSize() async => _physicalSize;

  @override
  Future<void> writeDeviceId(String value) async {
    _deviceId = value;
  }

  @override
  Future<void> writeDeviceName(String value) async {
    _deviceName = value;
  }

  @override
  Future<void> writePhysicalSize(String value) async {
    _physicalSize = value;
  }
}

class MockIosMetadataSource implements IosMetadataSource {
  @override
  Future<IosMetadata> fetch() async {
    return const IosMetadata(
      version: '1.0.0',
      model: 'iPhone14,2',
      vendorId: 'test-vendor-id-12345',
      systemVersion: '17.0',
    );
  }
}

void main() {
  group('DeviceMetadataStore', () {
    test('resolveStableDeviceId stores and returns device ID', () async {
      final persistence = MockDeviceMetadataPersistence();
      final store = DeviceMetadataStore(persistence);

      final deviceId = await store.resolveStableDeviceId('new-device-id');
      expect(deviceId, 'new-device-id');

      final cached = await store.resolveStableDeviceId('different-id');
      expect(cached, 'new-device-id');
    });

    test('deviceName returns null when not set', () async {
      final persistence = MockDeviceMetadataPersistence();
      final store = DeviceMetadataStore(persistence);

      final name = await store.deviceName();
      expect(name, isNull);
    });

    test('saveDeviceName persists device name', () async {
      final persistence = MockDeviceMetadataPersistence();
      final store = DeviceMetadataStore(persistence);

      await store.saveDeviceName('iPhone 13 Pro');
      final name = await store.deviceName();
      expect(name, 'iPhone 13 Pro');
    });

    test(
      'cachedDeviceName exposes the latest name without re-reading',
      () async {
        final persistence = MockDeviceMetadataPersistence();
        final store = DeviceMetadataStore(persistence);

        await store.loadCachedDeviceName();
        expect(store.cachedDeviceName, '');

        await store.saveDeviceName('iPhone 13 Pro');

        expect(store.cachedDeviceName, 'iPhone 13 Pro');
        expect(persistence.readDeviceNameCalls, 1);
      },
    );

    test('cachedDeviceName reads storage only once', () async {
      final persistence = MockDeviceMetadataPersistence();
      await persistence.writeDeviceName('iPhone 12');
      final store = DeviceMetadataStore(persistence);

      await store.loadCachedDeviceName();
      await store.loadCachedDeviceName();

      expect(store.cachedDeviceName, 'iPhone 12');
      expect(persistence.readDeviceNameCalls, 1);
    });
  });

  group('DeviceDeviceParamsProvider', () {
    test('fetch returns correct device params', () async {
      final persistence = MockDeviceMetadataPersistence();
      final store = DeviceMetadataStore(persistence);
      final source = MockIosMetadataSource();
      final provider = DeviceDeviceParamsProvider(
        source: source,
        metadataStore: store,
      );

      final params = await provider.fetch();

      expect(params.appVersion, '1.0.0');
      expect(params.modelCode, 'iPhone14,2');
      // 机型标识只用于查询设备名，不能作为公参里的设备名。
      expect(params.modelName, '');
      expect(params.deviceId, 'test-vendor-id-12345');
      expect(params.systemVersion, '17.0');
      expect(params.advertisingId, 'test-vendor-id-12345');
    });

    test('fetch uses stored device name when available', () async {
      final persistence = MockDeviceMetadataPersistence();
      final store = DeviceMetadataStore(persistence);
      await store.saveDeviceName('My iPhone');

      final source = MockIosMetadataSource();
      final provider = DeviceDeviceParamsProvider(
        source: source,
        metadataStore: store,
      );

      final params = await provider.fetch();
      expect(params.modelName, 'My iPhone');
    });

    test(
      'fetch returns the synced device name within the same process',
      () async {
        final persistence = MockDeviceMetadataPersistence();
        final store = DeviceMetadataStore(persistence);
        final provider = DeviceDeviceParamsProvider(
          source: MockIosMetadataSource(),
          metadataStore: store,
        );

        // 首次启动：本地没有缓存，公参设备名为空而不是 iPhone14,2。
        final before = await provider.fetch();
        expect(before.modelName, '');

        final synced = await DeviceNameSync.withLookup(
          paramsProvider: StaticDeviceParamsProvider(before),
          metadataStore: store,
          lookup: (deviceCode) async {
            expect(deviceCode, 'iPhone14,2');
            return const DeviceNameData(
              deviceName: 'iPhone 13 Pro',
              screenSize: 6.1,
            );
          },
        ).sync();
        expect(synced, true);

        // 同步成功后无需重启，重新取参数即为服务端设备名。
        final after = await provider.fetch();
        expect(after.modelName, 'iPhone 13 Pro');
        expect(after.modelCode, 'iPhone14,2');
      },
    );
  });

  group('PluginIosMetadataSource.resolveVendorId', () {
    test('prefers the native keychain identifier over the plugin IDFV', () {
      expect(
        PluginIosMetadataSource.resolveVendorId(
          'keychain-device-id',
          'plugin-idfv',
        ),
        'keychain-device-id',
      );
    });

    test('falls back to the plugin IDFV when the native value is missing', () {
      expect(
        PluginIosMetadataSource.resolveVendorId('', 'plugin-idfv'),
        'plugin-idfv',
      );
      expect(
        PluginIosMetadataSource.resolveVendorId('   ', 'plugin-idfv'),
        'plugin-idfv',
      );
    });

    test('returns an empty identifier when both sources are empty', () {
      expect(PluginIosMetadataSource.resolveVendorId('', ''), '');
      expect(PluginIosMetadataSource.resolveVendorId('  ', '  '), '');
    });
  });
}
