import 'package:flutter/material.dart';

import '../theme/app_assets.dart';
import '../theme/layout_adapter.dart';
import 'mine/widgets/widgets.dart';

class MinePage extends StatelessWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.homeBackground),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              MineProfileHeader(layout: layout),
              const MineServiceTitle(),
              SizedBox(height: layout.px(11)),
              Padding(
                padding: layout.edgeInsets(left: 20, right: 20),
                child: const MineServiceList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
