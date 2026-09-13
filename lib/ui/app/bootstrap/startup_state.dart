import 'package:psitta/app_dependencies.dart';

sealed class StartupState {
  const StartupState();
}

final class StartupLoading extends StartupState {
  const StartupLoading();
}

final class StartupReady extends StartupState {
  final AppDependencies dependencies;

  const StartupReady(this.dependencies);
}

final class StartupFailure extends StartupState {
  final Object error;

  const StartupFailure(this.error);
}
