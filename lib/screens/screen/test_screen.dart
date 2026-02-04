import 'package:flutter/material.dart';
import 'package:Bloomee/theme_data/default.dart';

class TestView extends StatelessWidget {
  const TestView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Default_Theme.themeColor,
      appBar: AppBar(
        backgroundColor: Default_Theme.themeColor,
        foregroundColor: Default_Theme.primaryColor1,
        title: Text(
          'Tests',
          style: TextStyle(
                  color: Default_Theme.primaryColor1,
                  fontSize: 25,
                  fontWeight: FontWeight.bold)
              .merge(Default_Theme.secondoryTextStyle),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Text(
              "Test View",
              style: TextStyle(color: scheme.onSurface),
            ),
            ElevatedButton(
              onPressed: () async {},
              child: Text(
                "Test API",
                style: TextStyle(color: scheme.onSurface),
              ),
            )
          ],
        ),
      ),
    );
  }
}
