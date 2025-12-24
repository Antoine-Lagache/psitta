import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Page d’accueil"),
    );
  }
}

PreferredSizeWidget buildHomeAppBar(BuildContext context) {
  return AppBar(
    title: const Text("Home"),
    backgroundColor: Theme.of(context).colorScheme.primary,
    elevation: 10,
    shadowColor: Theme.of(context).shadowColor
  );
}