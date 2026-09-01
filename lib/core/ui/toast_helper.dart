import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

/// Toast 和 Loading 提示工具类
///
/// 所有提示都居中显示，并在展示期间拦截用户交互。
class ToastHelper {
  ToastHelper._();

  static const _textDuration = Duration(seconds: 2);
  static const _animationDuration = Duration(milliseconds: 200);

  /// 显示 Loading
  static CancelFunc showLoading({String? message}) {
    return BotToast.showLoading(
      clickClose: false,
      allowClick: false,
      crossPage: true,
      align: Alignment.center,
      enableKeyboardSafeArea: false,
    );
  }

  /// 隐藏 Loading
  static void hideLoading() {
    BotToast.closeAllLoading();
  }

  /// 显示普通提示
  static void showMessage(String message) {
    _showText(message);
  }

  /// 显示成功提示
  static void showSuccess(String message) {
    _showText(message);
  }

  /// 显示错误提示
  static void showError(String message) {
    _showText(message);
  }

  /// 取消所有提示
  static void cancel() {
    BotToast.closeAllLoading();
    BotToast.removeAll(BotToast.textKey);
  }

  /// BotToast.showText 内部把 allowClick 固定为 true，无法拦截点击，
  /// 因此直接用 showAnimationWidget 自行组装居中且拦截交互的文本提示。
  ///
  /// enableKeyboardSafeArea 必须关掉：它会给整个 Toast 区域垫上等于键盘高度的
  /// 底部 padding，剩余区域居中就会偏上。
  static void _showText(String message) {
    if (message.isEmpty) return;
    BotToast.showAnimationWidget(
      groupKey: BotToast.textKey,
      crossPage: true,
      allowClick: false,
      clickClose: false,
      ignoreContentClick: true,
      onlyOne: true,
      enableKeyboardSafeArea: false,
      duration: _textDuration,
      animationDuration: _animationDuration,
      wrapToastAnimation: (controller, cancel, child) => FadeTransition(
        opacity: controller,
        child: Align(alignment: Alignment.center, child: child),
      ),
      toastBuilder: (_) => _CenteredTextToast(text: message),
    );
  }
}

class _CenteredTextToast extends StatelessWidget {
  const _CenteredTextToast({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.7,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }
}
