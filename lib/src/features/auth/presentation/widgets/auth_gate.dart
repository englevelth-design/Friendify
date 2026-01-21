import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:friendify/src/features/home/presentation/pages/main_page.dart';
import 'package:friendify/src/features/auth/presentation/pages/login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // While initializing, show a simple loading/splash screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(
              child: Icon(Icons.flash_on, size: 80, color: Color(0xFFD4FF00)),
            ),
          );
        }

        final session = snapshot.data?.session;
        // Also check static currentSession just in case stream is between events
        final effectiveSession = session ?? Supabase.instance.client.auth.currentSession;

        if (effectiveSession != null) {
          return const MainPage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
