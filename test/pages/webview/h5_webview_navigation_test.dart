import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/navigation/app_navigator.dart';
import 'package:peso_shield/core/navigation/app_route_generator.dart';
import 'package:peso_shield/core/navigation/app_routes.dart';
import 'package:peso_shield/pages/webview/webview_page.dart';

void main() {
  testWidgets('H5 打开新的 H5 页面时移除来源 H5 页面', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: AppNavigator.navigatorKey,
        onGenerateRoute: (settings) {
          final url = settings.name == AppRoutes.webView
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

    // 弹窗/banner 下发的推荐列表页 H5。
    unawaited(AppNavigator.toWebView(url: 'recommend-list'));
    await tester.pumpAndSettle();
    expect(find.text('recommend-list'), findsOneWidget);

    // H5 通过桥接打开确认用款页：来源 H5 必须关闭，
    // 否则退出确认用款页会再次回到推荐列表页。
    unawaited(openH5WebView('loan-confirmation'));
    await tester.pumpAndSettle();

    expect(find.text('loan-confirmation'), findsOneWidget);
    expect(find.text('recommend-list'), findsNothing);
  });
}
