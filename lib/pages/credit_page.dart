import 'package:flutter/material.dart';

import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/layout_adapter.dart';

class CreditPage extends StatefulWidget {
  const CreditPage({super.key});

  @override
  State<CreditPage> createState() => _CreditPageState();
}

class _CreditPageState extends State<CreditPage> {
  static const _filters = ['All order', 'Outstanding', 'Overdue', 'Settled'];
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.homeBackground),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayout.maxContentWidth,
                ),
                child: Padding(
                  padding: layout.edgeInsets(left: 20, right: 20, bottom: 24),
                  child: Column(
                    children: [
                      SizedBox(height: layout.px(19)),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Hi!  Welcome',
                              style: TextStyle(
                                color: AppColors.black,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                height: 26 / 22,
                              ),
                            ),
                          ),
                          Image.asset(
                            AppAssets.notification,
                            width: layout.px(29),
                            height: layout.px(32),
                            semanticLabel: 'Messages',
                          ),
                        ],
                      ),
                      SizedBox(height: layout.px(10)),
                      Container(
                        height: layout.px(40),
                        padding: EdgeInsets.all(layout.px(3)),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: layout.radius(20),
                        ),
                        child: Row(
                          children: List.generate(_filters.length, (index) {
                            final selected = index == _selectedFilter;
                            return Expanded(
                              flex: index == 1 ? 113 : 74,
                              child: Semantics(
                                selected: selected,
                                button: true,
                                child: Material(
                                  color: selected
                                      ? AppColors.coral
                                      : AppColors.white,
                                  borderRadius: layout.radius(20),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () =>
                                        setState(() => _selectedFilter = index),
                                    child: Center(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: Text(
                                            _filters[index],
                                            style: TextStyle(
                                              color: selected
                                                  ? AppColors.white
                                                  : AppColors
                                                        .identityUnselected,
                                              fontSize: 12,
                                              height: 18 / 12,
                                              fontWeight: selected
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      SizedBox(height: layout.px(116)),
                      Image.asset(
                        AppAssets.creditEmpty,
                        width: layout.px(204),
                        height: layout.px(170),
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                      SizedBox(height: layout.px(19)),
                      const Text(
                        'No information available',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.black,
                          fontSize: 14,
                          height: 18 / 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
