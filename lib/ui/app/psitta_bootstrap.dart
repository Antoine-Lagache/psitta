import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:psitta/app_dependencies.dart';
import 'package:psitta/ui/screens/home/home_screen.dart';

typedef AppDependenciesFactory = Future<AppDependencies> Function();

/// Initializes and owns the dependencies that live for the whole application.
class PsittaBootstrap extends StatefulWidget {
  final AppDependenciesFactory initializeDependencies;

  const PsittaBootstrap({
    this.initializeDependencies = AppDependencies.initialize,
    super.key,
  });

  @override
  State<PsittaBootstrap> createState() => _PsittaBootstrapState();
}

class _PsittaBootstrapState extends State<PsittaBootstrap> {
  _StartupState _startupState = const _StartupLoading();

  @override
  void initState() {
    super.initState();
    unawaited(_initializeDependencies());
  }

  Future<void> _initializeDependencies() async {
    try {
      final dependencies = await widget.initializeDependencies();

      if (!mounted) {
        await dependencies.dispose();
        return;
      }

      setState(() {
        _startupState = _StartupReady(dependencies);
      });
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Psitta bootstrap',
          context: ErrorDescription(
            'while initializing application dependencies',
          ),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _startupState = _StartupFailure(error);
      });
    }
  }

  void _retryInitialization() {
    setState(() {
      _startupState = const _StartupLoading();
    });

    unawaited(_initializeDependencies());
  }

  @override
  void dispose() {
    final startupState = _startupState;

    if (startupState is _StartupReady) {
      unawaited(startupState.dependencies.dispose());
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_startupState) {
      _StartupLoading() => const _StartupView(
        child: CircularProgressIndicator(),
      ),
      _StartupFailure(:final error) => _StartupView(
        child: _StartupError(
          error: error,
          onRetry: _retryInitialization,
        ),
      ),
      _StartupReady(:final dependencies) => HomeScreen(
        sessionController: dependencies.sessionController,
      ),
    };
  }
}

sealed class _StartupState {
  const _StartupState();
}

final class _StartupLoading extends _StartupState {
  const _StartupLoading();
}

final class _StartupReady extends _StartupState {
  final AppDependencies dependencies;

  const _StartupReady(this.dependencies);
}

final class _StartupFailure extends _StartupState {
  final Object error;

  const _StartupFailure(this.error);
}

class _StartupView extends StatelessWidget {
  final Widget child;

  const _StartupView({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _StartupError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Psitta could not be initialized.'),
        if (kDebugMode) ...[
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onRetry,
          child: const Text('Retry'),
        ),
      ],
    );
  }
}
