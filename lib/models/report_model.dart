import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hofra/config/server_config.dart';

class ReportModel {
  final String id;
  final String userId;
  final String userName;
  final double latitude;
  final double longitude;
  final String description;
  final List<String> images;
  final String status;
  final int confirmations;
  final int fixedConfirmations;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ReportModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.images,
    required this.status,
    required this.confirmations,
    required this.fixedConfirmations,
    required this.createdAt,
    this.updatedAt,
  });

  factory ReportModel.fromFirestore(Map<String, dynamic> data, String id) {
    // Normalize image URLs to ensure they use the correct path
    final rawImages = List<String>.from(data['images'] ?? []);
    final normalizedImages = rawImages.map((url) => _normalizeImageUrl(url)).toList();
    
    return ReportModel(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      images: normalizedImages,
      status: data['status'] ?? 'pending',
      confirmations: data['confirmations'] ?? 0,
      fixedConfirmations: data['fixedConfirmations'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
  
  /// Normalizes image URLs to use the correct path (api/uploads/reports/)
  /// This fixes URLs from old reports that might have the wrong path
  static String _normalizeImageUrl(String url) {
    try {
      // If URL doesn't contain the base URL, return as-is (might be relative)
      if (!url.contains(ServerConfig.baseUrl)) {
        return url;
      }
      
      // Extract filename from URL
      final uri = Uri.parse(url);
      final filename = uri.pathSegments.last;
      
      // Reconstruct URL with correct path
      return ServerConfig.getImageUrl(filename);
    } catch (e) {
      // If parsing fails, return original URL
      return url;
    }
  }
}

