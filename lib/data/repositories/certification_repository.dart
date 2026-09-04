import '../../core/network/http_client.dart';
import '../../core/network/api_response.dart';
import '../../core/network/obfuscation_helper.dart';

import '../models/certification_data.dart';

class CertificationRepository {
  const CertificationRepository(this._client);

  final HttpClient _client;

  /// 获取证件类型列表（用于证件选择页面）
  Future<ApiResponse<IdentityTypeList>> getIdentityTypeList({
    required String productId,
  }) async {
    return _client.get(
      '/outsmelled/bale?bombarder=$productId&soccers=${ObfuscationHelper.randomParam()}',
      parse: (json) => IdentityTypeList.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 上传证件图片或人脸图片（multipart/form-data）
  Future<ApiResponse<Map<String, dynamic>>> uploadImage({
    required String filePath,
    required String imageType,
    required String imageSource,
    String? uploadType,
    String? livenessId,
    String? license,
    String? livenessType,
    String? businessId,
  }) async {
    return _client.upload(
      '/outsmelled/slouchinesses',
      filePath: filePath,
      fileField: 'attach',
      params: {
        // 10 = face/liveness, 11 = ID card front
        'bellings': uploadType ?? '11',
        // 1 = gallery, 2 = camera. When uploadType=10, fixed as '1'.
        'televiewer': imageSource,
        // ID card type for uploadType=11, empty for uploadType=10
        'misapprehend': imageType,
        // For face upload: livenessId from trustdecision SDK
        'dispersant': livenessId ?? '',
        // For face upload: license/token from getFacePPToken
        'reconstruct': license ?? '',
        // For face upload: liveness type (7 = trustdecision)
        'serve': livenessType ?? '',
        // For face upload: business ID (type=10 && faceType=6)
        'pearlash': businessId ?? '',
      },
      parse: (json) {
        return json is Map<String, dynamic> ? json : <String, dynamic>{};
      },
    );
  }

  Future<ApiResponse<void>> saveIdentityInfo({
    required String birthDate,
    required String idNumber,
    required String fullName,
    required String type,
    required String cardType,
  }) async {
    return _client.post(
      '/outsmelled/bewails',
      params: {
        'sudaries': birthDate,
        'neighborhood': idNumber,
        'cymenes': fullName,
        'bellings': type,
        'misapprehend': cardType,
        'fumblers': ObfuscationHelper.randomParam(),
      },
      parse: (_) => null,
    );
  }

  Future<ApiResponse<PersonalInfoData>> getPersonalInfo({
    required String productId,
  }) async {
    return _client.post(
      '/outsmelled/satinwood',
      params: {
        'bombarder': productId,
        'reentrant': ObfuscationHelper.randomParam(),
      },
      parse: (json) => PersonalInfoData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<void>> savePersonalInfo({
    required String productId,
    required Map<String, dynamic> formData,
  }) async {
    return _client.post(
      '/outsmelled/wazoo',
      params: {'bombarder': productId, ...formData},
      parse: (_) => null,
    );
  }

  Future<ApiResponse<WorkInfoData>> getWorkInfo({
    required String productId,
  }) async {
    return _client.get(
      '/outsmelled/outduelled',
      params: {
        'bombarder': productId,
        'reentrant': ObfuscationHelper.randomParam(),
      },
      parse: (json) => WorkInfoData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<void>> saveWorkInfo({
    required String productId,
    required Map<String, dynamic> formData,
  }) async {
    return _client.post(
      '/outsmelled/applicants',
      params: {'bombarder': productId, ...formData},
      parse: (_) => null,
    );
  }

  Future<ApiResponse<ContactInfoData>> getContactInfo({
    required String productId,
  }) async {
    return _client.post(
      '/outsmelled/outduelled',
      params: {
        'bombarder': productId,
        'noncombatant': ObfuscationHelper.randomParam(),
      },
      parse: (json) => ContactInfoData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<void>> saveContactInfo({
    required String productId,
    required List<Map<String, dynamic>> contacts,
  }) async {
    return _client.post(
      '/outsmelled/geochronologist',
      params: {
        'bombarder': productId,
        'mugg': contacts,
        'spermatozoal': ObfuscationHelper.randomParam(),
      },
      parse: (_) => null,
    );
  }

  Future<ApiResponse<BankInfoData>> getBankInfo({
    required String productId,
  }) async {
    return _client.post(
      '/outsmelled/tremor',
      params: {
        'bombarder': productId,
        'gunfighter': ObfuscationHelper.randomParam(),
      },
      parse: (json) => BankInfoData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<void>> submitBankCard({
    required String productId,
    required String accountType,
    required String accountNumber,
    required String firstName,
    required String middleName,
    required String lastName,
  }) async {
    return _client.post(
      '/outsmelled/mycelia',
      params: {
        'bombarder': productId,
        'misapprehend': accountType,
        'barehanded': firstName,
        'unforced': middleName,
        'unenlightened': lastName,
        'flanken': accountNumber,
        'nighness': accountNumber,
        'potboilers': ObfuscationHelper.randomParam(),
      },
      parse: (_) => null,
    );
  }

  Future<ApiResponse<List<BankAccount>>> getUserBankAccounts({
    required String productId,
  }) async {
    return _client.post(
      '/outsmelled/reinters',
      params: {
        'bombarder': productId,
        'mallet': ObfuscationHelper.randomParam(),
        'snugger': ObfuscationHelper.randomParam(),
      },
      parse: (json) {
        final mugg = json as Map<String, dynamic>?;
        final applicants = mugg?['applicants'] as List<dynamic>? ?? [];
        final accounts = <BankAccount>[];
        for (final item in applicants) {
          final itemMap = item as Map<String, dynamic>;
          final list = itemMap['geochronologist'] as List<dynamic>? ?? [];
          accounts.addAll(
            list.map((e) => BankAccount.fromJson(e as Map<String, dynamic>)),
          );
        }
        return accounts;
      },
    );
  }

  Future<ApiResponse<AddressData>> getAddressInit() async {
    return _client.get(
      '/outsmelled/succedanea',
      parse: (json) => AddressData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<String>> getFacePPToken({
    required String orderNo,
    int type = 0,
  }) async {
    return _client.post(
      '/outsmelled/kestrel',
      params: {
        'superparasitism': orderNo,
        'bellings': type.toString(),
        'vermiculations': ObfuscationHelper.randomParam(),
        'unsellable': ObfuscationHelper.randomParam(),
      },
      parse: (json) {
        final mugg = json as Map<String, dynamic>?;
        return mugg?['legerity'] as String? ?? '';
      },
    );
  }

  /// 上传人脸识别结果（已废弃，使用 uploadImage 替代）
  @Deprecated('Use uploadImage with uploadType="10" instead')
  Future<ApiResponse<void>> uploadFaceLiveness({
    required String filePath,
    required String license,
    required String livenessId,
    required int livenessType,
  }) async {
    // 调用统一的 uploadImage 接口
    final response = await uploadImage(
      filePath: filePath,
      imageType: '',
      imageSource: '1',
      uploadType: '10',
      livenessId: livenessId,
      license: license,
      livenessType: '7',
    );

    return ApiResponse<void>(
      code: response.code,
      message: response.message,
      data: null,
    );
  }
}
