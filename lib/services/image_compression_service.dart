import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class ImageCompressionService {
  /// Compresses an image file
  /// Returns the path to the compressed image file
  /// 
  /// Parameters:
  /// - [imageFile]: The original image file
  /// - [maxWidth]: Maximum width in pixels (default: 1920)
  /// - [maxHeight]: Maximum height in pixels (default: 1920)
  /// - [quality]: Compression quality 0-100 (default: 70)
  /// - [format]: Image format (default: CompressFormat.jpeg)
  static Future<File> compressImage(
    File imageFile, {
    int maxWidth = 1920,
    int maxHeight = 1920,
    int quality = 70,
    CompressFormat format = CompressFormat.jpeg,
  }) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg',
      );

      // Compress the image
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: quality,
        format: format,
        keepExif: false, // Remove EXIF data to reduce file size
      );

      if (result == null) {
        throw Exception('Image compression failed');
      }

      final compressedFile = File(result.path);
      
      // Log compression results for debugging
      final originalSize = await imageFile.length();
      final compressedSize = await compressedFile.length();
      final compressionRatio = ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1);
      
      debugPrint('Image compressed: ${(originalSize / 1024).toStringAsFixed(1)}KB -> ${(compressedSize / 1024).toStringAsFixed(1)}KB (${compressionRatio}% reduction)');

      return compressedFile;
    } catch (e) {
      debugPrint('Compression error: $e');
      // If compression fails, return original file
      return imageFile;
    }
  }

  /// Compresses multiple image files
  /// Returns a list of compressed image files in the same order
  static Future<List<File>> compressImages(List<File> imageFiles) async {
    final List<File> compressedImages = [];
    
    for (final imageFile in imageFiles) {
      final compressed = await compressImage(imageFile);
      compressedImages.add(compressed);
    }
    
    return compressedImages;
  }
}


