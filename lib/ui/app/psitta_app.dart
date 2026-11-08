import 'package:flutter/material.dart';
import 'package:psitta/ui/app/psitta_bootstrap.dart';
import 'package:psitta/ui/theme/app_theme.dart';

/// Configures the application-wide Flutter UI.
class PsittaApp extends StatefulWidget {
  const PsittaApp({super.key});

  @override
  State<PsittaApp> createState() => _PsittaAppState();
}

class _PsittaAppState extends State<PsittaApp> {
  final _themeVariant = ValueNotifier(AppThemeVariant.light);

  @override
  void dispose() {
    _themeVariant.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeVariant>(
      valueListenable: _themeVariant,
      builder: (context, variant, _) => MaterialApp(
        title: 'Psitta',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(variant: variant),
        home: PsittaBootstrap(themeVariant: _themeVariant),
      ),
    );
  }
}
