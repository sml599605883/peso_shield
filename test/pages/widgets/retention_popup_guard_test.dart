import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/network/api_response.dart';
import 'package:peso_shield/data/models/retention_popup_data.dart';
import 'package:peso_shield/data/repositories/certification_repository.dart';
import 'package:peso_shield/pages/widgets/retention_popup_dialog.dart';
import 'package:peso_shield/pages/widgets/retention_popup_guard.dart';
import 'package:peso_shield/providers/repository_provider.dart';

class _FakeCertificationRepository implements CertificationRepository {
  final response = Completer<ApiResponse<RetentionPopupData>>();
  int calls = 0;

  @override
  Future<ApiResponse<RetentionPopupData>> getRetentionPopup({
    required String productId,
    required String popupType,
  }) {
    calls++;
    return response.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GuardHost extends ConsumerStatefulWidget {
  const _GuardHost();

  @override
  ConsumerState<_GuardHost> createState() => _GuardHostState();
}

class _GuardHostState extends ConsumerState<_GuardHost>
    with RetentionPopupGuard<_GuardHost> {
  @override
  String get retentionProductId => 'product-1';

  @override
  String get retentionPopupType => '0';

  bool? lastShouldPop;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () async {
            lastShouldPop = await handleRetentionExit();
          },
          child: const Text('exit'),
        ),
      ),
    );
  }
}

void main() {
  /// BotToast 的 loading 需要若干帧才会完成淡入/淡出，这里统一推进。
  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpHost(
    WidgetTester tester,
    _FakeCertificationRepository repository,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          certificationRepositoryProvider.overrideWith(
            (ref) async => repository,
          ),
        ],
        child: MaterialApp(
          builder: BotToastInit(),
          navigatorObservers: [BotToastNavigatorObserver()],
          home: const _GuardHost(),
        ),
      ),
    );
  }

  Future<void> tapExit(WidgetTester tester) async {
    await tester.tap(find.text('exit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('shows loading while the retention popup request is pending', (
    tester,
  ) async {
    final repository = _FakeCertificationRepository();
    await pumpHost(tester, repository);

    await tapExit(tester);

    expect(repository.calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.response.complete(
      const ApiResponse<RetentionPopupData>(
        code: 0,
        message: 'ok',
        data: RetentionPopupData(),
      ),
    );
    await tester.pump();
    await pumpFrames(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(RetentionPopupDialog), findsNothing);
    expect(
      tester.state<_GuardHostState>(find.byType(_GuardHost)).lastShouldPop,
      isTrue,
    );
  });

  testWidgets('dismisses loading before showing the popup', (tester) async {
    final repository = _FakeCertificationRepository();
    await pumpHost(tester, repository);

    await tapExit(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.response.complete(
      const ApiResponse<RetentionPopupData>(
        code: 0,
        message: 'ok',
        data: RetentionPopupData(imageUrl: 'https://example.com/popup.png'),
      ),
    );
    await tester.pump();
    await pumpFrames(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(RetentionPopupDialog), findsOneWidget);
  });
}
