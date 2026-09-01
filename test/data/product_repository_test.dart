import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/data/models/product_apply_result.dart';
import 'package:peso_shield/data/models/product_detail.dart';

void main() {
  group('ProductApplyResult', () {
    test('解析准入成功响应', () {
      final json = {
        'recklessly': 200,
        'throwaways': '2000.0000',
        'tribologies': '2000.0000',
        'narcein': ['91'],
        'accessorised': 1,
        'bonefishings': 0,
        'decoct': '',
        'mycelia': '',
        'unroped': '74effb3fd3646504',
        'gazania': 'f7167f31edd1adfe',
      };

      final result = ProductApplyResult.fromJson(json);

      expect(result.statusCode, 200);
      expect(result.isAdmitted, true);
      expect(result.accessKey, '74effb3fd3646504');
      expect(result.secretKey, 'f7167f31edd1adfe');
    });

    test('解析准入失败响应（跳转 H5）', () {
      final json = {
        'recklessly': 302,
        'mycelia':
            'http://47.103.73.105:9003/#/errorUrl?productId=1&productName=productName',
        'bellings': 1,
        'decoct': '成功',
      };

      final result = ProductApplyResult.fromJson(json);

      expect(result.statusCode, 302);
      expect(result.isAdmitted, false);
      expect(result.needsWebJump, true);
      expect(result.jumpUrl, contains('errorUrl'));
    });

    test('解析授信页响应', () {
      final json = {
        'recklessly': 302,
        'mycelia': 'gold://pocket/recredit',
        'bellings': 0,
      };

      final result = ProductApplyResult.fromJson(json);

      expect(result.statusCode, 302);
      expect(result.isCreditReview, true);
      expect(result.needsWebJump, false);
    });

    test('解析复贷弹窗响应', () {
      final json = {
        'abysmal': {
          'stalagmitic': 'Produk rekomendasi',
          'closets': 'Tersedia jalur VIP，tingkat acc hingga 99%, klik untuk mengajukan',
          'birls': [
            {'lookalike': 'AJUKAN SEKARANG', 'mycelia': 'url1'},
            {'lookalike': 'Mengajukan produk sekarang', 'mycelia': 'url2'},
          ],
        },
        'mycelia': 'http:///xxx',
      };

      final result = ProductApplyResult.fromJson(json);

      expect(result.dialog, isNotNull);
      expect(result.dialog!.title, 'Produk rekomendasi');
      expect(result.dialog!.leftButton, isNotNull);
      expect(result.dialog!.leftButton!.text, 'AJUKAN SEKARANG');
      expect(result.dialog!.rightButton, isNotNull);
      expect(result.dialog!.rightButton!.text, 'Mengajukan produk sekarang');
    });
  });

  group('ProductDetail', () {
    test('解析产品详情响应', () {
      // ResponseProtocol 已经提取了 mugg 字段，所以这里直接使用 mugg 内的数据
      final json = {
        'recklessly': 200,
        'cutbacks': {
          'ghostiest': ['1.100.000', '1.000.000'],
          'desalting': '1.100.000',
          'armpits': [7],
          'impotent': 'Jumlah Pinjaman(Rp)',
          'concertino': 'Jangka Pinjaman',
          'ventral': '1',
          'reinters': 'Super Prestamo',
          'cysticercosis': '302021063003045300522743',
          'cointerring': 266561,
          'haunts': 'Isi Informasi',
          'mycelia': 'http://example.com',
          'outsparkling': 1,
        },
        'unpunctual': {
          'bloodlust': '855123456',
          'teetotalism': 'CORM770627MDFNJA12',
          'cymenes': 'Ina Kumari',
        },
        'redialling': [
          {
            'stalagmitic': 'Informasi identitas',
            'vacantness': 'Harap tingkatkan identitas',
            'bellings': 0,
            'mycelia': '',
            'barghests': 1,
            'leses': 'Sertifikasi',
            'histolyses': 'public',
            'deity': 1,
            'priggisms': 'https://example.com/icon.png',
          },
        ],
        'laminarias': {
          'histolyses': 'bank',
          'mycelia': '',
          'bellings': 0,
          'stalagmitic': 'Informasi bank',
        },
        'assertively': [
          {
            'polarimetric': '1',
            'experimentalism': 1,
            'thrived': '1',
            'cointerring': 266561,
            'stalagmitic': 'Loan Agreement',
          },
        ],
      };

      final detail = ProductDetail.fromJson(json);

      expect(detail.certifications.length, 1);
      expect(detail.certifications[0].taskType, 'public');
      expect(detail.certifications[0].title, 'Informasi identitas');
      expect(detail.nextStep.taskType, 'bank');
      expect(detail.nextStep.title, 'Informasi bank');
      expect(detail.agreements.length, 1);
      expect(detail.agreements[0].title, 'Loan Agreement');
    });
  });
}
