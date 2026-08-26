import 'package:flutter/material.dart';

import 'pages/credit_page.dart';
import 'pages/home_page.dart';
import 'pages/mine_page.dart';
import 'theme/app_assets.dart';
import 'theme/app_colors.dart';
import 'theme/layout_adapter.dart';

class RootTabPage extends StatefulWidget {
  const RootTabPage({super.key});

  @override
  State<RootTabPage> createState() => _RootTabPageState();
}

class _RootTabPageState extends State<RootTabPage> {
  int _currentIndex = 0;

  static const _pages = [HomePage(), CreditPage(), MinePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _HomeTabBar(
        currentIndex: _currentIndex,
        onSelected: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _HomeTabBar extends StatelessWidget {
  const _HomeTabBar({required this.currentIndex, required this.onSelected});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return SizedBox(
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
            _TabItem(
              label: 'Home',
              activeIcon: AppAssets.homeActive,
              inactiveIcon: AppAssets.homeInactive,
              selected: currentIndex == 0,
              onTap: () => onSelected(0),
            ),
            _TabItem(
              label: 'Credit',
              activeIcon: AppAssets.creditActive,
              inactiveIcon: AppAssets.creditInactive,
              selected: currentIndex == 1,
              onTap: () => onSelected(1),
            ),
            _TabItem(
              label: 'Mine',
              activeIcon: AppAssets.mineActive,
              inactiveIcon: AppAssets.mineInactive,
              selected: currentIndex == 2,
              onTap: () => onSelected(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.selected,
    required this.onTap,
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
