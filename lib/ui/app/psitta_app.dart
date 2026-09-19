import 'package:flutter/material.dart';
import 'package:psitta/ui/app/psitta_bootstrap.dart';
import 'package:psitta/ui/theme/app_theme.dart';

/// Configures the application-wide Flutter UI.
class PsittaApp extends StatelessWidget {
  const PsittaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Psitta',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const PsittaBootstrap(),
    );
  }
}
