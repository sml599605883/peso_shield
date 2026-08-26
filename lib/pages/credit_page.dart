import 'package:flutter/material.dart';

class CreditPage extends StatelessWidget {
  const CreditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('授信'),
      ),
      body: const Center(
        child: Text('授信页面'),
      ),
    );
  }
}
