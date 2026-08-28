import 'package:flutter/material.dart';

import '../../../theme/app_assets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';

class MineServiceTitle extends StatelessWidget {
  const MineServiceTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        height: layout.px(42),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppAssets.loanProcessTitle),
              fit: BoxFit.fitHeight,
            ),
          ),
          alignment: Alignment.topCenter,
          padding: layout.edgeInsets(top: 6, left: 13, right: 13),
          child: Text(
            'Our Service',
            style: TextStyle(
              color: AppColors.white,
              fontSize: layout.px(16),
              fontWeight: FontWeight.w700,
              height: 19 / 16,
            ),
          ),
        ),
      ),
    );
  }
}
