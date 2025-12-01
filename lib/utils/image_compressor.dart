import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageCompressor {
  /// Compress image to reduce file size
  /// Returns compressed File, or original file if compression fails
  /// 
  /// Parameters:
  /// - imageFile: Original image file
  /// - maxWidth: Maximum width (default: 1920)
  /// - maxHeight: Maximum height (default: 1920)
  /// - quality: Compression quality 0-100 (default: 85)
  /// - minWidth: Minimum width to compress (default: 800)
  /// - minHeight: Minimum height to compress (default: 800)
  static Future<File> compressImage({
    required File imageFile,
    int maxWidth = 1920,
    int maxHeight = 1920,
    int quality = 85,
    int minWidth = 800,
    int minHeight = 800,
  }) async {
    try {
      // Get file size
      final originalSize = await imageFile.length();
      
      // If file is already small (< 500KB), return original
      if (originalSize < 500 * 1024) {
        return imageFile;
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final targetPath = path.join(
        tempDir.path,
        'compressed_$timestamp$extension',
      );

      // Compress image
      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        minWidth: minWidth,
        minHeight: minHeight,
        quality: quality,
        format: extension.toLowerCase() == '.png' 
            ? CompressFormat.png 
            : CompressFormat.jpeg,
        keepExif: false, // Remove EXIF data to reduce size
      );

      if (compressedXFile != null) {
        // Convert XFile to File
        final compressedFile = File(compressedXFile.path);
        final compressedSize = await compressedFile.length();
        
        // If compressed file is larger than original, use original
        if (compressedSize >= originalSize) {
          return imageFile;
        }
        
        return compressedFile;
      }
      
      // If compression fails, return original
      return imageFile;
    } catch (e) {
      print('Image compression error: $e');
      // If compression fails, return original file
      return imageFile;
    }
  }

  /// Compress product image (optimized for product photos)
  static Future<File> compressProductImage(File imageFile) async {
    return compressImage(
      imageFile: imageFile,
      maxWidth: 1920,
      maxHeight: 1920,
      quality: 85, // Good balance between quality and size
      minWidth: 800,
      minHeight: 800,
    );
  }

  /// Compress avatar image (smaller size for profile pictures)
  static Future<File> compressAvatarImage(File imageFile) async {
    return compressImage(
      imageFile: imageFile,
      maxWidth: 512,
      maxHeight: 512,
      quality: 80, // Slightly lower quality for smaller file size
      minWidth: 256,
      minHeight: 256,
    );
  }
}

