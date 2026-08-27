import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/device/device_metadata_store.dart';
import 'package:peso_shield/core/network/device_params.dart';

class MockDeviceMetadataPersistence implements DeviceMetadataPersistence {
  String? _deviceId;
  String? _deviceName;
  String? _physicalSize;

  @override
  Future<String?> readDeviceId() async => _deviceId;

  @override
  Future<String?> readDeviceName() async => _deviceName;

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
      expect(params.modelName, 'iPhone14,2');
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
  });
}
