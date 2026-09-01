import 'package:flutter/material.dart';

import '../theme/app_assets.dart';
import '../theme/layout_adapter.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Semantics(
      button: true,
      label: 'Back',
      child: InkResponse(
        onTap: () => Navigator.maybePop(context),
        radius: layout.px(20),
        child: SizedBox(
          width: layout.px(24),
          height: layout.px(24),
          child: Image.asset(
            AppAssets.loginBack,
            width: layout.px(24),
            height: layout.px(24),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
