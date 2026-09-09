import 'package:flutter/material.dart';
import 'package:peso_shield/pages/mine/widgets/service_title.dart';
import '../../../theme/layout_adapter.dart';
import '../../../data/models/home_data.dart';
import 'loan_process_card.dart';

class LoanProcessSection extends StatelessWidget {
  const LoanProcessSection({super.key, this.grummer = const []});

  final List<LoanProcessStep> grummer;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Column(
      children: [
        SizedBox(height: layout.px(15)),
        MineServiceTitle(title: 'Loan Process'),
        LoanProcessCard(steps: grummer),
      ],
    );
  }
}
