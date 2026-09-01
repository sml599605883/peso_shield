import 'package:peso_shield/core/device/session_store.dart';

/// In-memory [SessionPersistence] for tests.
class FakeSessionPersistence implements SessionPersistence {
  final Map<String, String?> values = <String, String?>{};

  @override
  Future<String?> readToken() async => values['token'];

  @override
  Future<String?> readUserId() async => values['userId'];

  @override
  Future<String?> readPhone() async => values['phone'];

  @override
  Future<void> writeToken(String? value) async => values['token'] = value;

  @override
  Future<void> writeUserId(String? value) async => values['userId'] = value;

  @override
  Future<void> writePhone(String? value) async => values['phone'] = value;

  @override
  Future<String?> readProductDetailPrompt() async => values['prompt'];

  @override
  Future<String?> readProductDetailIdentitySuccessPrompt() async =>
      values['identitySuccessPrompt'];

  @override
  Future<String?> readProductDetailFacePrompt() async => values['facePrompt'];

  @override
  Future<String?> readProductDetailOrderNo() async => values['orderNo'];

  @override
  Future<void> writeProductDetailPrompt(String? value) async =>
      values['prompt'] = value;

  @override
  Future<void> writeProductDetailIdentitySuccessPrompt(String? value) async =>
      values['identitySuccessPrompt'] = value;

  @override
  Future<void> writeProductDetailFacePrompt(String? value) async =>
      values['facePrompt'] = value;

  @override
  Future<void> writeProductDetailOrderNo(String? value) async =>
      values['orderNo'] = value;
}
