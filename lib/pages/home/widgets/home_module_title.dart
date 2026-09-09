import 'package:flutter/material.dart';
import '../../../theme/app_assets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';

class HomeModuleTitle extends StatelessWidget {
  const HomeModuleTitle({super.key, required this.title, required this.width});
  final String title;
  final double width;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return SizedBox(
      width: layout.px(width),
      height: layout.px(42),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(AppAssets.loanProcessTitle, fit: BoxFit.fill),
          ),
          Positioned(
            left: layout.px(13),
            right: layout.px(9),
            top: layout.px(6),
            height: layout.px(19),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Helvetica',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
