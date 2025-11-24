import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/product_service.dart';
import '../services/notification_service.dart';
import '../models/product.dart';
import '../utils/constants.dart';
import 'product_detail_screen.dart';
import 'profile_screen.dart';
import 'add_product_screen.dart';
import 'notifications_screen.dart';

class MainFeedScreen extends StatefulWidget {
  const MainFeedScreen({super.key});

  @override
  State<MainFeedScreen> createState() => _MainFeedScreenState();
}

class _MainFeedScreenState extends State<MainFeedScreen> {
  final ProductService _productService = ProductService();
  final NotificationService _notificationService = NotificationService();
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedProvince;
  int? _minRating;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadNotificationCount();
    // Delete expired products on startup
    _productService.deleteExpiredProducts();
  }

  Future<void> _loadNotificationCount() async {
    final appState = context.read<AppState>();
    if (appState.currentUser != null) {
      final count = await _notificationService.getUnreadCount(
        appState.currentUser!.id!,
      );
      setState(() {
        _unreadNotificationCount = count;
      });
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _productService.getAllActiveProducts(
        category: _selectedCategory,
        province: _selectedProvince,
        minRating: _minRating,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );
      setState(() {
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _loadProducts();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FilterBottomSheet(
        selectedCategory: _selectedCategory,
        selectedProvince: _selectedProvince,
        minRating: _minRating,
        onApply: (category, province, rating) {
          setState(() {
            _selectedCategory = category;
            _selectedProvince = province;
            _minRating = rating;
          });
          _applyFilters();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentUser = appState.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tặng đồ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Tìm kiếm'),
                  content: TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Nhập từ khóa...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      setState(() => _searchQuery = value);
                      _applyFilters();
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: _showFilterDialog,
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.black),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                  _loadNotificationCount();
                },
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotificationCount > 99 ? '99+' : '$_unreadNotificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () {
              if (currentUser != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(userId: currentUser.id!),
                  ),
                ).then((_) => _loadNotificationCount());
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Không có sản phẩm nào',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loadProducts,
                        child: const Text('Làm mới'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      return _ProductCard(
                        product: _filteredProducts[index],
                        onTap: () async {
                          final product = await _productService.getProductById(
                            _filteredProducts[index].id!,
                          );
                          if (product != null && mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(product: product),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
      floatingActionButton: currentUser != null
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                );
              },
              backgroundColor: Colors.orange,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

class _ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.onTap,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
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
                  widget.product.mainImage != null && widget.product.mainImage!.isNotEmpty
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
                  if (widget.product.province != null || widget.product.district != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '${widget.product.district ?? ''} ${widget.product.province ?? ''}'.trim(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final String? selectedCategory;
  final String? selectedProvince;
  final int? minRating;
  final Function(String?, String?, int?) onApply;

  const _FilterBottomSheet({
    required this.selectedCategory,
    required this.selectedProvince,
    required this.minRating,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String? _category;
  late String? _province;
  late int? _rating;

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _province = widget.selectedProvince;
    _rating = widget.minRating;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Lọc sản phẩm',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('Danh mục'),
          DropdownButton<String>(
            value: _category,
            isExpanded: true,
            hint: const Text('Tất cả'),
            items: [
              const DropdownMenuItem<String>(value: null, child: Text('Tất cả')),
              ...AppConstants.categories.map(
                (cat) => DropdownMenuItem<String>(value: cat, child: Text(cat)),
              ),
            ],
            onChanged: (value) => setState(() => _category = value),
          ),
          const SizedBox(height: 16),
          const Text('Tỉnh/Thành phố'),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Nhập tỉnh/thành phố',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: _province),
            onChanged: (value) => _province = value.isEmpty ? null : value,
          ),
          const SizedBox(height: 16),
          const Text('Đánh giá tối thiểu'),
          DropdownButton<int>(
            value: _rating,
            isExpanded: true,
            hint: const Text('Không yêu cầu'),
            items: [
              const DropdownMenuItem<int>(value: null, child: Text('Không yêu cầu')),
              ...List.generate(5, (i) => i + 1).map(
                (r) => DropdownMenuItem<int>(
                  value: r,
                  child: Text('$r sao trở lên'),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _rating = value),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _category = null;
                      _province = null;
                      _rating = null;
                    });
                  },
                  child: const Text('Xóa bộ lọc'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_category, _province, _rating);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


