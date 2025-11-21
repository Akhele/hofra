import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:hofra/services/image_upload_service.dart';

class ReportService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImageUploadService _imageUploadService = ImageUploadService();

  Future<String> createReport({
    required double latitude,
    required double longitude,
    String? description,
    required List<File> images,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated. Please log in again.');

      if (images.isEmpty) {
        throw Exception('Please add at least one image');
      }

      // Upload images to custom server
      List<String> imageUrls;
      try {
        imageUrls = await _imageUploadService.uploadImages(images);
      } catch (e) {
        // Re-throw with more context
        if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
          throw Exception('Image upload timed out. Please check your internet connection and try again.');
        }
        if (e.toString().contains('Network error') || e.toString().contains('SocketException')) {
          throw Exception('Network error: Unable to upload images. Please check your internet connection.');
        }
        throw Exception('Failed to upload images: ${e.toString()}');
      }

      if (imageUrls.isEmpty) {
        throw Exception('No images were uploaded successfully');
      }

      // Create report document
      final reportData = {
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'latitude': latitude,
        'longitude': longitude,
        'description': description?.trim() ?? '', // Optional description, default to empty string
        'images': imageUrls,
        'status': 'pending', // pending, confirmed, fixed
        'confirmations': 0,
        'fixedConfirmations': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('reports').add(reportData);
      notifyListeners();
      return docRef.id;
    } on FirebaseException catch (e) {
      // Preserve permission-denied errors for better user feedback
      if (e.code == 'permission-denied' || e.code == 'PERMISSION_DENIED') {
        throw Exception('permission-denied: Firestore security rules not deployed. Please deploy firestore.rules to Firebase.');
      }
      throw Exception('Firebase error: ${e.message ?? e.code}');
    } catch (e) {
      // Re-throw if it's already a formatted error message
      if (e.toString().startsWith('Failed to upload') || 
          e.toString().contains('Network error') ||
          e.toString().contains('timeout')) {
        rethrow;
      }
      throw Exception('Failed to create report: ${e.toString()}');
    }
  }

  Future<void> confirmReport(String reportId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final reportRef = _firestore.collection('reports').doc(reportId);
      final reportDoc = await reportRef.get();

      if (!reportDoc.exists) throw Exception('Report not found');

      final confirmationsRef = _firestore
          .collection('reports')
          .doc(reportId)
          .collection('confirmations')
          .doc(user.uid);

      final confirmationDoc = await confirmationsRef.get();

      if (confirmationDoc.exists && confirmationDoc.data()?['type'] == 'confirm') {
        // Already confirmed, remove confirmation
        await confirmationsRef.delete();
        await reportRef.update({
          'confirmations': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Add confirmation
        await confirmationsRef.set({
          'userId': user.uid,
          'type': 'confirm',
          'createdAt': FieldValue.serverTimestamp(),
        });
        await reportRef.update({
          'confirmations': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to confirm report: $e');
    }
  }

  Future<void> confirmFixed(String reportId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final reportRef = _firestore.collection('reports').doc(reportId);
      final confirmationsRef = _firestore
          .collection('reports')
          .doc(reportId)
          .collection('confirmations')
          .doc('${user.uid}_fixed');

      final confirmationDoc = await confirmationsRef.get();

      if (confirmationDoc.exists && confirmationDoc.data()?['type'] == 'fixed') {
        // Already confirmed as fixed, remove confirmation
        await confirmationsRef.delete();
        final reportData = (await reportRef.get()).data();
        final currentFixedConfirmations = reportData?['fixedConfirmations'] ?? 0;
        
        // If this was the last fixed confirmation, change status back to pending
        if (currentFixedConfirmations <= 1) {
          await reportRef.update({
            'fixedConfirmations': FieldValue.increment(-1),
            'status': 'pending',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          await reportRef.update({
            'fixedConfirmations': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // Add fixed confirmation
        await confirmationsRef.set({
          'userId': user.uid,
          'type': 'fixed',
          'createdAt': FieldValue.serverTimestamp(),
        });
        await reportRef.update({
          'fixedConfirmations': FieldValue.increment(1),
          'status': 'fixed', // Mark report as fixed so it disappears from map
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to confirm fixed: $e');
    }
  }

  Stream<QuerySnapshot> getReports() {
    return _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<Map<String, int>> getUserStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {'reported': 0, 'fixed': 0, 'pending': 0};

      final reports = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: user.uid)
          .get();

      int reported = reports.docs.length;
      int fixed = reports.docs.where((doc) => doc.data()['status'] == 'fixed').length;
      int pending = reported - fixed;

      return {
        'reported': reported,
        'fixed': fixed,
        'pending': pending,
      };
    } catch (e) {
      return {'reported': 0, 'fixed': 0, 'pending': 0};
    }
  }
}

