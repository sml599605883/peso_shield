import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/navigation/app_navigator.dart';
import 'package:peso_shield/core/navigation/app_route_generator.dart';
import 'package:peso_shield/core/navigation/app_routes.dart';
import 'package:peso_shield/pages/login_page.dart';

/// 构建一个“首页 + 残留 H5”的路由栈，H5 用假页面代替真实 WebView。
Future<void> _pumpExpiredWebViewStack(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        navigatorKey: AppNavigator.navigatorKey,
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.webView) {
            final url =
                (settings.arguments as WebViewPageArguments?)?.url ?? 'webview';
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => Scaffold(body: Text(url)),
            );
          }
          return AppRouteGenerator.onGenerateRoute(settings);
        },
        home: const Scaffold(body: Text('home')),
      ),
    ),
  );
  await tester.pump();

  unawaited(AppNavigator.toWebView(url: 'webview-expired'));
  await tester.pumpAndSettle();
  expect(find.text('webview-expired'), findsOneWidget);
}

void main() {
  testWidgets('toLogin clears the expired webview below the login page', (
    tester,
  ) async {
    await _pumpExpiredWebViewStack(tester);

    unawaited(AppNavigator.toLogin());
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('webview-expired'), findsNothing);

    // 登录成功后登录页出栈，露出的是首页而不是残留的 H5。
    AppNavigator.pop(true);
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsNothing);
    expect(find.text('home'), findsOneWidget);
    expect(find.text('webview-expired'), findsNothing);
  });

  testWidgets('concurrent toLogin with a stale webview opens one login page', (
    tester,
  ) async {
    await _pumpExpiredWebViewStack(tester);

    final first = AppNavigator.toLogin();
    final second = AppNavigator.toLogin();
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('webview-expired'), findsNothing);

    AppNavigator.pop(true);
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);

    await first;
    await second;
  });
}
