import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review.dart';

class SupabaseReviewService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> addReview(Review review) async {
    try {
      final reviewData = {
        'product_id': review.productId,
        'user_id': review.userId,
        'rating': review.rating,
        'comment': review.comment,
        'created_at': review.createdAt.toIso8601String(),
      };

      final response = await _supabase
          .from('reviews')
          .insert(reviewData)
          .select()
          .single();

      return response['id'] as String?;
    } catch (e) {
      print('Add review error: $e');
      return null;
    }
  }

  Future<List<Review>> getProductReviews(String productId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('product_id', productId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((map) => Review.fromMap(map as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Get product reviews error: $e');
      return [];
    }
  }

  Future<double> getProductAverageRating(String productId) async {
    try {
      final response = await _supabase.rpc(
        'get_product_average_rating',
        params: {'product_uuid': productId},
      );
      return (response as num).toDouble();
    } catch (e) {
      print('Get average rating error: $e');
      // Fallback: calculate manually
      final reviews = await getProductReviews(productId);
      if (reviews.isEmpty) return 0.0;
      final totalRating = reviews.fold<int>(
        0,
        (sum, review) => sum + review.rating,
      );
      return totalRating / reviews.length;
    }
  }
}

