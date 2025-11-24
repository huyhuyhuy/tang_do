import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/goldchip_service.dart';
import '../models/goldchip_transaction.dart';
import '../utils/constants.dart';

class GoldChipScreen extends StatefulWidget {
  const GoldChipScreen({super.key});

  @override
  State<GoldChipScreen> createState() => _GoldChipScreenState();
}

class _GoldChipScreenState extends State<GoldChipScreen> {
  final GoldChipService _goldChipService = GoldChipService();
  List<GoldChipTransaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final appState = context.read<AppState>();
    if (appState.currentUser != null) {
      _transactions = await _goldChipService.getUserTransactions(
        appState.currentUser!.id!,
      );
      await appState.refreshUser();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _transferGoldChip() async {
    final appState = context.read<AppState>();
    if (appState.currentUser == null) return;

    final toUserIdController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chuyển GoldChip'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: toUserIdController,
                decoration: const InputDecoration(
                  labelText: 'ID người nhận',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Số lượng',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Lời nhắn (tùy chọn)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Chuyển'),
          ),
        ],
      ),
    );

    if (result == true) {
      final toUserId = int.tryParse(toUserIdController.text);
      final amount = int.tryParse(amountController.text);

      if (toUserId == null || amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thông tin không hợp lệ'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final success = await _goldChipService.transferGoldChip(
        fromUserId: appState.currentUser!.id!,
        toUserId: toUserId,
        amount: amount,
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
      );

      if (success) {
        _loadTransactions();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chuyển GoldChip thành công')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chuyển GoldChip thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GoldChip'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.orange[50],
                  child: Column(
                    children: [
                      const Text(
                        'Số dư GoldChip',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${user?.goldChip ?? 0}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _transferGoldChip,
                        icon: const Icon(Icons.send),
                        label: const Text('Chuyển GoldChip'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Rút GoldChip (Coming Soon)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lịch sử hoạt động',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadTransactions,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _transactions.isEmpty
                      ? const Center(
                          child: Text(
                            'Chưa có giao dịch nào',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _transactions[index];
                            final isReceived = transaction.type ==
                                AppConstants.transactionReceived;
                            final isOutgoing = transaction.type ==
                                AppConstants.transactionTransfer &&
                                transaction.fromUserId == user?.id;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isReceived
                                      ? Colors.green[100]
                                      : Colors.orange[100],
                                  child: Icon(
                                    isReceived
                                        ? Icons.arrow_downward
                                        : isOutgoing
                                            ? Icons.arrow_upward
                                            : Icons.card_giftcard,
                                    color: isReceived
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                                title: Text(
                                  transaction.type ==
                                          AppConstants.transactionReferral
                                      ? 'Giới thiệu bạn bè'
                                      : isReceived
                                          ? 'Nhận từ người dùng #${transaction.fromUserId}'
                                          : 'Chuyển cho người dùng #${transaction.toUserId}',
                                ),
                                subtitle: transaction.description != null
                                    ? Text(transaction.description!)
                                    : null,
                                trailing: Text(
                                  '${isReceived ? '+' : '-'}${transaction.amount}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isReceived ? Colors.green : Colors.red,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

