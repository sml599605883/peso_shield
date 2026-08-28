import 'package:flutter/material.dart';

import '../../../theme/app_assets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Padding(
      padding: layout.edgeInsets(left: 20, top: 24, right: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Hi!  Welcome',
              style: TextStyle(
                color: AppColors.black,
                fontSize: layout.px(22),
                fontWeight: FontWeight.w700,
                height: 30 / 22,
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Messages',
            child: Image.asset(
              AppAssets.notification,
              width: layout.px(30),
              height: layout.px(32),
            ),
          ),
        ],
      ),
    );
  }
}
