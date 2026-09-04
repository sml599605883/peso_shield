class ProductApplyResult {
  const ProductApplyResult({
    required this.statusCode,
    required this.jumpUrl,
    required this.jumpType,
    required this.message,
    this.dialog,
    this.accessKey,
    this.secretKey,
  });

  factory ProductApplyResult.fromJson(Map<String, dynamic> json) {
    return ProductApplyResult(
      statusCode: json['recklessly'] as int? ?? 0,
      jumpUrl: json['mycelia'] as String? ?? '',
      jumpType: json['bellings'] as int? ?? 0,
      message: json['decoct'] as String? ?? '',
      dialog: json['abysmal'] != null
          ? ApplyDialog.fromJson(json['abysmal'] as Map<String, dynamic>)
          : null,
      accessKey: json['unroped'] as String?,
      secretKey: json['gazania'] as String?,
    );
  }

  final int statusCode;
  final String jumpUrl;
  final int jumpType; // 0: 原生, 1: H5
  final String message;
  final ApplyDialog? dialog;
  final String? accessKey; // advance accessKey
  final String? secretKey; // advance secretKey

  /// 是否准入成功（statusCode == 200）
  bool get isAdmitted => statusCode == 200;

  /// 是否需要跳转 H5
  bool get needsWebJump => jumpType == 1 && jumpUrl.isNotEmpty;

  /// 是否是授信页（ph://peso-shield/ios/Umbrages）
  bool get isCreditReview {
    final uri = Uri.tryParse(jumpUrl);
    return uri?.scheme == 'ph' &&
        uri?.host == 'peso-shield' &&
        uri?.pathSegments.length == 2 &&
        uri?.pathSegments[0] == 'ios' &&
        uri?.pathSegments[1] == 'Umbrages';
  }
}

class ApplyDialog {
  const ApplyDialog({
    required this.title,
    required this.content,
    required this.leftButton,
    required this.rightButton,
  });

  factory ApplyDialog.fromJson(Map<String, dynamic> json) {
    final buttons = json['birls'] as List<dynamic>? ?? [];
    return ApplyDialog(
      title: json['stalagmitic'] as String? ?? '',
      content: json['closets'] as String? ?? '',
      leftButton: buttons.isNotEmpty
          ? DialogButton.fromJson(buttons[0] as Map<String, dynamic>)
          : null,
      rightButton: buttons.length > 1
          ? DialogButton.fromJson(buttons[1] as Map<String, dynamic>)
          : null,
    );
  }

  final String title;
  final String content;
  final DialogButton? leftButton;
  final DialogButton? rightButton;
}

class DialogButton {
  const DialogButton({required this.text, required this.url});

  factory DialogButton.fromJson(Map<String, dynamic> json) {
    return DialogButton(
      text: json['lookalike'] as String? ?? '',
      url: json['mycelia'] as String? ?? '',
    );
  }

  final String text;
  final String url;
}
