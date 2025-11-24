class Review {
  final int? id;
  final int productId;
  final int userId;
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
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      userId: map['user_id'] as int,
      rating: map['rating'] as int,
      comment: map['comment'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}

