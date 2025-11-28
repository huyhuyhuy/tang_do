import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as models;

class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<models.User?> login(String identifier, String password) async {
    try {
      // Find user by phone or nickname
      final userResponse = await _supabase
          .from('users')
          .select()
          .or('phone.eq.$identifier,nickname.eq.$identifier')
          .maybeSingle();

      if (userResponse == null) return null;

      // Compare password directly (for testing)
      final storedPassword = userResponse['password'] as String;
      if (storedPassword != password) return null;

      return models.User.fromMap(userResponse);
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<models.User?> register({
    required String phone,
    required String nickname,
    required String password,
    String? name,
    String? email,
  }) async {
    try {
      // Check if phone or nickname already exists
      final existingUser = await _supabase
          .from('users')
          .select()
          .or('phone.eq.$phone,nickname.eq.$nickname')
          .maybeSingle();

      if (existingUser != null) return null;

      // Create user in public.users table (password stored directly for testing)
      final userData = {
        'phone': phone,
        'nickname': nickname,
        'password': password, // Store directly, no hashing for testing
        'name': name,
        'email': email,
      };

      final response = await _supabase
          .from('users')
          .insert(userData)
          .select()
          .single();

      return models.User.fromMap(response);
    } catch (e) {
      print('Register error: $e');
      return null;
    }
  }

  Future<bool> checkPhoneExists(String phone) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('phone', phone)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkNicknameExists(String nickname) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('nickname', nickname)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<models.User?> getUserById(String id) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return models.User.fromMap(response);
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  Future<models.User?> getCurrentUser() async {
    try {
      // For simple testing, we'll use a different approach
      // Since we're not using Supabase Auth, we need to store current user ID somewhere
      // For now, return null - session will be managed by AppState
      return null;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  Future<bool> updateUser(models.User user) async {
    try {
      final updateData = {
        'name': user.name,
        'email': user.email,
        'address': user.address,
        'province': user.province,
        'district': user.district,
        'ward': user.ward,
        'avatar_url': user.avatar,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('users')
          .update(updateData)
          .eq('id', user.id!);

      return true;
    } catch (e) {
      print('Update user error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    // No Supabase Auth session to sign out
    // Just clear local state
  }
}
