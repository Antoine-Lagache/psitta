import 'dart:async';

import 'package:flutter/material.dart';
import 'package:psitta/app_dependencies.dart';
import 'package:psitta/ui/app/psitta_app.dart';

/// Initializes and owns the dependencies that live for the whole application.
class PsittaBootstrap extends StatefulWidget {
  const PsittaBootstrap({super.key});

  @override
  State<PsittaBootstrap> createState() => _PsittaBootstrapState();
}

class _PsittaBootstrapState extends State<PsittaBootstrap> {
  late Future<AppDependencies> _initialization;
  AppDependencies? _dependencies;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeDependencies();
  }

  Future<AppDependencies> _initializeDependencies() async {
    final dependencies = await AppDependencies.initialize();

    if (!mounted) {
      await dependencies.dispose();
      return dependencies;
    }

    _dependencies = dependencies;
    return dependencies;
  }

  void _retryInitialization() {
    setState(() {
      _initialization = _initializeDependencies();
    });
  }

  @override
  void dispose() {
    unawaited(_dependencies?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppDependencies>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StartupApp(
            body: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return _StartupApp(
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Psitta could not be initialized.'),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _retryInitialization,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return PsittaApp(dependencies: snapshot.requireData);
      },
    );
  }
}

class _StartupApp extends StatelessWidget {
  final Widget body;

  const _StartupApp({required this.body});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}
