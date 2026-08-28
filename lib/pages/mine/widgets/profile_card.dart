import 'package:flutter/material.dart';

import '../../../theme/app_assets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';
import 'order_item.dart';

class MineProfileCard extends StatelessWidget {
  const MineProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.mineOrdersCard),
          fit: BoxFit.fill,
        ),
      ),
      child: Padding(
        padding: layout.edgeInsets(top: 52, left: 48, right: 48),
        child: Column(
          children: [
            Text(
              '960 **** 5854',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.black,
                fontSize: layout.px(22),
                fontWeight: FontWeight.w800,
                height: 26 / 22,
              ),
            ),
            SizedBox(height: layout.px(29)),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MineOrderItem('All order', AppAssets.mineOrderAll),
                MineOrderItem('Outstanding', AppAssets.mineOrderOutstanding),
                MineOrderItem('Settled', AppAssets.mineOrderSettled),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
