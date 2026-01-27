import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseReportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Report content (product, user, or review).
  /// reason: short code e.g. 'spam', 'offensive', 'inappropriate', 'other'
  Future<bool> reportContent({
    required String reporterId,
    required String contentType,
    required String contentId,
    required String reportedUserId,
    required String reason,
    String? description,
  }) async {
    try {
      await _supabase.from('content_reports').insert({
        'reporter_id': reporterId,
        'content_type': contentType,
        'content_id': contentId,
        'reported_user_id': reportedUserId,
        'reason': reason,
        'description': description,
        'status': 'pending',
      });
      return true;
    } catch (e) {
      print('Report content error: $e');
      return false;
    }
  }

  /// Report reasons for UI
  static const List<Map<String, String>> reportReasons = [
    {'code': 'spam', 'label': 'Spam / Quảng cáo'},
    {'code': 'offensive', 'label': 'Nội dung xúc phạm'},
    {'code': 'inappropriate', 'label': 'Nội dung không phù hợp'},
    {'code': 'fake', 'label': 'Lừa đảo / Gian lận'},
    {'code': 'harassment', 'label': 'Quấy rối'},
    {'code': 'other', 'label': 'Khác'},
  ];
}
