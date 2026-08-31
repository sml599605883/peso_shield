import 'package:flutter/material.dart';

import '../../../theme/app_assets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';

class MineServiceRow extends StatelessWidget {
  const MineServiceRow(
    this.label,
    this.asset, {
    this.hasDivider = false,
    this.onTap,
    super.key,
  });

  final String label;
  final String asset;
  final bool hasDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: hasDivider
                ? const Border(
                    bottom: BorderSide(color: AppColors.mineServiceDivider),
                  )
                : null,
          ),
          child: SizedBox(
            height: layout.px(58),
            child: Padding(
              padding: layout.edgeInsets(left: 17, right: 17),
              child: Row(
                children: [
                  Image.asset(
                    asset,
                    width: layout.px(22),
                    height: layout.px(20),
                  ),
                  SizedBox(width: layout.px(20)),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: AppColors.mineServiceText,
                        fontSize: layout.px(16),
                        height: 20 / 16,
                      ),
                    ),
                  ),
                  Image.asset(
                    AppAssets.mineChevron,
                    width: layout.px(7),
                    height: layout.px(12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
