import 'package:flutter/material.dart';

import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/layout_adapter.dart';

/// Full-screen state shown when a request cannot reach the network.
class NetworkErrorPage extends StatelessWidget {
  const NetworkErrorPage({
    this.onRetry,
    this.checking = false,
    super.key,
  });

  final VoidCallback? onRetry;
  final bool checking;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: SizedBox.expand(
          child: Column(
            children: [
              // The design includes the 16px page inset and 16px status row
              // before the 171px gap; SafeArea already supplies the status area.
              SizedBox(height: layout.px(179)),
              Image.asset(
                AppAssets.networkErrorIllustration,
                width: layout.px(237),
                height: layout.px(170),
                fit: BoxFit.fill,
              ),
              SizedBox(height: layout.px(27)),
              SizedBox(
                width: layout.px(240),
                child: Text(
                  'Network error, please try again later or contact our customer service',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.black,
                    fontFamily: 'Helvetica',
                    fontSize: layout.px(12),
                    fontWeight: FontWeight.normal,
                    height: 18 / 12,
                  ),
                ),
              ),
              if (onRetry != null) ...[
                SizedBox(height: layout.px(32)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: layout.px(40)),
                  child: SizedBox(
                    width: double.infinity,
                    height: layout.px(48),
                    child: ElevatedButton(
                      onPressed: checking ? null : onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor: AppColors.coral.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(layout.px(24)),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        checking ? 'Checking...' : 'Try Again',
                        style: TextStyle(
                          fontSize: layout.px(14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
