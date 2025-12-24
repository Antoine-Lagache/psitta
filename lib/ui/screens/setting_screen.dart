import 'package:flutter/material.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Page des paramètres"),
    );
  }
}

PreferredSizeWidget buildSettingAppBar(BuildContext context) {
  return AppBar(
    title: const Text("Setting"),
    backgroundColor: Theme.of(context).colorScheme.primary,
  );
}