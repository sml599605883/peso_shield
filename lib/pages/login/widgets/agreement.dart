import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_assets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';

class LoginAgreement extends StatefulWidget {
  const LoginAgreement({
    required this.selected,
    required this.onChanged,
    this.onPrivacyPolicyTap,
    super.key,
  });

  final bool selected;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onPrivacyPolicyTap;

  @override
  State<LoginAgreement> createState() => _LoginAgreementState();
}

class _LoginAgreementState extends State<LoginAgreement> {
  late final TapGestureRecognizer _privacyPolicyRecognizer;

  @override
  void initState() {
    super.initState();
    _privacyPolicyRecognizer = TapGestureRecognizer()
      ..onTap = widget.onPrivacyPolicyTap;
  }

  @override
  void didUpdateWidget(covariant LoginAgreement oldWidget) {
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
