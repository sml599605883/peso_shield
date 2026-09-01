import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/device/session_store.dart';

import '../../support/fake_session_persistence.dart';

void main() {
  group('SessionStore 产品详情保存', () {
    late SessionStore store;
    late FakeSessionPersistence persistence;

    setUp(() {
      persistence = FakeSessionPersistence();
      store = SessionStore(persistence);
    });

    test('保存产品详情字段到持久化存储', () async {
      await store.saveProductDetail(
        prompt: 'Please upload your ID',
        identitySuccessPrompt: 'Identity verified successfully',
        facePrompt: 'Please complete face verification',
        orderNo: 'ORDER123456',
      );

      expect(store.productDetailPrompt, 'Please upload your ID');
      expect(store.productDetailIdentitySuccessPrompt,
          'Identity verified successfully');
      expect(store.productDetailFacePrompt, 'Please complete face verification');
      expect(store.productDetailOrderNo, 'ORDER123456');

      // 验证持久化
      expect(await persistence.readProductDetailPrompt(), 'Please upload your ID');
      expect(await persistence.readProductDetailIdentitySuccessPrompt(),
          'Identity verified successfully');
      expect(await persistence.readProductDetailFacePrompt(),
          'Please complete face verification');
      expect(await persistence.readProductDetailOrderNo(), 'ORDER123456');
    });

    test('从持久化存储恢复产品详情字段', () async {
      // 先保存数据
      await store.saveProductDetail(
        prompt: 'Upload ID prompt',
        identitySuccessPrompt: 'Success prompt',
        facePrompt: 'Face prompt',
        orderNo: 'ORDER999',
      );

      // 创建新的 store 实例模拟重启
      final newStore = SessionStore(persistence);
      await newStore.restore();

      expect(newStore.productDetailPrompt, 'Upload ID prompt');
      expect(newStore.productDetailIdentitySuccessPrompt, 'Success prompt');
      expect(newStore.productDetailFacePrompt, 'Face prompt');
      expect(newStore.productDetailOrderNo, 'ORDER999');
    });

    test('清除会话时清除产品详情字段', () async {
      // 先保存数据
      await store.saveProductDetail(
        prompt: 'Test prompt',
        identitySuccessPrompt: 'Test success',
        facePrompt: 'Test face',
        orderNo: 'TEST_ORDER',
      );

      expect(store.productDetailPrompt, 'Test prompt');
      expect(store.productDetailOrderNo, 'TEST_ORDER');

      // 清除会话
      await store.clear();

      expect(store.productDetailPrompt, '');
      expect(store.productDetailIdentitySuccessPrompt, '');
      expect(store.productDetailFacePrompt, '');
      expect(store.productDetailOrderNo, '');

      // 验证持久化也被清除
      expect(await persistence.readProductDetailPrompt(), null);
      expect(await persistence.readProductDetailOrderNo(), null);
    });

    test('保存时自动 trim 空白字符', () async {
      await store.saveProductDetail(
        prompt: '  Trimmed prompt  ',
        identitySuccessPrompt: '\nSuccess\n',
        facePrompt: '\t Face \t',
        orderNo: '  ORDER_TRIM  ',
      );

      expect(store.productDetailPrompt, 'Trimmed prompt');
      expect(store.productDetailIdentitySuccessPrompt, 'Success');
      expect(store.productDetailFacePrompt, 'Face');
      expect(store.productDetailOrderNo, 'ORDER_TRIM');
    });
  });
}
