import '../database/database_helper.dart';
import '../models/product.dart';
import '../utils/constants.dart';
import 'auth_service.dart';
import 'product_service.dart';

class SeedService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AuthService _authService = AuthService();
  final ProductService _productService = ProductService();

  Future<void> seedData() async {
    // Check if data already exists
    final db = await _dbHelper.database;
    final userCount = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    if ((userCount.first['count'] as int) > 0) {
      return; // Data already seeded
    }

    final now = DateTime.now();

    // Create sample users
    final user1 = await _authService.register(
      phone: '0901234567',
      nickname: 'tuananh9x',
      password: '123456',
      name: 'Nguyễn Tuấn Anh',
    );
    if (user1 != null) {
      await _authService.updateUser(user1.copyWith(
        email: 'tuananh@example.com',
        address: '123 Đường ABC',
        district: 'Quận 1',
        province: 'TP. Hồ Chí Minh',
        avatar: 'https://i.pravatar.cc/150?img=1',
      ));
    }

    final user2 = await _authService.register(
      phone: '0907654321',
      nickname: 'Thai_duc',
      password: '123456',
      name: 'Trần Thái Đức',
    );
    if (user2 != null) {
      await _authService.updateUser(user2.copyWith(
        email: 'thaiduc@example.com',
        address: '456 Đường XYZ',
        district: 'Quận 3',
        province: 'TP. Hồ Chí Minh',
        avatar: 'https://i.pravatar.cc/150?img=5',
      ));
    }

    final user3 = await _authService.register(
      phone: '0901111111',
      nickname: 'Huy_Le',
      password: '123456',
      name: 'Lê Văn Huy',
    );
    if (user3 != null) {
      await _authService.updateUser(user3.copyWith(
        email: 'huyle99@example.com',
        address: '789 Đường DEF',
        district: 'Quận 7',
        province: 'TP. Hồ Chí Minh',
        avatar: 'https://i.pravatar.cc/150?img=12',
      ));
    }

    // Create sample products with images (10 products total)
    if (user1 != null) {
      // Product 1: Quần áo
      await _productService.createProduct(Product(
        userId: user1.id!,
        name: 'Áo thun cũ còn tốt',
        description: 'Áo thun nam size M, đã mặc vài lần nhưng còn tốt',
        category: AppConstants.categories[3], // Quần áo
        condition: AppConstants.conditionUsed,
        address: '123 Đường ABC',
        district: 'Quận 1',
        province: 'TP. Hồ Chí Minh',
        image1: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&h=400&fit=crop',
        image2: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400&h=400&fit=crop',
        expiryDays: 7,
        createdAt: now,
        expiresAt: now.add(const Duration(days: 7)),
      ));

      // Product 2: Sách
      await _productService.createProduct(Product(
        userId: user1.id!,
        name: 'Sách tiếng Anh',
        description: 'K còn sử dụng, muốn tặng sách học tiếng Anh cơ bản, còn mới',
        category: AppConstants.categories[4], // Sách
        condition: AppConstants.conditionNew,
        address: '123 Đường ABC',
        district: 'Quận 1',
        province: 'TP. Hồ Chí Minh',
        image1: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=400&h=400&fit=crop',
        image2: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop',
        expiryDays: 14,
        createdAt: now,
        expiresAt: now.add(const Duration(days: 14)),
      ));

      // Product 3: Đồ điện tử
      await _productService.createProduct(Product(
        userId: user1.id!,
        name: 'Bàn phím cơ cũ',
        description: 'Bàn phím cơ còn hoạt động tốt, bỏ xó đã lâu, ai cần ib',
        category: AppConstants.categories[0], // Đồ điện tử
        condition: AppConstants.conditionUsed,
        address: '123 Đường ABC',
        district: 'Quận 1',
        province: 'TP. Hồ Chí Minh',
        image1: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=400&h=400&fit=crop',
        image2: 'https://images.unsplash.com/photo-1618384887929-16ec33cab9ef?w=400&h=400&fit=crop',
        expiryDays: 10,
        createdAt: now,
        expiresAt: now.add(const Duration(days: 10)),
      ));

      // Product 4: Văn phòng phẩm
      await _productService.createProduct(Product(
        userId: user1.id!,
        name: 'Bút bi và vở',
        description: 'Bộ bút bi và vở học sinh còn mới, chưa sử dụng',
        category: AppConstants.categories[7], // Văn phòng phẩm
        condition: AppConstants.conditionNew,
        address: '123 Đường ABC',
        district: 'Quận 1',
        province: 'TP. Hồ Chí Minh',
        image1: 'https://images.unsplash.com/photo-1583484963886-cfe2bff2945f?w=400&h=400&fit=crop',
        image2: 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=400&h=400&fit=crop',
        expiryDays: 5,
        createdAt: now,
        expiresAt: now.add(const Duration(days: 5)),
      ));
    }

    if (user2 != null) {
      // Product 5: Đồ chơi
      await _productService.createProduct(Product(
        userId: user2.id!,
        name: 'Đồ chơi trẻ em',
        description: 'Đồ chơi gỗ cho trẻ em, còn mới',
        category: AppConstants.categories[6], // Đồ chơi
        condition: AppConstants.conditionNew,
        address: '456 Đường XYZ',
        district: 'Quận 3',
        province: 'TP. Hồ Chí Minh',
        image1: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=400&fit=crop',
        image2: 'https://images.unsplash.com/photo-1515488042361-ee00e0d4d8be?w=400&h=400&fit=crop',
        image3: 'https://images.unsplash.com/photo-1606312619070-d48b4e001a59?w=400&h=400&fit=crop',
        expiryDays: 10,
        createdAt: now,
        expiresAt: now.add(const Duration(days: 10)),
      ));

      // Product 6: Mỹ phẩm
      await _productService.createProduct(Product(
        userId: user2.id!,
        name: 'Mỹ phẩm chưa dùng',
        description: 'Son môi chưa mở hộp, nguyên tem cho ai cần',
        category: AppConstants.categories[2], // Mỹ phẩm
        condition: AppConstants.conditionNew,
        address: '456 Đường XYZ',
        district: 'Quận 3',
        province: 'TP. Hồ Chí Minh',
        image1: 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&h=400&fit=crop',
        image2: 'https://images.unsplash.com/photo-1522338242992-e1a54906a8da?w=400&h=400&fit=crop',
        expiryDays: 5,
        createdAt: now,
        expiresAt: now.add(const Duration(days: 5)),
      ));

      // Product 7: Đồ gia dụng
      await _productService.createProduct(Product(
        userId: user2.id!,
        name: 'Bộ nồi inox',
        description: 'Muốn tặng trẻ vùng cao, bộ nồi inox còn mới, chưa sử dụng',
        category: AppConstants.categories[8], // Đồ gia dụng
        condition: AppConstants.conditionNew,
        address: '456 Đường XYZ',
        district: 'Quận 3',
        province: 'TP. Hồ Chí Minh',
        image1: 'https://images.unsplash.com/photo-1556911220-bff31c812dba?w=400&h=400&fit=crop',
        image2: 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=400&h=400&fit=crop',
        expiryDays: 12,
        createdAt: now,
        expiresAt: now.add(const Duration(days: 12)),
      ));

      // Product 8: Thực phẩm
      await _productService.createProduct(Product(
        userId: user2.id!,
        name: 'Gạo và mì tôm',
        description: 'Gạo và mì tôm còn hạn sử dụng, muốn gửi trẻ vùng cao',
        category: AppConstants.categories[1], // Thực phẩm
        condition: AppConstants.conditionNew,
        address: '456 Đường XYZ',
        district: 'Quận 3',
        province: 'TP. Hồ Chí Minh',
        image1: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400&h=400&fit=crop',
        image2: 'https://images.unsplash.com/photo-1612929633732-8c44b6b0b5c8?w=400&h=400&fit=crop',
        expiryDays: 3,
        createdAt: now,
        expiresAt: now.add(const Duration(days: 3)),
      ));
    }

    if (user3 != null) {
      // Product 9: Đồ điện tử
      await _productService.createProduct(Product(
        userId: user3.id!,
        name: 'Tai nghe Bluetooth',
        description: 'Ai cần ib. Tai nghe Bluetooth còn hoạt động tốt',
        category: AppConstants.categories[0], // Đồ điện tử
        condition: AppConstants.conditionUsed,
        address: '789 Đường DEF',
        district: 'Quận 7',
        province: 'TP. Hồ Chí Minh',
        image1: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop',
        image2: 'https://images.unsplash.com/photo-1484704849700-f032a568e944?w=400&h=400&fit=crop',
        image3: 'https://images.unsplash.com/photo-1572569511254-d8f925fe2cbb?w=400&h=400&fit=crop',
        expiryDays: 7,
        createdAt: now,
        expiresAt: now.add(const Duration(days: 7)),
      ));

      // Product 10: Thú cưng
      await _productService.createProduct(Product(
        userId: user3.id!,
        name: 'Đồ chơi cho chó',
        description: 'Free. Đồ chơi và thức ăn cho chó còn mới',
        category: AppConstants.categories[5], // Thú cưng
        condition: AppConstants.conditionNew,
        address: '789 Đường DEF',
        district: 'Quận 7',
        province: 'TP. Hồ Chí Minh',
        image1: 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400&h=400&fit=crop',
        image2: 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400&h=400&fit=crop',
        expiryDays: 8,
        createdAt: now,
        expiresAt: now.add(const Duration(days: 8)),
      ));
    }
  }
}

