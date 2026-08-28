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
  Future<void> handleExpiredSession() {
    final active = _handling;
    if (active != null) return active;
    if (!ref.read(userSessionProvider).isLoggedIn) return Future.value();

    final operation = _clearAndNotify();
    _handling = operation;
    return operation.whenComplete(() {
      if (identical(_handling, operation)) _handling = null;
    });
  }

  Future<void> _clearAndNotify() async {
    ref.read(userSessionProvider.notifier).clearSession();
    _events.add(null);
  }

  Future<void> close() => _events.close();
}
