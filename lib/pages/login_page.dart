import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/device/user_session.dart';
import '../core/navigation/app_navigator.dart';
import '../core/network/http_exception.dart';
import '../core/report/peso_report_service.dart';
import '../core/ui/toast_helper.dart';
import '../providers/home_provider.dart';
import '../providers/report_provider.dart';
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
  late final int _sceneStartTime;

  bool get _canSubmit =>
      _phoneController.text.trim().isNotEmpty &&
      _codeController.text.trim().length == 6;

  @override
  void initState() {
    super.initState();
    _sceneStartTime = PesoReportService.nowSeconds();
    _phoneController.addListener(_onFormChanged);
    _codeController.addListener(_onCodeChanged);
    _loadRememberedPhone();
  }

  void _onFormChanged() => setState(() {});

  void _onCodeChanged() {
    setState(() {});
    if (_codeController.text.length == 6) {
      unawaited(_submitAutomatically());
    }
  }

  /// 从 userSession 加载上次登录的手机号
  Future<void> _loadRememberedPhone() async {
    final session = ref.read(userSessionProvider);
    final phone = session.phone;
    if (phone == null || phone.isEmpty || _phoneController.text.isNotEmpty) {
      return;
    }
    _phoneController.text = phone;
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
      ToastHelper.showMessage('Please enter your cellphone number.');
      return;
    }

    final loginState = ref.read(loginStateProvider);
    if (loginState.requestingCode || loginState.countdownSeconds > 0) {
      return;
    }

    ToastHelper.showLoading();
    ref.read(loginStateProvider.notifier).setRequestingCode(true);
    try {
      final repository = await ref.read(authRepositoryProvider.future);
      final response = await repository.sendVerificationCode(
        phone: phone,
        channel: 'sms',
      );
      if (mounted) {
        ToastHelper.hideLoading();
        if (response.isSuccess) {
          ToastHelper.showSuccess('Verification code sent.');
          ref.read(loginStateProvider.notifier).startCountdown();
          _codeFocusNode.requestFocus();
        } else {
          ToastHelper.showError(response.message);
        }
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.hideLoading();
        final message = _extractErrorMessage(e);
        if (message.isNotEmpty) {
          ToastHelper.showError(message);
        }
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
        ToastHelper.showMessage(
          'Please agree to the Privacy Policy and Terms of Service',
        );
      }
      return false;
    }

    if (!_canSubmit) {
      return false;
    }

    ref.read(loginStateProvider.notifier).setLoggingIn(true);
    ToastHelper.showLoading();
    try {
      final repository = await ref.read(authRepositoryProvider.future);
      final response = await repository.login(
        phone: _phoneController.text.trim(),
        code: _codeController.text.trim(),
      );
      if (!mounted) return false;

      ToastHelper.hideLoading();
      if (!response.isSuccess) {
        ToastHelper.showError(response.message);
        return false;
      }

      await ref
          .read(userSessionProvider.notifier)
          .setSession(
            token: response.data.accessToken,
            userId: response.data.userId,
            phone: _phoneController.text.trim(),
          );

      // 上报登录成功和风险场景
      try {
        final reportService = ref.read(reportServiceProvider);
        await reportService.loginSucceeded();
        unawaited(
          reportService.reportRisk(
            productId: '', // 登录场景不需要 productId
            scene: '1',
            startedAtSeconds: _sceneStartTime,
          ),
        );
      } catch (_) {
        // 上报失败不影响登录流程
      }

      if (!mounted) return true;

      unawaited(ref.read(homeDataProvider.notifier).refresh());
      if (widget.onLoginSuccess != null) {
        await widget.onLoginSuccess!();
      } else if (mounted) {
        AppNavigator.pop(true);
      }
      return true;
    } catch (e) {
      if (mounted) {
        ToastHelper.hideLoading();
        final message = _extractErrorMessage(e);
        if (message.isNotEmpty) {
          ToastHelper.showError(message);
        }
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
      return ''; // 返回空字符串，调用方会检查并跳过 toast
    }

    // 其他错误显示具体消息或通用提示
    if (error is HttpException) {
      return error.message.isNotEmpty
          ? error.message
          : 'Unable to complete the request.';
    }
    return 'Unable to complete the request.';
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
