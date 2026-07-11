import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      return account;
    } catch (error) {
      debugPrint('Google Sign-In Error: $error');
      return null;
    }
  }

  Future<AuthorizationCredentialAppleID?> signInWithApple() async {
    try {
      if (kIsWeb) return null; // Apple Sign-In on Web requires different setup

      if (Platform.isMacOS || Platform.isIOS) {
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );
        return credential;
      }
      return null;
    } catch (error) {
      debugPrint('Apple Sign-In Error: $error');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
