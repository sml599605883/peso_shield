import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/device/session_store.dart';

class _FakeSessionPersistence implements SessionPersistence {
  String? token;
  String? userId;
  String? phone;
  bool throwOnRead = false;

  @override
  Future<String?> readToken() async {
    if (throwOnRead) throw Exception('keychain unavailable');
    return token;
  }

  @override
  Future<String?> readUserId() async => userId;

  @override
  Future<String?> readPhone() async => phone;

  @override
  Future<void> writeToken(String? value) async => token = value;

  @override
  Future<void> writeUserId(String? value) async => userId = value;

  @override
  Future<void> writePhone(String? value) async => phone = value;
}

void main() {
  late _FakeSessionPersistence persistence;
  late SessionStore store;

  setUp(() {
    persistence = _FakeSessionPersistence();
    store = SessionStore(persistence);
  });

  test('restore returns logged out state when no token is stored', () async {
    final session = await store.restore();

    expect(session.isLoggedIn, isFalse);
    expect(session.accessToken, isNull);
    expect(session.isRestored, isTrue);
  });

  test('saved session survives a restore', () async {
    await store.save(token: 'token-1', userId: 'user-1', phone: '09171234567');

    final session = await store.restore();

    expect(session.isLoggedIn, isTrue);
    expect(session.accessToken, 'token-1');
    expect(session.userId, 'user-1');
    expect(session.phone, '09171234567');
  });

  test('blank stored values are treated as absent', () async {
    persistence
      ..token = '   '
      ..userId = ''
      ..phone = '';

    final session = await store.restore();

    expect(session.isLoggedIn, isFalse);
    expect(session.accessToken, isNull);
  });

  test('clear drops the token but keeps the phone by default', () async {
    await store.save(token: 'token-1', userId: 'user-1', phone: '09171234567');

    await store.clear();

    expect(persistence.token, isNull);
    expect(persistence.userId, isNull);
    expect(persistence.phone, '09171234567');

    final session = await store.restore();
    expect(session.isLoggedIn, isFalse);
  });

  test('clear with keepPhone false removes the phone too', () async {
    await store.save(token: 'token-1', userId: 'user-1', phone: '09171234567');

    await store.clear(keepPhone: false);

    expect(persistence.phone, isNull);
  });

  test('restore degrades to logged out when storage throws', () async {
    persistence
      ..token = 'token-1'
      ..throwOnRead = true;

    final session = await store.restore();

    expect(session.isLoggedIn, isFalse);
    expect(session.isRestored, isTrue);
  });
}
