import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/navigation/app_navigator.dart';
import 'package:peso_shield/core/navigation/app_route_generator.dart';
import 'package:peso_shield/pages/login_page.dart';

void main() {
  testWidgets('concurrent toLogin calls open a single login page', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          navigatorKey: AppNavigator.navigatorKey,
          onGenerateRoute: AppRouteGenerator.onGenerateRoute,
          home: const Scaffold(body: Text('home')),
        ),
      ),
    );
    await tester.pump();

    final first = AppNavigator.toLogin();
    final second = AppNavigator.toLogin();
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);

    AppNavigator.pop(true);
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsNothing);

    await first;
    await second;
  });
}
