import 'package:flutter/material.dart';

import '../../../theme/app_assets.dart';
import '../../../theme/layout_adapter.dart';

class LoginIllustrationHeader extends StatelessWidget {
  const LoginIllustrationHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return SizedBox(
      height: layout.px(178),
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.loginIllustration,
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: layout.edgeInsets(left: 16, top: 21),
              child: IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.maybePop(context),
                iconSize: layout.px(24),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(
                  width: layout.px(24),
                  height: layout.px(24),
                ),
                icon: Image.asset(AppAssets.loginBack),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
