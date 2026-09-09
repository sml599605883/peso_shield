import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/navigation/app_navigator.dart';
import 'package:peso_shield/data/models/home_popup_data.dart';
import 'package:peso_shield/pages/home/home_popup.dart';

void main() {
  testWidgets('upgrade content fits small screen and cannot stack', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: AppNavigator.navigatorKey,
        home: const Scaffold(),
      ),
    );
    final closed = HomePopup.show(
      HomePopupData(
        type: HomePopupType.appUpgrade,
        version: '2.0',
        message: List.filled(30, 'Update available.').join(' '),
      ),
    );
    await tester.pumpAndSettle();
    await HomePopup.show(
      const HomePopupData(type: HomePopupType.appUpgrade, version: '3.0'),
    );
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('2.0'), findsOneWidget);
    expect(find.text('3.0'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await closed;
  });

  testWidgets('membership displays server level and benefits', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: AppNavigator.navigatorKey,
        home: const Scaffold(),
      ),
    );
    final closed = HomePopup.show(
      const HomePopupData(
        type: HomePopupType.membershipUpgrade,
        previousLevel: 'Level I',
        currentLevel: 'Level II',
        benefits: ['Increase loan amount'],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Level II'), findsOneWidget);
    expect(find.text('Previous: Level I'), findsOneWidget);
    expect(find.text('Increase loan amount'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await closed;
  });
}
