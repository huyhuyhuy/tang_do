class Review {
  final String? id; // UUID from Supabase
  final String productId; // UUID from Supabase
  final String userId; // UUID from Supabase
  final int rating;
  final String? comment;
  final DateTime createdAt;

  Review({
    this.id,
    required this.productId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
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
    
    return Review(
      id: map['id']?.toString(),
      productId: map['product_id']?.toString() ?? map['product_id'].toString(),
      userId: map['user_id']?.toString() ?? map['user_id'].toString(),
      rating: map['rating'] as int,
      comment: map['comment'] as String?,
      createdAt: parseDateTime(map['created_at']) ?? DateTime.now(),
    );
  }
}

