import 'dart:convert';

import '../../core/network/http_client.dart';
import '../../core/network/api_response.dart';
import '../../core/network/obfuscation_helper.dart';
import '../../core/json/json.dart';
import '../models/face_token_result.dart';

import '../models/certification_data.dart';
import '../models/emergency_contact_data.dart';
import '../models/bind_card_data.dart';
import '../models/retention_popup_data.dart';

class CertificationRepository {
  const CertificationRepository(this._client);

  final HttpClient _client;

  /// 获取证件类型列表（用于证件选择页面）
  Future<ApiResponse<IdentityTypeList>> getIdentityTypeList({
    required String productId,
  }) async {
    return _client.get(
      '/outsmelled/bale',
      params: {
        'bombarder': productId,
        'soccers': ObfuscationHelper.randomParam(),
      },
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
      parse: (_) {},
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
      params: {
        'bombarder': productId,
        ...formData,
        'pulis': ObfuscationHelper.randomParam(),
        'brakiest': ObfuscationHelper.randomParam(),
      },
      parse: (_) {},
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
      params: {
        'bombarder': productId,
        ...formData,
        'gloat': ObfuscationHelper.randomParam(),
        'shergottites': ObfuscationHelper.randomParam(),
        'dawt': ObfuscationHelper.randomParam(),
      },
      parse: (_) {},
    );
  }

  /// 获取联系人信息（第四项）
  Future<ApiResponse<EmergencyContactData>> getContactInfo({
    required String productId,
  }) async {
    return _client.get(
      '/outsmelled/bellings',
      params: {
        'bombarder': productId,
        'columniation': ObfuscationHelper.randomParam(),
      },
      parse: (json) =>
          EmergencyContactData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 保存联系人信息（第四项）
  Future<ApiResponse<void>> saveContactInfo({
    required String productId,
    required List<Map<String, String>> contacts,
  }) async {
    return _client.post(
      '/outsmelled/geochronologist',
      params: {
        'bombarder': productId,
        'mugg': jsonEncode(contacts),
        'spermatozoal': ObfuscationHelper.randomParam(),
      },
      parse: (_) {},
    );
  }

  /// 获取绑卡信息（第五项）
  Future<ApiResponse<BindCardData>> getBindCardInfo({
    required String productId,
  }) async {
    return _client.get(
      '/outsmelled/ventral',
      params: {
        'bombarder': productId,
        'openhearted': ObfuscationHelper.randomParam(),
        'revelation': ObfuscationHelper.randomParam(),
      },
      parse: (json) =>
          BindCardData.fromJson(Json(json as Map<String, dynamic>)),
    );
  }

  /// 提交绑卡（第五项）
  Future<ApiResponse<Map<String, dynamic>>> submitBindCard({
    required String productId,
    required String accountType,
    required Map<String, String> fields,
    String livenessType = '',
    String livenessId = '',
    String image = '',
    String businessId = '',
    String license = '',
  }) async {
    final params = <String, Object?>{
      'bombarder': productId,
      'misapprehend': accountType,
      ...fields,
      'serve': livenessType,
      'dispersant': livenessId,
      'attach': image,
      'pearlash': businessId,
      'reconstruct': license,
      'potboilers': ObfuscationHelper.randomParam(),
    };
    final channel = params.remove('channelCode');
    if (channel != null) params['bartering'] = channel;
    return _client.post(
      '/outsmelled/mycelia',
      params: params,
      parse: (json) =>
          json is Map<String, dynamic> ? json : <String, dynamic>{},
    );
  }

  /// 更换银行卡
  Future<ApiResponse<String>> changeBindCard({
    required String orderNo,
    required String bindId,
  }) async {
    return _client.post(
      '/outsmelled/crampfishes',
      params: {
        'superparasitism': orderNo,
        'retraction': bindId,
        'podophyllins': ObfuscationHelper.randomParam(),
      },
      parse: (json) =>
          (json as Map<String, dynamic>?)?['antineoplastic']?.toString() ?? '',
    );
  }

  /// 用户账户列表
  Future<ApiResponse<BankAccountList>> getUserBankAccounts({
    required String productId,
  }) async {
    return _client.post(
      '/outsmelled/reinters',
      params: {
        'bombarder': productId,
        'mallet': ObfuscationHelper.randomParam(),
        'snugger': ObfuscationHelper.randomParam(),
      },
      parse: (json) =>
          BankAccountList.fromJson(json as Map<String, dynamic>? ?? const {}),
    );
  }

  Future<ApiResponse<AddressData>> getAddressInit() async {
    return _client.get(
      '/outsmelled/succedanea',
      parse: (json) => AddressData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<FaceTokenResult>> getFacePPToken({
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
      parse: (json) => FaceTokenResult.fromJson(Json(json)),
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

  /// 获取认证流程返回挽留弹窗配置
  Future<ApiResponse<RetentionPopupData>> getRetentionPopup({
    required String productId,
    required String popupType,
  }) async {
    return _client.post(
      '/outsmelled/haunts',
      params: {
        'forgets': popupType,
        'polarimetric': productId,
        'rethought': ObfuscationHelper.randomParam(),
      },
      parse: (json) => RetentionPopupData.fromJson(json as Map<String, dynamic>),
    );
  }
}
