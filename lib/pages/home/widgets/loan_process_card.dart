import 'package:flutter/material.dart';
import '../../../data/models/home_data.dart';

import '../../../theme/app_assets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';

class LoanProcessCard extends StatelessWidget {
  const LoanProcessCard({super.key, this.steps = const []});

  final List<LoanProcessStep> steps;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    if (steps.isNotEmpty) {
      return _LoanProcessStatusCard(layout: layout, steps: steps);
    }
    return Container(
      key: const Key('loan-process-card'),
      width: double.infinity,
      height: layout.px(121),
      margin: layout.edgeInsets(left: 20, right: 20),
      padding: layout.edgeInsets(left: 19, top: 17, right: 19, bottom: 19),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: layout.radius(15),
      ),
      child: Image.asset(AppAssets.loanProcessSteps, fit: BoxFit.fill),
    );
  }
}

class _LoanProcessStatusCard extends StatelessWidget {
  const _LoanProcessStatusCard({required this.layout, required this.steps});

  final AppLayout layout;
  final List<LoanProcessStep> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('loan-process-status-card'),
      width: double.infinity,
      height: layout.px(98),
      margin: layout.edgeInsets(left: 20, right: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: layout.radius(15),
      ),
      child: Stack(
        children: [
          Positioned(
            left: layout.px(12),
            right: layout.px(12),
            top: layout.px(22),
            height: layout.px(4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.loanProcessTrack,
                borderRadius: layout.radius(4),
              ),
            ),
          ),
          Positioned(
            left: layout.px(12),
            right: layout.px(12),
            top: layout.px(15),
            height: layout.px(65),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < steps.length; index++) ...[
                  if (index > 0) SizedBox(width: layout.px(8)),
                  Expanded(
                    child: _LoanProcessStatusItem(
                      layout: layout,
                      title: steps[index].title,
                      amount: steps[index].amount,
                      active: steps[index].active,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanProcessStatusItem extends StatelessWidget {
  const _LoanProcessStatusItem({
    required this.layout,
    required this.title,
    required this.amount,
    required this.active,
  });

  final AppLayout layout;
  final String title;
  final String amount;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final textColor = active ? AppColors.white : AppColors.loanProcessInactive;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // The exported background includes the pointer and shadow outsets.
        Positioned(
          left: layout.px(-4),
          right: layout.px(-4),
          top: layout.px(20),
          height: layout.px(51),
          child: Image.asset(
            active
                ? AppAssets.loanProcessCardActiveBackground
                : AppAssets.loanProcessCardInactiveBackground,
            fit: BoxFit.fill,
          ),
        ),
        Image.asset(
          active
              ? AppAssets.loanProcessLockActive
              : AppAssets.loanProcessLockInactive,
          width: layout.px(19),
          height: layout.px(19),
        ),
        Positioned(
          top: layout.px(34),
          left: 0,
          right: 0,
          height: layout.px(10),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                color: textColor,
                fontFamily: 'Helvetica',
                fontSize: layout.px(8),
                height: 10 / 8,
              ),
            ),
          ),
        ),
        Positioned(
          top: layout.px(43),
          left: layout.px(4),
          right: layout.px(4),
          height: layout.px(17),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: TextStyle(
                color: textColor,
                fontFamily: 'Helvetica',
                fontSize: layout.px(14),
                fontWeight: FontWeight.w700,
                height: 17 / 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
