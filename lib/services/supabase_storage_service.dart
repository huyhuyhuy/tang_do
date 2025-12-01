import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import '../utils/image_compressor.dart';

class SupabaseStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload image to Supabase Storage
  /// Returns public URL of uploaded image, or null if failed
  /// Automatically compresses image before uploading
  Future<String?> uploadImage({
    required File imageFile,
    required String bucketName,
    String? folder, // Optional folder path (e.g., 'products', 'avatars')
    bool compress = true, // Whether to compress image before upload
  }) async {
    try {
      // Compress image before uploading to save storage
      File fileToUpload = imageFile;
      if (compress) {
        if (bucketName == 'avatars') {
          fileToUpload = await ImageCompressor.compressAvatarImage(imageFile);
        } else {
          fileToUpload = await ImageCompressor.compressProductImage(imageFile);
        }
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(fileToUpload.path);
      final fileName = '$timestamp$extension';
      
      // Build file path
      final filePath = folder != null ? '$folder/$fileName' : fileName;

      // Upload file to Supabase Storage
      await _supabase.storage.from(bucketName).upload(
        filePath,
        fileToUpload,
        fileOptions: const FileOptions(
          upsert: false, // Don't overwrite existing files
        ),
      );

      // Get public URL
      final publicUrl = _supabase.storage.from(bucketName).getPublicUrl(filePath);
      
      // Clean up compressed file if it's different from original
      if (compress && fileToUpload.path != imageFile.path) {
        try {
          await fileToUpload.delete();
        } catch (e) {
          // Ignore cleanup errors
        }
      }
      
      return publicUrl;
    } catch (e) {
      print('Upload image error: $e');
      return null;
    }
  }

  /// Delete image from Supabase Storage
  /// Returns true if successful, false otherwise
  Future<bool> deleteImage({
    required String imageUrl,
    required String bucketName,
  }) async {
    try {
      // Extract file path from URL
      // URL format: https://[project].supabase.co/storage/v1/object/public/[bucket]/[path]
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      
      // Find index of bucket name in path
      final bucketIndex = segments.indexOf(bucketName);
      if (bucketIndex == -1 || bucketIndex == segments.length - 1) {
        print('Invalid image URL format: $imageUrl');
        return false;
      }
      
      // Get file path after bucket name
      final filePath = segments.sublist(bucketIndex + 1).join('/');
      
      // Delete file
      await _supabase.storage.from(bucketName).remove([filePath]);
      
      return true;
    } catch (e) {
      print('Delete image error: $e');
      return false;
    }
  }

  /// Upload product image
  /// Returns public URL or null
  Future<String?> uploadProductImage(File imageFile) async {
    return uploadImage(
      imageFile: imageFile,
      bucketName: 'product-images',
      folder: 'products',
    );
  }

  /// Delete product image
  Future<bool> deleteProductImage(String imageUrl) async {
    return deleteImage(
      imageUrl: imageUrl,
      bucketName: 'product-images',
    );
  }

  /// Upload avatar image
  /// Returns public URL or null
  Future<String?> uploadAvatarImage(File imageFile) async {
    return uploadImage(
      imageFile: imageFile,
      bucketName: 'avatars',
      folder: 'users',
    );
  }

  /// Delete avatar image
  Future<bool> deleteAvatarImage(String imageUrl) async {
    return deleteImage(
      imageUrl: imageUrl,
      bucketName: 'avatars',
    );
  }
}

