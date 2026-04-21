import 'package:flutter/foundation.dart';

// Stub auth service — wired to Firebase when firebase_options.dart is configured.
// For UI development, uses a simple in-memory state.
class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _userId = '';
  String _userEmail = '';

  bool get isLoggedIn => _isLoggedIn;
  String get userId => _userId;
  String get userEmail => _userEmail;

  Future<bool> signIn(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (email.isNotEmpty && password.isNotEmpty) {
      _isLoggedIn = true;
      _userId = 'demo_user_001';
      _userEmail = email;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> signOut() async {
    _isLoggedIn = false;
    _userId = '';
    _userEmail = '';
    notifyListeners();
  }
}
