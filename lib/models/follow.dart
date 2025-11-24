class Follow {
  final int? id;
  final int followerId;
  final int followingId;
  final DateTime createdAt;

  Follow({
    this.id,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'follower_id': followerId,
      'following_id': followingId,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Follow.fromMap(Map<String, dynamic> map) {
    return Follow(
      id: map['id'] as int?,
      followerId: map['follower_id'] as int,
      followingId: map['following_id'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}

