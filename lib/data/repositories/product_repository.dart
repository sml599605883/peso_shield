import '../../core/network/http_client.dart';
import '../../core/network/api_response.dart';
import '../../core/network/obfuscation_helper.dart';

import '../models/product_apply_result.dart';
import '../models/product_detail.dart';

class ProductRepository {
  const ProductRepository(this._client);

  final HttpClient _client;

  Future<ApiResponse<ProductApplyResult>> applyProduct({
    required String productId,
    int apiRemind = 0,
  }) async {
    return _client.post(
      '/outsmelled/czarevnas',
      params: {
        'bombarder': productId,
        'parliament': apiRemind.toString(),
        'dibbed': ObfuscationHelper.randomParam(),
        'heaumes': ObfuscationHelper.randomParam(),
      },
      parse: (json) =>
          ProductApplyResult.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ProductDetail>> getProductDetail({
    required String productId,
  }) async {
    return _client.post(
      '/outsmelled/rackworks',
      params: {
        'bombarder': productId,
        'holloaed': ObfuscationHelper.randomParam(),
        'gamer': ObfuscationHelper.randomParam(),
        'imped': ObfuscationHelper.randomParam(),
      },
      parse: (json) => ProductDetail.fromJson(json as Map<String, dynamic>),
    );
  }
}
