import 'package:flutter/material.dart';

class Exo2App extends StatelessWidget {
  const Exo2App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Exo2",
      home: Exo2(),
    );
  }
}

class Exo2 extends StatefulWidget {
  const Exo2({super.key});

  @override
  State<Exo2> createState() => _Exo2State();
}

class _Exo2State extends State<Exo2> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Exercice 2",
          textScaler: TextScaler.linear(2.0),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("$counter", textScaler: const TextScaler.linear(3.0)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => counter++),
                  child: const Icon(Icons.plus_one_rounded, size: 50),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => setState(() => counter--),
                  child: const Icon(Icons.exposure_minus_1_rounded, size: 50),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
