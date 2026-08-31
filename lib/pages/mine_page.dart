import 'package:flutter/material.dart';

import '../theme/app_assets.dart';
import '../theme/layout_adapter.dart';
import '../core/navigation/app_routes.dart';
import 'mine/widgets/widgets.dart';

class MinePage extends StatelessWidget {
  const MinePage({this.phone, super.key});

  final String? phone;

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    MineProfileHeader(layout: layout, phone: phone),
                    const MineServiceTitle(),
                    SizedBox(height: layout.px(11)),
                    Padding(
                      padding: layout.edgeInsets(left: 20, right: 20),
                      child: MineServiceList(
                        onSettingTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.settings),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
