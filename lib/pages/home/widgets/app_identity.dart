import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';

class AppIdentity extends StatelessWidget {
  const AppIdentity({required this.name, required this.logoUrl, super.key});

  final String name;
  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Container(
      padding: layout.edgeInsets(left: 5, top: 4, right: 6, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: layout.radius(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: layout.px(11),
            backgroundColor: AppColors.avatarGray,
            backgroundImage: logoUrl.isEmpty ? null : NetworkImage(logoUrl),
          ),
          SizedBox(width: layout.px(6)),
          Text(
            name,
            style: TextStyle(
              color: AppColors.black,
              fontSize: layout.px(16),
              fontWeight: FontWeight.w700,
              height: 19 / 16,
            ),
          ),
        ],
      ),
    );
  }
}
