import 'package:flutter/material.dart';

/// 路由观察者 - 用于监听路由变化，可用于日志记录、埋点等
class AppRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  AppRouteObserver() {
    debugPrint('[AppRouteObserver] Route observer initialized');
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logRouteChange('PUSH', route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _logRouteChange('POP', route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _logRouteChange('REPLACE', newRoute, oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _logRouteChange('REMOVE', route, previousRoute);
  }

  void _logRouteChange(
    String action,
    Route<dynamic>? route,
    Route<dynamic>? previousRoute,
  ) {
    final routeName = route?.settings.name ?? 'unknown';
    final previousRouteName = previousRoute?.settings.name ?? 'none';

    debugPrint('[AppRouteObserver] ========================================');
    debugPrint('[AppRouteObserver] Action: $action');
    debugPrint('[AppRouteObserver] Current Route: $routeName');
    debugPrint('[AppRouteObserver] Previous Route: $previousRouteName');
    if (route?.settings.arguments != null) {
      debugPrint('[AppRouteObserver] Arguments: ${route?.settings.arguments}');
    }
    debugPrint('[AppRouteObserver] ========================================');

    // TODO: 在这里可以添加埋点上报逻辑
    // 例如：AnalyticsService.trackPageView(routeName);
  }
}
