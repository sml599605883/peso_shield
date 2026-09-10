import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/network/http_client.dart';
import 'package:peso_shield/core/network/api_response.dart';
import 'package:peso_shield/data/repositories/order_repository.dart';
import 'package:peso_shield/data/repositories/certification_repository.dart';

class ContractClient implements HttpClient {
  String path = '';
  Map<String, Object?> params = {};
  Object? payload;
  @override
  Future<ApiResponse<T>> post<T>(
    String path, {
    required Map<String, Object?> params,
    required T Function(Object?) parse,
  }) async {
    this.path = path;
    this.params = params;
    return ApiResponse(code: 0, message: 'success', data: parse(payload));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('retry uses documented order key and redirect payload', () async {
    final client = ContractClient()
      ..payload = {'antineoplastic': 'https://example.com/order'};
    final response = await OrderRepository(
      client,
    ).retryOriginalAccount('order-1');
    expect(client.path, '/outsmelled/superparasitism');
    expect(client.params, {'cysticercosis': 'order-1'});
    expect(response.data, 'https://example.com/order');
  });
  test(
    'account list retains maintenance accounts and correct bind id',
    () async {
      final client = ContractClient()
        ..payload = {
          'applicants': [
            {
              'burlesquer': 'Bank',
              'geochronologist': [
              {
                'retraction': '555',
                'barghests': 0,
                'photoduplicated': 'BDO',
                'banisters': '123456',
                'rivieres': {'barehanded': 'First', 'unenlightened': 'Last'},
                'lookalike': 'Bank maintenance in progress',
              },
              ],
            },
          ],
        };
      final repository = CertificationRepository(client);
      final response = await repository.getUserBankAccounts(productId: '12');
      expect(client.path, '/outsmelled/reinters');
      expect(client.params['bombarder'], '12');
      expect(response.data.groups.single.title, 'Bank');
      expect(response.data.accounts.single.id, '555');
      expect(response.data.accounts.single.accountNumber, '123456');
      expect(response.data.accounts.single.accountName, 'First Last');
      client.payload = {'antineoplastic': 'https://example.com/changed'};
      final changed = await repository.changeBindCard(
        orderNo: 'order-1',
        bindId: response.data.accounts.single.id,
      );
      expect(client.path, '/outsmelled/crampfishes');
      expect(client.params['superparasitism'], 'order-1');
      expect(client.params['retraction'], '555');
      expect(changed.data, 'https://example.com/changed');
    },
  );
}
