import 'package:flutter/foundation.dart';

class AuthManager extends ChangeNotifier {
  // Singleton pattern
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  bool _isLoggedIn = false;
  String _userName = 'Guest';
  String _email = '';

  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get email => _email;

  void login(String emailInput, String password) {
    _isLoggedIn = true;
    _email = emailInput;
    // Simple derivation of userName from email if needed
    if (emailInput.contains('@')) {
      final namePart = emailInput.split('@')[0];
      if (namePart.isNotEmpty) {
        _userName = namePart[0].toUpperCase() + namePart.substring(1);
      } else {
        _userName = 'User';
      }
    } else {
      _userName = emailInput;
    }
    notifyListeners();
  }

  void register(String nameInput, String emailInput) {
    _isLoggedIn = true;
    _userName = nameInput;
    _email = emailInput;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _userName = 'Guest';
    _email = '';
    notifyListeners();
  }
}
