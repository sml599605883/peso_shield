import '../../core/network/api_response.dart';
import '../../core/network/http_client.dart';
import '../../core/network/obfuscation_helper.dart';
import '../models/login_response.dart';

class AuthRepository {
  const AuthRepository(this._client);

  final HttpClient _client;

  Future<ApiResponse<void>> sendVerificationCode({
    required String phone,
    required String channel,
  }) async {
    return _client.post(
      '/outsmelled/bloodlust',
      params: {
        'bloodlust': phone,
        'curricular': channel,
        'taxidermic': ObfuscationHelper.randomParam(),
      },
      parse: (_) => null,
    );
  }

  Future<ApiResponse<LoginResponse>> login({
    required String phone,
    required String code,
  }) async {
    return _client.post(
      '/outsmelled/curricular',
      params: {
        'lobstering': phone,
        'czarevnas': code,
        'chewiness': ObfuscationHelper.randomParam(),
        'conjugants': ObfuscationHelper.randomParam(),
      },
      parse: (json) => LoginResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<void>> logout() async {
    return _client.get(
      '/outsmelled/coffees',
      params: {
        'subtract': ObfuscationHelper.randomParam(),
        'kestrel': ObfuscationHelper.randomParam(),
      },
      parse: (_) => null,
    );
  }

  Future<ApiResponse<void>> deleteAccount() async {
    return _client.get(
      '/outsmelled/closets',
      params: {
        'dumbfoundering': ObfuscationHelper.randomParam(),
      },
      parse: (_) => null,
    );
  }
}

class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.userId,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['pachysandra'] as String? ?? '',
      userId: json['ventral'] as String? ?? '',
    );
  }

  final String accessToken;
  final String userId;
}
