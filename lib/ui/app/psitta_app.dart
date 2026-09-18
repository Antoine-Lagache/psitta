import 'package:flutter/material.dart';
import 'package:psitta/ui/app/psitta_bootstrap.dart';

/// Configures the application-wide Flutter UI.
class PsittaApp extends StatelessWidget {
  const PsittaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.black,
      brightness: Brightness.light,
    ).copyWith(
      error: const Color(0xFF424242),
      onError: Colors.white,
      errorContainer: const Color(0xFFE0E0E0),
      onErrorContainer: Colors.black,
    );

    return MaterialApp(
      title: 'Psitta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F7F7),
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Color(0xFFD6D6D6)),
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        useMaterial3: true,
      ),
      home: const PsittaBootstrap(),
    );
  }
}
