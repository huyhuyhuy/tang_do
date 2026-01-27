import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBlockService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Block a user. Returns true if successful.
  Future<bool> blockUser(String blockerId, String blockedId) async {
    if (blockerId == blockedId) return false;
    try {
      await _supabase.from('blocked_users').insert({
        'blocker_id': blockerId,
        'blocked_id': blockedId,
      });
      return true;
    } catch (e) {
      print('Block user error: $e');
      return false;
    }
  }

  /// Unblock a user.
  Future<bool> unblockUser(String blockerId, String blockedId) async {
    try {
      await _supabase
          .from('blocked_users')
          .delete()
          .eq('blocker_id', blockerId)
          .eq('blocked_id', blockedId);
      return true;
    } catch (e) {
      print('Unblock user error: $e');
      return false;
    }
  }

  /// Get list of user IDs that the current user has blocked.
  Future<List<String>> getBlockedUserIds(String userId) async {
    try {
      final response = await _supabase
          .from('blocked_users')
          .select('blocked_id')
          .eq('blocker_id', userId);
      return (response as List)
          .map((r) => r['blocked_id'] as String)
          .toList();
    } catch (e) {
      print('Get blocked users error: $e');
      return [];
    }
  }

  /// Check if current user has blocked target user.
  Future<bool> isBlocked(String blockerId, String blockedId) async {
    try {
      final response = await _supabase
          .from('blocked_users')
          .select()
          .eq('blocker_id', blockerId)
          .eq('blocked_id', blockedId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      print('Is blocked check error: $e');
      return false;
    }
  }
}
