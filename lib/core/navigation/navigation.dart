/// 导航模块统一导出
///
/// 使用方式：
/// ```dart
/// import 'package:peso_shield/core/navigation/navigation.dart';
///
/// // 跳转到登录页
/// AppNavigator.toLogin();
///
/// // 通过路由名称跳转
/// AppNavigator.toNamed(AppRoutes.login);
///
/// // 返回上一页
/// AppNavigator.pop();
/// ```

export 'app_navigator.dart';
export 'app_route_generator.dart';
export 'app_route_observer.dart';
export 'app_routes.dart';
