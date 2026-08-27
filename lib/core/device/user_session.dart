import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserSession {
  const UserSession({
    this.accessToken,
    this.userId,
    this.isLoggedIn = false,
  });

  final String? accessToken;
  final String? userId;
  final bool isLoggedIn;

  UserSession copyWith({
    String? accessToken,
    String? userId,
    bool? isLoggedIn,
  }) {
    return UserSession(
      accessToken: accessToken ?? this.accessToken,
      userId: userId ?? this.userId,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

class UserSessionNotifier extends Notifier<UserSession> {
  @override
  UserSession build() {
    return const UserSession();
  }

  void setSession({required String token, required String userId}) {
    state = UserSession(
      accessToken: token,
      userId: userId,
      isLoggedIn: true,
    );
  }

  void clearSession() {
    state = const UserSession();
  }
}

final userSessionProvider =
    NotifierProvider<UserSessionNotifier, UserSession>(() {
  return UserSessionNotifier();
});
