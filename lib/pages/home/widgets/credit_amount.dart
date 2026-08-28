import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';

class CreditAmount extends StatelessWidget {
  const CreditAmount({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '₱',
            style: TextStyle(
              fontSize: layout.px(36),
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: ' 60,000',
            style: TextStyle(
              fontSize: layout.px(50),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.black, height: 60 / 50),
    );
  }
}
