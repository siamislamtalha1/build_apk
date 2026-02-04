import 'package:flutter/material.dart';

class MoodsGenresScreen extends StatelessWidget {
  const MoodsGenresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder categories until YT API integration
    final categories = [
      "Relax",
      "Workout",
      "Focus",
      "Party",
      "Commute",
      "Romance",
      "Sleep",
      "Energize"
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moods & Genres'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final baseColor = Colors.primaries[index % Colors.primaries.length];
          final textColor =
              ThemeData.estimateBrightnessForColor(baseColor) == Brightness.dark
                  ? Colors.white
                  : Colors.black;
          return Card(
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            child: InkWell(
              onTap: () {
                // Navigate to playlist/search for this mood
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      baseColor,
                      baseColor.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    categories[index],
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
