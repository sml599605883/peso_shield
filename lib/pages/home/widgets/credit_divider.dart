import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';

class CreditDivider extends StatelessWidget {
  const CreditDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Container(height: layout.px(1), color: AppColors.dividerBlue);
  }
}
