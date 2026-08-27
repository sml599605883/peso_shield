import '../../core/network/http_client.dart';
import '../../core/network/api_response.dart';
import '../../core/network/obfuscation_helper.dart';

import '../models/home_data.dart';

class AppRepository {
  const AppRepository(this._client);

  final HttpClient _client;

  Future<ApiResponse<HomeData>> getHomePage() async {
    return _client.get(
      '/outsmelled/mugg?hierarchies=&borohydrides=',
      parse: (json) => HomeData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<void>> reportAppEvent({
    required String eventType,
    required String eventData,
  }) async {
    return _client.post(
      '/outsmelled/conjugants',
      params: {
        'dissertational': eventType,
        'priggisms': eventData,
        'rewet': ObfuscationHelper.randomParam(),
      },
      parse: (_) => null,
    );
  }
}
