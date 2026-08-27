import '../../core/network/http_client.dart';
import '../../core/network/api_response.dart';
import '../../core/network/obfuscation_helper.dart';


class ReportRepository {
  const ReportRepository(this._client);

  final HttpClient _client;

  Future<ApiResponse<void>> reportLocation({
    required String countryCode,
    required String country,
    required String street,
    required double latitude,
    required double longitude,
    required String city,
    String? province,
  }) async {
    return _client.post(
      '/outsmelled/akinetic',
      params: {
        'nabob': countryCode,
        'instituter': country,
        'traceabilities': street,
        'sade': latitude.toString(),
        'salivating': longitude.toString(),
        'hostages': city,
        if (province != null) 'countertrend': province,
        'ovicide': ObfuscationHelper.randomParam(),
        'kuchens': ObfuscationHelper.randomParam(),
      },
      parse: (_) => null,
    );
  }

  Future<ApiResponse<void>> reportGoogleMarket({
    required String idfv,
    required String idfa,
  }) async {
    return _client.post(
      '/outsmelled/amoebaean',
      params: {
        'trouncing': idfv,
        'depriver': ObfuscationHelper.randomParam(),
        'tinged': idfa,
      },
      parse: (_) => null,
    );
  }

  Future<ApiResponse<void>> reportRiskEvent({
    required String productId,
    required String sceneType,
    required String orderNo,
    required String newDeviceId,
    required String advertisingId,
    required double longitude,
    required double latitude,
    required String startTime,
    required String endTime,
  }) async {
    return _client.post(
      '/outsmelled/quinellas',
      params: {
        'polarimetric': productId,
        'furioso': sceneType,
        'cysticercosis': orderNo,
        'steamboats': newDeviceId,
        'contrastable': advertisingId,
        'salivating': longitude,
        'sade': latitude,
        'hypersecretions': startTime,
        'galoping': endTime,
        'openhearted': latitude,
      },
      parse: (_) => null,
    );
  }

  Future<ApiResponse<void>> reportDeviceInfo({
    required String encryptedData,
  }) async {
    return _client.post(
      '/outsmelled/dieselization',
      params: {
        'mugg': encryptedData,
      },
      parse: (_) => null,
    );
  }

  Future<ApiResponse<void>> reportApplePushToken({
    required String token,
  }) async {
    return _client.post(
      '/outsmelled/banisters',
      params: {
        'amender': token,
      },
      parse: (_) => null,
    );
  }
}
