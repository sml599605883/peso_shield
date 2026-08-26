import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'root_tab_page.dart';

void main() {
  runApp(const ProviderScope(child: PesoShieldApp()));
}

class PesoShieldApp extends StatelessWidget {
  const PesoShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Peso Shield',
      debugShowCheckedModeBanner: false,
      home: RootTabPage(),
    );
  }
}
