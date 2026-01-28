import 'package:flutter/material.dart';

class DeveloperToolsScreen extends StatelessWidget {
  const DeveloperToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Developer Tools')),
      body: const Center(
        child: Text("Developer tools coming soon"),
      ),
    );
  }
}
