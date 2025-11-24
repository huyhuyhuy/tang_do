class Notification {
  final int? id;
  final int userId;
  final String type; // 'review', 'goldchip_received', etc.
  final String title;
  final String? message;
  final int? relatedId;
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
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      type: map['type'] as String,
      title: map['title'] as String,
      message: map['message'] as String?,
      relatedId: map['related_id'] as int?,
      isRead: (map['is_read'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}

