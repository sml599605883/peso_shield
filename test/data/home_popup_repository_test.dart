import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/network/http_client.dart';
import 'package:peso_shield/core/network/api_response.dart';
import 'package:peso_shield/data/repositories/app_repository.dart';

class PopupClient implements HttpClient {
  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, Object?>? params,
    required T Function(Object?) parse,
  }) async {
    expect(path, '/outsmelled/picture');
    expect(params, {'feting': 1});
    return ApiResponse(
      code: 0,
      message: 'success',
      data: parse({
        'bellings': 1,
        'abysmal': {'woodhen': '2.0', 'knucklers': 'Update'},
      }),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'home popup uses documented GET path, scene and response payload',
    () async {
      final result = await AppRepository(PopupClient()).getHomePopup();
      expect(result.isSuccess, true);
      expect(result.data.version, '2.0');
      expect(result.data.shouldShow, true);
    },
  );
}
