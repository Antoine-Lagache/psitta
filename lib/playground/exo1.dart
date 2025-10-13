import 'package:flutter/material.dart';


class MyAppTest extends StatelessWidget{
  const MyAppTest({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'test1',
      home: MyCustomForm(),
    );
  }
}


class MyCustomForm extends StatefulWidget{
  const MyCustomForm({super.key});
  @override
  State<MyCustomForm> createState() => _MyCustomFormState();
  }

class _MyCustomFormState extends State<MyCustomForm>{
   final myController1 = TextEditingController();
   final myController2 = TextEditingController();

   @override
  void dispose() {
    myController1.dispose();
    myController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title : const Text("Exercice 1 !")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: myController1, decoration: InputDecoration(border: OutlineInputBorder(), labelText: "prenom")),
            TextField(controller: myController2, decoration: InputDecoration(border: OutlineInputBorder(), labelText: "age"), keyboardType: TextInputType.number),
            if (myController1.text.isNotEmpty && myController2.text.isNotEmpty)
              Text("Tu t'appelles ${myController1.text} et tu as ${myController2.text} ans.")
            ])),
        floatingActionButton: FloatingActionButton(
        // When the user presses the button, show an alert dialog containing
        // the text that the user has entered into the text field.
        onPressed: () {
          setState(() {});
        },
        tooltip: 'Valider',
        child: const Icon(Icons.text_fields),
      ),
            );
  }
}