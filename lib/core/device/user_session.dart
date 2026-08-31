import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_store.dart';

class UserSession {
  const UserSession({
    this.accessToken,
    this.userId,
    this.phone,
    this.isLoggedIn = false,
    this.isRestored = false,
  });

  final String? accessToken;
  final String? userId;
  final String? phone;
  final bool isLoggedIn;

  /// 是否已完成从本地存储的恢复。启动阶段用它区分「未登录」和「还没读出来」。
  final bool isRestored;

  UserSession copyWith({
    String? accessToken,
    String? userId,
    String? phone,
    bool? isLoggedIn,
    bool? isRestored,
  }) {
    return UserSession(
      accessToken: accessToken ?? this.accessToken,
      userId: userId ?? this.userId,
      phone: phone ?? this.phone,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isRestored: isRestored ?? this.isRestored,
    );
  }
}

final sessionStoreProvider = Provider<SessionStore>((ref) {
  return SessionStore.persistent();
});

class UserSessionNotifier extends Notifier<UserSession> {
  Future<void>? _restoring;

  SessionStore get _store => ref.read(sessionStoreProvider);

  @override
  UserSession build() {
    // 立即触发恢复，保证即使没人显式 await restore()，登录态最终也会补齐
    unawaited(restore());
    return const UserSession();
  }

  /// 从本地存储恢复会话。重复调用复用同一个 Future。
  Future<void> restore() {
    final active = _restoring;
    if (active != null) return active;
    if (state.isRestored) return Future<void>.value();

    final operation = _restore();
    _restoring = operation;
    return operation.whenComplete(() {
      if (identical(_restoring, operation)) _restoring = null;
    });
  }

  Future<void> _restore() async {
    final restored = await _store.restore();
    // 恢复期间用户可能已手动登录完成，不要用旧数据覆盖
    if (state.isLoggedIn) {
      state = state.copyWith(isRestored: true);
      return;
    }
    state = restored;
  }

  Future<void> setSession({
    required String token,
    required String userId,
    required String phone,
  }) async {
    state = UserSession(
      accessToken: token,
      userId: userId,
      phone: phone,
      isLoggedIn: true,
      isRestored: true,
    );
    await _store.save(token: token, userId: userId, phone: phone);
  }

  /// 清除会话，保留手机号供下次登录预填
  Future<void> clearSession() async {
    state = UserSession(phone: state.phone, isRestored: true);
    await _store.clear();
  }
}

final userSessionProvider = NotifierProvider<UserSessionNotifier, UserSession>(
  () {
    return UserSessionNotifier();
  },
);
