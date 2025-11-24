class GoldChipTransaction {
  final int? id;
  final int? fromUserId;
  final int toUserId;
  final int amount;
  final String type; // 'transfer', 'referral', 'received'
  final String? description;
  final DateTime createdAt;

  GoldChipTransaction({
    this.id,
    this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.type,
    this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'amount': amount,
      'type': type,
      'description': description,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory GoldChipTransaction.fromMap(Map<String, dynamic> map) {
    return GoldChipTransaction(
      id: map['id'] as int?,
      fromUserId: map['from_user_id'] as int?,
      toUserId: map['to_user_id'] as int,
      amount: map['amount'] as int,
      type: map['type'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}

