import 'package:flutter/material.dart';

/// Temporary home screen used while the application shell is being built.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Psitta')),
      body: const Center(child: Text('Psitta')),
    );
  }
}
