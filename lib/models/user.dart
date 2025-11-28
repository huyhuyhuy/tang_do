class User {
  final String? id; // UUID from Supabase
  final String phone;
  final String nickname;
  final String password; // Stored directly in database (for testing)
  final String? name;
  final String? email;
  final String? address;
  final String? province;
  final String? district;
  final String? ward;
  final String? avatar; // avatar_url in Supabase
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
    this.ward,
    this.avatar,
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
      'ward': ward,
      'avatar_url': avatar,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    // Handle both Supabase (TIMESTAMPTZ) and SQLite (int) formats
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
    
    return User(
      id: map['id']?.toString(),
      phone: map['phone'] as String,
      nickname: map['nickname'] as String,
      password: map['password'] as String,
      name: map['name'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      province: map['province'] as String?,
      district: map['district'] as String?,
      ward: map['ward'] as String?,
      avatar: map['avatar_url'] as String? ?? map['avatar'] as String?,
      createdAt: parseDateTime(map['created_at']) ?? DateTime.now(),
      updatedAt: parseDateTime(map['updated_at']) ?? DateTime.now(),
    );
  }

  User copyWith({
    String? id,
    String? phone,
    String? nickname,
    String? password,
    String? name,
    String? email,
    String? address,
    String? province,
    String? district,
    String? ward,
    String? avatar,
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
      ward: ward ?? this.ward,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
