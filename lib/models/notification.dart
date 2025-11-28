class Notification {
  final String? id; // UUID from Supabase
  final String userId; // UUID from Supabase
  final String type; // 'review', etc.
  final String title;
  final String? message;
  final String? relatedId; // UUID from Supabase
  final bool isRead;
  final DateTime createdAt;

  Notification({
    this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.message,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'related_id': relatedId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Notification.fromMap(Map<String, dynamic> map) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now();
    }
    
    return Notification(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString() ?? map['user_id'].toString(),
      type: map['type'] as String,
      title: map['title'] as String,
      message: map['message'] as String?,
      relatedId: map['related_id']?.toString(),
      isRead: map['is_read'] is bool 
          ? map['is_read'] as bool 
          : ((map['is_read'] as int? ?? 0) == 1),
      createdAt: parseDateTime(map['created_at']) ?? DateTime.now(),
    );
  }
}

