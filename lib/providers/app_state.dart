import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  User? _currentUser;
  final AuthService _authService = AuthService();

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  AppState() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('current_user_id');
    if (userId != null) {
      _currentUser = await _authService.getUserById(userId);
      notifyListeners();
    }
  }

  Future<bool> login(String identifier, String password) async {
    final user = await _authService.login(identifier, password);
    if (user != null) {
      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_user_id', user.id!);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register({
    required String phone,
    required String nickname,
    required String password,
    String? name,
    String? email,
    String? referralCode,
  }) async {
    final user = await _authService.register(
      phone: phone,
      nickname: nickname,
      password: password,
      name: name,
      email: email,
      referralCode: referralCode,
    );
    if (user != null) {
      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_user_id', user.id!);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_currentUser?.id != null) {
      _currentUser = await _authService.getUserById(_currentUser!.id!);
      notifyListeners();
    }
  }
}

