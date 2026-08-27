import '../../core/network/http_client.dart';
import '../../core/network/api_response.dart';
import '../../core/network/obfuscation_helper.dart';

import '../models/order_data.dart';

class OrderRepository {
  const OrderRepository(this._client);

  final HttpClient _client;

  Future<ApiResponse<String>> getOrderJumpUrl({
    required String orderNo,
    required String amount,
    required String loanTerm,
    required String termType,
  }) async {
    return _client.post(
      '/outsmelled/corporeally',
      params: {
        'superparasitism': orderNo,
        'desalting': amount,
        'copies': loanTerm,
        'accessorised': termType,
        'yammers': ObfuscationHelper.randomParam(),
        'repressurized': ObfuscationHelper.randomParam(),
        'dynein': ObfuscationHelper.randomParam(),
        'thingamabob': ObfuscationHelper.randomParam(),
      },
      parse: (json) {
        final mugg = json as Map<String, dynamic>?;
        return mugg?['mycelia'] as String? ?? '';
      },
    );
  }

  Future<ApiResponse<OrderListData>> getOrderList({
    int page = 1,
    int pageSize = 20,
  }) async {
    return _client.post(
      '/outsmelled/weakness',
      params: {
        'segregate': page.toString(),
        'interstratified': pageSize.toString(),
        'ovicide': ObfuscationHelper.randomParam(),
      },
      parse: (json) => OrderListData.fromJson(json as Map<String, dynamic>),
    );
  }
}
