import 'package:flutter/material.dart';
import 'package:psitta/infrastructure/persistence/database/sqlite_database.dart';
// ignore: unnecessary_import
//import 'package:psitta/ui/screens/main_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO(review): Replace this database smoke-test entry point when the
  // application UI is ready to own the database lifecycle.
  final database = SqliteDatabase();

  await database.open();

  print('Database opened');

  await database.close();
}
