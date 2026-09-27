import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../widgets/common/locallens_components.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Screen 13: Experience Map Screen with Route & Bottom Detail Card
class ExperienceMapScreen extends StatefulWidget {
  const ExperienceMapScreen({super.key});

  @override
  State<ExperienceMapScreen> createState() => _ExperienceMapScreenState();
}

class _ExperienceMapScreenState extends State<ExperienceMapScreen> {
  GoogleMapController? _mapController;

  static const _center = LatLng(18.9894, 73.1175);
  static const _stop1 = LatLng(18.9850, 73.1120);
  static const _stop2 = LatLng(18.9920, 73.1230);
  static const _stop3 = LatLng(18.9980, 73.1290);

  final Set<Marker> _markers = {
    Marker(
      markerId: const MarkerId('stop1'),
      position: _stop1,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
      infoWindow: const InfoWindow(title: 'Panvel Heritage Trail', snippet: 'Stop 1'),
    ),
    Marker(
      markerId: const MarkerId('stop2'),
      position: _stop2,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      infoWindow: const InfoWindow(title: 'Sunset by the Coast', snippet: 'Stop 2'),
    ),
    Marker(
      markerId: const MarkerId('stop3'),
      position: _stop3,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'Local Spice Tasting', snippet: 'Stop 3'),
    ),
  };

  final Set<Polyline> _polylines = {
    const Polyline(
      polylineId: PolylineId('experience_trail_route'),
      points: [_stop1, _stop2, _stop3],
      color: LocalLensColors.primaryTeal,
      width: 5,
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
          // Full-screen Interactive Real Google Map
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _center,
                zoom: 13.8,
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

          // Top Floating Navigation Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: LocalLensColors.textPrimary, size: 18),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                        boxShadow: LocalLensDimensions.softCardShadow,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: LocalLensColors.primaryTeal, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Panvel Coastline & Trails',
                            style: LocalLensTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Floating Experience Preview Card
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
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
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/destinations/sunset_coast.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sunset by the Coast',
                              style: LocalLensTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹899 • 2.5 hrs • 4.8 ★',
                              style: LocalLensTypography.caption.copyWith(
                                color: LocalLensColors.primaryTeal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LocalLensPrimaryButton(
                    text: 'View Details',
                    isOrange: false,
                    onPressed: () {
                      context.push(AppRoutes.experienceDetails);
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
