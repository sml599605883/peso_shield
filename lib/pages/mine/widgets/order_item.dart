import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';

class MineOrderItem extends StatelessWidget {
  const MineOrderItem(this.label, this.asset, {super.key});

  final String label;
  final String asset;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return SizedBox(
      width: layout.px(65),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(asset, width: layout.px(53), height: layout.px(53)),
          SizedBox(height: layout.px(10)),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(
              color: AppColors.black,
              fontSize: layout.px(12),
              height: 18 / 12,
            ),
          ),
        ],
      ),
    );
  }
}
