import '../database/database_helper.dart';
import '../models/notification.dart';

class NotificationService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> createNotification(Notification notification) async {
    final db = await _dbHelper.database;
    return await db.insert('notifications', notification.toMap());
  }

  Future<List<Notification>> getUserNotifications(int userId, {bool unreadOnly = false}) async {
    final db = await _dbHelper.database;
    String where = 'user_id = ?';
    List<dynamic> whereArgs = [userId];
    
    if (unreadOnly) {
      where += ' AND is_read = 0';
    }
    
    final maps = await db.query(
      'notifications',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Notification.fromMap(map)).toList();
  }

  Future<int> getUnreadCount(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = 0',
      [userId],
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<bool> markAsRead(int notificationId) async {
    final db = await _dbHelper.database;
    final count = await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
    return count > 0;
  }

  Future<bool> markAllAsRead(int userId) async {
    final db = await _dbHelper.database;
    final count = await db.update(
      'notifications',
      {'is_read': 1},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return count > 0;
  }

  Future<void> createReviewNotification({
    required int productOwnerId,
    required int reviewerId,
    required int productId,
    required String reviewerNickname,
    required String productName,
  }) async {
    final notification = Notification(
      userId: productOwnerId,
      type: 'review',
      title: 'Có đánh giá mới',
      message: '$reviewerNickname đã đánh giá sản phẩm "$productName" của bạn',
      relatedId: productId,
      createdAt: DateTime.now(),
    );
    await createNotification(notification);
  }

}

