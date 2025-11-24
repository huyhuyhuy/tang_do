import '../database/database_helper.dart';
import '../models/user.dart';
import 'goldchip_service.dart';

class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<User?> login(String identifier, String password) async {
    final db = await _dbHelper.database;
    
    // Try login by phone or nickname
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: '(phone = ? OR nickname = ?) AND password = ?',
      whereArgs: [identifier, identifier, password],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> register({
    required String phone,
    required String nickname,
    required String password,
    String? name,
    String? email,
    String? referralCode,
  }) async {
    final db = await _dbHelper.database;
    
    try {
      final now = DateTime.now();
      final user = User(
        phone: phone,
        nickname: nickname,
        password: password,
        name: name,
        email: email,
        createdAt: now,
        updatedAt: now,
      );

      final id = await db.insert('users', user.toMap());
      final newUser = user.copyWith(id: id);

      // Check for referral code and award bonus
      if (referralCode != null && referralCode.isNotEmpty) {
        await _checkAndAwardReferral(referralCode, phone, id);
      }

      return newUser;
    } catch (e) {
      // Handle unique constraint violation
      return null;
    }
  }

  Future<void> _checkAndAwardReferral(String referralCode, String newUserPhone, int newUserId) async {
    final db = await _dbHelper.database;
    
    // Find user with phone matching referral code
    final referrerUsers = await db.query(
      'users',
      where: 'phone = ?',
      whereArgs: [referralCode],
      limit: 1,
    );

    if (referrerUsers.isNotEmpty) {
      final referrerId = referrerUsers.first['id'] as int;
      
      // Don't award if referring to self
      if (referrerId == newUserId) return;
      
      // Save referral record
      await db.insert('referrals', {
        'referrer_id': referrerId,
        'referred_phone': newUserPhone,
        'is_completed': 1,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'completed_at': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Award bonus to referrer
      final goldChipService = GoldChipService();
      await goldChipService.addReferralBonus(referrerId);
    }
  }

  Future<bool> checkPhoneExists(String phone) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'users',
      where: 'phone = ?',
      whereArgs: [phone],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<bool> checkNicknameExists(String nickname) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'users',
      where: 'nickname = ?',
      whereArgs: [nickname],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<User?> getUserById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<bool> updateUser(User user) async {
    final db = await _dbHelper.database;
    final updatedUser = user.copyWith(updatedAt: DateTime.now());
    final count = await db.update(
      'users',
      updatedUser.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
    return count > 0;
  }
}

