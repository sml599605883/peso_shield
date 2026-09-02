import 'package:flutter/material.dart';

import '../../pages/home_page.dart';
import '../../pages/login_page.dart';
import '../../root_tab_page.dart';
import '../../pages/settings_page.dart';
import '../../pages/identity_type_page.dart';
import '../../pages/identity_upload_page.dart';
import '../../pages/identity_confirmation_page.dart';
import 'app_routes.dart';

/// 禁用侧滑返回的自定义路由
class NoSwipePageRoute<T> extends MaterialPageRoute<T> {
  NoSwipePageRoute({
    required super.builder,
    super.settings,
  });

  @override
  bool get popGestureEnabled => false;
}

/// 路由参数类型定义
class LoginPageArguments {
  const LoginPageArguments({this.onLoginSuccess});

  final Future<void> Function()? onLoginSuccess;
}

class IdentityTypePageArguments {
  const IdentityTypePageArguments({required this.productId});

  final String productId;
}

class IdentityUploadPageArguments {
  const IdentityUploadPageArguments({
    required this.productId,
    required this.cardType,
  });

  final String productId;
  final String cardType;
}

class IdentityConfirmationPageArguments {
  const IdentityConfirmationPageArguments({
    required this.productId,
    required this.cardType,
    this.recognizedInfo,
  });
  final String productId;
  final String cardType;
  final Map<String, dynamic>? recognizedInfo;
}

/// 应用路由生成器
class AppRouteGenerator {
  AppRouteGenerator._();

  /// 生成路由
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    debugPrint('[AppRouteGenerator] Navigating to: ${settings.name}');
    debugPrint('[AppRouteGenerator] Arguments: ${settings.arguments}');

    switch (settings.name) {
      case AppRoutes.root:
        return NoSwipePageRoute<void>(
          builder: (_) => const RootTabPage(),
          settings: settings,
        );

      case AppRoutes.login:
        final args = settings.arguments as LoginPageArguments?;
        return NoSwipePageRoute<bool>(
          builder: (_) => LoginPage(onLoginSuccess: args?.onLoginSuccess),
          settings: settings,
        );

      case AppRoutes.home:
        return NoSwipePageRoute<void>(
          builder: (_) => const HomePage(),
          settings: settings,
        );

      case AppRoutes.settings:
        return NoSwipePageRoute<void>(
          builder: (_) => const SettingsPage(),
          settings: settings,
        );

      case AppRoutes.identityType:
        final args = settings.arguments as IdentityTypePageArguments?;
        if (args == null) {
          return _errorRoute(settings.name);
        }
        return NoSwipePageRoute<String>(
          builder: (_) => IdentityTypePage(productId: args.productId),
          settings: settings,
        );

      case AppRoutes.identityUpload:
        final args = settings.arguments as IdentityUploadPageArguments?;
        if (args == null) return _errorRoute(settings.name);
        return NoSwipePageRoute<void>(
          builder: (_) => IdentityUploadPage(
            productId: args.productId,
            cardType: args.cardType,
          ),
          settings: settings,
        );

      case AppRoutes.identityConfirmation:
        final args = settings.arguments as IdentityConfirmationPageArguments?;
        if (args == null) return _errorRoute(settings.name);
        return NoSwipePageRoute<void>(
          builder: (_) => IdentityConfirmationPage(
            productId: args.productId,
            cardType: args.cardType,
            recognizedInfo: args.recognizedInfo,
          ),
          settings: settings,
        );

      default:
        return _errorRoute(settings.name);
    }
  }

  /// 未找到路由时的错误页面
  static Route<dynamic> _errorRoute(String? routeName) {
    return NoSwipePageRoute<void>(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Route not found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                routeName ?? '(null)',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
