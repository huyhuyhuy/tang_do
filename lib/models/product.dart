class Product {
  final String? id; // UUID from Supabase
  final String userId; // UUID from Supabase
  final String name;
  final String? description;
  final String category;
  final String condition; // 'new' or 'used'
  final String? address;
  final String? province;
  final String? district;
  final String? ward;
  final String? contactPhone;
  final String? image1;
  final String? image2;
  final String? image3;
  final int expiryDays;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;

  Product({
    this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.category,
    required this.condition,
    this.address,
    this.province,
    this.district,
    this.ward,
    this.contactPhone,
    this.image1,
    this.image2,
    this.image3,
    required this.expiryDays,
    required this.createdAt,
    required this.expiresAt,
    this.isActive = true,
  });

  List<String> get images {
    final List<String> imgList = [];
    if (image1 != null && image1!.isNotEmpty) imgList.add(image1!);
    if (image2 != null && image2!.isNotEmpty) imgList.add(image2!);
    if (image3 != null && image3!.isNotEmpty) imgList.add(image3!);
    return imgList;
  }

  String? get mainImage => image1;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'category': category,
      'condition': condition,
      'address': address,
      'province': province,
      'district': district,
      'ward': ward,
      'contact_phone': contactPhone,
      'image1_url': image1,
      'image2_url': image2,
      'image3_url': image3,
      'expiry_days': expiryDays,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
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
    
    return Product(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString() ?? map['user_id'].toString(),
      name: map['name'] as String,
      description: map['description'] as String?,
      category: map['category'] as String,
      condition: map['condition'] as String,
      address: map['address'] as String?,
      province: map['province'] as String?,
      district: map['district'] as String?,
      ward: map['ward'] as String?,
      contactPhone: map['contact_phone'] as String?,
      image1: map['image1_url'] as String? ?? map['image1'] as String?,
      image2: map['image2_url'] as String? ?? map['image2'] as String?,
      image3: map['image3_url'] as String? ?? map['image3'] as String?,
      expiryDays: map['expiry_days'] as int,
      createdAt: parseDateTime(map['created_at']) ?? DateTime.now(),
      expiresAt: parseDateTime(map['expires_at']) ?? DateTime.now(),
      isActive: map['is_active'] is bool 
          ? map['is_active'] as bool 
          : ((map['is_active'] as int? ?? 1) == 1),
    );
  }

  Product copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? category,
    String? condition,
    String? address,
    String? province,
    String? district,
    String? ward,
    String? contactPhone,
    String? image1,
    String? image2,
    String? image3,
    int? expiryDays,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      address: address ?? this.address,
      province: province ?? this.province,
      district: district ?? this.district,
      ward: ward ?? this.ward,
      contactPhone: contactPhone ?? this.contactPhone,
      image1: image1 ?? this.image1,
      image2: image2 ?? this.image2,
      image3: image3 ?? this.image3,
      expiryDays: expiryDays ?? this.expiryDays,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

