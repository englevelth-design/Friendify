import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:friendify/src/features/home/presentation/pages/main_page.dart';
import 'package:friendify/src/features/auth/presentation/pages/login_page.dart';
import 'package:friendify/src/features/onboarding/presentation/pages/onboarding_page.dart';

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
          // User is signed in. Check if they have completed onboarding.
          return FutureBuilder<Map<String, dynamic>?>(
            future: Supabase.instance.client
                .from('profiles')
                .select('profile_complete')
                .eq('id', effectiveSession.user.id)
                .maybeSingle(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Color(0xFF0F172A),
                  body: Center(
                    child: CircularProgressIndicator(color: Color(0xFFD4FF00)),
                  ),
                );
              }
              
              if (profileSnapshot.hasError) {
                // print("AUTHGATE ERROR: ${profileSnapshot.error}");
              }

              final profileData = profileSnapshot.data;
              final bool isComplete = profileData?['profile_complete'] == true;

              if (isComplete) {
                return const MainPage();
              } else {
                return const OnboardingPage();
              }
            },
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
