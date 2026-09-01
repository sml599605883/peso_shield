import '../../core/network/http_client.dart';
import '../../core/network/api_response.dart';
import '../../core/network/obfuscation_helper.dart';

import '../models/certification_data.dart';

class CertificationRepository {
  const CertificationRepository(this._client);

  final HttpClient _client;

  Future<ApiResponse<IdentityData>> getIdentityInfo({
    required String productId,
  }) async {
    return _client.get(
      '/outsmelled/bale?bombarder=$productId&soccers=',
      parse: (json) => IdentityData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取证件类型列表（仅用于证件选择页面）
  Future<ApiResponse<IdentityTypeList>> getIdentityTypeList({
    required String productId,
  }) async {
    return _client.get(
      '/outsmelled/bale?bombarder=$productId&soccers=',
      parse: (json) => IdentityTypeList.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<String>> uploadImage({
    required String imageData,
    required String imageType,
  }) async {
    return _client.post(
      '/outsmelled/slouchinesses',
      params: {
        'attach': imageData,
        'bellings': imageType,
        'televiewer': ObfuscationHelper.randomParam(),
        'misapprehend': ObfuscationHelper.randomParam(),
        'dispersant': ObfuscationHelper.randomParam(),
        'serve': ObfuscationHelper.randomParam(),
      },
      parse: (json) {
        final mugg = json as Map<String, dynamic>?;
        return mugg?['mycelia'] as String? ?? '';
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
      params: {
        'bombarder': productId,
        ...formData,
      },
      parse: (_) => null,
    );
  }

  Future<ApiResponse<WorkInfoData>> getWorkInfo({
    required String productId,
  }) async {
    return _client.post(
      '/outsmelled/indissoluble',
      params: {
        'bombarder': productId,
        'bloodlust': ObfuscationHelper.randomParam(),
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
      },
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
}
