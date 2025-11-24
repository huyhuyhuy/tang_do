import '../database/database_helper.dart';
import '../models/goldchip_transaction.dart';
import '../utils/constants.dart';

class GoldChipService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<bool> transferGoldChip({
    required int fromUserId,
    required int toUserId,
    required int amount,
    String? description,
  }) async {
    if (fromUserId == toUserId || amount <= 0) return false;

    final db = await _dbHelper.database;
    
    try {
      await db.transaction((txn) async {
        // Check sender balance
        final sender = await txn.query(
          'users',
          where: 'id = ?',
          whereArgs: [fromUserId],
          limit: 1,
        );
        if (sender.isEmpty) throw Exception('Sender not found');
        final senderGoldChip = sender.first['gold_chip'] as int;
        if (senderGoldChip < amount) throw Exception('Insufficient balance');

        // Update sender balance
        await txn.update(
          'users',
          {'gold_chip': senderGoldChip - amount},
          where: 'id = ?',
          whereArgs: [fromUserId],
        );

        // Update receiver balance
        final receiver = await txn.query(
          'users',
          where: 'id = ?',
          whereArgs: [toUserId],
          limit: 1,
        );
        if (receiver.isEmpty) throw Exception('Receiver not found');
        final receiverGoldChip = receiver.first['gold_chip'] as int;
        await txn.update(
          'users',
          {'gold_chip': receiverGoldChip + amount},
          where: 'id = ?',
          whereArgs: [toUserId],
        );

        // Create transaction records
        final transaction = GoldChipTransaction(
          fromUserId: fromUserId,
          toUserId: toUserId,
          amount: amount,
          type: AppConstants.transactionTransfer,
          description: description,
          createdAt: DateTime.now(),
        );
        await txn.insert('goldchip_transactions', transaction.toMap());

        final receivedTransaction = GoldChipTransaction(
          fromUserId: fromUserId,
          toUserId: toUserId,
          amount: amount,
          type: AppConstants.transactionReceived,
          description: description,
          createdAt: DateTime.now(),
        );
        await txn.insert('goldchip_transactions', receivedTransaction.toMap());
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addReferralBonus(int userId) async {
    final db = await _dbHelper.database;
    
    try {
      await db.transaction((txn) async {
        final user = await txn.query(
          'users',
          where: 'id = ?',
          whereArgs: [userId],
          limit: 1,
        );
        if (user.isEmpty) throw Exception('User not found');
        
        final currentGoldChip = user.first['gold_chip'] as int;
        await txn.update(
          'users',
          {'gold_chip': currentGoldChip + AppConstants.referralBonus},
          where: 'id = ?',
          whereArgs: [userId],
        );

        final transaction = GoldChipTransaction(
          toUserId: userId,
          amount: AppConstants.referralBonus,
          type: AppConstants.transactionReferral,
          description: 'Giới thiệu bạn bè',
          createdAt: DateTime.now(),
        );
        await txn.insert('goldchip_transactions', transaction.toMap());
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<GoldChipTransaction>> getUserTransactions(int userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'goldchip_transactions',
      where: 'from_user_id = ? OR to_user_id = ?',
      whereArgs: [userId, userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => GoldChipTransaction.fromMap(map)).toList();
  }
}

