import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:peso_shield/core/device/session_store.dart';
import 'package:peso_shield/core/device/user_session.dart';
import 'package:peso_shield/pages/identity_upload_page.dart';

import 'support/fake_session_persistence.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, SessionStore store) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionStoreProvider.overrideWithValue(store)],
        child: const MaterialApp(
          home: IdentityUploadPage(productId: '1', cardType: 'PRC ID'),
        ),
      ),
    );
  }

  testWidgets('identity upload page renders fixed guidance content', (
    tester,
  ) async {
    await pumpPage(tester, SessionStore(FakeSessionPersistence()));

    expect(find.text('Identity verification'), findsOneWidget);
    expect(find.text(IdentityUploadPage.defaultPrompt), findsOneWidget);
    expect(
      find.bySemanticsLabel('Identity upload instructions'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('identity-upload-submit')), findsOneWidget);
  });

  testWidgets('identity upload page prefers the cached product detail prompt', (
    tester,
  ) async {
    final store = SessionStore(FakeSessionPersistence());
    await store.saveProductDetail(
      prompt: 'Upload your ID to unlock ₱60,000.',
      identitySuccessPrompt: '',
      facePrompt: '',
      orderNo: '',
    );

    await pumpPage(tester, store);

    expect(find.text('Upload your ID to unlock ₱60,000.'), findsOneWidget);
    expect(find.text(IdentityUploadPage.defaultPrompt), findsNothing);
  });

  testWidgets(
    'identity upload page falls back when the cached prompt is empty',
    (tester) async {
      final store = SessionStore(FakeSessionPersistence());
      await store.saveProductDetail(
        prompt: '   ',
        identitySuccessPrompt: '',
        facePrompt: '',
        orderNo: '',
      );

      await pumpPage(tester, store);

      expect(find.text(IdentityUploadPage.defaultPrompt), findsOneWidget);
    },
  );

  testWidgets('submit opens the upload method selector over the page', (
    tester,
  ) async {
    await pumpPage(tester, SessionStore(FakeSessionPersistence()));

    await tester.tap(find.byKey(const Key('identity-upload-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Photograph'), findsOneWidget);
    expect(find.text('Photo Album'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.bySemanticsLabel('Selected upload method'), findsOneWidget);
    expect(find.text(IdentityUploadPage.defaultPrompt), findsOneWidget);
    final barriers = tester.widgetList<ModalBarrier>(find.byType(ModalBarrier));
    expect(
      barriers.any(
        (barrier) => barrier.color == const Color.fromRGBO(0, 0, 0, 0.6),
      ),
      isTrue,
    );
  });

  testWidgets('upload method selector can switch method and cancel', (
    tester,
  ) async {
    await pumpPage(tester, SessionStore(FakeSessionPersistence()));

    await tester.tap(find.byKey(const Key('identity-upload-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Photo Album'));
    await tester.pump();

    expect(find.bySemanticsLabel('Selected upload method'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Photo Album'), findsNothing);
  });
}
