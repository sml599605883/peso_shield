import 'package:flutter/material.dart';

/// 全局加载和错误提示组件
abstract final class LoadingOverlay {
  static OverlayEntry? _loadingEntry;
  static OverlayEntry? _messageEntry;

  /// 显示加载指示器
  static void show([BuildContext? context]) {
    dismiss();
    final overlay = _getOverlay(context);
    if (overlay == null) return;

    _loadingEntry = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_loadingEntry!);
  }

  /// 隐藏加载指示器
  static void dismiss() {
    _loadingEntry?.remove();
    _loadingEntry = null;
  }

  /// 显示错误消息
  static void showError(String message, [BuildContext? context]) {
    _showMessage(message, isError: true, context: context);
  }

  /// 显示普通消息
  static void showMessage(String message, [BuildContext? context]) {
    _showMessage(message, isError: false, context: context);
  }

  static void _showMessage(
    String message, {
    required bool isError,
    BuildContext? context,
  }) {
    _dismissMessage();
    final overlay = _getOverlay(context);
    if (overlay == null) return;

    _messageEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isError ? Colors.red : Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
    overlay.insert(_messageEntry!);

    Future.delayed(const Duration(seconds: 2), _dismissMessage);
  }

  static void _dismissMessage() {
    _messageEntry?.remove();
    _messageEntry = null;
  }

  static OverlayState? _getOverlay(BuildContext? context) {
    if (context != null && context.mounted) {
      return Overlay.of(context, rootOverlay: true);
    }
    return null;
  }
}
