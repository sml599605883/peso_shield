import 'package:flutter/material.dart';

import '../../../theme/app_assets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';

class LoanProcessCard extends StatelessWidget {
  const LoanProcessCard({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Container(
      key: const Key('loan-process-card'),
      width: double.infinity,
      height: layout.px(121),
      margin: layout.edgeInsets(left: 20, right: 20),
      padding: layout.edgeInsets(left: 19, top: 17, right: 19, bottom: 19),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: layout.radius(15),
      ),
      child: Image.asset(AppAssets.loanProcessSteps, fit: BoxFit.fill),
    );
  }
}
