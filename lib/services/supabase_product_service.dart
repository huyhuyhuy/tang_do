import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class SupabaseProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> createProduct(Product product) async {
    try {
      final productData = {
        'user_id': product.userId,
        'name': product.name,
        'description': product.description,
        'category': product.category,
        'condition': product.condition,
        'address': product.address,
        'province': product.province,
        'district': product.district,
        'ward': product.ward,
        'contact_phone': product.contactPhone,
        'image1_url': product.image1,
        'image2_url': product.image2,
        'image3_url': product.image3,
        'expiry_days': product.expiryDays,
        'created_at': product.createdAt.toIso8601String(),
        'expires_at': product.expiresAt.toIso8601String(),
        'is_active': product.isActive,
      };

      final response = await _supabase
          .from('products')
          .insert(productData)
          .select()
          .single();

      return response['id'] as String?;
    } catch (e) {
      print('Create product error: $e');
      return null;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      final productData = {
        'name': product.name,
        'description': product.description,
        'category': product.category,
        'condition': product.condition,
        'address': product.address,
        'province': product.province,
        'district': product.district,
        'ward': product.ward,
        'contact_phone': product.contactPhone,
        'image1_url': product.image1,
        'image2_url': product.image2,
        'image3_url': product.image3,
        'expiry_days': product.expiryDays,
        'expires_at': product.expiresAt.toIso8601String(),
        'is_active': product.isActive,
      };

      await _supabase
          .from('products')
          .update(productData)
          .eq('id', product.id!);

      return true;
    } catch (e) {
      print('Update product error: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _supabase
          .from('products')
          .delete()
          .eq('id', productId);
      return true;
    } catch (e) {
      print('Delete product error: $e');
      return false;
    }
  }

  Future<Product?> getProductById(String id) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Product.fromMap(response);
    } catch (e) {
      print('Get product error: $e');
      return null;
    }
  }

  Future<List<Product>> getProductsByUserId(String userId) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((map) => Product.fromMap(map as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Get products by user error: $e');
      return [];
    }
  }

  Future<List<Product>> getAllActiveProducts({
    String? category,
    String? province,
    String? district,
    String? ward,
    String? condition,
    String? searchQuery,
  }) async {
    try {
      var query = _supabase
          .from('products')
          .select()
          .eq('is_active', true)
          .gt('expires_at', DateTime.now().toIso8601String());

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      if (province != null && province.isNotEmpty) {
        query = query.eq('province', province);
      }

      if (district != null && district.isNotEmpty) {
        query = query.eq('district', district);
      }

      if (ward != null && ward.isNotEmpty) {
        query = query.eq('ward', ward);
      }

      if (condition != null && condition.isNotEmpty) {
        query = query.eq('condition', condition);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      final response = await query.order('created_at', ascending: false);
      
      return (response as List)
          .map((map) => Product.fromMap(map as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Get all active products error: $e');
      return [];
    }
  }
}

