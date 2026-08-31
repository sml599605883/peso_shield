import 'package:flutter/material.dart';

import '../../../theme/app_assets.dart';
import '../../../theme/layout_adapter.dart';
import 'profile_card.dart';

class MineProfileHeader extends StatelessWidget {
  const MineProfileHeader({required this.layout, this.phone, super.key});

  final AppLayout layout;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth - layout.px(20);
        final cardHeight = cardWidth * 235 / 355;
        return SizedBox(
          height: layout.px(84) + cardHeight + layout.px(10),
          child: Stack(
            children: [
              Positioned(
                top: layout.px(84),
                left: layout.px(10),
                width: cardWidth,
                height: cardHeight,
                child: MineProfileCard(phone: phone),
              ),
              Positioned(
                top: layout.px(49),
                left: 0,
                right: 0,
                child: Center(
                  child: Image.asset(
                    AppAssets.mineAvatar,
                    width: layout.px(81),
                    height: layout.px(81),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
