import 'package:flutter/material.dart';

import '../../../theme/layout_adapter.dart';
import 'app_identity.dart';

class LoanOfferCardHeader extends StatelessWidget {
  const LoanOfferCardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return SizedBox(
      height: layout.px(44),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [const AppIdentity(), const Spacer()],
      ),
    );
  }
}
