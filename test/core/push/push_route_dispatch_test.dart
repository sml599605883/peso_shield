import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/navigation/app_navigator.dart';
import 'package:peso_shield/core/navigation/app_routes.dart';
import 'package:peso_shield/providers/credit_orders_provider.dart';

void main() {
  testWidgets('push order link opens the order list with its status filter', (
    tester,
  ) async {
    RouteSettings? captured;
    late WidgetRef widgetRef;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          navigatorKey: AppNavigator.navigatorKey,
          onGenerateRoute: (settings) {
            captured = settings;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const SizedBox.shrink(),
            );
          },
          home: Consumer(
            builder: (context, ref, _) {
              widgetRef = ref;
              return const Scaffold(body: Text('home'));
            },
          ),
        ),
      ),
    );
    await tester.pump();

    // 导航 Future 在页面 pop 后才完成，先不 await。
    final navigation = AppNavigator.navigateRawTarget(
      context: tester.element(find.text('home')),
      ref: widgetRef,
      target: 'ph://peso-shield/ios/PermutesLinotypes?segregate=6',
    );
    await tester.pumpAndSettle();

    expect(captured?.name, AppRoutes.mineOrderList);
    expect(captured?.arguments, OrderFilter.overdue);

    AppNavigator.pop();
    await tester.pumpAndSettle();
    await navigation;
  });
}
