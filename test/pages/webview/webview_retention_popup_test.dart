import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/network/api_response.dart';
import 'package:peso_shield/data/models/retention_popup_data.dart';
import 'package:peso_shield/data/repositories/certification_repository.dart';
import 'package:peso_shield/pages/webview/webview_page.dart';

/// 真实下发的确认用款页地址（查询参数在 `#` 之后）。
const String _confirmUrl =
    'http://8.212.131.176/#/AmalgamatorsMarqueterie?cointerring=1'
    '&polarimetric=3&changeAccount=1&cysticercosis=1662026101216094540294210';

class _SpyCertificationRepository implements CertificationRepository {
  _SpyCertificationRepository({this.response = _success});

  static const ApiResponse<RetentionPopupData> _success =
      ApiResponse<RetentionPopupData>(
        code: 0,
        message: 'ok',
        data: RetentionPopupData(imageUrl: 'https://example.com/popup.png'),
      );

  ApiResponse<RetentionPopupData> response;
  int calls = 0;
  String? lastProductId;
  String? lastPopupType;

  @override
  Future<ApiResponse<RetentionPopupData>> getRetentionPopup({
    required String productId,
    required String popupType,
  }) async {
    calls++;
    lastProductId = productId;
    lastPopupType = popupType;
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('confirmProductIdFromUrl', () {
    test('从 fragment 查询参数中解析产品 ID', () {
      expect(confirmProductIdFromUrl(_confirmUrl), '3');
    });

    test('支持直接查询参数（别名出现在路径段中）', () {
      expect(
        confirmProductIdFromUrl(
          'http://host/AmalgamatorsMarqueterie?polarimetric=7',
        ),
        '7',
      );
    });

    test('只有产品 ID、没有确认用款页别名时返回空串', () {
      expect(confirmProductIdFromUrl('http://host/?polarimetric=7'), '');
    });

    test('支持 fragment 中的查询参数', () {
      expect(
        confirmProductIdFromUrl(
          'http://host/#/AmalgamatorsMarqueterie?polarimetric=9',
        ),
        '9',
      );
    });

    test('非确认用款页返回空串', () {
      expect(
        confirmProductIdFromUrl(
          'http://host/#/PodophyllumHerstories?polarimetric=3',
        ),
        '',
      );
    });

    test('确认用款页缺少产品 ID 时返回空串', () {
      expect(
        confirmProductIdFromUrl(
          'http://host/#/AmalgamatorsMarqueterie?cointerring=1',
        ),
        '',
      );
      expect(
        confirmProductIdFromUrl('http://host/#/AmalgamatorsMarqueterie'),
        '',
      );
    });

    test('productId 作为备用参数名', () {
      expect(
        confirmProductIdFromUrl(
          'http://host/#/AmalgamatorsMarqueterie?productId=5',
        ),
        '5',
      );
    });

    test('无效地址返回空串', () {
      expect(confirmProductIdFromUrl(''), '');
    });
  });

  group('fetchConfirmPageRetentionPopup', () {
    test('确认用款页使用 forgets=5 请求挽留弹窗', () async {
      final repository = _SpyCertificationRepository();

      final data = await fetchConfirmPageRetentionPopup(
        repository: repository,
        rawUrl: _confirmUrl,
      );

      expect(repository.calls, 1);
      expect(repository.lastProductId, '3');
      expect(repository.lastPopupType, confirmPageRetentionPopupType);
      expect(repository.lastPopupType, '5');
      expect(data?.imageUrl, 'https://example.com/popup.png');
    });

    test('非确认用款页不请求挽留弹窗', () async {
      final repository = _SpyCertificationRepository();

      final data = await fetchConfirmPageRetentionPopup(
        repository: repository,
        rawUrl: 'http://host/#/PodophyllumHerstories?polarimetric=3',
      );

      expect(repository.calls, 0);
      expect(data, isNull);
    });

    test('缺少产品 ID 时不请求挽留弹窗', () async {
      final repository = _SpyCertificationRepository();

      final data = await fetchConfirmPageRetentionPopup(
        repository: repository,
        rawUrl: 'http://host/#/AmalgamatorsMarqueterie?cointerring=1',
      );

      expect(repository.calls, 0);
      expect(data, isNull);
    });

    test('接口失败时返回 null，放行返回', () async {
      final repository = _SpyCertificationRepository(
        response: const ApiResponse<RetentionPopupData>(
          code: 500,
          message: 'error',
          data: RetentionPopupData(imageUrl: 'https://example.com/popup.png'),
        ),
      );

      final data = await fetchConfirmPageRetentionPopup(
        repository: repository,
        rawUrl: _confirmUrl,
      );

      expect(repository.calls, 1);
      expect(data, isNull);
    });
  });
}
