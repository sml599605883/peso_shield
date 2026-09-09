import 'package:flutter/material.dart';

import '../../../theme/layout_adapter.dart';
import 'app_identity.dart';

class LoanOfferCardHeader extends StatelessWidget {
  const LoanOfferCardHeader({
    required this.name,
    required this.logoUrl,
    super.key,
  });

  final String name;
  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return SizedBox(
      height: layout.px(44),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIdentity(name: name, logoUrl: logoUrl),
          const Spacer(),
        ],
      ),
    );
  }
}
