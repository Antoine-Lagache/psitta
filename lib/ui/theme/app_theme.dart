import 'package:flutter/material.dart';

enum AppThemeVariant { light, dark, psitta }

/// Builds one of the application colour themes.
ThemeData buildAppTheme({AppThemeVariant variant = AppThemeVariant.light}) {
  final brightness = variant == AppThemeVariant.dark ? Brightness.dark : Brightness.light;
  final seedColor = variant == AppThemeVariant.psitta
      ? const Color(0xFFAD422D)
      : Colors.black;
  final colorScheme = _buildColorScheme(seedColor, brightness);
  final background = switch (variant) {
    AppThemeVariant.light => const Color(0xFFF7F7F7),
    AppThemeVariant.dark => const Color(0xFF121212),
    AppThemeVariant.psitta => const Color(0xFFF6F5F0),
  };
  final cardColor = switch (variant) {
    AppThemeVariant.light => Colors.white,
    AppThemeVariant.dark => const Color(0xFF1E1E1E),
    AppThemeVariant.psitta => Colors.white,
  };
  final borderColor = switch (variant) {
    AppThemeVariant.light => const Color(0xFFD6D6D6),
    AppThemeVariant.dark => const Color(0xFF424242),
    AppThemeVariant.psitta => const Color(0xFFDEDFD5),
  };
  final filledButtonTheme = switch (variant) {
    AppThemeVariant.psitta => FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF262820),
        foregroundColor: const Color(0xFFF6F5F0),
      ),
    ),
    AppThemeVariant.dark => FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFC7C7C7),
        foregroundColor: const Color(0xFF171717),
        disabledBackgroundColor: const Color(0xFF343434),
        disabledForegroundColor: const Color(0xFF8A8A8A),
      ),
    ),
    AppThemeVariant.light => const FilledButtonThemeData(),
  };
  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainer,
    ),
    sliderTheme: variant == AppThemeVariant.dark
        ? const SliderThemeData(
            activeTrackColor: Color(0xFFBDBDBD),
            inactiveTrackColor: Color(0xFF484848),
            thumbColor: Color(0xFFC7C7C7),
            overlayColor: Color(0x29C7C7C7),
            valueIndicatorColor: Color(0xFFBDBDBD),
            valueIndicatorTextStyle: TextStyle(color: Color(0xFF171717)),
          )
        : null,
    filledButtonTheme: filledButtonTheme,
    useMaterial3: true,
  );
}

ColorScheme _buildColorScheme(Color seedColor, Brightness brightness) {
  return ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
    dynamicSchemeVariant: seedColor == Colors.black
        ? DynamicSchemeVariant.monochrome
        : DynamicSchemeVariant.tonalSpot,
  ).copyWith(
    surfaceContainerHighest: brightness == Brightness.dark
        ? const Color(0xFF303030)
        : null,
    error: const Color(0xFF424242),
    onError: Colors.white,
    errorContainer: const Color(0xFFE0E0E0),
    onErrorContainer: Colors.black,
  );
}
