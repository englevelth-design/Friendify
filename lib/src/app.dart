import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/swipe/presentation/pages/swipe_page.dart';

class FriendifyApp extends StatelessWidget {
  const FriendifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Friendify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4FF00), // Neon Firefly Yellow-Green
          brightness: Brightness.dark,
          primary: const Color(0xFFD4FF00),
          secondary: const Color(0xFF38BDF8), // Moonlight Blue
          surface: const Color(0xFF1E293B), // Dark Blue-Grey
          background: const Color(0xFF0F172A), // Deep Night Sky
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Deep Night Sky
      ),
      home: const SwipePage(),
    );
  }
}
