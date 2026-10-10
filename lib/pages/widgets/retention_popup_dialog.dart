import 'package:flutter/material.dart';

import '../../data/models/retention_popup_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/layout_adapter.dart';

/// 认证流程返回挽留弹窗。
///
/// 设计稿：上方为服务端下发的完整弹窗插画，下方为“退出 / 继续”两个按钮。
/// 两个按钮固定在图片下方，避免像旧实现那样叠加在插画文案上造成遮挡。
class RetentionPopupDialog extends StatelessWidget {
  const RetentionPopupDialog({
    required this.data,
    this.imageProvider,
    super.key,
  });

  final RetentionPopupData data;

  /// 测试时可注入本地图片，避免依赖网络。
  final ImageProvider<Object>? imageProvider;

  /// 设计稿（375pt 宽）尺寸。
  static const _imageWidth = 330.0;
  static const _buttonRowWidth = 266.0;
  static const _buttonHeight = 48.0;
  static const _buttonGap = 10.0;

  /// 显示挽留弹窗，返回 true 表示用户选择继续认证，false 表示离开。
  static Future<bool> show(
    BuildContext context,
    RetentionPopupData data,
  ) async {
    if (!data.shouldShow || data.imageUrl.isEmpty) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.dialogBarrier,
      barrierDismissible: false,
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: RetentionPopupDialog(data: data),
      ),
    );

    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: layout.edgeInsets(top: 24, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image(
                image: imageProvider ?? NetworkImage(data.imageUrl),
                width: layout.px(_imageWidth),
                fit: BoxFit.fitWidth,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
              SizedBox(height: layout.px(4)),
              SizedBox(
                width: layout.px(_buttonRowWidth),
                height: layout.px(_buttonHeight),
                child: Row(
                  children: [
                    Expanded(
                      child: _RetentionButton(
                        text: data.cancelText.isNotEmpty
                            ? data.cancelText
                            : 'Exit',
                        background: AppColors.white,
                        foreground: AppColors.retentionExitText,
                        onTap: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    SizedBox(width: layout.px(_buttonGap)),
                    Expanded(
                      child: _RetentionButton(
                        text: data.confirmText.isNotEmpty
                            ? data.confirmText
                            : 'Continue',
                        background: AppColors.retentionPrimary,
                        foreground: AppColors.white,
                        onTap: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RetentionButton extends StatelessWidget {
  const _RetentionButton({
    required this.text,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String text;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: layout.edgeInsets(left: 12, right: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: layout.radius(24),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foreground,
            fontSize: layout.px(18),
            fontWeight: FontWeight.w700,
            height: 22 / 18,
          ),
        ),
      ),
    );
  }
}
