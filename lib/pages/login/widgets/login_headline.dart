import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';

class LoginHeadline extends StatelessWidget {
  const LoginHeadline({super.key});

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
