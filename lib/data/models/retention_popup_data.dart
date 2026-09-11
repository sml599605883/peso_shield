/// 认证流程返回挽留弹窗数据模型
class RetentionPopupData {
  const RetentionPopupData({
    this.title = '',
    this.message = '',
    this.duration = 0,
    this.imageUrl = '',
    this.confirmText = '',
    this.cancelText = '',
  });

  factory RetentionPopupData.fromJson(Map<String, dynamic> json) {
    final data = json['abysmal'];
    if (data == null || data is! Map<String, dynamic>) {
      return const RetentionPopupData();
    }
    
    return RetentionPopupData(
      title: _text(data['stalagmitic']),
      message: _text(data['closets']),
      duration: _parseInt(data['desalting']),
      imageUrl: _text(data['mycelia']),
      confirmText: _text(data['tallyhoing']),
      cancelText: _text(data['nonconventional']),
    );
  }

  /// 弹窗标题
  final String title;

  /// 弹窗正文内容
  final String message;

  /// 持续时间（毫秒）
  final int duration;

  /// 弹窗图片 URL（可选）
  final String imageUrl;

  /// 确认按钮文案（继续认证）
  final String confirmText;

  /// 取消按钮文案（离开页面）
  final String cancelText;

  /// 是否应该展示弹窗（有标题或正文时展示）
  bool get shouldShow => title.isNotEmpty || message.isNotEmpty;

  static int _parseInt(Object? value) => int.tryParse('$value') ?? 0;
  static String _text(Object? value) => value?.toString().trim() ?? '';
}
