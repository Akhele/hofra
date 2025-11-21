import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:hofra/services/report_service.dart';
import 'package:hofra/models/report_model.dart';
import 'package:hofra/screens/report/report_screen.dart';
import 'package:hofra/widgets/report_info_bottom_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadReports();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled. Please enable them.'),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permissions are denied.'),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied.'),
            ),
          );
        }
        return;
      }

      // Use a timeout to prevent hanging
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Changed from high to medium for faster response
        timeLimit: const Duration(seconds: 10),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Location request timed out');
        },
      );
      
      if (!mounted) return;
      
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15.0,
        ),
      );
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  void _loadReports() {
    final reportService = Provider.of<ReportService>(context, listen: false);
    reportService.getReports().listen(
      (snapshot) {
        if (!mounted) return;

        Set<Marker> markers = {};
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final report = ReportModel.fromFirestore(data, doc.id);

          // Skip fixed reports - they should not appear on the map
          if (report.status == 'fixed') {
            continue;
          }

          Color markerColor = Colors.red;
          if (report.confirmations > 0) {
            markerColor = Colors.orange;
          }

          markers.add(
            Marker(
              markerId: MarkerId(report.id),
              position: LatLng(report.latitude, report.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                _getMarkerHue(markerColor),
              ),
              infoWindow: InfoWindow(
                title: 'Road Problem',
                snippet: '${report.confirmations} confirmations',
              ),
              onTap: () {
                _showReportInfo(report);
              },
            ),
          );
        }

        setState(() {
          _markers = markers;
        });
      },
      onError: (error) {
        if (!mounted) return;
        
        String errorMessage = 'Failed to load reports';
        if (error.toString().contains('permission-denied') || 
            error.toString().contains('PERMISSION_DENIED')) {
          errorMessage = 'Permission denied. Please check Firestore security rules.';
        } else if (error.toString().contains('network') || 
                   error.toString().contains('Network')) {
          errorMessage = 'Network error. Please check your internet connection.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 4),
          ),
        );
      },
    );
  }

  double _getMarkerHue(Color color) {
    if (color == Colors.red) return BitmapDescriptor.hueRed;
    if (color == Colors.green) return BitmapDescriptor.hueGreen;
    if (color == Colors.orange) return BitmapDescriptor.hueOrange;
    return BitmapDescriptor.hueRed;
  }

  void _showReportInfo(ReportModel report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReportInfoBottomSheet(report: report),
    );
  }

  Future<void> _reportProblem() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for location to be determined.'),
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportScreen(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
        ),
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Road Problems'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'Get current location',
          ),
        ],
      ),
      body: _isLoadingLocation
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition?.latitude ?? 0.0,
                      _currentPosition?.longitude ?? 0.0,
                    ),
                    zoom: _currentPosition != null ? 15.0 : 2.0,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapType: MapType.normal,
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton.extended(
                    onPressed: _reportProblem,
                    icon: const Icon(Icons.add),
                    label: const Text('Report Problem'),
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

