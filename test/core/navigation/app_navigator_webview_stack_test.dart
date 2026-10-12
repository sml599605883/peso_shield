import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/navigation/app_navigator.dart';
import 'package:peso_shield/core/navigation/app_route_generator.dart';
import 'package:peso_shield/core/navigation/app_routes.dart';

void main() {
  testWidgets('removeWebViewPages closes the previous webview route', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: AppNavigator.navigatorKey,
        onGenerateRoute: (settings) {
          final isWebView = settings.name == AppRoutes.webView;
          final url = isWebView
              ? (settings.arguments as WebViewPageArguments?)?.url ?? 'webview'
              : 'home';
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => Scaffold(body: Text(url)),
          );
        },
        home: const Scaffold(body: Text('home')),
      ),
    );

    // 旧的订单详情 WebView。
    unawaited(AppNavigator.toWebView(url: 'order-detail'));
    await tester.pumpAndSettle();
    expect(find.text('order-detail'), findsOneWidget);

    // 进入借款确认页时移除来源 WebView。
    unawaited(
      AppNavigator.toWebView(url: 'confirm', removeWebViewPages: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('confirm'), findsOneWidget);
    expect(find.text('order-detail'), findsNothing);
  });
}
