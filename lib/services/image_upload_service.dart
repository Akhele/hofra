import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hofra/config/server_config.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ImageUploadService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const Duration _uploadTimeout = Duration(seconds: 30);

  /// Uploads a single image file to the server
  /// Returns the URL or filename of the uploaded image
  Future<String> uploadImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file not found');
      }

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

      // Send request with timeout
      http.StreamedResponse streamedResponse;
      try {
        streamedResponse = await request.send().timeout(
          _uploadTimeout,
          onTimeout: () {
            throw TimeoutException('Image upload timed out after ${_uploadTimeout.inSeconds} seconds');
          },
        );
      } on SocketException catch (e) {
        debugPrint('DNS/Network error during upload: $e');
        throw Exception('Cannot connect to server. Please check:\n1. The server URL is correct (${ServerConfig.baseUrl})\n2. Your internet connection\n3. The server is online\n\nError: ${e.message}');
      }
      
      http.Response response;
      try {
        response = await http.Response.fromStream(streamedResponse).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Failed to receive server response');
          },
        );
      } on SocketException catch (e) {
        debugPrint('DNS/Network error receiving response: $e');
        throw Exception('Cannot connect to server. Please check:\n1. The server URL is correct (${ServerConfig.baseUrl})\n2. Your internet connection\n3. The server is online\n\nError: ${e.message}');
      }

      // Log the response for debugging
      debugPrint('Upload response status: ${response.statusCode}');
      debugPrint('Upload response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse response - adjust based on your server's response format
        try {
          final jsonResponse = json.decode(response.body);
          
          // Check if server indicates success
          if (jsonResponse['success'] == false) {
            final errorMsg = jsonResponse['message'] ?? 'Upload failed';
            throw Exception('Server error: $errorMsg');
          }
          
          // If your server returns the full URL
          if (jsonResponse['url'] != null) {
            final url = jsonResponse['url'] as String;
            debugPrint('Upload successful, URL: $url');
            
            // Verify the file is accessible (optional check)
            try {
              final verifyResponse = await http.head(Uri.parse(url)).timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  debugPrint('Warning: Could not verify uploaded file exists (timeout)');
                  return http.Response('', 408);
                },
              );
              
              if (verifyResponse.statusCode == 200 || verifyResponse.statusCode == 404) {
                if (verifyResponse.statusCode == 404) {
                  debugPrint('Warning: Uploaded file not found at URL: $url');
                  debugPrint('The server reported success but the file may not be accessible.');
                } else {
                  debugPrint('Verified: Uploaded file is accessible at: $url');
                }
              }
            } catch (e) {
              debugPrint('Warning: Could not verify uploaded file: $e');
              // Don't fail the upload if verification fails - server said it worked
            }
            
            return url;
          }
          
          // If your server returns just the filename
          if (jsonResponse['filename'] != null) {
            final url = ServerConfig.getImageUrl(jsonResponse['filename'] as String);
            debugPrint('Upload successful, filename: ${jsonResponse['filename']}, URL: $url');
            
            // Verify the file is accessible
            try {
              final verifyResponse = await http.head(Uri.parse(url)).timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  debugPrint('Warning: Could not verify uploaded file exists (timeout)');
                  return http.Response('', 408);
                },
              );
              
              if (verifyResponse.statusCode == 404) {
                debugPrint('Warning: Uploaded file not found at URL: $url');
                debugPrint('The server reported success but the file may not be accessible.');
              } else if (verifyResponse.statusCode == 200) {
                debugPrint('Verified: Uploaded file is accessible at: $url');
              }
            } catch (e) {
              debugPrint('Warning: Could not verify uploaded file: $e');
            }
            
            return url;
          }
          
          // If your server returns a path
          if (jsonResponse['path'] != null) {
            final url = ServerConfig.getImageUrl(jsonResponse['path'] as String);
            debugPrint('Upload successful, path: ${jsonResponse['path']}, URL: $url');
            return url;
          }
          
          // If success is true but no URL/filename, something is wrong
          if (jsonResponse['success'] == true) {
            throw Exception('Server returned success but no image URL or filename');
          }
        } catch (e) {
          // If it's already an Exception we threw, rethrow it
          if (e is Exception) rethrow;
          
          // If response is not JSON, check if it's a plain text error
          final responseBody = response.body.trim();
          if (responseBody.toLowerCase().contains('error') || 
              responseBody.toLowerCase().contains('fail')) {
            throw Exception('Server error: $responseBody');
          }
          
          // If response is empty, that's suspicious
          if (responseBody.isEmpty) {
            throw Exception('Server returned empty response. Upload may have failed.');
          }
          
          // If it looks like a URL, use it
          if (responseBody.startsWith('http://') || responseBody.startsWith('https://')) {
            debugPrint('Upload successful, URL from response: $responseBody');
            return responseBody;
          }
          
          // If it looks like a filename, construct URL
          if (responseBody.length < 200 && !responseBody.contains('\n')) {
            final url = ServerConfig.getImageUrl(responseBody);
            debugPrint('Upload successful, filename from response: $responseBody, URL: $url');
            return url;
          }
          
          // Unknown response format
          throw Exception('Unknown server response format: $responseBody');
        }
        
        // Should not reach here, but if we do, it's an error
        throw Exception('Server returned success but response format is unrecognized');
      } else {
        final errorMessage = response.body.isNotEmpty 
            ? response.body 
            : 'Server returned status ${response.statusCode}';
        throw Exception('Upload failed (HTTP ${response.statusCode}): $errorMessage');
      }
    } on TimeoutException catch (e) {
      throw Exception('Upload timeout: ${e.message}\n\nPlease check:\n1. Your internet connection\n2. The server is online (${ServerConfig.baseUrl})\n3. The upload endpoint exists (${ServerConfig.uploadUrl})');
    } on SocketException catch (e) {
      debugPrint('SocketException: ${e.message}');
      if (e.message.contains('Failed host lookup') || e.message.contains('No address associated')) {
        throw Exception('Cannot resolve server address: ${ServerConfig.baseUrl}\n\nPlease check:\n1. The domain name is correct\n2. The server is online\n3. Your DNS settings\n\nError: ${e.message}');
      }
      throw Exception('Network error: Unable to connect to server.\n\nPlease check:\n1. Your internet connection\n2. The server URL is correct (${ServerConfig.baseUrl})\n3. The server is online\n\nError: ${e.message}');
    } on HttpException catch (e) {
      throw Exception('HTTP error: ${e.message}');
    } catch (e) {
      debugPrint('Upload error: $e');
      if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
        throw Exception('Upload timeout: Please check your internet connection and try again.');
      }
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup') || e.toString().contains('No address associated')) {
        throw Exception('Cannot connect to server: ${ServerConfig.baseUrl}\n\nPlease verify:\n1. The domain name is correct\n2. The server is online\n3. Your internet connection');
      }
      throw Exception('Failed to upload image: ${e.toString()}');
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

