import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Toast 提示工具类
class ToastHelper {
  ToastHelper._();

  /// 显示普通提示
  static void showMessage(String message) {
    if (message.isEmpty) return;

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.black.withOpacity(0.8),
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  /// 显示成功提示
  static void showSuccess(String message) {
    if (message.isEmpty) return;

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.green.withOpacity(0.8),
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  /// 显示错误提示
  static void showError(String message) {
    if (message.isEmpty) return;

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red.withOpacity(0.8),
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  /// 取消当前显示的 Toast
  static void cancel() {
    Fluttertoast.cancel();
  }
}
