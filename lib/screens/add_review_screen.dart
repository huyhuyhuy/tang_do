import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../models/review.dart';
import '../providers/app_state.dart';
import 'package:provider/provider.dart';

class AddReviewScreen extends StatefulWidget {
  final int productId;

  const AddReviewScreen({super.key, required this.productId});

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final ProductService _productService = ProductService();
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = context.read<AppState>();
    if (appState.currentUser == null) return;

    setState(() => _isLoading = true);

    final review = Review(
      productId: widget.productId,
      userId: appState.currentUser!.id!,
      rating: _rating,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      createdAt: DateTime.now(),
    );

    final result = await _productService.addReview(review);
    
    if (result > 0) {
      // Get product info to create notification
      final product = await _productService.getProductById(widget.productId);
      if (product != null) {
        final reviewer = await _authService.getUserById(appState.currentUser!.id!);
        await _notificationService.createReviewNotification(
          productOwnerId: product.userId,
          reviewerId: appState.currentUser!.id!,
          productId: widget.productId,
          reviewerNickname: reviewer?.nickname ?? 'Người dùng',
          productName: product.name,
        );
      }
      
      setState(() => _isLoading = false);
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đánh giá đã được thêm')),
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn đã đánh giá sản phẩm này rồi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Viết đánh giá'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Đánh giá của bạn',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const Text(
                'Số sao',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      size: 48,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() => _rating = index + 1);
                    },
                  );
                }),
              ),
              const SizedBox(height: 32),
              const Text(
                'Nhận xét (tùy chọn)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Chia sẻ cảm nhận của bạn về sản phẩm...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Gửi đánh giá',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

