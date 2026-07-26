import 'package:flutter/material.dart';
import 'package:psitta/infrastructure/persistence/database/sqlite_database.dart';
// ignore: unnecessary_import
//import 'package:psitta/ui/screens/main_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = SqliteDatabase();

  await database.open();

  print('Database opened');

  await database.close();
}
