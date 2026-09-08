import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/device/session_store.dart';
import 'package:peso_shield/core/device/user_session.dart';
import 'package:peso_shield/pages/face_recognition_page.dart';
import 'package:peso_shield/pages/identity_upload_page.dart';

import '../../support/fake_session_persistence.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter.baseflow.com/permissions/methods');

  for (final face in [false, true]) {
    for (final status in [0, 2, 4]) {
      testWidgets('camera face=$face status=$status offers settings', (
        tester,
      ) async {
        var settingsOpened = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              switch (call.method) {
                case 'checkPermissionStatus':
                  return status;
                case 'requestPermissions':
                  return {for (final id in call.arguments as List) id: status};
                case 'openAppSettings':
                  settingsOpened++;
                  return true;
                default:
                  throw StateError('Unexpected call: ${call.method}');
              }
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null);
        });
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionStoreProvider.overrideWithValue(
                SessionStore(FakeSessionPersistence()),
              ),
            ],
            child: MaterialApp(
              home: face
                  ? const FaceRecognitionPage(productId: '1')
                  : const IdentityUploadPage(
                      productId: '1',
                      cardType: 'PRC ID',
                    ),
            ),
          ),
        );
        await tester.tap(
          find.byKey(
            Key(face ? 'face-recognition-submit' : 'identity-upload-submit'),
          ),
        );
        await tester.pumpAndSettle();
        if (!face) {
          await tester.tap(find.text('Done'));
          await tester.pumpAndSettle();
        }
        expect(find.text('Allow Camera Access'), findsOneWidget);
        expect(settingsOpened, 0);
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        expect(settingsOpened, 1);
        expect(find.text('Allow Camera Access'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
