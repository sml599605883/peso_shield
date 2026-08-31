import 'package:flutter/material.dart';

import '../theme/app_assets.dart';
import '../theme/layout_adapter.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return IconButton(
      tooltip: 'Back',
      onPressed: () => Navigator.maybePop(context),
      iconSize: layout.px(24),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(
        width: layout.px(24),
        height: layout.px(24),
      ),
      icon: Image.asset(AppAssets.loginBack),
    );
  }
}
