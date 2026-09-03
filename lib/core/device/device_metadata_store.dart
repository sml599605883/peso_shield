import 'package:shared_preferences/shared_preferences.dart';

abstract interface class DeviceMetadataPersistence {
  Future<String?> readDeviceId();

  Future<String?> readDeviceName();

  Future<String?> readPhysicalSize();

  Future<void> writeDeviceId(String value);

  Future<void> writeDeviceName(String value);

  Future<void> writePhysicalSize(String value);
}

class PersistentDeviceMetadata implements DeviceMetadataPersistence {
  PersistentDeviceMetadata({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  static const deviceIdKey = 'peso_shield.device.stable_idfv';
  static const deviceNameKey = 'peso_shield.device.server_name';
  static const physicalSizeKey = 'peso_shield.device.physical_size';

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> readDeviceId() => _preferences.getString(deviceIdKey);

  @override
  Future<String?> readDeviceName() => _preferences.getString(deviceNameKey);

  @override
  Future<String?> readPhysicalSize() => _preferences.getString(physicalSizeKey);

  @override
  Future<void> writeDeviceId(String value) {
    return _preferences.setString(deviceIdKey, value);
  }

  @override
  Future<void> writeDeviceName(String value) {
    return _preferences.setString(deviceNameKey, value);
  }

  @override
  Future<void> writePhysicalSize(String value) {
    return _preferences.setString(physicalSizeKey, value);
  }
}

class DeviceMetadataStore {
  DeviceMetadataStore(this._persistence);

  factory DeviceMetadataStore.persistent() {
    return DeviceMetadataStore(PersistentDeviceMetadata());
  }

  final DeviceMetadataPersistence _persistence;

  Future<String> resolveStableDeviceId(String currentIdfv) async {
    final stored = _normalize(await _persistence.readDeviceId());
    if (stored != null) {
      return stored;
    }

    final current = _normalize(currentIdfv);
    if (current == null) {
      return '';
    }
    await _persistence.writeDeviceId(current);
    return current;
  }

  Future<String?> deviceName() async {
    return _normalize(await _persistence.readDeviceName());
  }

  Future<void> saveDeviceName(String value) async {
    final normalized = _normalize(value);
    if (normalized == null) {
      return;
    }
    await _persistence.writeDeviceName(normalized);
  }

  Future<String?> physicalSize() async {
    return _normalize(await _persistence.readPhysicalSize());
  }

  Future<void> savePhysicalSize(num? value) async {
    if (value == null || !value.isFinite || value <= 0) {
      return;
    }
    await _persistence.writePhysicalSize(value.toString());
  }

  static String? _normalize(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
