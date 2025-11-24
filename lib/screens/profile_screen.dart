import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/app_state.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../services/goldchip_service.dart';
import '../services/notification_service.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import '../utils/contact_utils.dart';
import 'product_detail_screen.dart';
import 'edit_profile_screen.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'goldchip_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;
  final bool isOwnProfile;

  const ProfileScreen({
    super.key,
    required this.userId,
    this.isOwnProfile = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();
  final GoldChipService _goldChipService = GoldChipService();
  final NotificationService _notificationService = NotificationService();

  User? _user;
  List<Product> _products = [];
  bool _isLoading = true;
  String _selectedCategory = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _user = await _authService.getUserById(widget.userId);
    if (_user != null) {
      _products = await _productService.getProductsByUserId(_user!.id!);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _showGiveGoldChipDialog() async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tặng GoldChip'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Số lượng GoldChip',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Lời nhắn (tùy chọn)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tặng'),
          ),
        ],
      ),
    );

    if (result == true && _user != null) {
      final appState = context.read<AppState>();
      if (appState.currentUser == null) return;

      final amount = int.tryParse(amountController.text);
      if (amount == null || amount <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Số lượng không hợp lệ'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final success = await _goldChipService.transferGoldChip(
        fromUserId: appState.currentUser!.id!,
        toUserId: _user!.id!,
        amount: amount,
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
      );

      if (success) {
        // Create notification for receiver
        await _notificationService.createGoldChipReceivedNotification(
          userId: _user!.id!,
          fromUserId: appState.currentUser!.id!,
          amount: amount,
          fromUserNickname: appState.currentUser!.nickname,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã tặng $amount GoldChip cho ${_user!.nickname}'),
            ),
          );
        }
        await appState.refreshUser();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tặng GoldChip thất bại'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  List<Product> get _filteredProducts {
    if (_selectedCategory == 'Tất cả') return _products;
    return _products.where((p) => p.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isOwnProfile = widget.isOwnProfile ||
        (appState.currentUser?.id == widget.userId);

    if (_isLoading || _user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hồ sơ')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_user!.nickname),
        actions: isOwnProfile
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(user: _user!),
                      ),
                    );
                    if (result == true) {
                      _loadData();
                      appState.refreshUser();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.account_balance_wallet),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const GoldChipScreen(),
                      ),
                    );
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'logout') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Đăng xuất'),
                          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Hủy'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Đăng xuất'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && mounted) {
                        await appState.logout();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile header - Compact Card
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar and nickname row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.orange,
                          backgroundImage: _user!.avatar != null && _user!.avatar!.isNotEmpty
                              ? (_user!.avatar!.startsWith('http')
                                  ? NetworkImage(_user!.avatar!)
                                  : FileImage(File(_user!.avatar!)) as ImageProvider)
                              : null,
                          child: _user!.avatar == null || _user!.avatar!.isEmpty
                              ? Text(
                                  _user!.nickname[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 28, color: Colors.white),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_user!.name != null)
                                Text(
                                  _user!.name!,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (_user!.email != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _user!.email!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!isOwnProfile) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _showGiveGoldChipDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Tặng GoldChip'),
                        ),
                      ),
                    ],
                    const Divider(height: 24),
                    // Contact info - compact
                    _CompactInfoRow(
                      icon: Icons.phone,
                      value: _user!.phone,
                      onTap: () => ContactUtils.makePhoneCall(_user!.phone),
                    ),
                    if (_user!.address != null || _user!.province != null) ...[
                      const SizedBox(height: 8),
                      _CompactInfoRow(
                        icon: Icons.location_on,
                        value: '${_user!.address ?? ''} ${_user!.district ?? ''} ${_user!.province ?? ''}'.trim(),
                        onTap: () {
                          final address = '${_user!.address ?? ''} ${_user!.district ?? ''} ${_user!.province ?? ''}'.trim();
                          ContactUtils.copyToClipboard(context, address);
                        },
                        actionIcon: Icons.copy,
                        onAction: () {
                          final address = '${_user!.address ?? ''} ${_user!.district ?? ''} ${_user!.province ?? ''}'.trim();
                          ContactUtils.copyToClipboard(context, address);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Products section
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sản phẩm',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isOwnProfile)
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddProductScreen(),
                          ),
                        );
                        if (result == true) {
                          _loadData();
                        }
                      },
                    ),
                ],
              ),
            ),

            // Category filter
            if (_products.isNotEmpty)
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    'Tất cả',
                    ...AppConstants.categories,
                  ].map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedCategory = category);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Products grid
            if (_filteredProducts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Không có sản phẩm nào',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  return _ProfileProductCard(
                    product: _filteredProducts[index],
                    isOwnProfile: isOwnProfile,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: _filteredProducts[index]),
                        ),
                      );
                    },
                    onEdit: isOwnProfile ? () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EditProductScreen(
                            product: _filteredProducts[index],
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadData();
                      }
                    } : null,
                    onDelete: isOwnProfile ? () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Xóa sản phẩm'),
                          content: const Text(
                            'Bạn có chắc chắn muốn xóa sản phẩm này?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Xóa'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _productService.deleteProduct(_filteredProducts[index].id!);
                        _loadData();
                      }
                    } : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _ProfileProductCard extends StatefulWidget {
  final Product product;
  final bool isOwnProfile;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ProfileProductCard({
    required this.product,
    required this.isOwnProfile,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<_ProfileProductCard> createState() => _ProfileProductCardState();
}

class _ProfileProductCardState extends State<_ProfileProductCard> {
  double? _averageRating;
  bool _isLoadingRating = true;

  @override
  void initState() {
    super.initState();
    _loadRating();
  }

  Future<void> _loadRating() async {
    final productService = ProductService();
    final rating = await productService.getProductAverageRating(widget.product.id!);
    setState(() {
      _averageRating = rating > 0 ? rating : null;
      _isLoadingRating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  widget.product.mainImage != null &&
                          widget.product.mainImage!.isNotEmpty
                      ? Image.network(
                          widget.product.mainImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 48),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 48),
                        ),
                  if (_averageRating != null && !_isLoadingRating)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              _averageRating!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.isOwnProfile) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: widget.onEdit,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          color: Colors.red,
                          onPressed: widget.onDelete,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactInfoRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback? onTap;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const _CompactInfoRow({
    required this.icon,
    required this.value,
    this.onTap,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (actionIcon != null && onAction != null)
              IconButton(
                icon: Icon(actionIcon, size: 18),
                onPressed: onAction,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: actionIcon == Icons.phone ? 'Gọi điện' : 'Sao chép',
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final TextStyle? valueStyle;
  final VoidCallback? onTap;
  final List<Widget>? actions;

  const _InfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueStyle,
    this.onTap,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    value!,
                    style: valueStyle ?? const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}


