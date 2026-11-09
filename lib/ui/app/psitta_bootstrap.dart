import 'dart:async';

import 'package:flutter/material.dart';
import 'package:psitta/app_dependencies.dart';
import 'package:psitta/ui/app/bootstrap/startup_screen.dart';
import 'package:psitta/ui/app/bootstrap/startup_state.dart';
import 'package:psitta/ui/screens/main/main_screen.dart';
import 'package:psitta/ui/theme/app_theme.dart';

/// Creates the dependencies owned by the application bootstrap.
/// Each call must create a fresh instance and clean up resources on failure.
typedef AppDependenciesFactory = Future<AppDependencies> Function();

/// Initializes and owns the dependencies that live for the whole application.
class PsittaBootstrap extends StatefulWidget {
  final AppDependenciesFactory initializeDependencies;
  final ValueNotifier<AppThemeVariant>? themeVariant;

  const PsittaBootstrap({
    this.initializeDependencies = AppDependencies.initialize,
    this.themeVariant,
    super.key,
  });

  @override
  State<PsittaBootstrap> createState() => _PsittaBootstrapState();
}

class _PsittaBootstrapState extends State<PsittaBootstrap> {
  StartupState _startupState = const StartupLoading();

  @override
  void initState() {
    super.initState();
    unawaited(_initializeDependencies());
  }

  Future<void> _initializeDependencies() async {
    try {
      final dependencies = await widget.initializeDependencies();

      final savedTheme = await dependencies.settingsController.get('appearance.theme');
      widget.themeVariant?.value = switch (savedTheme) {
        'dark' => AppThemeVariant.dark,
        'psitta' => AppThemeVariant.psitta,
        _ => AppThemeVariant.light,
      };

      if (!mounted) {
        await _disposeDependencies(dependencies);
        return;
      }

      setState(() {
        _startupState = StartupReady(dependencies);
      });
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Psitta bootstrap',
          context: ErrorDescription('while initializing application dependencies'),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _startupState = StartupFailure(error);
      });
    }
  }

  void _retryInitialization() {
    if (!mounted || _startupState is! StartupFailure) {
      return;
    }

    setState(() {
      _startupState = const StartupLoading();
    });

    unawaited(_initializeDependencies());
  }

  Future<void> _disposeDependencies(AppDependencies dependencies) async {
    try {
      await dependencies.dispose();
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Psitta bootstrap',
          context: ErrorDescription('while disposing application dependencies'),
        ),
      );
    }
  }

  @override
  void dispose() {
    final startupState = _startupState;

    if (startupState is StartupReady) {
      unawaited(_disposeDependencies(startupState.dependencies));
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_startupState) {
      StartupLoading() => const StartupScreen.loading(),
      StartupFailure(:final error) => StartupScreen.failure(
        error: error,
        onRetry: _retryInitialization,
      ),
      StartupReady(:final dependencies) => MainScreen(
        sessionController: dependencies.sessionController,
        progressController: dependencies.progressController,
        statisticController: dependencies.statisticController,
        settingsController: dependencies.settingsController,
        contentRenderer: dependencies.contentRenderer,
        contentReleaseState: dependencies.contentReleaseState,
        themeVariant: widget.themeVariant,
      ),
    };
  }
}
