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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
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
            alignment: Alignment.centerLeft,
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
