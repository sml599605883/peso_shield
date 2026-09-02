import 'package:flutter/material.dart';

import '../../theme/app_assets.dart';
import '../../theme/layout_adapter.dart';

/// Prompt and shield illustration used at the top of identity upload flows.
class IdentityUploadPrompt extends StatelessWidget {
  const IdentityUploadPrompt({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: layout.edgeInsets(left: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Padding(
                padding: layout.edgeInsets(left: 10, bottom: 17),
                child: Text(
                  message,
                  style: TextStyle(
                    color: const Color.fromRGBO(50, 99, 110, 1),
                    fontFamily: 'Helvetica',
                    fontSize: layout.px(16),
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                    height: 18 / 16,
                  ),
                ),
              ),
            ),
            Image.asset(
              AppAssets.identityShieldIllustration,
              width: layout.px(113),
              height: layout.px(117),
            ),
          ],
        ),
      ),
    );
  }
}
