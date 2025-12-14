import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_state.dart';
import '../services/supabase_product_service.dart';
import '../services/supabase_auth_service.dart';
import '../services/supabase_review_service.dart';
import '../models/product.dart';
import '../models/review.dart';
import '../models/user.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/bottom_nav_bar_widget.dart';
import '../utils/contact_utils.dart';
import 'profile_screen.dart';
import 'add_review_screen.dart';
import 'main_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final SupabaseProductService _productService = SupabaseProductService();
  final SupabaseAuthService _authService = SupabaseAuthService();
  final SupabaseReviewService _reviewService = SupabaseReviewService();
  
  Product? _product;
  User? _owner;
  List<Review> _reviews = [];
  double _averageRating = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    _product = await _productService.getProductById(widget.product.id!);
    if (_product != null) {
      _owner = await _authService.getUserById(_product!.userId);
      _reviews = await _reviewService.getProductReviews(_product!.id!);
      _averageRating = await _reviewService.getProductAverageRating(_product!.id!);
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Images
            SizedBox(
              height: 300,
              child: PageView.builder(
                itemCount: _product!.images.length,
                itemBuilder: (context, index) {
                  final image = _product!.images[index];
                  return image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: image,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 64),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 64),
                        );
                },
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    _product!.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Category and condition
                  Row(
                    children: [
                      Chip(
                        label: Text(_product!.category),
                        backgroundColor: Colors.orange[100],
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          _product!.condition == 'new' ? 'Chưa sử dụng' : 'Đã qua sử dụng',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  if (_product!.description != null && _product!.description!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mô tả',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_product!.description!),
                        const SizedBox(height: 16),
                      ],
                    ),
                  
                  // Contact Phone
                  if (_product!.contactPhone != null && _product!.contactPhone!.isNotEmpty)
                    InkWell(
                      onTap: () => ContactUtils.makePhoneCall(_product!.contactPhone!),
                      child: Row(
                        children: [
                          const Icon(Icons.phone, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _product!.contactPhone!,
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_product!.contactPhone != null && _product!.contactPhone!.isNotEmpty)
                    const SizedBox(height: 16),
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_product!.address ?? ''} ${_product!.ward != null && _product!.ward!.isNotEmpty ? _product!.ward! + ', ' : ''}${_product!.district ?? ''} ${_product!.province ?? ''}'.trim(),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Owner info
                  if (_owner != null) ...[
                    const Divider(),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(userId: _owner!.id!),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.orange,
                            backgroundImage: _owner!.avatar != null && _owner!.avatar!.isNotEmpty
                                ? (_owner!.avatar!.startsWith('http')
                                    ? CachedNetworkImageProvider(_owner!.avatar!)
                                    : FileImage(File(_owner!.avatar!)) as ImageProvider)
                                : null,
                            child: _owner!.avatar == null || _owner!.avatar!.isEmpty
                                ? Text(
                                    _owner!.nickname[0].toUpperCase(),
                                    style: const TextStyle(fontSize: 20, color: Colors.white),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _owner!.nickname,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_owner!.province ?? ''} ${_owner!.district ?? ''}'.trim(),
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                  ],
                  
                  // Reviews section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Đánh giá',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          if (_averageRating > 0) ...[
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              _averageRating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Text('(${_reviews.length})'),
                          ] else
                            const Text('Chưa có đánh giá'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Add review button
                  Builder(
                    builder: (context) {
                      final appState = context.watch<AppState>();
                      if (appState.currentUser != null &&
                          appState.currentUser!.id != _product!.userId) {
                        return ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddReviewScreen(productId: _product!.id!),
                              ),
                            );
                            if (result == true) {
                              _loadData();
                            }
                          },
                          icon: const Icon(Icons.rate_review),
                          label: const Text('Viết đánh giá'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Reviews list
                  if (_reviews.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'Chưa có đánh giá nào',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ..._reviews.map((review) => _ReviewCard(review: review)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BannerAdWidget(),
          BottomNavBarWidget(
            currentIndex: _getCurrentTabIndex(context),
            onDestinationSelected: (index) {
              _navigateToTab(context, index);
            },
          ),
        ],
      ),
    );
  }

  int _getCurrentTabIndex(BuildContext context) {
    // ProductDetailScreen được push từ MainFeedScreen, nên tab hiện tại là 0 (Trang chủ)
    return 0;
  }

  void _navigateToTab(BuildContext context, int index) {
    // Pop về MainScreen và switch tab
    Navigator.of(context).popUntil((route) => route.isFirst);
    // Navigate về MainScreen với tab được chọn
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainScreenWithTab(initialTab: index),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  '${review.rating}/5',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment!),
            ],
            const SizedBox(height: 8),
            Text(
              '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

