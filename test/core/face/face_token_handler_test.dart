import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/face/face_token_handler.dart';
import 'package:peso_shield/core/navigation/app_navigator.dart';
import 'package:peso_shield/core/navigation/app_route_generator.dart';
import 'package:peso_shield/core/navigation/app_routes.dart';
import 'package:peso_shield/core/network/api_response.dart';
import 'package:peso_shield/core/network/http_client.dart';
import 'package:peso_shield/core/ui/toast_helper.dart';
import 'package:peso_shield/data/models/face_token_result.dart';
import 'package:peso_shield/data/repositories/certification_repository.dart';

class _Client implements HttpClient {
  Object? payload;

  @override
  Future<ApiResponse<T>> post<T>(
    String path, {
    required Map<String, Object?> params,
    required T Function(Object?) parse,
  }) async {
    expect(path, '/outsmelled/kestrel');
    return ApiResponse(code: 0, message: 'Success', data: parse(payload));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final code in [200, '200', 400, '400', 500, '500']) {
    test('repository preserves cullay=$code and trackable', () async {
      final client = _Client()
        ..payload = {
          'cullay': code,
          'legerity': 'license',
          'trackable': 'Server error detail',
        };
      final response = await CertificationRepository(
        client,
      ).getFacePPToken(orderNo: 'order');
      expect(response.data.resultCode, int.parse('$code'));
      expect(response.data.token, 'license');
      expect(response.data.error, 'Server error detail');
    });
  }

  for (final code in [200, 400, 500, 0, 999]) {
    for (final confirm in code == 400 ? [false, true] : [false]) {
      testWidgets('result=$code confirm=$confirm controls continuation', (
        tester,
      ) async {
        bool? continueLiveness;
        RouteSettings? destination;
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: AppNavigator.navigatorKey,
            builder: BotToastInit(),
            navigatorObservers: [BotToastNavigatorObserver()],
            onGenerateRoute: (settings) {
              destination = settings;
              return MaterialPageRoute<String>(
                settings: settings,
                builder: (_) => const Scaffold(body: Text('ID types')),
              );
            },
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    ToastHelper.showLoading();
                    await Future<void>.delayed(const Duration(milliseconds: 1));
                    if (!context.mounted) return;
                    continueLiveness = await handleFaceTokenResponse(
                      context,
                      productId: 'product-42',
                      response: ApiResponse(
                        code: 0,
                        message: 'Success',
                        data: FaceTokenResult(
                          resultCode: code,
                          token: 'present-even-on-error',
                          error: code == 500
                              ? 'Verification service unavailable'
                              : '',
                        ),
                      ),
                    );
                    ToastHelper.hideLoading();
                  },
                  child: const Text('Start'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Start'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 10));
        await tester.pump(const Duration(milliseconds: 400));
        if (code == 400) {
          expect(find.text('Upload Your ID Again'), findsOneWidget);
          expect(destination, isNull);
          await tester.tap(find.text(confirm ? 'Confirm' : 'Cancel'));
          await tester.pumpAndSettle();
          if (confirm) {
            expect(destination!.name, AppRoutes.identityType);
            expect(
              (destination!.arguments as IdentityTypePageArguments).productId,
              'product-42',
            );
          } else {
            expect(destination, isNull);
            expect(find.text('Start'), findsOneWidget);
          }
        } else if (code == 500) {
          expect(find.text('Verification service unavailable'), findsOneWidget);
          expect(destination, isNull);
        }
        expect(continueLiveness, code == 200);
        ToastHelper.cancel();
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
