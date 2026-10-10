import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/face/face_liveness_bridge.dart';

void main() {
  test('treats a non-200 code with image data as uploadable', () {
    // 回归用例：同盾 success 回调返回的 code 未必是 200，
    // 只要带回图片和 liveness_id 就必须继续上传。
    const result = FaceLivenessResult(
      success: false,
      code: 400,
      message: 'captured',
      image: 'base64-image',
      livenessId: 'liveness-1',
    );
    expect(hasUploadableLivenessData(result), isTrue);
  });

  test('rejects results without image data', () {
    const result = FaceLivenessResult(
      success: true,
      code: 200,
      message: '',
      image: '',
      livenessId: 'liveness-1',
    );
    expect(hasUploadableLivenessData(result), isFalse);
  });

  test('rejects results without a liveness id', () {
    const result = FaceLivenessResult(
      success: true,
      code: 200,
      message: '',
      image: 'base64-image',
      livenessId: '',
    );
    expect(hasUploadableLivenessData(result), isFalse);
  });
}
