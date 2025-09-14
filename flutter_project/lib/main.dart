import 'package:flutter/material.dart';

import 'MainRouter.dart';

void main() {
  //runApp(const MyApp());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "App pour apprentissage de langue",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue
        ),
      ),
      home: MainRouter(),
    );
  }
}
