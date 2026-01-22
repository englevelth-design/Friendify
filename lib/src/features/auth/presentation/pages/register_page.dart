import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:friendify/src/features/swipe/presentation/pages/swipe_page.dart';
import 'package:friendify/src/features/auth/presentation/widgets/auth_gate.dart';
import '../widgets/neon_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        // Auto login usually happens on signup, but we can verify
        // Auto login usually happens on signup
        if (Supabase.instance.client.auth.currentSession != null) {
          // Navigate to AuthGate to handle onboarding routing
          Navigator.of(context).pushAndRemoveUntil(
             MaterialPageRoute(builder: (_) => const AuthGate()),
             (route) => false,
          );
        } else {
          // If email confirmation is on, they might not be logged in immediately
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please check your email to verify!")));
           Navigator.of(context).pop(); 
        }
      }
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Signup failed")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black), // Dark Back Button
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Text(
                "Join the Swarm",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.black, // Dark Text
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              NeonTextField(controller: _emailController, label: "Email"),
              const SizedBox(height: 16),
              NeonTextField(controller: _passwordController, label: "Password", isPassword: true),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4FF00), // Firefly Yellow Button
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text("SIGN UP", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
