import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/contact.dart';
import '../models/user.dart' as models;

class SupabaseContactService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Add a contact (save a user to contacts)
  Future<bool> addContact(String userId, String contactUserId) async {
    try {
      // Check if already exists
      final existing = await _supabase
          .from('contacts')
          .select()
          .eq('user_id', userId)
          .eq('contact_user_id', contactUserId)
          .maybeSingle();
      
      if (existing != null) {
        // Already exists
        return true;
      }

      await _supabase.from('contacts').insert({
        'user_id': userId,
        'contact_user_id': contactUserId,
      });
      return true;
    } catch (e) {
      print('Add contact error: $e');
      return false;
    }
  }

  /// Remove a contact
  Future<bool> removeContact(String userId, String contactUserId) async {
    try {
      await _supabase
          .from('contacts')
          .delete()
          .eq('user_id', userId)
          .eq('contact_user_id', contactUserId);
      return true;
    } catch (e) {
      print('Remove contact error: $e');
      return false;
    }
  }

  /// Check if a user is in contacts
  Future<bool> isContact(String userId, String contactUserId) async {
    try {
      final response = await _supabase
          .from('contacts')
          .select()
          .eq('user_id', userId)
          .eq('contact_user_id', contactUserId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      print('Check contact error: $e');
      return false;
    }
  }

  /// Get all contacts for a user (returns User objects)
  Future<List<models.User>> getContacts(String userId) async {
    try {
      // Get contact records with user details using join
      final contactsResponse = await _supabase
          .from('contacts')
          .select('contact_user_id, users!contact_user_id(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      if (contactsResponse.isEmpty) {
        return [];
      }

      // Extract user data from joined response
      final users = <models.User>[];
      for (var contact in contactsResponse as List) {
        final userData = contact['users'];
        if (userData != null) {
          try {
            users.add(models.User.fromMap(userData as Map<String, dynamic>));
          } catch (e) {
            print('Error parsing user data: $e');
          }
        }
      }

      return users;
    } catch (e) {
      print('Get contacts error: $e');
      // Fallback: query each user individually
      try {
        final contactsResponse = await _supabase
            .from('contacts')
            .select('contact_user_id')
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        
        if (contactsResponse.isEmpty) {
          return [];
        }

        final contactUserIds = (contactsResponse as List)
            .map((item) => item['contact_user_id'] as String)
            .toList();

        final users = <models.User>[];
        for (final contactUserId in contactUserIds) {
          try {
            final userResponse = await _supabase
                .from('users')
                .select()
                .eq('id', contactUserId)
                .maybeSingle();
            if (userResponse != null) {
              users.add(models.User.fromMap(userResponse as Map<String, dynamic>));
            }
          } catch (e) {
            print('Error fetching user $contactUserId: $e');
          }
        }
        return users;
      } catch (fallbackError) {
        print('Fallback query error: $fallbackError');
        return [];
      }
    }
  }

  /// Get contact count for a user
  Future<int> getContactCount(String userId) async {
    try {
      final response = await _supabase
          .from('contacts')
          .select()
          .eq('user_id', userId);
      
      return (response as List).length;
    } catch (e) {
      print('Get contact count error: $e');
      return 0;
    }
  }
}

