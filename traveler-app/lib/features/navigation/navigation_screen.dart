import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../widgets/common/locallens_components.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Screen 19: Turn-by-Turn Navigation Screen
class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  GoogleMapController? _mapController;

  static const _userLoc = LatLng(18.9894, 73.1175);
  static const _destLoc = LatLng(18.9950, 73.1250);

  final Set<Marker> _markers = {
    Marker(
      markerId: const MarkerId('user_current_location'),
      position: _userLoc,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'You are here', snippet: 'Current Location'),
    ),
    Marker(
      markerId: const MarkerId('experience_destination'),
      position: _destLoc,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      infoWindow: const InfoWindow(title: 'Local Food Experience', snippet: 'Destination'),
    ),
  };

  final Set<Polyline> _polylines = {
    const Polyline(
      polylineId: PolylineId('navigation_turn_by_turn_route'),
      points: [_userLoc, LatLng(18.9920, 73.1200), _destLoc],
      color: LocalLensColors.primaryTeal,
      width: 6,
      geodesic: true,
    ),
  };

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Navigation Route Real Google Map
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _userLoc,
                zoom: 15.0,
              ),
              markers: _markers,
              polylines: _polylines,
              zoomControlsEnabled: false,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          ),

          // Top Turn-by-Turn Maneuver Pill
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: LocalLensColors.textPrimary,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                  boxShadow: LocalLensDimensions.floatingShadow,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.turn_right_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'In 200m turn right',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'onto Coast Market Road',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Destination Card with "Arrived" button
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(LocalLensDimensions.radiusLarge),
                boxShadow: LocalLensDimensions.floatingShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: LocalLensColors.primaryTealSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.restaurant_rounded, color: LocalLensColors.primaryTeal),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Local Food Experience',
                              style: LocalLensTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '1.2 km • 6 min remaining',
                              style: LocalLensTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LocalLensPrimaryButton(
                    text: 'I Have Arrived',
                    isOrange: true,
                    height: 48,
                    onPressed: () {
                      context.push(AppRoutes.adventureComplete);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
