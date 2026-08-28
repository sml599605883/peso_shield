import 'package:flutter/material.dart';

import '../../../theme/app_assets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';
import 'service_row.dart';

class MineServiceList extends StatelessWidget {
  const MineServiceList({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(layout.px(15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: layout.px(8),
            offset: Offset(0, layout.px(4)),
          ),
        ],
      ),
      child: Column(
        children: [
          const MineServiceRow(
            'Online Services',
            AppAssets.mineOnlineService,
            hasDivider: true,
          ),
          const MineServiceRow(
            'Setting',
            AppAssets.mineSetting,
            hasDivider: true,
          ),
          const MineServiceRow('Privacy Agreement', AppAssets.minePrivacy),
        ],
      ),
    );
  }
}
