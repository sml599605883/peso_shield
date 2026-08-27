import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/startup/startup_network_gate.dart';
import 'root_tab_page.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: PesoShieldApp(),
    ),
  );
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
        home: const RootTabPage(),
      ),
    );
  }
}
