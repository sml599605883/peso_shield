import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_session.dart';

abstract interface class SessionPersistence {
  Future<String?> readToken();

  Future<String?> readUserId();

  Future<String?> readPhone();

  Future<void> writeToken(String? value);

  Future<void> writeUserId(String? value);

  Future<void> writePhone(String? value);
}

class PersistentSessionPersistence implements SessionPersistence {
  PersistentSessionPersistence({
    SharedPreferencesAsync? preferences,
    FlutterSecureStorage? secureStorage,
  }) : _preferences = preferences ?? SharedPreferencesAsync(),
       _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.first_unlock_this_device,
             ),
           );

  static const tokenKey = 'peso_shield.session.access_token';
  static const userIdKey = 'peso_shield.session.user_id';
  static const phoneKey = 'peso_shield.session.phone';

  final SharedPreferencesAsync _preferences;
  final FlutterSecureStorage _secureStorage;

  @override
  Future<String?> readToken() => _secureStorage.read(key: tokenKey);

  @override
  Future<String?> readUserId() => _preferences.getString(userIdKey);

  @override
  Future<String?> readPhone() => _preferences.getString(phoneKey);

  @override
  Future<void> writeToken(String? value) {
    if (value == null) {
      return _secureStorage.delete(key: tokenKey);
    }
    return _secureStorage.write(key: tokenKey, value: value);
  }

  @override
  Future<void> writeUserId(String? value) {
    if (value == null) {
      return _preferences.remove(userIdKey);
    }
    return _preferences.setString(userIdKey, value);
  }

  @override
  Future<void> writePhone(String? value) {
    if (value == null) {
      return _preferences.remove(phoneKey);
    }
    return _preferences.setString(phoneKey, value);
  }
}

/// 会话持久化存储
///
/// access token 存 Keychain，其余非敏感字段存 SharedPreferences。
/// 读写失败不抛给调用方：登录态丢失只影响体验，不应让 App 启动失败。
class SessionStore {
  SessionStore(this._persistence);

  factory SessionStore.persistent() {
    return SessionStore(PersistentSessionPersistence());
  }

  final SessionPersistence _persistence;

  /// 读取已保存的会话。没有 token 时返回未登录状态。
  Future<UserSession> restore() async {
    try {
      final values = await Future.wait([
        _persistence.readToken(),
        _persistence.readUserId(),
        _persistence.readPhone(),
      ]);
      final token = _normalize(values[0]);
      if (token == null) {
        return const UserSession(isRestored: true);
      }
      return UserSession(
        accessToken: token,
        userId: _normalize(values[1]),
        phone: _normalize(values[2]),
        isLoggedIn: true,
        isRestored: true,
      );
    } catch (_) {
      return const UserSession(isRestored: true);
    }
  }

  Future<void> save({
    required String token,
    required String userId,
    required String phone,
  }) async {
    try {
      await Future.wait([
        _persistence.writeToken(_normalize(token)),
        _persistence.writeUserId(_normalize(userId)),
        _persistence.writePhone(_normalize(phone)),
      ]);
    } catch (_) {
      // 持久化失败时保留内存态，下次启动重新登录
    }
  }

  /// 清除会话。默认保留手机号，方便下次登录预填。
  Future<void> clear({bool keepPhone = true}) async {
    try {
      await Future.wait([
        _persistence.writeToken(null),
        _persistence.writeUserId(null),
        if (!keepPhone) _persistence.writePhone(null),
      ]);
    } catch (_) {
      // 忽略清除失败
    }
  }

  static String? _normalize(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
