import 'package:flutter/material.dart';
import 'package:psitta/ui/app/psitta_bootstrap.dart';

/// Configures the application-wide Flutter UI.
class PsittaApp extends StatelessWidget {
  const PsittaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Psitta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const PsittaBootstrap(),
    );
  }
}
