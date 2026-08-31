import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/device/user_session.dart';
import '../core/navigation/app_navigator.dart';
import '../core/network/http_exception.dart';
import '../providers/repository_provider.dart';
import '../theme/app_assets.dart';
import '../theme/layout_adapter.dart';
import 'login/login_state.dart';
import 'login/widgets/widgets.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({this.onLoginSuccess, this.onPrivacyPolicyTap, super.key});

  final Future<void> Function()? onLoginSuccess;
  final VoidCallback? onPrivacyPolicyTap;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();

  bool get _canSubmit =>
      _phoneController.text.trim().isNotEmpty &&
      _codeController.text.trim().length == 6;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onFormChanged);
    _codeController.addListener(_onCodeChanged);
  }

  void _onFormChanged() => setState(() {});

  void _onCodeChanged() {
    setState(() {});
    if (_codeController.text.length == 6) {
      unawaited(_submitAutomatically());
    }
  }

  Future<void> _submitAutomatically() async {
    final loginState = ref.read(loginStateProvider);
    final shouldResetOnFailure = loginState.agreementAccepted;
    final success = await _submit(showAgreementError: false);
    if (!success && shouldResetOnFailure && mounted) {
      _codeController.clear();
      _codeFocusNode.requestFocus();
    }
  }

  Future<void> _requestCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showMessage('Please enter your cellphone number.');
      return;
    }

    final loginState = ref.read(loginStateProvider);
    if (loginState.requestingCode || loginState.countdownSeconds > 0) {
      return;
    }

    ref.read(loginStateProvider.notifier).setRequestingCode(true);
    try {
      final repository = await ref.read(authRepositoryProvider.future);
      final response = await repository.sendVerificationCode(
        phone: phone,
        channel: 'sms',
      );
      if (mounted) {
        if (response.isSuccess) {
          _showMessage('Verification code sent.');
          ref.read(loginStateProvider.notifier).startCountdown();
          _codeFocusNode.requestFocus();
        } else {
          _showMessage(response.message);
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage(_extractErrorMessage(e));
      }
    } finally {
      if (mounted) {
        ref.read(loginStateProvider.notifier).setRequestingCode(false);
      }
    }
  }

  Future<bool> _submit({bool showAgreementError = true}) async {
    final loginState = ref.read(loginStateProvider);

    if (loginState.loggingIn) {
      return false;
    }

    if (!loginState.agreementAccepted) {
      if (showAgreementError) {
        _showMessage('Please agree to the Privacy Policy and Terms of Service');
      }
      return false;
    }

    if (!_canSubmit) {
      return false;
    }

    ref.read(loginStateProvider.notifier).setLoggingIn(true);
    try {
      final repository = await ref.read(authRepositoryProvider.future);
      final response = await repository.login(
        phone: _phoneController.text.trim(),
        code: _codeController.text.trim(),
      );
      if (!mounted) return false;

      if (!response.isSuccess) {
        _showMessage(response.message);
        return false;
      }

      ref
          .read(userSessionProvider.notifier)
          .setSession(
            token: response.data.accessToken,
            userId: response.data.userId,
          );

      if (widget.onLoginSuccess != null) {
        await widget.onLoginSuccess!();
      } else if (mounted) {
        AppNavigator.pop(true);
      }
      return true;
    } catch (e) {
      if (mounted) {
        _showMessage(_extractErrorMessage(e));
      }
      return false;
    } finally {
      if (mounted) {
        ref.read(loginStateProvider.notifier).setLoggingIn(false);
      }
    }
  }

  String _extractErrorMessage(Object error) {
    // 会话过期时不显示错误消息，因为 SessionExpiryCoordinator 会处理
    if (error is DioException &&
        error.error is HttpException &&
        (error.error as HttpException).type == HttpFailureType.authentication) {
      return ''; // 返回空字符串，_showMessage 会忽略
    }

    // 其他错误显示具体消息或通用提示
    if (error is HttpException) {
      return error.message.isNotEmpty
          ? error.message
          : 'Unable to complete the request.';
    }
    return 'Unable to complete the request.';
  }

  void _showMessage(String message) {
    if (message.isEmpty) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    final loginState = ref.watch(loginStateProvider);
    final submitEnabled = _canSubmit && loginState.agreementAccepted;
    final canSubmit = submitEnabled && !loginState.loggingIn;

    return Scaffold(
      // Keep the decorative background/illustration anchored when the
      // keyboard appears. The form itself remains scrollable inside the
      // white panel, so the Scaffold does not need to relayout its body.
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppAssets.homeBackground),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth = constraints.maxWidth - layout.px(40);
                return Column(
                  children: [
                    const LoginIllustrationHeader(),
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          LoginFormPanel(
                            contentWidth: contentWidth,
                            phoneController: _phoneController,
                            codeController: _codeController,
                            codeFocusNode: _codeFocusNode,
                            requestingCode: loginState.requestingCode,
                            countdownSeconds: loginState.countdownSeconds,
                            loggingIn: loginState.loggingIn,
                            submitEnabled: submitEnabled,
                            onRequestCode: _requestCode,
                            onSubmit: canSubmit ? () => _submit() : null,
                          ),
                          Positioned(
                            top: layout.px(-49),
                            left: layout.px(16),
                            child: IgnorePointer(
                              child: Image.asset(
                                AppAssets.loginAvatarPlaceholder,
                                width: layout.px(104),
                                height: layout.px(104),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: layout.edgeInsets(left: 20, right: 20),
          child: LoginAgreement(
            selected: loginState.agreementAccepted,
            onChanged: (selected) =>
                ref.read(loginStateProvider.notifier).toggleAgreement(),
            onPrivacyPolicyTap:
                widget.onPrivacyPolicyTap ??
                () => debugPrint('Privacy Policy tapped'),
          ),
        ),
      ),
    );
  }
}
