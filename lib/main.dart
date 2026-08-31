import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_navigator.dart';
import 'core/navigation/app_route_generator.dart';
import 'core/navigation/app_route_observer.dart';
import 'core/navigation/app_routes.dart';
import 'core/startup/startup_network_gate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const ProviderScope(child: PesoShieldApp()));
}

class PesoShieldApp extends ConsumerWidget {
  const PesoShieldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StartupNetworkGate(
      ref: ref,
      child: MaterialApp(
        title: 'Peso Shield',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        // 配置全局导航键
        navigatorKey: AppNavigator.navigatorKey,
        // 配置路由观察者
        navigatorObservers: [AppRouteObserver(), BotToastNavigatorObserver()],
        // 配置初始路由
        initialRoute: AppRoutes.root,
        // 配置路由生成器
        onGenerateRoute: AppRouteGenerator.onGenerateRoute,
        // 配置 BotToast
        builder: BotToastInit(),
      ),
    );
  }
}
