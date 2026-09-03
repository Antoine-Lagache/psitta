import 'package:flutter/material.dart';
import 'package:psitta/app_dependencies.dart';
// ignore: unnecessary_import
//import 'package:psitta/ui/screens/main_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dependencies = await AppDependencies.initialize();

  print('Database opened');

  await dependencies.dispose();
}
