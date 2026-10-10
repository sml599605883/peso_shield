import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/data/models/retention_popup_data.dart';
import 'package:peso_shield/pages/widgets/retention_popup_dialog.dart';

void main() {
  // 1x1 transparent GIF，避免测试依赖网络图片。
  final onePixel = base64Decode(
    'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
  );

  testWidgets('places exit and continue buttons below the illustration', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: RetentionPopupDialog(
          data: const RetentionPopupData(
            title: 'Congratulations!',
            message: 'preliminary approval. Finish your ID check.',
            imageUrl: 'https://example.com/popup.png',
            confirmText: 'Continue',
            cancelText: 'Exit',
          ),
          imageProvider: MemoryImage(onePixel),
        ),
      ),
    );
    await tester.pump();

    final image = tester.getRect(find.byType(Image));
    final exit = tester.getRect(find.text('Exit'));
    final cont = tester.getRect(find.text('Continue'));

    // 两个按钮同一行，Exit 在左、Continue 在右。
    expect(exit.center.dy, moreOrLessEquals(cont.center.dy, epsilon: 0.5));
    expect(exit.center.dx, lessThan(cont.center.dx));

    // 按钮位于插画下方，不再叠加遮挡图片内容。
    expect(image.top, lessThan(exit.top));
    expect(image.bottom, lessThanOrEqualTo(exit.top));
  });
}
