import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';
import 'login_field.dart';

class LoginPhoneField extends StatelessWidget {
  const LoginPhoneField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return LoginField(
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
