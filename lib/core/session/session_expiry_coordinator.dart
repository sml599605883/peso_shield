import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../device/user_session.dart';

/// 会话过期协调器
///
/// 当检测到会话过期（401/20000 错误码）时，负责清除会话并通过事件流通知监听者
class SessionExpiryCoordinator {
  SessionExpiryCoordinator({required this.ref});

  final Ref ref;
  final StreamController<void> _events = StreamController<void>.broadcast();
  Future<void>? _handling;

  Stream<void> get events => _events.stream;

  /// 处理会话过期：清除会话并广播事件
  ///
  /// 使用去重机制，确保同时多个请求失败时只处理一次
  Future<void> handleExpiredSession() => _handle();

  /// 处理 H5 下发的 login 深链（H5 判定登录态失效）
  ///
  /// 与 [handleExpiredSession] 一样清理会话并广播事件，但即使本地已无会话
  /// 也会广播：H5 的 sessionId 可能先于本地 token 失效，此时同样需要回到
  /// 首页 Tab 并弹出登录页。
  Future<void> handleLoginRequired() => _handle(force: true);

  Future<void> _handle({bool force = false}) {
    final active = _handling;
    if (active != null) return active;
    if (!force && !ref.read(userSessionProvider).isLoggedIn) {
      return Future.value();
    }

    final operation = _clearAndNotify();
    _handling = operation;
    return operation.whenComplete(() {
      if (identical(_handling, operation)) _handling = null;
    });
  }

  Future<void> _clearAndNotify() async {
    await ref.read(userSessionProvider.notifier).clearSession();
    _events.add(null);
  }

  Future<void> close() => _events.close();
}
