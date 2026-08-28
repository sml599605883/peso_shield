import 'package:flutter/material.dart';

import '../../theme/app_assets.dart';
import '../../theme/app_colors.dart';
import '../../theme/layout_adapter.dart';
import 'tab_item.dart';

class HomeTabBar extends StatelessWidget {
  const HomeTabBar({
    required this.currentIndex,
    required this.onSelected,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return SizedBox(
      key: const Key('home-tab-bar'),
      height: layout.px(70) + bottomInset,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppAssets.homeBackground),
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),
          if (bottomInset > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: bottomInset,
              child: const ColoredBox(color: AppColors.white),
            ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: layout.px(70),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AppAssets.tabBarBackground),
                  fit: BoxFit.fill,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  HomeTabItem(
                    label: 'Home',
                    activeIcon: AppAssets.homeActive,
                    inactiveIcon: AppAssets.homeInactive,
                    selected: currentIndex == 0,
                    onTap: () => onSelected(0),
                  ),
                  HomeTabItem(
                    label: 'Credit',
                    activeIcon: AppAssets.creditActive,
                    inactiveIcon: AppAssets.creditInactive,
                    selected: currentIndex == 1,
                    onTap: () => onSelected(1),
                  ),
                  HomeTabItem(
                    label: 'Mine',
                    activeIcon: AppAssets.mineActive,
                    inactiveIcon: AppAssets.mineInactive,
                    selected: currentIndex == 2,
                    onTap: () => onSelected(2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
