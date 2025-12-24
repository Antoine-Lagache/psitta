import 'package:flutter/material.dart';

class StatisticScreen extends StatelessWidget {
  const StatisticScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Page des statistiques"),
    );
  }
}

PreferredSizeWidget buildStatisticAppBar(BuildContext context) {
  return AppBar(
    title: const Text("Statistic"),
    backgroundColor: Theme.of(context).colorScheme.primary,
  );
}