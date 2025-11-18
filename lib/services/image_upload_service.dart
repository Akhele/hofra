import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hofra/config/server_config.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ImageUploadService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Uploads a single image file to the server
  /// Returns the URL or filename of the uploaded image
  Future<String> uploadImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ServerConfig.uploadUrl),
      );

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${user.uid}_${timestamp}_${imageFile.path.split('/').last}';

      // Add file to request
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // Field name - adjust based on your server's expected field name
          imageFile.path,
        ),
      );

      // Add additional fields if your server needs them
      request.fields['userId'] = user.uid;
      request.fields['filename'] = filename;
      request.fields['timestamp'] = timestamp.toString();

      // Add authorization header if needed
      // request.headers['Authorization'] = 'Bearer ${user.getIdToken()}';

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse response - adjust based on your server's response format
        try {
          final jsonResponse = json.decode(response.body);
          
          // If your server returns the full URL
          if (jsonResponse['url'] != null) {
            return jsonResponse['url'] as String;
          }
          
          // If your server returns just the filename
          if (jsonResponse['filename'] != null) {
            return ServerConfig.getImageUrl(jsonResponse['filename'] as String);
          }
          
          // If your server returns a path
          if (jsonResponse['path'] != null) {
            return ServerConfig.getImageUrl(jsonResponse['path'] as String);
          }
        } catch (e) {
          // If response is not JSON, assume it's the filename or URL
          final responseBody = response.body.trim();
          if (responseBody.startsWith('http://') || responseBody.startsWith('https://')) {
            return responseBody;
          }
          return ServerConfig.getImageUrl(responseBody);
        }
        
        // Fallback: use the filename we generated
        return ServerConfig.getImageUrl(filename);
      } else {
        throw Exception(
          'Upload failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Uploads multiple images
  /// Returns a list of URLs/filenames in the same order as input
  Future<List<String>> uploadImages(List<File> imageFiles) async {
    final List<String> uploadedUrls = [];
    
    for (final imageFile in imageFiles) {
      try {
        final url = await uploadImage(imageFile);
        uploadedUrls.add(url);
      } catch (e) {
        // If one image fails, you can either:
        // 1. Throw error and stop (current behavior)
        // 2. Continue with other images and return partial results
        throw Exception('Failed to upload image ${imageFiles.indexOf(imageFile) + 1}: $e');
      }
    }
    
    return uploadedUrls;
  }
}

