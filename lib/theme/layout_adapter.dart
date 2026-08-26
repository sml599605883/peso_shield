import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Scales 375 pt design measurements to the current screen width.
///
/// The upper limit preserves the mobile composition on tablets and landscape
/// windows, where scaling every fixed measurement to the full screen width
/// would make vertically stacked content overflow.
class AppLayout {
  const AppLayout._(this.scale);

  static const designWidth = 375.0;
  static const maxScale = 1.2;
  static const maxContentWidth = designWidth * maxScale;

  final double scale;

  factory AppLayout.of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final layoutWidth = math.min(math.max(width, 1), designWidth * maxScale);
    return AppLayout._(layoutWidth / designWidth);
  }

  double px(num value) => value * scale;

  EdgeInsets edgeInsets({
    num left = 0,
    num top = 0,
    num right = 0,
    num bottom = 0,
  }) => EdgeInsets.fromLTRB(px(left), px(top), px(right), px(bottom));

  BorderRadius radius(num value) =>
      BorderRadius.all(Radius.circular(px(value)));
}
