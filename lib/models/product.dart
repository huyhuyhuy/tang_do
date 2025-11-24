class Product {
  final int? id;
  final int userId;
  final String name;
  final String? description;
  final String category;
  final String condition; // 'new' or 'used'
  final String? address;
  final String? province;
  final String? district;
  final String? image1;
  final String? image2;
  final String? image3;
  final String? image4;
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
    this.image1,
    this.image2,
    this.image3,
    this.image4,
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
    if (image4 != null && image4!.isNotEmpty) imgList.add(image4!);
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
      'image1': image1,
      'image2': image2,
      'image3': image3,
      'image4': image4,
      'expiry_days': expiryDays,
      'created_at': createdAt.millisecondsSinceEpoch,
      'expires_at': expiresAt.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      category: map['category'] as String,
      condition: map['condition'] as String,
      address: map['address'] as String?,
      province: map['province'] as String?,
      district: map['district'] as String?,
      image1: map['image1'] as String?,
      image2: map['image2'] as String?,
      image3: map['image3'] as String?,
      image4: map['image4'] as String?,
      expiryDays: map['expiry_days'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expires_at'] as int),
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }

  Product copyWith({
    int? id,
    int? userId,
    String? name,
    String? description,
    String? category,
    String? condition,
    String? address,
    String? province,
    String? district,
    String? image1,
    String? image2,
    String? image3,
    String? image4,
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
      image1: image1 ?? this.image1,
      image2: image2 ?? this.image2,
      image3: image3 ?? this.image3,
      image4: image4 ?? this.image4,
      expiryDays: expiryDays ?? this.expiryDays,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

