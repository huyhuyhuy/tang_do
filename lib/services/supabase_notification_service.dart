import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

class SupabaseNotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Notification>> getUserNotifications(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((map) => Notification.fromMap(map as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Get notifications error: $e');
      return [];
    }
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase.rpc(
        'get_unread_notification_count',
        params: {'user_uuid': userId},
      );
      return response as int;
    } catch (e) {
      print('Get unread count error: $e');
      // Fallback: count manually
      final notifications = await getUserNotifications(userId);
      return notifications.where((n) => !n.isRead).length;
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      return true;
    } catch (e) {
      print('Mark as read error: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      return true;
    } catch (e) {
      print('Mark all as read error: $e');
      return false;
    }
  }
}

