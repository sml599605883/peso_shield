import 'package:flutter/material.dart';

import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/layout_adapter.dart';
import '../widgets/app_back_button.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: layout.edgeInsets(left: 20, right: 20, bottom: 11),
          child: Column(
            children: [
              Row(
                children: [
                  const AppBackButton(),
                  const Spacer(),
                  Text(
                    'Setting',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: layout.px(20),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(width: layout.px(24)),
                ],
              ),
              SizedBox(height: layout.px(51)),
              Image.asset(
                AppAssets.loginAvatarPlaceholder,
                width: layout.px(111),
                height: layout.px(111),
              ),
              SizedBox(height: layout.px(96)),
              Container(
                width: double.infinity,
                padding: layout.edgeInsets(
                  left: 15,
                  right: 15,
                  top: 18,
                  bottom: 18,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: layout.radius(15),
                  border: const Border.fromBorderSide(
                    BorderSide(color: AppColors.avatarGray),
                  ),
                ),
                child: const Column(
                  children: [
                    _InfoRow('Website', 'xxxxxxxxxxxxxxxx'),
                    SizedBox(height: 37),
                    _InfoRow('E-mail', 'xxxxxxxxx'),
                    SizedBox(height: 37),
                    _InfoRow('Version', 'V1.1.1'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SettingsButton(
            label: 'Deactivate Account',
            backgroundColor: AppColors.settingsDeactivate,
            foregroundColor: AppColors.settingsDeactivateText,
          ),
          SizedBox(height: layout.px(10)),
          const _SettingsButton(
            label: 'Logout',
            backgroundColor: AppColors.coral,
            foregroundColor: AppColors.white,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.settingsInfoLabel,
            fontSize: layout.px(16),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.settingsInfoValue,
            fontSize: layout.px(16),
          ),
        ),
      ],
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return SizedBox(
      width: double.infinity,
      height: layout.px(50),
      child: FilledButton(
        onPressed: () {},
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(borderRadius: layout.radius(25)),
        ),
        child: Text(label, style: TextStyle(fontSize: layout.px(18))),
      ),
    );
  }
}
