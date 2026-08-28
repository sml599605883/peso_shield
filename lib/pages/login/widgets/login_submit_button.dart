import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';

class LoginSubmitButton extends StatelessWidget {
  const LoginSubmitButton({
    required this.width,
    required this.enabled,
    required this.loggingIn,
    required this.onTap,
    super.key,
  });

  final double width;
  final bool enabled;
  final bool loggingIn;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Center(
      child: SizedBox(
        width: width,
        height: layout.px(50),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: enabled ? AppColors.coral : AppColors.loginDisabled,
              borderRadius: layout.radius(25),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: layout.radius(25),
              child: Center(
                child: loggingIn
                    ? SizedBox.square(
                        dimension: layout.px(18),
                        child: const CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Sign up / Sign in',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: layout.px(18),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
