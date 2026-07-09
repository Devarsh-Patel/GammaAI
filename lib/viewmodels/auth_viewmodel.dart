import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Object? _user; // Can be GoogleSignInAccount or AuthorizationCredentialAppleID
  Object? get user => _user;

  bool get isAuthenticated => _user != null;

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _user = await _authService.signInWithGoogle();
      if (_user == null) {
        _errorMessage = "Google Sign-In was cancelled or failed.";
      }
    } catch (e) {
      _errorMessage = "Google Sign-In Error: $e";
    }
    _setLoading(false);
  }

  Future<void> signInWithApple() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _user = await _authService.signInWithApple();
      if (_user == null) {
        _errorMessage = "Apple Sign-In is not supported on this device or was cancelled.";
      }
    } catch (e) {
      _errorMessage = "Apple Sign-In Error: $e";
    }
    _setLoading(false);
  }

  /// Temporary method to bypass sign-in for testing
  void continueAsGuest() {
    _user = "guest_user";
    notifyListeners();
  }

  void signOut() {
    _authService.signOut();
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
