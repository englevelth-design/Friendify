import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:friendify/src/features/auth/presentation/widgets/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Force Portrait Mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 2. Enable Edge-to-Edge (Transparent Status & Nav Bar)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, 
  ));

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  await Supabase.initialize(
    url: 'https://lcnpedbzmzvhrtfhqfno.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxjbnBlZGJ6bXp2aHJ0ZmhxZm5vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg5NjIyNjQsImV4cCI6MjA4NDUzODI2NH0.OrNjVt0tzxpuxhpfxbU9uIp0Eu7AcB5xiTUFscwfY3M',
  );

  runApp(const FriendifyApp());
}

class FriendifyApp extends StatelessWidget {
  const FriendifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Friendify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4FF00),
          brightness: Brightness.light, // SWITCH TO LIGHT
          primary: const Color(0xFFD4FF00),
          secondary: const Color(0xFF38BDF8),
          surface: Colors.white,
          background: Colors.white,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto', // Or standard
        scaffoldBackgroundColor: Colors.transparent, // Important for gradient
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      // GLOBAL GRADIENT FIX: Applies to ALL screens (Auth, Main, Settings, etc.)
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                 Color(0xFFF3FFCC), // Very light lime tint
                Color(0xFFD4FF00), // Neon Lime at bottom
              ],
              stops: [0.0, 0.7, 1.0],
            ),
          ),
          child: child,
        );
      },
      home: const AuthGate(),
    );
  }
}
