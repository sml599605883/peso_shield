import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';

class CreditAmount extends StatelessWidget {
  const CreditAmount({required this.amount, super.key});

  final String amount;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return SizedBox(
      height: layout.px(60),
      child: Center(
        child: Text(
          amount,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.black,
            fontSize: layout.px(50),
            fontWeight: FontWeight.w700,
            height: 60 / 50,
          ),
        ),
      ),
    );
  }
}
