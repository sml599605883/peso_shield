import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:peso_shield/pages/identity_type_page.dart';
import 'package:peso_shield/widgets/app_back_button.dart';

void main() {
  testWidgets('identity type page renders recommended options', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(top: 44, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: IdentityTypePage(productId: '1')),
      ),
    );
    await tester.pump();

    expect(find.text('Identity verification'), findsOneWidget);
    expect(find.text('PRC ID'), findsOneWidget);
    expect(find.text('UMID(Unified Multi-Purpose ID)'), findsOneWidget);
    expect(find.text("DRIVER'S LICENSE"), findsNothing);
    expect(tester.getSize(find.byType(AppBackButton)), const Size(24, 24));
  });

  testWidgets('identity type page switches options and returns selection', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selected = await Navigator.of(context).push<String>(
                  MaterialPageRoute(
                    builder: (_) => const IdentityTypePage(productId: '1'),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other Options'));
    await tester.pumpAndSettle();

    expect(find.text("DRIVER'S LICENSE"), findsOneWidget);
    expect(find.text('PRC ID'), findsNothing);

    await tester.tap(find.text('TIN ID'));
    await tester.pumpAndSettle();
    expect(selected, 'TIN ID');
  });
}
