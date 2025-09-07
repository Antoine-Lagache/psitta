import 'package:flutter/material.dart';

class MyAppTest extends StatelessWidget{
  const MyAppTest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title : "Exo2",
      home: Exo2()
    );  }
}

class Exo2 extends StatefulWidget{

  const Exo2({super.key});

  @override
  State<Exo2> createState() => _Exo2State();

}

class _Exo2State extends State<Exo2>{
  int monNombre = 0;

  void plus(){
    setState(() {
      monNombre++;
    });
  }

  void minus(){
    setState(() {
      monNombre--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exercice 2", textScaler: TextScaler.linear(2.0)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("$monNombre", textScaler: TextScaler.linear(3.0)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: plus, child: const Icon(Icons.plus_one_rounded, size: 50)),
                ElevatedButton(onPressed: minus, child: const Icon(Icons.exposure_minus_1_rounded, size: 50))
              ],
            )
          ],
        )
      )
    );
  }
}