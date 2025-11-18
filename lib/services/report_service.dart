import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class ReportService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createReport({
    required double latitude,
    required double longitude,
    required String description,
    required List<File> images,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Upload images
      List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        final ref = _storage.ref().child('reports/${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        await ref.putFile(images[i]);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      // Create report document
      final reportData = {
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
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
    } catch (e) {
      throw Exception('Failed to create report: $e');
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
        await reportRef.update({
          'fixedConfirmations': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Add fixed confirmation
        await confirmationsRef.set({
          'userId': user.uid,
          'type': 'fixed',
          'createdAt': FieldValue.serverTimestamp(),
        });
        await reportRef.update({
          'fixedConfirmations': FieldValue.increment(1),
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

