import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/layout_adapter.dart';

class HomeTabItem extends StatelessWidget {
  const HomeTabItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final String activeIcon;
  final String inactiveIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: layout.px(75),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                selected ? activeIcon : inactiveIcon,
                width: layout.px(34),
                height: layout.px(34),
              ),
              SizedBox(height: layout.px(2)),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? AppColors.selectedNavigation
                      : AppColors.unselectedNavigation,
                  fontSize: layout.px(12),
                  height: 14 / 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
