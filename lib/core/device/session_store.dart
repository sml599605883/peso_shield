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

  // 产品详情相关字段
  Future<String?> readProductDetailPrompt();

  Future<String?> readProductDetailIdentitySuccessPrompt();

  Future<String?> readProductDetailFacePrompt();

  Future<String?> readProductDetailOrderNo();

  Future<void> writeProductDetailPrompt(String? value);

  Future<void> writeProductDetailIdentitySuccessPrompt(String? value);

  Future<void> writeProductDetailFacePrompt(String? value);

  Future<void> writeProductDetailOrderNo(String? value);
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
  static const productDetailPromptKey = 'peso_shield.product_detail.prompt';
  static const productDetailIdentitySuccessPromptKey =
      'peso_shield.product_detail.identity_success_prompt';
  static const productDetailFacePromptKey =
      'peso_shield.product_detail.face_prompt';
  static const productDetailOrderNoKey = 'peso_shield.product_detail.order_no';

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

  @override
  Future<String?> readProductDetailPrompt() =>
      _preferences.getString(productDetailPromptKey);

  @override
  Future<String?> readProductDetailIdentitySuccessPrompt() =>
      _preferences.getString(productDetailIdentitySuccessPromptKey);

  @override
  Future<String?> readProductDetailFacePrompt() =>
      _preferences.getString(productDetailFacePromptKey);

  @override
  Future<String?> readProductDetailOrderNo() =>
      _preferences.getString(productDetailOrderNoKey);

  @override
  Future<void> writeProductDetailPrompt(String? value) {
    if (value == null) {
      return _preferences.remove(productDetailPromptKey);
    }
    return _preferences.setString(productDetailPromptKey, value);
  }

  @override
  Future<void> writeProductDetailIdentitySuccessPrompt(String? value) {
    if (value == null) {
      return _preferences.remove(productDetailIdentitySuccessPromptKey);
    }
    return _preferences.setString(productDetailIdentitySuccessPromptKey, value);
  }

  @override
  Future<void> writeProductDetailFacePrompt(String? value) {
    if (value == null) {
      return _preferences.remove(productDetailFacePromptKey);
    }
    return _preferences.setString(productDetailFacePromptKey, value);
  }

  @override
  Future<void> writeProductDetailOrderNo(String? value) {
    if (value == null) {
      return _preferences.remove(productDetailOrderNoKey);
    }
    return _preferences.setString(productDetailOrderNoKey, value);
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

  // 产品详情缓存（内存）
  String _productDetailPrompt = '';
  String _productDetailIdentitySuccessPrompt = '';
  String _productDetailFacePrompt = '';
  String _productDetailOrderNo = '';

  /// 获取缓存的产品详情身份认证页顶部文案
  String get productDetailPrompt => _productDetailPrompt;

  /// 获取缓存的产品详情身份认证成功页顶部文案
  String get productDetailIdentitySuccessPrompt =>
      _productDetailIdentitySuccessPrompt;

  /// 获取缓存的产品详情活体认证页顶部文案
  String get productDetailFacePrompt => _productDetailFacePrompt;

  /// 获取缓存的产品详情订单号
  String get productDetailOrderNo => _productDetailOrderNo;

  /// 读取已保存的会话。
  ///
  /// 手机号独立于 token 恢复：未登录状态下也要带上，登录页才能跨启动预填。
  Future<UserSession> restore() async {
    try {
      final values = await Future.wait([
        _persistence.readToken(),
        _persistence.readUserId(),
        _persistence.readPhone(),
        _persistence.readProductDetailPrompt(),
        _persistence.readProductDetailIdentitySuccessPrompt(),
        _persistence.readProductDetailFacePrompt(),
        _persistence.readProductDetailOrderNo(),
      ]);
      final token = _normalize(values[0]);
      final phone = _normalize(values[2]);
      
      // 恢复产品详情缓存到内存
      _productDetailPrompt = _normalize(values[3]) ?? '';
      _productDetailIdentitySuccessPrompt = _normalize(values[4]) ?? '';
      _productDetailFacePrompt = _normalize(values[5]) ?? '';
      _productDetailOrderNo = _normalize(values[6]) ?? '';
      
      if (token == null) {
        return UserSession(phone: phone, isRestored: true);
      }
      return UserSession(
        accessToken: token,
        userId: _normalize(values[1]),
        phone: phone,
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

  /// 保存产品详情相关字段
  Future<void> saveProductDetail({
    required String prompt,
    required String identitySuccessPrompt,
    required String facePrompt,
    required String orderNo,
  }) async {
    _productDetailPrompt = prompt.trim();
    _productDetailIdentitySuccessPrompt = identitySuccessPrompt.trim();
    _productDetailFacePrompt = facePrompt.trim();
    _productDetailOrderNo = orderNo.trim();

    try {
      await Future.wait([
        _persistence.writeProductDetailPrompt(_productDetailPrompt),
        _persistence
            .writeProductDetailIdentitySuccessPrompt(_productDetailIdentitySuccessPrompt),
        _persistence.writeProductDetailFacePrompt(_productDetailFacePrompt),
        _persistence.writeProductDetailOrderNo(_productDetailOrderNo),
      ]);
    } catch (_) {
      // 持久化失败时保留内存态
    }
  }

  /// 清除会话。手机号始终保留，方便下次登录预填。
  Future<void> clear() async {
    try {
      await Future.wait([
        _persistence.writeToken(null),
        _persistence.writeUserId(null),
        _persistence.writeProductDetailPrompt(null),
        _persistence.writeProductDetailIdentitySuccessPrompt(null),
        _persistence.writeProductDetailFacePrompt(null),
        _persistence.writeProductDetailOrderNo(null),
      ]);
      
      // 清除内存缓存
      _productDetailPrompt = '';
      _productDetailIdentitySuccessPrompt = '';
      _productDetailFacePrompt = '';
      _productDetailOrderNo = '';
    } catch (_) {
      // 忽略清除失败
    }
  }

  static String? _normalize(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
