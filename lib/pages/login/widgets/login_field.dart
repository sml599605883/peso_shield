import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';

class LoginField extends StatelessWidget {
  const LoginField({required this.child, super.key});

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
