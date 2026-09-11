import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/retention_popup_data.dart';
import '../../theme/app_colors.dart';

/// 认证流程返回挽留弹窗
/// 设计稿: 背景图由服务端完整下发，底部两个按钮需要客户端实现
class RetentionPopupDialog extends StatelessWidget {
  const RetentionPopupDialog({
    required this.data,
    super.key,
  });

  final RetentionPopupData data;

  static const _designWidth = 343.0;
  static const _designHeight = 332.0;

  /// 显示挽留弹窗，返回 true 表示用户选择继续认证，false 表示离开
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final availableWidth = screenWidth - 32;
    final scale = math.min(availableWidth / _designWidth, 1.0);
    final cardWidth = _designWidth * scale;
    final cardHeight = _designHeight * scale;

    return Center(
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: Stack(
          children: [
            // 背景图片（服务端下发的完整内容）
            Positioned.fill(
              child: Image.network(
                data.imageUrl,
                fit: BoxFit.fill,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),

            // 继续按钮（渐变按钮）
            Positioned(
              left: 12 * scale,
              right: 12 * scale,
              top: 237 * scale,
              height: 40 * scale,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(true),
                child: Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.retentionGradientStart,
                        AppColors.retentionGradientMiddle,
                        AppColors.retentionGradientEnd,
                      ],
                      stops: [0, 0.47929414, 1],
                    ),
                    borderRadius: BorderRadius.circular(20 * scale),
                  ),
                  child: Text(
                    data.confirmText.isNotEmpty ? data.confirmText : 'Continue',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w700,
                      height: 18 / 15,
                    ),
                  ),
                ),
              ),
            ),

            // 退出按钮（纯文字）
            Positioned(
              left: 12 * scale,
              right: 12 * scale,
              top: 293 * scale,
              height: 18 * scale,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.of(context).pop(false);
                },
                child: Center(
                  child: Text(
                    data.cancelText.isNotEmpty ? data.cancelText : 'Exit',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.retentionSecondary,
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w700,
                      height: 18 / 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
