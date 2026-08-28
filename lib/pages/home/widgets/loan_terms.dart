import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';
import 'loan_term.dart';

class LoanTerms extends StatelessWidget {
  const LoanTerms({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Container(
      height: layout.px(85),
      padding: layout.edgeInsets(left: 17, top: 13, right: 17, bottom: 13),
      decoration: BoxDecoration(
        color: AppColors.paleBlue,
        borderRadius: layout.radius(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: LoanTerm(label: 'Loan Term', value: '91-180 Days'),
          ),
          SizedBox(width: layout.px(12)),
          Expanded(
            child: LoanTerm(label: 'Low Interest', value: '≤ 0.05% / Day'),
          ),
        ],
      ),
    );
  }
}
