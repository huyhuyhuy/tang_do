import '../database/database_helper.dart';
import '../models/follow.dart';

class FollowService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<bool> followUser(int followerId, int followingId) async {
    if (followerId == followingId) return false;

    final db = await _dbHelper.database;
    try {
      final follow = Follow(
        followerId: followerId,
        followingId: followingId,
        createdAt: DateTime.now(),
      );
      await db.insert('follows', follow.toMap());
      return true;
    } catch (e) {
      // Already following
      return false;
    }
  }

  Future<bool> unfollowUser(int followerId, int followingId) async {
    final db = await _dbHelper.database;
    final count = await db.delete(
      'follows',
      where: 'follower_id = ? AND following_id = ?',
      whereArgs: [followerId, followingId],
    );
    return count > 0;
  }

  Future<bool> isFollowing(int followerId, int followingId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'follows',
      where: 'follower_id = ? AND following_id = ?',
      whereArgs: [followerId, followingId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<int> getFollowerCount(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM follows WHERE following_id = ?',
      [userId],
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<int> getFollowingCount(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM follows WHERE follower_id = ?',
      [userId],
    );
    return result.first['count'] as int? ?? 0;
  }
}

