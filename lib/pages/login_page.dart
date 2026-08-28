import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/device/user_session.dart';
import '../core/navigation/app_navigator.dart';
import '../providers/repository_provider.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/layout_adapter.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({this.onLoginSuccess, super.key});

  final Future<void> Function()? onLoginSuccess;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _hasAcceptedAgreement = false;
  bool _requestingCode = false;
  bool _signingIn = false;

  bool get _canSubmit =>
      _hasAcceptedAgreement &&
      _phoneController.text.trim().isNotEmpty &&
      _codeController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onFormChanged);
    _codeController.addListener(_onFormChanged);
  }

  void _onFormChanged() => setState(() {});

  Future<void> _requestCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showMessage('Please enter your cellphone number.');
      return;
    }
    setState(() => _requestingCode = true);
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
      }
    } catch (_) {
      if (mounted) _showMessage('Unable to send the verification code.');
    } finally {
      if (mounted) setState(() => _requestingCode = false);
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit || _signingIn) return;
    setState(() => _signingIn = true);
    try {
      final repository = await ref.read(authRepositoryProvider.future);
      final response = await repository.login(
        phone: _phoneController.text.trim(),
        code: _codeController.text.trim(),
      );
      if (!mounted) return;
      if (!response.isSuccess) {
        _showMessage(response.message);
        return;
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
    } catch (_) {
      if (mounted) _showMessage('Unable to sign in. Please try again.');
    } finally {
      if (mounted) setState(() => _signingIn = false);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
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
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Image.asset(
                      AppAssets.loginIllustration,
                      width: constraints.maxWidth,
                      height: layout.px(209),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: layout.px(154),
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(layout.px(27)),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.18),
                            offset: Offset(0, layout.px(-5)),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: layout.edgeInsets(left: 20, right: 20),
                        child: SizedBox(
                          height: constraints.maxHeight - layout.px(154),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: layout.px(108)),
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
                                padding: layout.edgeInsets(left: 12, right: 19),
                                child: _PhoneField(
                                  controller: _phoneController,
                                ),
                              ),
                              SizedBox(height: layout.px(20)),
                              const _FieldLabel('Send SMS verification code'),
                              SizedBox(height: layout.px(9)),
                              Padding(
                                padding: layout.edgeInsets(left: 12, right: 19),
                                child: _CodeField(
                                  controller: _codeController,
                                  requestingCode: _requestingCode,
                                  onRequestCode: _requestCode,
                                ),
                              ),
                              SizedBox(height: layout.px(42)),
                              Center(
                                child: SizedBox(
                                  width: contentWidth - layout.px(72),
                                  height: layout.px(50),
                                  child: FilledButton(
                                    onPressed: _canSubmit && !_signingIn
                                        ? _submit
                                        : null,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.loginDisabled,
                                      disabledBackgroundColor:
                                          AppColors.loginDisabled,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: layout.radius(25),
                                      ),
                                    ),
                                    child: Text(
                                      'Sign up / Sign in',
                                      style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: layout.px(18),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Padding(
                                padding: layout.edgeInsets(bottom: 22),
                                child: _Agreement(
                                  selected: _hasAcceptedAgreement,
                                  onChanged: (selected) => setState(
                                    () => _hasAcceptedAgreement = selected,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: layout.px(92),
                    left: layout.px(16),
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
                  Positioned(
                    top: layout.px(105),
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
              );
            },
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
    required this.requestingCode,
    required this.onRequestCode,
  });

  final TextEditingController controller;
  final bool requestingCode;
  final VoidCallback onRequestCode;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return _LoginField(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Verification Code',
                border: InputBorder.none,
              ),
            ),
          ),
          TextButton(
            onPressed: requestingCode ? null : onRequestCode,
            child: Text(
              requestingCode ? 'Sending...' : 'Get Code',
              style: TextStyle(
                color: AppColors.coral,
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

class _Agreement extends StatelessWidget {
  const _Agreement({required this.selected, required this.onChanged});

  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return InkWell(
      onTap: () => onChanged(!selected),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: layout.px(16),
            height: layout.px(16),
            child: selected
                ? const Icon(Icons.check_circle, color: AppColors.coral)
                : Image.asset(AppAssets.loginAgreementUnchecked),
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
                children: const [
                  TextSpan(text: 'I have read and agree to the '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: AppColors.loginAgreementLink,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: AppColors.loginAgreementLink,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
