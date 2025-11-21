import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hofra/models/report_model.dart';
import 'package:hofra/services/report_service.dart';

class ReportInfoBottomSheet extends StatefulWidget {
  final ReportModel report;

  const ReportInfoBottomSheet({
    super.key,
    required this.report,
  });

  @override
  State<ReportInfoBottomSheet> createState() => _ReportInfoBottomSheetState();
}

class _ReportInfoBottomSheetState extends State<ReportInfoBottomSheet> {
  bool _isConfirming = false;
  bool _isMarkingFixed = false;

  @override
  Widget build(BuildContext context) {
    final reportService = Provider.of<ReportService>(context, listen: false);
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(widget.report.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.report.status.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(widget.report.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (widget.report.images.isNotEmpty) ...[
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.report.images.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 200,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[200],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  widget.report.images[index],
                                  fit: BoxFit.cover,
                                  cacheWidth: 400, // Cache at display size for better performance
                                  cacheHeight: 400,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Image not available',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child;
                                    }
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (widget.report.description.isNotEmpty)
                      Text(
                        widget.report.description,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              'No description provided',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Reported by ${widget.report.userName}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          dateFormat.format(widget.report.createdAt),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.report.latitude.toStringAsFixed(6)}, ${widget.report.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            context: context,
                            icon: Icons.thumb_up,
                            label: 'Confirm\n(${widget.report.confirmations})',
                            color: Colors.blue,
                            isLoading: _isConfirming,
                            onPressed: _isConfirming ? null : () async {
                              setState(() => _isConfirming = true);
                              try {
                                await reportService.confirmReport(widget.report.id);
                                if (context.mounted) {
                                  // Close the bottom sheet first
                                  Navigator.pop(context);
                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.white),
                                          SizedBox(width: 8),
                                          Text('Report confirmed successfully!'),
                                        ],
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.error, color: Colors.white),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              e.toString().contains('permission-denied') || 
                                              e.toString().contains('PERMISSION_DENIED')
                                                  ? 'Permission denied. Please deploy Firestore rules.'
                                                  : 'Error: ${e.toString()}',
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isConfirming = false);
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            context: context,
                            icon: Icons.check_circle,
                            label: 'Fixed\n(${widget.report.fixedConfirmations})',
                            color: Colors.green,
                            isLoading: _isMarkingFixed,
                            onPressed: _isMarkingFixed ? null : () async {
                              setState(() => _isMarkingFixed = true);
                              try {
                                await reportService.confirmFixed(widget.report.id);
                                if (context.mounted) {
                                  // Close the bottom sheet first
                                  Navigator.pop(context);
                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.white),
                                          SizedBox(width: 8),
                                          Text('Report marked as fixed!'),
                                        ],
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.error, color: Colors.white),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              e.toString().contains('permission-denied') || 
                                              e.toString().contains('PERMISSION_DENIED')
                                                  ? 'Permission denied. Please deploy Firestore rules.'
                                                  : 'Error: ${e.toString()}',
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isMarkingFixed = false);
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'fixed':
        return Colors.green;
      case 'confirmed':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isLoading 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(icon),
      label: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        disabledBackgroundColor: color.withOpacity(0.6),
      ),
    );
  }
}

