import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';
import 'login_field.dart';

class LoginCodeField extends StatelessWidget {
  const LoginCodeField({
    required this.controller,
    required this.focusNode,
    required this.requestingCode,
    required this.countdownSeconds,
    required this.onRequestCode,
    super.key,
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

    return LoginField(
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
