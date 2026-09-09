import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';
import '../../../data/models/home_data.dart';
import 'loan_term.dart';

class LoanTerms extends StatelessWidget {
  const LoanTerms({
    required this.loanTerm,
    required this.interestRate,
    this.rows = const [],
    super.key,
  });

  final String loanTerm;
  final String interestRate;
  final List<LoanTermRow> rows;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Container(
      height: layout.px(69),
      padding: layout.edgeInsets(left: 17, top: 13, right: 17, bottom: 13),
      decoration: BoxDecoration(
        color: AppColors.paleBlue,
        borderRadius: layout.radius(15),
      ),
      child: rows.isNotEmpty
          ? Column(
              children: [
                for (final row in rows)
                  Expanded(
                    child: LoanTerm(label: row.label, value: row.value),
                  ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: LoanTerm(label: 'Loan Term', value: loanTerm),
                ),
                SizedBox(width: layout.px(12)),
                Expanded(
                  child: LoanTerm(label: 'Low Interest', value: interestRate),
                ),
              ],
            ),
    );
  }
}
