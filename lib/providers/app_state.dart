import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/supabase_auth_service.dart';
import '../services/interstitial_ad_service.dart';

class AppState extends ChangeNotifier {
  User? _currentUser;
  final SupabaseAuthService _authService = SupabaseAuthService();

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  AppState() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    // Load current user ID from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('current_user_id');
    if (userId != null) {
      _currentUser = await _authService.getUserById(userId);
      if (_currentUser != null) {
        notifyListeners();
      }
    }
  }

  Future<bool> login(String identifier, String password) async {
    final user = await _authService.login(identifier, password);
    if (user != null) {
      _currentUser = user;
      // Save user ID to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', user.id!);
      
      // Load and show interstitial ad on first login
      InterstitialAdService.loadAd();
      // Show ad after a short delay to ensure UI is ready
      Future.delayed(const Duration(milliseconds: 1500), () {
        InterstitialAdService.showAdIfNeeded(isFirstLogin: true);
      });
      
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
  }) async {
    final user = await _authService.register(
      phone: phone,
      nickname: nickname,
      password: password,
      name: name,
      email: email,
    );
    if (user != null) {
      _currentUser = user;
      // Save user ID to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', user.id!);
      
      // Load and show interstitial ad on first login (after registration)
      InterstitialAdService.loadAd();
      // Show ad after a short delay to ensure UI is ready
      Future.delayed(const Duration(milliseconds: 1500), () {
        InterstitialAdService.showAdIfNeeded(isFirstLogin: true);
      });
      
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    // Clear user ID from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    // Reset first login ad flag so next login will show ad
    await InterstitialAdService.resetAdTiming();
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_currentUser?.id != null) {
      _currentUser = await _authService.getUserById(_currentUser!.id!);
      notifyListeners();
    }
  }
}

