import '../../core/network/http_client.dart';
import '../../core/network/api_response.dart';
import '../../core/network/obfuscation_helper.dart';
import '../../core/network/http_exception.dart';

class ReportRepository {
  ReportRepository(HttpClient client) : _client = (() async => client);

  ReportRepository.deferred(this._client);

  final Future<HttpClient> Function() _client;

  Future<ApiResponse<T>> _post<T>(
    String path, {
    required Map<String, dynamic> params,
    required T Function(dynamic) parse,
  }) async {
    final client = await _client();
    final response = await client.post<T>(path, params: params, parse: parse);
    if (!response.isSuccess) {
      throw HttpException(
        type: HttpFailureType.businessLogic,
        message: response.message,
        code: response.code,
      );
    }
    return response;
  }

  Future<ApiResponse<void>> reportLocation({
    required String countryCode,
    required String country,
    required String street,
    required String latitude,
    required String longitude,
    required String city,
    String? province,
  }) async {
    return _post(
      '/outsmelled/akinetic',
      params: {
        'nabob': countryCode,
        'instituter': country,
        'traceabilities': street,
        'sade': latitude,
        'salivating': longitude,
        'hostages': city,
        if (province != null) 'countertrend': province,
        'ovicide': ObfuscationHelper.randomParam(),
        'kuchens': ObfuscationHelper.randomParam(),
      },
      parse: (_) => null,
    );
  }

  Future<ApiResponse<String>> reportGoogleMarket({
    required String idfv,
    required String idfa,
  }) async {
    return _post(
      '/outsmelled/amoebaean',
      params: {
        'trouncing': idfv,
        'depriver': ObfuscationHelper.randomParam(),
        'tinged': idfa,
      },
      parse: (data) =>
          data is Map ? data['fogeyish']?.toString().trim() ?? '' : '',
    );
  }

  Future<ApiResponse<void>> reportRiskEvent({
    required String productId,
    required String sceneType,
    required String orderNo,
    required String newDeviceId,
    required String advertisingId,
    required double? longitude,
    required double? latitude,
    required String startTime,
    required String endTime,
  }) async {
    return _post(
      '/outsmelled/quinellas',
      params: {
        'polarimetric': productId,
        'furioso': sceneType,
        'cysticercosis': orderNo,
        'steamboats': newDeviceId,
        'contrastable': advertisingId,
        'salivating': longitude ?? '',
        'sade': latitude ?? '',
        'hypersecretions': startTime,
        'galoping': endTime,
        'openhearted': ObfuscationHelper.randomParam(),
      },
      parse: (_) => null,
    );
  }

  Future<ApiResponse<void>> reportDeviceInfo({
    required String encryptedData,
  }) async {
    return _post(
      '/outsmelled/dieselization',
      params: {'mugg': encryptedData},
      parse: (_) => null,
    );
  }

  Future<ApiResponse<void>> reportApplePushToken({
    required String token,
  }) async {
    return _post(
      '/outsmelled/banisters',
      params: {'amender': token},
      parse: (_) => null,
    );
  }

  Future<ApiResponse<void>> reportTrustDecisionResult({
    required String livenessId,
    required String requestId,
    required String resultCode,
    required String result,
  }) {
    return _post(
      '/outsmelled/contexts',
      params: {
        'counterargued': livenessId,
        'herrying': requestId,
        'cullay': resultCode,
        'recklessly': result,
      },
      parse: (_) => null,
    );
  }
}
