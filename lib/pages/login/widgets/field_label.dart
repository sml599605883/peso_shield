import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';

class LoginFieldLabel extends StatelessWidget {
  const LoginFieldLabel(this.label, {super.key});

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
