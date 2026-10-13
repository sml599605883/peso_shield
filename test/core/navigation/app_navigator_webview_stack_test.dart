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

  testWidgets('removeCertificationPages closes the recredit loading route', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: AppNavigator.navigatorKey,
        onGenerateRoute: (settings) {
          final label = settings.name == AppRoutes.webView
              ? (settings.arguments as WebViewPageArguments?)?.url ?? 'webview'
              : (settings.name ?? 'home');
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => Scaffold(body: Text(label)),
          );
        },
        home: const Scaffold(body: Text('home')),
      ),
    );

    // 确认用款页之前的授信 loading 页。
    unawaited(AppNavigator.toRecredit(productId: 'p1'));
    await tester.pumpAndSettle();
    expect(find.text(AppRoutes.recredit), findsOneWidget);

    // 授信成功后准入跳转确认用款页时清除重新授信 loading 页。
    unawaited(
      AppNavigator.toWebView(
        url: 'confirm',
        removeCertificationPages: true,
        removeWebViewPages: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('confirm'), findsOneWidget);
    expect(find.text(AppRoutes.recredit), findsNothing);
    AppNavigator.pop<void>();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });
}
