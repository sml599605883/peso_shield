import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginState {
  const LoginState({
    this.agreementAccepted = true,
    this.requestingCode = false,
    this.loggingIn = false,
    this.countdownSeconds = 0,
  });

  final bool agreementAccepted;
  final bool requestingCode;
  final bool loggingIn;
  final int countdownSeconds;

  LoginState copyWith({
    bool? agreementAccepted,
    bool? requestingCode,
    bool? loggingIn,
    int? countdownSeconds,
  }) {
    return LoginState(
      agreementAccepted: agreementAccepted ?? this.agreementAccepted,
      requestingCode: requestingCode ?? this.requestingCode,
      loggingIn: loggingIn ?? this.loggingIn,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
    );
  }
}

class LoginStateNotifier extends Notifier<LoginState> {
  Timer? _countdownTimer;

  @override
  LoginState build() {
    ref.onDispose(() {
      _countdownTimer?.cancel();
    });
    return const LoginState();
  }

  void toggleAgreement() {
    state = state.copyWith(agreementAccepted: !state.agreementAccepted);
  }

  void setRequestingCode(bool value) {
    state = state.copyWith(requestingCode: value);
  }

  void setLoggingIn(bool value) {
    state = state.copyWith(loggingIn: value);
  }

  void startCountdown({int seconds = 60}) {
    _countdownTimer?.cancel();
    state = state.copyWith(countdownSeconds: seconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.countdownSeconds <= 1) {
        timer.cancel();
        state = state.copyWith(countdownSeconds: 0);
      } else {
        state = state.copyWith(countdownSeconds: state.countdownSeconds - 1);
      }
    });
  }
}

final loginStateProvider = NotifierProvider<LoginStateNotifier, LoginState>(() {
  return LoginStateNotifier();
});
