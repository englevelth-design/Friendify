import 'package:flutter/material.dart';

class FireflyGamePage extends StatelessWidget {
  const FireflyGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bug_report, size: 64, color: Color(0xFFD4FF00)), // Firefly Yellow
            SizedBox(height: 16),
            Text(
              "Firefly Game\nComing Soon",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
