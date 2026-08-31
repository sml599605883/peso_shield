import 'package:flutter_easyloading/flutter_easyloading.dart';

/// Toast 和 Loading 提示工具类
class ToastHelper {
  ToastHelper._();

  /// 显示 Loading
  static void showLoading({String? message}) {
    EasyLoading.show(
      status: message ?? 'Loading...',
      maskType: EasyLoadingMaskType.clear,
    );
  }

  /// 隐藏 Loading
  static void hideLoading() {
    EasyLoading.dismiss();
  }

  /// 显示普通提示
  static void showMessage(String message) {
    if (message.isEmpty) return;
    EasyLoading.showToast(
      message,
      duration: const Duration(seconds: 2),
      toastPosition: EasyLoadingToastPosition.center,
    );
  }

  /// 显示成功提示
  static void showSuccess(String message) {
    if (message.isEmpty) return;
    EasyLoading.showSuccess(
      message,
      duration: const Duration(seconds: 2),
      maskType: EasyLoadingMaskType.clear,
    );
  }

  /// 显示错误提示
  static void showError(String message) {
    if (message.isEmpty) return;
    EasyLoading.showError(
      message,
      duration: const Duration(seconds: 2),
      maskType: EasyLoadingMaskType.clear,
    );
  }

  /// 取消当前显示的提示
  static void cancel() {
    EasyLoading.dismiss();
  }
}
