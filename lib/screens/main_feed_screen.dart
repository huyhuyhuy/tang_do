import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_state.dart';
import '../services/supabase_product_service.dart';
import '../services/supabase_notification_service.dart';
import '../services/supabase_review_service.dart';
import '../models/product.dart';
import '../utils/constants.dart';
import '../utils/vietnam_addresses.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/searchable_address_dropdown.dart';
import 'product_detail_screen.dart';

class MainFeedScreen extends StatefulWidget {
  const MainFeedScreen({super.key});

  @override
  State<MainFeedScreen> createState() => MainFeedScreenState();
}

class MainFeedScreenState extends State<MainFeedScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  void resetSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedCategory = null;
      _selectedProvince = null;
      _selectedDistrict = null;
      _selectedWard = null;
      _selectedCondition = null;
    });
    _loadProducts();
  }

  /// Public method to refresh products list
  void refreshProducts() {
    _loadProducts();
  }
  final SupabaseProductService _productService = SupabaseProductService();
  final SupabaseNotificationService _notificationService = SupabaseNotificationService();
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedWard;
  String? _selectedCondition;
  int _unreadNotificationCount = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadNotificationCount();
    // Note: Expired products are filtered by expires_at in query, no need to delete
    _searchController.addListener(() {
      if (_searchController.text != _searchQuery) {
        setState(() => _searchQuery = _searchController.text);
        _applyFilters();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        district: _selectedDistrict,
        ward: _selectedWard,
        condition: _selectedCondition,
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
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => _FilterBottomSheet(
          selectedCategory: _selectedCategory,
          selectedProvince: _selectedProvince,
          selectedDistrict: _selectedDistrict,
          selectedWard: _selectedWard,
          selectedCondition: _selectedCondition,
          onApply: (category, province, district, ward, condition) {
            setState(() {
              _selectedCategory = category;
              _selectedProvince = province;
              _selectedDistrict = district;
              _selectedWard = ward;
              _selectedCondition = condition;
            });
            _applyFilters();
          },
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final appState = context.watch<AppState>();
    final currentUser = appState.currentUser;

    return WillPopScope(
      onWillPop: () async {
        if (_searchQuery.isNotEmpty || _selectedCategory != null || _selectedProvince != null || _selectedDistrict != null || _selectedWard != null || _selectedCondition != null) {
          resetSearch();
          return false; // Prevent default back behavior
        }
        return true;
      },
      child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Tặng đồ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Search bar - thu nhỏ, đứng trước nút lọc
          Container(
            width: MediaQuery.of(context).size.width * 0.5, // Không quá 1/2 màn hình
            margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                hintStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
                prefixIcon: Icon(Icons.search, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black54, size: 18),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                    width: 1.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                    width: 1.0,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                isDense: true,
              ),
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: _showFilterDialog,
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
      ),
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
    final reviewService = SupabaseReviewService();
    final rating = await reviewService.getProductAverageRating(widget.product.id!);
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
                      ? (widget.product.mainImage!.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: widget.product.mainImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image, size: 48),
                              ),
                            )
                          : Image.file(
                              File(widget.product.mainImage!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image, size: 48),
                              ),
                            ))
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
  final String? selectedDistrict;
  final String? selectedWard;
  final String? selectedCondition;
  final Function(String?, String?, String?, String?, String?) onApply;
  final ScrollController scrollController;

  const _FilterBottomSheet({
    required this.selectedCategory,
    required this.selectedProvince,
    required this.selectedDistrict,
    required this.selectedWard,
    required this.selectedCondition,
    required this.onApply,
    required this.scrollController,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String? _category;
  late String? _province;
  late String? _district;
  late String? _ward;
  late String? _condition;

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _province = widget.selectedProvince;
    _district = widget.selectedDistrict;
    _ward = widget.selectedWard;
    _condition = widget.selectedCondition;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Lọc sản phẩm',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Danh mục',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Tất cả'),
                        selected: _category == null,
                        onSelected: (selected) {
                          setState(() => _category = null);
                        },
                      ),
                      ...AppConstants.categories.map((cat) {
                        return FilterChip(
                          label: Text(cat),
                          selected: _category == cat,
                          onSelected: (selected) {
                            setState(() => _category = selected ? cat : null);
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tỉnh/Thành phố',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SearchableAddressDropdown(
                    type: AddressType.province,
                    value: _province,
                    allOptionText: 'Tất cả',
                    onChanged: (value) {
                      setState(() {
                        _province = value;
                        _district = null; // Reset district when province changes
                        _ward = null; // Reset ward when province changes
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Quận/Huyện',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SearchableAddressDropdown(
                    type: AddressType.district,
                    value: _district,
                    province: _province,
                    allOptionText: 'Tất cả',
                    onChanged: _province == null
                        ? null
                        : (value) {
                            setState(() {
                              _district = value;
                              _ward = null; // Reset ward when district changes
                            });
                          },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Phường/Xã',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SearchableAddressDropdown(
                    type: AddressType.ward,
                    value: _ward,
                    district: _district,
                    allOptionText: 'Tất cả',
                    onChanged: _district == null
                        ? null
                        : (value) {
                            setState(() => _ward = value);
                          },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Trạng thái',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _condition = _condition == AppConstants.conditionNew
                                  ? null
                                  : AppConstants.conditionNew;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _condition == AppConstants.conditionNew
                                  ? Colors.orange
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _condition == AppConstants.conditionNew
                                    ? Colors.orange
                                    : Colors.grey,
                              ),
                            ),
                            child: Text(
                              'Chưa sử dụng',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _condition == AppConstants.conditionNew
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _condition = _condition == AppConstants.conditionUsed
                                  ? null
                                  : AppConstants.conditionUsed;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _condition == AppConstants.conditionUsed
                                  ? Colors.orange
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _condition == AppConstants.conditionUsed
                                    ? Colors.orange
                                    : Colors.grey,
                              ),
                            ),
                            child: Text(
                              'Đã qua sử dụng',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _condition == AppConstants.conditionUsed
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _category = null;
                              _province = null;
                              _district = null;
                              _ward = null;
                              _condition = null;
                            });
                          },
                          child: const Text('Xóa bộ lọc'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onApply(_category, _province, _district, _ward, _condition);
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
            ),
          ),
        ],
      ),
    );
  }
}


