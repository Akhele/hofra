import 'package:cloud_firestore/cloud_firestore.dart';

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
    return ReportModel(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      status: data['status'] ?? 'pending',
      confirmations: data['confirmations'] ?? 0,
      fixedConfirmations: data['fixedConfirmations'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

