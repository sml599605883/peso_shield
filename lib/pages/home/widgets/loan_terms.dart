import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';
import '../../../data/models/home_data.dart';
import 'loan_term.dart';

class LoanTerms extends StatelessWidget {
  const LoanTerms({
    required this.loanTerm,
    required this.interestRate,
    this.termLabel = '',
    this.rateLabel = '',
    this.rows = const [],
    super.key,
  });

  final String loanTerm;
  final String interestRate;
  final String termLabel;
  final String rateLabel;
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
          ? Row(
              children: [
                for (var index = 0; index < rows.length; index++) ...[
                  if (index > 0) SizedBox(width: layout.px(12)),
                  Expanded(
                    child: LoanTerm(
                      label: rows[index].label,
                      value: rows[index].value,
                    ),
                  ),
                ],
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: LoanTerm(
                    label: termLabel.isEmpty ? 'Loan Term' : termLabel,
                    value: loanTerm,
                  ),
                ),
                SizedBox(width: layout.px(12)),
                Expanded(
                  child: LoanTerm(
                    label: rateLabel.isEmpty ? 'Low Interest' : rateLabel,
                    value: interestRate,
                  ),
                ),
              ],
            ),
    );
  }
}
