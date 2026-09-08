import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/client/client_bridge.dart';
import 'package:peso_shield/core/permissions/permission_coordinator.dart';
import 'package:peso_shield/core/permissions/permission_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
  var serviceEnabled = true;
  var permissionStatus = 4;
  var settingsOpened = 0;

  setUp(() {
    serviceEnabled = true;
    permissionStatus = 4;
    settingsOpened = 0;
    PermissionCoordinator.initialize(ClientBridge());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'checkServiceStatus':
              return serviceEnabled ? 1 : 0;
            case 'checkPermissionStatus':
              return permissionStatus;
            case 'openAppSettings':
              settingsOpened++;
              return true;
            default:
              throw StateError('Unexpected permission call: ${call.method}');
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  for (final serviceDisabled in [false, true]) {
    for (final openSettings in [false, true]) {
      testWidgets(
        'location serviceDisabled=$serviceDisabled settings=$openSettings',
        (tester) async {
          serviceEnabled = !serviceDisabled;
          bool? mayContinue;
          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () async {
                      mayContinue =
                          await PermissionHelper.requestCertificationLocation(
                            context,
                          );
                    },
                    child: const Text('Apply'),
                  );
                },
              ),
            ),
          );
          await tester.tap(find.text('Apply'));
          await tester.pumpAndSettle();
          expect(
            find.text(
              serviceDisabled
                  ? 'Turn On Location Services'
                  : 'Allow Location Access',
            ),
            findsOneWidget,
          );
          await tester.tap(find.text(openSettings ? 'Settings' : 'Cancel'));
          await tester.pumpAndSettle();
          expect(mayContinue, !openSettings);
          expect(settingsOpened, openSettings ? 1 : 0);
        },
      );
    }
  }

  testWidgets('granted location continues without a settings prompt', (
    tester,
  ) async {
    permissionStatus = 1;
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(
      await PermissionHelper.requestCertificationLocation(context),
      isTrue,
    );
    expect(settingsOpened, 0);
    expect(find.text('Allow Location Access'), findsNothing);
  });
}
