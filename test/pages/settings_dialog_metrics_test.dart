import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/pages/settings_page.dart';

/// 底图 assets/settings/account_dialog_panel.png（933x927px = 311x309pt @3x）
/// 的实测几何：可见面板上边缘 y=27pt，内层浅色框 y=89..227.7pt，
/// 右上角星球装饰在标题所在高度上占据 x>=192.7pt。
void main() {
  test('标题栏位于面板上边缘与内层浅色框之间', () {
    expect(AccountDialogMetrics.panelTop, 27);
    expect(
      AccountDialogMetrics.contentTop,
      greaterThan(AccountDialogMetrics.panelTop),
    );
    expect(
      AccountDialogMetrics.contentTop + AccountDialogMetrics.contentHeight,
      closeTo(227.7, 2),
    );
  });

  test('标题不会压到底图右上角星球装饰', () {
    expect(
      AccountDialogMetrics.titleLeft + AccountDialogMetrics.titleMaxWidth,
      lessThanOrEqualTo(AccountDialogMetrics.decorationLeft),
    );
  });

  test('标题行高与行数能放进标题栏', () {
    final textHeight =
        AccountDialogMetrics.titleMaxLines *
        AccountDialogMetrics.titleFontSize *
        AccountDialogMetrics.titleLineHeight;
    expect(textHeight, lessThanOrEqualTo(AccountDialogMetrics.titleBandHeight));
  });

  test('弹窗内容总高度与底图一致，不会溢出', () {
    expect(AccountDialogMetrics.totalHeight, AccountDialogMetrics.height);
    expect(
      AccountDialogMetrics.contentWidth + AccountDialogMetrics.sidePadding * 2,
      AccountDialogMetrics.width,
    );
  });
}
