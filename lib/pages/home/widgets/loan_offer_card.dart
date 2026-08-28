import 'package:flutter/material.dart';

import '../../../theme/app_assets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';
import 'credit_amount.dart';
import 'credit_divider.dart';
import 'loan_offer_card_header.dart';
import 'loan_terms.dart';

class LoanOfferCard extends StatelessWidget {
  const LoanOfferCard({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Semantics(
      button: true,
      label: 'Apply Now',
      child: InkWell(
        onTap: onTap,
        borderRadius: layout.radius(15),
        child: AspectRatio(
          aspectRatio: 335 / 330,
          child: Container(
            padding: layout.edgeInsets(
              left: 44,
              top: 23,
              right: 44,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppAssets.loanOfferCard),
                fit: BoxFit.fill,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LoanOfferCardHeader(),
                SizedBox(height: layout.px(6)),
                Text(
                  'Maximum Credit Amount',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: layout.px(12),
                    fontWeight: FontWeight.w300,
                    height: 14 / 12,
                  ),
                ),
                SizedBox(height: layout.px(6)),
                const CreditDivider(),
                const CreditAmount(),
                const CreditDivider(),
                SizedBox(height: layout.px(8)),
                const LoanTerms(),
                const Spacer(),
                Center(
                  child: SizedBox(
                    height: layout.px(33),
                    child: Center(
                      child: Text(
                        'Apply Now',
                        style: TextStyle(
                          color: AppColors.black,
                          fontSize: layout.px(18),
                          fontWeight: FontWeight.w700,
                          height: 22 / 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
