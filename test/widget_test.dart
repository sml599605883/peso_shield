import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:peso_shield/main.dart';

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
}
