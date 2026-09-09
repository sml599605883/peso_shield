import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/pages/credit_page.dart';
import 'package:peso_shield/theme/app_assets.dart';
import 'package:peso_shield/theme/app_colors.dart';

void main() {
  testWidgets('Credit empty state matches design geometry and filters', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(375, 812),
            padding: EdgeInsets.only(top: 44),
          ),
          child: Scaffold(body: CreditPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final illustration = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image == const AssetImage(AppAssets.creditEmpty),
    );
    expect(tester.getSize(illustration), const Size(204, 170));
    expect(tester.getTopLeft(illustration).dy, 261);
    expect(find.text('No information available'), findsOneWidget);
    expect(find.text('No credit applications yet'), findsNothing);
    for (final filter in ['All order', 'Outstanding', 'Overdue', 'Settled']) {
      await tester.tap(find.text(filter));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.text(filter)).style?.color,
        AppColors.white,
      );
      expect(find.text('No information available'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Credit fits a narrow screen with enlarged text', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(body: CreditPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('No information available'));
    expect(tester.takeException(), isNull);
  });
}
