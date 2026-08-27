class ProductApplyResult {
  const ProductApplyResult({
    required this.jumpUrl,
    required this.dialog,
  });

  factory ProductApplyResult.fromJson(Map<String, dynamic> json) {
    return ProductApplyResult(
      jumpUrl: json['mycelia'] as String? ?? '',
      dialog: json['toper'] != null
          ? ApplyDialog.fromJson(json['toper'] as Map<String, dynamic>)
          : null,
    );
  }

  final String jumpUrl;
  final ApplyDialog? dialog;
}

class ApplyDialog {
  const ApplyDialog({
    required this.title,
    required this.content,
    required this.leftButton,
    required this.rightButton,
  });

  factory ApplyDialog.fromJson(Map<String, dynamic> json) {
    return ApplyDialog(
      title: json['stalagmitic'] as String? ?? '',
      content: json['subtrahend'] as String? ?? '',
      leftButton: json['desalting'] != null
          ? DialogButton.fromJson(json['desalting'] as Map<String, dynamic>)
          : null,
      rightButton: json['chromosphere'] != null
          ? DialogButton.fromJson(
              json['chromosphere'] as Map<String, dynamic>)
          : null,
    );
  }

  final String title;
  final String content;
  final DialogButton? leftButton;
  final DialogButton? rightButton;
}

class DialogButton {
  const DialogButton({
    required this.text,
    required this.url,
  });

  factory DialogButton.fromJson(Map<String, dynamic> json) {
    return DialogButton(
      text: json['stalagmitic'] as String? ?? '',
      url: json['mycelia'] as String? ?? '',
    );
  }

  final String text;
  final String url;
}
