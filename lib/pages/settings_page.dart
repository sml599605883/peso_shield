import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/device/user_session.dart';
import '../core/network/api_exception.dart';
import '../features/settings/account_action_coordinator.dart';
import '../providers/network_provider.dart';
import '../providers/repository_provider.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/layout_adapter.dart';
import '../widgets/app_back_button.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    _InfoDivider(),
                    _InfoRow('E-mail', 'xxxxxxxxx'),
                    _InfoDivider(),
                    _InfoRow('Version', 'V1.1.1'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: layout.edgeInsets(left: 56, right: 56, bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SettingsButton(
                label: 'Deactivate Account',
                backgroundColor: AppColors.settingsDeactivate,
                foregroundColor: AppColors.settingsDeactivateText,
                onPressed: () =>
                    _showAccountDialog(context, ref, isDelete: true),
              ),
              SizedBox(height: layout.px(10)),
              _SettingsButton(
                label: 'Logout',
                backgroundColor: AppColors.coral,
                foregroundColor: AppColors.white,
                onPressed: () => _showAccountDialog(context, ref),
              ),
            ],
          ),
        ),
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

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Divider(height: 1, thickness: 1, color: AppColors.avatarGray),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return SizedBox(
      width: double.infinity,
      height: layout.px(50),
      child: FilledButton(
        onPressed: onPressed,
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

Future<void> _showAccountDialog(
  BuildContext context,
  WidgetRef ref, {
  bool isDelete = false,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color.fromRGBO(0, 0, 0, 0.6),
    builder: (_) => _AccountDialog(
      isDelete: isDelete,
      onConfirm: (selectedAction) =>
          _handleAccountAction(context, ref, selectedAction),
    ),
  );
}

class _AccountDialog extends StatefulWidget {
  const _AccountDialog({required this.isDelete, required this.onConfirm});

  final bool isDelete;
  final Future<bool> Function(AccountAction action) onConfirm;

  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  bool _submitting = false;

  Future<void> _handleAction(AccountAction action) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    // 成功时由 onConfirm 内部 popUntil 关闭本弹窗，无需在此 pop
    await widget.onConfirm(action);
    if (!mounted) return;
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final width = (screenWidth - 64).clamp(0.0, double.infinity);
    final scale = width / 311;
    final layout = _DialogLayout(scale);
    final height = width * 927 / 933;
    final isDelete = widget.isDelete;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                AppAssets.accountDialogPanel,
                fit: BoxFit.fill,
              ),
            ),
            Padding(
              padding: layout.edgeInsets(
                left: 14,
                right: 14,
                top: 46,
                bottom: 17,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: layout.edgeInsets(left: 12),
                    child: Text(
                      isDelete ? 'We\u2019d really miss you' : 'Before You Go',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: layout.px(20),
                        fontFamily: 'Helvetica',
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                  SizedBox(height: layout.px(19)),
                  Container(
                    width: layout.px(283),
                    height: layout.px(139),
                    padding: layout.edgeInsets(
                      left: 28,
                      right: 27,
                      top: 29,
                      bottom: 30,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isDelete
                          ? 'Deleting your account removes all your data, history, and settings forever. This action cannot be undone.'
                          : 'Keep your account connected for a smoother experience and quick access to your application details.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color.fromRGBO(51, 51, 51, 1),
                        fontSize: layout.px(16),
                        fontFamily: 'Helvetica',
                        height: 1.25,
                      ),
                    ),
                  ),
                  SizedBox(height: layout.px(16)),
                  SizedBox(
                    height: layout.px(48),
                    child: Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _DialogAction(
                            label: isDelete ? 'Delete' : 'Logout',
                            layout: layout,
                            enabled: !_submitting,
                            onPressed: () => _handleAction(
                              isDelete
                                  ? AccountAction.deleteAccount
                                  : AccountAction.logout,
                            ),
                          ),
                          SizedBox(width: layout.px(10)),
                          _DialogAction(
                            label: isDelete ? 'Stay Here' : 'Stay',
                            layout: layout,
                            primary: true,
                            enabled: !_submitting,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogAction extends StatelessWidget {
  const _DialogAction({
    required this.label,
    required this.layout,
    required this.onPressed,
    this.primary = false,
    this.enabled = true,
  });

  final String label;
  final _DialogLayout layout;
  final VoidCallback onPressed;
  final bool primary;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: layout.px(48),
        child: TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            backgroundColor: primary ? AppColors.coral : AppColors.white,
            foregroundColor: primary ? AppColors.white : AppColors.mutedBlue,
            disabledBackgroundColor: primary
                ? AppColors.coral.withValues(alpha: 0.6)
                : AppColors.white,
            disabledForegroundColor: primary
                ? AppColors.white.withValues(alpha: 0.6)
                : AppColors.mutedBlue.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(
              borderRadius: layout.radius(24),
              side: primary
                  ? const BorderSide(color: AppColors.white)
                  : BorderSide.none,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: layout.px(18),
              fontWeight: FontWeight.w700,
              height: 22 / 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogLayout {
  const _DialogLayout(this.scale);

  final double scale;

  double px(num value) => value * scale;

  EdgeInsets edgeInsets({
    num left = 0,
    num top = 0,
    num right = 0,
    num bottom = 0,
  }) => EdgeInsets.fromLTRB(px(left), px(top), px(right), px(bottom));

  BorderRadius radius(num value) =>
      BorderRadius.all(Radius.circular(px(value)));
}

Future<bool> _handleAccountAction(
  BuildContext context,
  WidgetRef ref,
  AccountAction action,
) async {
  final cancelFunc = BotToast.showLoading();
  try {
    final authRepository = await ref.read(authRepositoryProvider.future);

    await AccountActionCoordinator(
      authRepository: authRepository,
    ).execute(action);

    // 清除会话，手机号保留供下次登录预填
    await ref.read(userSessionProvider.notifier).clearSession();

    // 强制刷新 httpClient 以使用新的空 token
    ref.invalidate(httpClientProvider);

    if (!context.mounted) return false;

    // 成功后关闭弹窗并返回根页面
    Navigator.of(context).popUntil((route) => route.isFirst);

    return true;
  } on ApiException catch (e) {
    BotToast.showText(text: e.message);
    return false;
  } catch (e) {
    BotToast.showText(text: 'Unexpected error occurred');
    return false;
  } finally {
    cancelFunc();
  }
}
