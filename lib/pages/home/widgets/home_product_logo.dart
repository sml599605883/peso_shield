import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class HomeProductLogo extends StatelessWidget {
  const HomeProductLogo({super.key, required this.url, required this.size});
  final String url;
  final double size;
  @override
  Widget build(BuildContext context) => ClipOval(
    child: SizedBox.square(
      dimension: size,
      child: url.isEmpty
          ? const ColoredBox(color: AppColors.avatarGray)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: AppColors.avatarGray),
            ),
    ),
  );
}
