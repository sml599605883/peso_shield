import 'package:peso_shield/core/device/device_name_data.dart';
import 'package:peso_shield/core/device/device_metadata_store.dart';
import 'package:peso_shield/core/network/device_params.dart';
import 'package:peso_shield/core/network/http_client.dart';

typedef DeviceNameLookup = Future<DeviceNameData?> Function(String deviceCode);

class DeviceNameSync {
  DeviceNameSync({
    required HttpClient httpClient,
    required this.paramsProvider,
    required this.metadataStore,
  }) : _lookup = ((deviceCode) => _lookupWithApi(httpClient, deviceCode));

  const DeviceNameSync.withLookup({
    required this.paramsProvider,
    required this.metadataStore,
    required DeviceNameLookup lookup,
  }) : _lookup = lookup;

  final DeviceParamsProvider paramsProvider;
  final DeviceMetadataStore metadataStore;
  final DeviceNameLookup _lookup;

  Future<bool> sync() async {
    try {
      final params = await paramsProvider.fetch();
      final metadata = await _lookup(params.modelCode);
      if (metadata == null || metadata.deviceName.trim().isEmpty) {
        return false;
      }
      await metadataStore.saveDeviceName(metadata.deviceName);
      await metadataStore.savePhysicalSize(metadata.screenSize);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<DeviceNameData?> _lookupWithApi(
    HttpClient httpClient,
    String deviceCode,
  ) async {
    try {
      final response = await httpClient.post<DeviceNameData?>(
        '/outsmelled/lobstering',
        params: {'cymenes': deviceCode, 'chump': _generateRandomDigits(6)},
        parse: (data) {
          if (data == null) return null;
          return DeviceNameData.fromJson(data as Map<String, dynamic>);
        },
      );

      return response.data;
    } catch (e) {
      return null;
    }
  }

  static String _generateRandomDigits(int length) {
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write((DateTime.now().millisecondsSinceEpoch % 10).toString());
    }
    return buffer.toString();
  }
}
