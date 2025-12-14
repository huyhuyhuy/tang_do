class Contact {
  final String? id; // UUID from Supabase
  final String userId; // UUID of the user who saved this contact
  final String contactUserId; // UUID of the saved user
  final DateTime createdAt;

  Contact({
    this.id,
    required this.userId,
    required this.contactUserId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'contact_user_id': contactUserId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
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
    
    return Contact(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString() ?? map['user_id'].toString(),
      contactUserId: map['contact_user_id']?.toString() ?? map['contact_user_id'].toString(),
      createdAt: parseDateTime(map['created_at']) ?? DateTime.now(),
    );
  }
}

