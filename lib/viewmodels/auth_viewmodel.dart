import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Object? _user; // Can be GoogleSignInAccount or AuthorizationCredentialAppleID
  Object? get user => _user;

  bool get isAuthenticated => _user != null;

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _user = await _authService.signInWithGoogle();
    _setLoading(false);
  }

  Future<void> signInWithApple() async {
    _setLoading(true);
    _user = await _authService.signInWithApple();
    _setLoading(false);
  }

  void signOut() {
    _authService.signOut();
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
