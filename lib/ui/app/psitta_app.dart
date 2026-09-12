import 'package:flutter/material.dart';
import 'package:psitta/app_dependencies.dart';
import 'package:psitta/ui/screens/home/home_screen.dart';

/// Configures the application-wide Flutter UI.
class PsittaApp extends StatelessWidget {
  final AppDependencies dependencies;

  const PsittaApp({required this.dependencies, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Psitta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: HomeScreen(sessionController: dependencies.sessionController),
    );
  }
}
