import 'package:flutter/material.dart';

class RecentMatchesPage extends StatelessWidget {
  const RecentMatchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Color(0xFF38BDF8)), // Moonlight Blue
            SizedBox(height: 16),
            Text(
              "Recent Matches\nComing Soon",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
