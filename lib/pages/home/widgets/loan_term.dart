import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';

class LoanTerm extends StatelessWidget {
  const LoanTerm({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.mutedBlue,
            fontSize: layout.px(14),
            height: 17 / 14,
          ),
        ),
        SizedBox(height: layout.px(6)),
        SizedBox(
          height: layout.px(19),
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: AppColors.black,
                fontSize: layout.px(16),
                fontWeight: FontWeight.w700,
                height: 19 / 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Term option used when the server delivers loan term rows: the value sits in
/// a rounded badge followed by its unit label, e.g. `3` + `Terms`.
class LoanTermOption extends StatelessWidget {
  const LoanTermOption({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Loan Term',
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.mutedBlue,
            fontSize: layout.px(14),
            height: 17 / 14,
          ),
        ),
        SizedBox(height: layout.px(6)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: layout.px(27),
              constraints: BoxConstraints(minWidth: layout.px(28)),
              padding: layout.edgeInsets(left: 8, right: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.loanTermBadge,
                borderRadius: layout.radius(6),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: layout.px(22),
                    fontWeight: FontWeight.w700,
                    height: 26 / 22,
                  ),
                ),
              ),
            ),
            SizedBox(width: layout.px(10)),
            Flexible(
              child: _LoanTermUnitLabel(
                text: label,
                maxFontSize: layout.px(16),
                minFontSize: layout.px(10),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Unit label next to the term badge.
///
/// Two delivered rows halve the width left for the label, so it shrinks to
/// [minFontSize] first and only then falls back to an ellipsis.
class _LoanTermUnitLabel extends StatelessWidget {
  const _LoanTermUnitLabel({
    required this.text,
    required this.maxFontSize,
    required this.minFontSize,
  });

  final String text;
  final double maxFontSize;
  final double minFontSize;

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(
      const TextStyle(
        color: AppColors.black,
        fontWeight: FontWeight.w700,
        height: 19 / 16,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final textDirection = Directionality.of(context);
        final textScaler = MediaQuery.textScalerOf(context);
        return Text(
          text,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: base.copyWith(
            fontSize: _fittedFontSize(
              text: text,
              style: base,
              maxWidth: constraints.maxWidth,
              maxFontSize: maxFontSize,
              minFontSize: minFontSize,
              textDirection: textDirection,
              textScaler: textScaler,
            ),
          ),
        );
      },
    );
  }
}

/// Largest font size in `[minFontSize, maxFontSize]` that renders [text] on a
/// single line within [maxWidth].
double _fittedFontSize({
  required String text,
  required TextStyle style,
  required double maxWidth,
  required double maxFontSize,
  required double minFontSize,
  required TextDirection textDirection,
  required TextScaler textScaler,
}) {
  if (!maxWidth.isFinite || maxWidth <= 0) {
    return minFontSize;
  }
  var fontSize = maxFontSize;
  while (fontSize > minFontSize &&
      _measureTextWidth(
            text,
            style.copyWith(fontSize: fontSize),
            textDirection,
            textScaler,
          ) >
          maxWidth) {
    fontSize = math.max(minFontSize, fontSize - 1);
  }
  return fontSize;
}

/// Width of [text] laid out on a single line, measured with the same style and
/// text scaling the label renders with.
double _measureTextWidth(
  String text,
  TextStyle style,
  TextDirection textDirection,
  TextScaler textScaler,
) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 1,
    textDirection: textDirection,
    textScaler: textScaler,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}
