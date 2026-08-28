import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';
import 'code_field.dart';
import 'field_label.dart';
import 'login_headline.dart';
import 'login_submit_button.dart';
import 'phone_field.dart';

class LoginFormPanel extends StatelessWidget {
  const LoginFormPanel({
    required this.contentWidth,
    required this.phoneController,
    required this.codeController,
    required this.codeFocusNode,
    required this.requestingCode,
    required this.countdownSeconds,
    required this.loggingIn,
    required this.submitEnabled,
    required this.onRequestCode,
    required this.onSubmit,
    super.key,
  });

  final double contentWidth;
  final TextEditingController phoneController;
  final TextEditingController codeController;
  final FocusNode codeFocusNode;
  final bool requestingCode;
  final int countdownSeconds;
  final bool loggingIn;
  final bool submitEnabled;
  final VoidCallback onRequestCode;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return DecoratedBox(
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
      child: LayoutBuilder(
        builder: (context, panelConstraints) {
          return SingleChildScrollView(
            padding: layout.edgeInsets(left: 20, right: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: panelConstraints.maxHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: layout.px(63)),
                  Padding(
                    padding: layout.edgeInsets(left: 7),
                    child: const LoginHeadline(),
                  ),
                  SizedBox(height: layout.px(42)),
                  const LoginFieldLabel('Please fill in your phone number'),
                  SizedBox(height: layout.px(9)),
                  Padding(
                    padding: layout.edgeInsets(left: 12, right: 19),
                    child: LoginPhoneField(controller: phoneController),
                  ),
                  SizedBox(height: layout.px(20)),
                  const LoginFieldLabel('Send SMS verification code'),
                  SizedBox(height: layout.px(9)),
                  Padding(
                    padding: layout.edgeInsets(left: 12, right: 19),
                    child: LoginCodeField(
                      controller: codeController,
                      focusNode: codeFocusNode,
                      requestingCode: requestingCode,
                      countdownSeconds: countdownSeconds,
                      onRequestCode: onRequestCode,
                    ),
                  ),
                  SizedBox(height: layout.px(42)),
                  LoginSubmitButton(
                    width: contentWidth - layout.px(72),
                    enabled: submitEnabled,
                    loggingIn: loggingIn,
                    onTap: onSubmit,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
