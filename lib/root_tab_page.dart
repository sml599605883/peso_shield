import 'package:flutter/material.dart';

import 'pages/credit_page.dart';
import 'pages/home_page.dart';
import 'pages/mine_page.dart';
import 'widgets/tab_bar/home_tab_bar.dart';

class RootTabPage extends StatefulWidget {
  const RootTabPage({super.key});

  @override
  State<RootTabPage> createState() => _RootTabPageState();
}

class _RootTabPageState extends State<RootTabPage> {
  int _currentIndex = 0;

  static const _pages = [HomePage(), CreditPage(), MinePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: HomeTabBar(
        currentIndex: _currentIndex,
        onSelected: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
