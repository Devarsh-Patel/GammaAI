import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'dart:io';

class SignInView extends StatelessWidget {
  const SignInView({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    bool showAppleSignIn = false;
    if (!kIsWeb) {
      try {
        if (Platform.isIOS || Platform.isMacOS) {
          showAppleSignIn = true;
        }
      } catch (_) {}
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'γ',
                style: TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Welcome to GammaAI',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              if (authViewModel.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    authViewModel.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (authViewModel.isLoading)
                const CircularProgressIndicator()
              else ...[
                ElevatedButton.icon(
                  onPressed: () => authViewModel.signInWithGoogle(),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                if (showAppleSignIn) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => authViewModel.signInWithApple(),
                    icon: const Icon(Icons.apple),
                    label: const Text('Sign in with Apple'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => authViewModel.continueAsGuest(),
                  child: const Text('Continue as Guest (Skip for now)'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
