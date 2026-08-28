import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/device/user_session.dart';
import '../core/navigation/app_navigator.dart';
import '../providers/repository_provider.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/layout_adapter.dart';
import 'login/login_state.dart';

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
        _showMessage(
          response.isSuccess ? 'Verification code sent.' : response.message,
        );
        if (response.isSuccess) {
          ref.read(loginStateProvider.notifier).startCountdown();
          _codeFocusNode.requestFocus();
        }
      }
    } catch (_) {
      if (mounted) _showMessage('Unable to send the verification code.');
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
    } catch (_) {
      if (mounted) _showMessage('Unable to sign in. Please try again.');
      return false;
    } finally {
      if (mounted) {
        ref.read(loginStateProvider.notifier).setLoggingIn(false);
      }
    }
  }

  void _showMessage(String message) {
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
                    SizedBox(
                      height: layout.px(178),
                      width: double.infinity,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              AppAssets.loginIllustration,
                              fit: BoxFit.fitWidth,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: layout.edgeInsets(left: 16, top: 21),
                              child: IconButton(
                                tooltip: 'Back',
                                onPressed: () => Navigator.maybePop(context),
                                iconSize: layout.px(24),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints.tightFor(
                                  width: layout.px(24),
                                  height: layout.px(24),
                                ),
                                icon: Image.asset(AppAssets.loginBack),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(layout.px(27)),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.black.withValues(
                                    alpha: 0.18,
                                  ),
                                  offset: Offset(0, layout.px(-5)),
                                ),
                              ],
                            ),
                            child: LayoutBuilder(
                              builder: (context, panelConstraints) {
                                return SingleChildScrollView(
                                  padding: layout.edgeInsets(
                                    left: 20,
                                    right: 20,
                                  ),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: panelConstraints.maxHeight,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: layout.px(63)),
                                        Padding(
                                          padding: layout.edgeInsets(left: 7),
                                          child: const _LoginHeadline(),
                                        ),
                                        SizedBox(height: layout.px(42)),
                                        const _FieldLabel(
                                          'Please fill in your phone number',
                                        ),
                                        SizedBox(height: layout.px(9)),
                                        Padding(
                                          padding: layout.edgeInsets(
                                            left: 12,
                                            right: 19,
                                          ),
                                          child: _PhoneField(
                                            controller: _phoneController,
                                          ),
                                        ),
                                        SizedBox(height: layout.px(20)),
                                        const _FieldLabel(
                                          'Send SMS verification code',
                                        ),
                                        SizedBox(height: layout.px(9)),
                                        Padding(
                                          padding: layout.edgeInsets(
                                            left: 12,
                                            right: 19,
                                          ),
                                          child: _CodeField(
                                            controller: _codeController,
                                            focusNode: _codeFocusNode,
                                            requestingCode:
                                                loginState.requestingCode,
                                            countdownSeconds:
                                                loginState.countdownSeconds,
                                            onRequestCode: _requestCode,
                                          ),
                                        ),
                                        SizedBox(height: layout.px(42)),
                                        Center(
                                          child: SizedBox(
                                            width: contentWidth - layout.px(72),
                                            height: layout.px(50),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: Ink(
                                                decoration: BoxDecoration(
                                                  color: submitEnabled
                                                      ? AppColors.coral
                                                      : AppColors.loginDisabled,
                                                  borderRadius: layout.radius(
                                                    25,
                                                  ),
                                                ),
                                                child: InkWell(
                                                  onTap: canSubmit
                                                      ? () => _submit()
                                                      : null,
                                                  borderRadius: layout.radius(
                                                    25,
                                                  ),
                                                  child: Center(
                                                    child: loginState.loggingIn
                                                        ? SizedBox.square(
                                                            dimension: layout
                                                                .px(18),
                                                            child:
                                                                const CircularProgressIndicator(
                                                                  color:
                                                                      AppColors
                                                                          .white,
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                          )
                                                        : Text(
                                                            'Sign up / Sign in',
                                                            style: TextStyle(
                                                              color: AppColors
                                                                  .white,
                                                              fontSize: layout
                                                                  .px(18),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
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
          child: _Agreement(
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

class _LoginHeadline extends StatelessWidget {
  const _LoginHeadline();

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: AppColors.loginText,
          fontSize: layout.px(20),
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
        children: const [
          TextSpan(text: 'Welcome to '),
          TextSpan(
            text: 'App Name',
            style: TextStyle(color: AppColors.coral),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Padding(
      padding: layout.edgeInsets(left: 12),
      child: Text(
        label,
        style: TextStyle(color: AppColors.loginText, fontSize: layout.px(14)),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return _LoginField(
      child: Row(
        children: [
          Text(
            '+ 62',
            style: TextStyle(
              color: AppColors.coral,
              fontSize: layout.px(20),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(width: layout.px(23)),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Cellphone number',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeField extends StatelessWidget {
  const _CodeField({
    required this.controller,
    required this.focusNode,
    required this.requestingCode,
    required this.countdownSeconds,
    required this.onRequestCode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool requestingCode;
  final int countdownSeconds;
  final VoidCallback onRequestCode;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    final isCountingDown = countdownSeconds > 0;
    final canGetCode = !requestingCode && !isCountingDown;

    return _LoginField(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(
                hintText: 'Verification Code',
                border: InputBorder.none,
              ),
            ),
          ),
          if (requestingCode)
            SizedBox(
              width: layout.px(60),
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox.square(
                  dimension: layout.px(16),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.coral,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: canGetCode ? onRequestCode : null,
              child: Text(
                isCountingDown ? '${countdownSeconds}s' : 'Get Code',
                style: TextStyle(
                  color: canGetCode ? AppColors.coral : AppColors.loginHint,
                  fontSize: layout.px(18),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Container(
      height: layout.px(48),
      padding: layout.edgeInsets(left: 13, right: 11),
      decoration: BoxDecoration(
        color: AppColors.loginField,
        borderRadius: layout.radius(12),
      ),
      alignment: Alignment.center,
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            hintStyle: TextStyle(
              color: AppColors.loginHint,
              fontSize: layout.px(16),
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _Agreement extends StatefulWidget {
  const _Agreement({
    required this.selected,
    required this.onChanged,
    this.onPrivacyPolicyTap,
  });

  final bool selected;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onPrivacyPolicyTap;

  @override
  State<_Agreement> createState() => _AgreementState();
}

class _AgreementState extends State<_Agreement> {
  late final TapGestureRecognizer _privacyPolicyRecognizer;

  @override
  void initState() {
    super.initState();
    _privacyPolicyRecognizer = TapGestureRecognizer()
      ..onTap = widget.onPrivacyPolicyTap;
  }

  @override
  void didUpdateWidget(covariant _Agreement oldWidget) {
    super.didUpdateWidget(oldWidget);
    _privacyPolicyRecognizer.onTap = widget.onPrivacyPolicyTap;
  }

  @override
  void dispose() {
    _privacyPolicyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => widget.onChanged(!widget.selected),
          child: SizedBox(
            width: layout.px(16),
            height: layout.px(16),
            child: widget.selected
                ? Image.asset(AppAssets.loginAgreementChecked)
                : Image.asset(AppAssets.loginAgreementUnchecked),
          ),
        ),
        SizedBox(width: layout.px(16)),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: AppColors.loginAgreementText,
                fontSize: layout.px(14),
                height: 18 / 14,
              ),
              children: [
                const TextSpan(text: 'I have read and agree to the '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: const TextStyle(
                    color: AppColors.loginAgreementLink,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: _privacyPolicyRecognizer,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
