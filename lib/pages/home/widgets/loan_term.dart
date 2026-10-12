import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';

class LoanTerm extends StatelessWidget {
  const LoanTerm({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.mutedBlue,
            fontSize: layout.px(14),
            height: 17 / 14,
          ),
        ),
        SizedBox(height: layout.px(6)),
        SizedBox(
          height: layout.px(19),
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: AppColors.black,
                fontSize: layout.px(16),
                fontWeight: FontWeight.w700,
                height: 19 / 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Term option used when the server delivers loan term rows: the value sits in
/// a rounded badge followed by its unit, e.g. `3` + `Terms`.
class LoanTermOption extends StatelessWidget {
  const LoanTermOption({
    required this.label,
    required this.value,
    required this.unit,
    super.key,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.mutedBlue,
            fontSize: layout.px(14),
            height: 17 / 14,
          ),
        ),
        SizedBox(height: layout.px(6)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: layout.px(27),
              constraints: BoxConstraints(minWidth: layout.px(28)),
              padding: layout.edgeInsets(left: 8, right: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.loanTermBadge,
                borderRadius: layout.radius(6),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: layout.px(22),
                    fontWeight: FontWeight.w700,
                    height: 26 / 22,
                  ),
                ),
              ),
            ),
            SizedBox(width: layout.px(10)),
            Flexible(
              child: Text(
                unit,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: layout.px(16),
                  fontWeight: FontWeight.w700,
                  height: 19 / 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
