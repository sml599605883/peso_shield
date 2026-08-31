import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

/// Toast 和 Loading 提示工具类
class ToastHelper {
  ToastHelper._();

  /// 显示 Loading
  static CancelFunc showLoading({String? message}) {
    return BotToast.showLoading(
      clickClose: false,
      allowClick: false,
      crossPage: true,
    );
  }

  /// 隐藏 Loading
  static void hideLoading() {
    BotToast.closeAllLoading();
  }

  /// 显示普通提示
  static void showMessage(String message) {
    if (message.isEmpty) return;
    BotToast.showText(
      text: message,
      duration: const Duration(seconds: 2),
      contentColor: Colors.black.withOpacity(0.8),
      textStyle: const TextStyle(color: Colors.white, fontSize: 14),
    );
  }

  /// 显示成功提示
  static void showSuccess(String message) {
    if (message.isEmpty) return;
    BotToast.showText(
      text: message,
      duration: const Duration(seconds: 2),
      contentColor: Colors.green.withOpacity(0.8),
      textStyle: const TextStyle(color: Colors.white, fontSize: 14),
    );
  }

  /// 显示错误提示
  static void showError(String message) {
    if (message.isEmpty) return;
    BotToast.showText(
      text: message,
      duration: const Duration(seconds: 2),
      contentColor: Colors.red.withOpacity(0.8),
      textStyle: const TextStyle(color: Colors.white, fontSize: 14),
    );
  }

  /// 取消所有提示
  static void cancel() {
    BotToast.closeAllLoading();
  }
}
