import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/review.dart';

class ProductService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> createProduct(Product product) async {
    final db = await _dbHelper.database;
    return await db.insert('products', product.toMap());
  }

  Future<bool> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    final count = await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
    return count > 0;
  }

  Future<bool> deleteProduct(int productId) async {
    final db = await _dbHelper.database;
    final count = await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );
    return count > 0;
  }

  Future<Product?> getProductById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<List<Product>> getProductsByUserId(int userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getAllActiveProducts({
    String? category,
    String? province,
    String? district,
    int? minRating,
    String? searchQuery,
  }) async {
    final db = await _dbHelper.database;
    
    String where = 'is_active = 1 AND expires_at > ?';
    List<dynamic> whereArgs = [DateTime.now().millisecondsSinceEpoch];

    if (category != null && category.isNotEmpty) {
      where += ' AND category = ?';
      whereArgs.add(category);
    }

    if (province != null && province.isNotEmpty) {
      where += ' AND province = ?';
      whereArgs.add(province);
    }

    if (district != null && district.isNotEmpty) {
      where += ' AND district = ?';
      whereArgs.add(district);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      where += ' AND (name LIKE ? OR description LIKE ?)';
      final query = '%$searchQuery%';
      whereArgs.add(query);
      whereArgs.add(query);
    }

    final maps = await db.query(
      'products',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    List<Product> products = maps.map((map) => Product.fromMap(map)).toList();

    // Filter by rating if needed
    if (minRating != null && minRating > 0) {
      products = await _filterByRating(products, minRating);
    }

    return products;
  }

  Future<List<Product>> _filterByRating(
    List<Product> products,
    int minRating,
  ) async {
    final db = await _dbHelper.database;
    final List<Product> filtered = [];

    for (final product in products) {
      final reviews = await db.query(
        'reviews',
        where: 'product_id = ?',
        whereArgs: [product.id],
      );

      if (reviews.isEmpty) continue;

      final totalRating = reviews.fold<int>(
        0,
        (sum, review) => sum + (review['rating'] as int),
      );
      final avgRating = totalRating / reviews.length;

      if (avgRating >= minRating) {
        filtered.add(product);
      }
    }

    return filtered;
  }

  Future<double> getProductAverageRating(int productId) async {
    final db = await _dbHelper.database;
    final reviews = await db.query(
      'reviews',
      where: 'product_id = ?',
      whereArgs: [productId],
    );

    if (reviews.isEmpty) return 0.0;

    final totalRating = reviews.fold<int>(
      0,
      (sum, review) => sum + (review['rating'] as int),
    );
    return totalRating / reviews.length;
  }

  Future<int> getProductReviewCount(int productId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM reviews WHERE product_id = ?',
      [productId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> deleteExpiredProducts() async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      {'is_active': 0},
      where: 'expires_at <= ?',
      whereArgs: [DateTime.now().millisecondsSinceEpoch],
    );
  }

  Future<int> addReview(Review review) async {
    final db = await _dbHelper.database;
    try {
      final reviewId = await db.insert('reviews', review.toMap());
      
      // Create notification for product owner
      final product = await getProductById(review.productId);
      if (product != null) {
        // Get reviewer info
        final reviewer = await db.query(
          'users',
          where: 'id = ?',
          whereArgs: [review.userId],
          limit: 1,
        );
        final reviewerNickname = reviewer.isNotEmpty 
            ? reviewer.first['nickname'] as String 
            : 'Người dùng';
        
        // Import and create notification
        // Note: We'll handle this in the calling code to avoid circular dependency
      }
      
      return reviewId;
    } catch (e) {
      // Handle unique constraint (user already reviewed)
      return -1;
    }
  }

  Future<List<Review>> getProductReviews(int productId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'reviews',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Review.fromMap(map)).toList();
  }
}

