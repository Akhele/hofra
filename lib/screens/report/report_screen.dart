import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:hofra/services/report_service.dart';
import 'package:hofra/services/image_compression_service.dart';

class ReportScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const ReportScreen({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<File> _images = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 3 images allowed'),
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Compressing image...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 100, // Get full quality first, then compress
      );

      if (image != null) {
        // Compress the image
        final originalFile = File(image.path);
        final compressedFile = await ImageCompressionService.compressImage(
          originalFile,
          maxWidth: 1920,
          maxHeight: 1920,
          quality: 70, // Good balance between quality and file size
        );

        if (mounted) {
          setState(() {
            _images.add(compressedFile);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one image'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final reportService = Provider.of<ReportService>(context, listen: false);
      final description = _descriptionController.text.trim();
      await reportService.createReport(
        latitude: widget.latitude,
        longitude: widget.longitude,
        description: description.isEmpty ? null : description, // Pass null if empty
        images: _images,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error submitting report';
        String errorString = e.toString();
        
        // Provide more specific error messages
        if (errorString.contains('permission-denied') || 
            errorString.contains('PERMISSION_DENIED')) {
          errorMessage = 'Permission denied. Please contact support or check Firestore rules.';
        } else if (errorString.contains('Cannot resolve server') ||
                   errorString.contains('Cannot connect to server') ||
                   errorString.contains('Failed host lookup') ||
                   errorString.contains('No address associated')) {
          // Show full DNS/server connection error (contains helpful troubleshooting info)
          errorMessage = errorString.replaceFirst('Exception: ', '');
        } else if (errorString.contains('network') || 
                   errorString.contains('Network') ||
                   errorString.contains('timeout') ||
                   errorString.contains('Timeout')) {
          // Show full timeout/network error if it contains troubleshooting info
          if (errorString.contains('Please check:')) {
            errorMessage = errorString.replaceFirst('Exception: ', '');
          } else {
            errorMessage = 'Network error. Please check your internet connection and try again.';
          }
        } else if (errorString.contains('upload') || errorString.contains('Upload')) {
          // Show full upload error if it contains troubleshooting info
          if (errorString.contains('Please check:') || errorString.contains('Please verify:')) {
            errorMessage = errorString.replaceFirst('Exception: ', '');
          } else {
            errorMessage = 'Failed to upload images. Please check your server configuration.';
          }
        } else {
          errorMessage = 'Error: $errorString';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 8), // Longer duration for detailed errors
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Problem'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Latitude: ${widget.latitude.toStringAsFixed(6)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Longitude: ${widget.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Describe the road problem... (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 5,
                // No validator - description is optional
              ),
              const SizedBox(height: 24),
              const Text(
                'Photos (Max 3)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_images.isEmpty)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('No images selected'),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Camera'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._images.asMap().entries.map((entry) {
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(entry.value),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                onPressed: () => _removeImage(entry.key),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    if (_images.length < 3)
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt),
                                    title: const Text('Take Photo'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage(ImageSource.camera);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_library),
                                    title: const Text('Choose from Gallery'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage(ImageSource.gallery);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add, size: 40),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

