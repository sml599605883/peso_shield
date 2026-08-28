import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:peso_shield/main.dart';
import 'package:peso_shield/root_tab_page.dart';
import 'package:peso_shield/pages/mine_page.dart';

void main() {
  testWidgets('Home renders the Lanhu loan offer layout', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: PesoShieldApp()));

    expect(find.text('Hi!  Welcome'), findsOneWidget);
    expect(find.text('Maximum Credit Amount'), findsOneWidget);
    expect(find.text('₱ 60,000', findRichText: true), findsOneWidget);
    expect(find.text('Apply Now'), findsOneWidget);
    expect(find.byKey(const Key('loan-process-card')), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Credit'), findsOneWidget);
    expect(find.text('Mine'), findsOneWidget);
  });

  testWidgets('Home layout fits a wide mobile screen', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: PesoShieldApp()));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('loan-process-card')), findsOneWidget);
  });

  testWidgets('Tab bar preserves the bottom safe area', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const MaterialApp(home: RootTabPage()));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const Key('home-tab-bar'))),
      const Size(375, 104),
    );
  });

  testWidgets('Mine tab renders the personal center layout', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MinePage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('960 **** 5854'), findsOneWidget);
    expect(find.text('Online Services'), findsOneWidget);
    expect(find.text('Setting'), findsOneWidget);
    expect(find.text('Privacy Agreement'), findsOneWidget);
  });
}
