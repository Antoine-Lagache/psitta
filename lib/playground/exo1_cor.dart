import 'package:flutter/material.dart';

class MyAppTest extends StatelessWidget {
  const MyAppTest({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Test1',
      home: MyCustomForm(),
    );
  }
}

class MyCustomForm extends StatefulWidget {
  const MyCustomForm({super.key});

  @override
  State<MyCustomForm> createState() => _MyCustomFormState();
}

class _MyCustomFormState extends State<MyCustomForm> {
  final firstNameController = TextEditingController();
  final ageController = TextEditingController();

  @override
  void dispose() {
    firstNameController.dispose();
    ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Exercice 1")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Prénom",
              ),
            ),
            const SizedBox(height: 36),
            TextField(
              controller: ageController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Âge",
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            if (firstNameController.text.isNotEmpty &&
                ageController.text.isNotEmpty)
              Text(
                "Tu t'appelles ${firstNameController.text} et tu as ${ageController.text} ans.",
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() {}),
        tooltip: 'Valider',
        child: const Icon(Icons.text_fields),
      ),
    );
  }
}
