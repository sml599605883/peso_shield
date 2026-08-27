import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/device/device_metadata_store.dart';
import 'package:peso_shield/core/device/device_name_data.dart';
import 'package:peso_shield/core/device/device_name_sync.dart';
import 'package:peso_shield/core/network/device_params.dart';

class MockDeviceParamsProvider implements DeviceParamsProvider {
  @override
  Future<DeviceParams> fetch() async {
    return const DeviceParams(
      appVersion: '1.0.0',
      modelCode: 'iPhone14,2',
      modelName: 'iPhone 13 Pro',
      deviceId: 'test-device-id',
      systemVersion: '17.0',
      advertisingId: 'test-ad-id',
    );
  }
}

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

void main() {
  group('DeviceNameSync', () {
    test('sync saves device name and physical size', () async {
      final persistence = MockDeviceMetadataPersistence();
      final metadataStore = DeviceMetadataStore(persistence);
      final paramsProvider = MockDeviceParamsProvider();

      final sync = DeviceNameSync.withLookup(
        paramsProvider: paramsProvider,
        metadataStore: metadataStore,
        lookup: (deviceCode) async {
          expect(deviceCode, 'iPhone14,2');
          return const DeviceNameData(
            deviceName: 'iPhone 13 Pro',
            screenSize: 6.1,
          );
        },
      );

      final success = await sync.sync();
      expect(success, true);

      final savedName = await metadataStore.deviceName();
      expect(savedName, 'iPhone 13 Pro');

      final savedSize = await metadataStore.physicalSize();
      expect(savedSize, '6.1');
    });

    test('sync returns false when device name is empty', () async {
      final persistence = MockDeviceMetadataPersistence();
      final metadataStore = DeviceMetadataStore(persistence);
      final paramsProvider = MockDeviceParamsProvider();

      final sync = DeviceNameSync.withLookup(
        paramsProvider: paramsProvider,
        metadataStore: metadataStore,
        lookup: (deviceCode) async {
          return const DeviceNameData(deviceName: '', screenSize: null);
        },
      );

      final success = await sync.sync();
      expect(success, false);

      final savedName = await metadataStore.deviceName();
      expect(savedName, null);
    });

    test('sync returns false when lookup returns null', () async {
      final persistence = MockDeviceMetadataPersistence();
      final metadataStore = DeviceMetadataStore(persistence);
      final paramsProvider = MockDeviceParamsProvider();

      final sync = DeviceNameSync.withLookup(
        paramsProvider: paramsProvider,
        metadataStore: metadataStore,
        lookup: (deviceCode) async => null,
      );

      final success = await sync.sync();
      expect(success, false);
    });
  });

  group('DeviceNameData', () {
    test('fromJson parses valid response', () {
      final json = {
        'mugg': {'externalizes': 'iPhone 13 Pro', 'niobic': 6.1},
      };

      final data = DeviceNameData.fromJson(json);
      expect(data.deviceName, 'iPhone 13 Pro');
      expect(data.screenSize, 6.1);
    });

    test('fromJson handles missing data', () {
      final data = DeviceNameData.fromJson({});
      expect(data.deviceName, '');
      expect(data.screenSize, null);
    });

    test('fromJson trims device name', () {
      final json = {
        'mugg': {'externalizes': '  iPhone 13 Pro  ', 'niobic': 6.1},
      };

      final data = DeviceNameData.fromJson(json);
      expect(data.deviceName, 'iPhone 13 Pro');
    });

    test('fromJson parses the unwrapped API payload', () {
      final data = DeviceNameData.fromJson({
        'externalizes': ' iPhone 15,2 ',
        'niobic': '6.7',
      });

      expect(data.deviceName, 'iPhone 15,2');
      expect(data.screenSize, 6.7);
    });
  });
}
