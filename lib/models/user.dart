class User {
  final int? id;
  final String phone;
  final String nickname;
  final String password;
  final String? name;
  final String? email;
  final String? address;
  final String? province;
  final String? district;
  final String? avatar;
  final int goldChip;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    this.id,
    required this.phone,
    required this.nickname,
    required this.password,
    this.name,
    this.email,
    this.address,
    this.province,
    this.district,
    this.avatar,
    this.goldChip = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phone': phone,
      'nickname': nickname,
      'password': password,
      'name': name,
      'email': email,
      'address': address,
      'province': province,
      'district': district,
      'avatar': avatar,
      'gold_chip': goldChip,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      phone: map['phone'] as String,
      nickname: map['nickname'] as String,
      password: map['password'] as String,
      name: map['name'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      province: map['province'] as String?,
      district: map['district'] as String?,
      avatar: map['avatar'] as String?,
      goldChip: map['gold_chip'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  User copyWith({
    int? id,
    String? phone,
    String? nickname,
    String? password,
    String? name,
    String? email,
    String? address,
    String? province,
    String? district,
    String? avatar,
    int? goldChip,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      nickname: nickname ?? this.nickname,
      password: password ?? this.password,
      name: name ?? this.name,
      email: email ?? this.email,
      address: address ?? this.address,
      province: province ?? this.province,
      district: district ?? this.district,
      avatar: avatar ?? this.avatar,
      goldChip: goldChip ?? this.goldChip,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

