import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../models/ride_model.dart';
import '../../providers/ride_provider.dart';
import '../../widgets/common/locallens_components.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Screen: Live Ride Tracking & Status Simulation Screen
class LiveRideScreen extends ConsumerStatefulWidget {
  const LiveRideScreen({super.key});

  @override
  ConsumerState<LiveRideScreen> createState() => _LiveRideScreenState();
}

class _LiveRideScreenState extends ConsumerState<LiveRideScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _carAnimationController;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();

    _carAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..forward();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _carAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RideState>(rideProvider, (previous, next) {
      if (next.status == RideStatus.completed) {
        context.pushReplacement(AppRoutes.travelerRideCompleted);
      }
    });

    final rideState = ref.watch(rideProvider);
    final rider = rideState.activeRider ?? Rider.defaultMockRider;
    final vehicle = rideState.selectedVehicle;
    final status = rideState.status;

    final riderPos = LatLng(rideState.riderLat, rideState.riderLng);
    final dropPos = LatLng(rideState.dropLat, rideState.dropLng);

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('rider_vehicle_marker'),
        position: riderPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: '${rider.name} (${vehicle.name})', snippet: 'En Route to Destination'),
      ),
      Marker(
        markerId: const MarkerId('destination_marker'),
        position: dropPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        infoWindow: const InfoWindow(title: 'Destination', snippet: 'Experience Dropoff Location'),
      ),
    };

    final polylines = <Polyline>{
      Polyline(
        polylineId: const PolylineId('rider_to_destination_route'),
        points: [riderPos, dropPos],
        color: LocalLensColors.primaryTeal,
        width: 5,
        geodesic: true,
      ),
    };

    return Scaffold(
      backgroundColor: LocalLensColors.background,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Google Map Canvas Background with active Route Polyline
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: dropPos,
                  zoom: 14.5,
                ),
                markers: markers,
                polylines: polylines,
                zoomControlsEnabled: false,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                  final bounds = LatLngBounds(
                    southwest: LatLng(
                      riderPos.latitude < dropPos.latitude ? riderPos.latitude - 0.005 : dropPos.latitude - 0.005,
                      riderPos.longitude < dropPos.longitude ? riderPos.longitude - 0.005 : dropPos.longitude - 0.005,
                    ),
                    northeast: LatLng(
                      riderPos.latitude > dropPos.latitude ? riderPos.latitude + 0.005 : dropPos.latitude + 0.005,
                      riderPos.longitude > dropPos.longitude ? riderPos.longitude + 0.005 : dropPos.longitude + 0.005,
                    ),
                  );
                  controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
                },
              ),
            ),

            // 2. Top Header Navigation Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back / Minimize Button
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: LocalLensDimensions.floatingShadow,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: LocalLensColors.textPrimary, size: 18),
                      onPressed: () => context.pop(),
                    ),
                  ),

                  // Live Status Pill
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                          boxShadow: LocalLensDimensions.floatingShadow,
                          border: Border.all(
                            color: status == RideStatus.arrived
                                ? LocalLensColors.successGreen
                                : LocalLensColors.primaryTeal,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: status == RideStatus.arrived
                                    ? LocalLensColors.successGreen
                                    : LocalLensColors.accentOrange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                status == RideStatus.arrived
                                    ? 'Driver has arrived!'
                                    : (status == RideStatus.inProgress
                                        ? 'Heading to destination'
                                        : 'Driver arriving • ETA 3 min'),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: LocalLensTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: LocalLensColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // SOS / Safety Shield Button
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: LocalLensDimensions.floatingShadow,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.shield_outlined, color: LocalLensColors.accentOrange, size: 20),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('LocalLens Safety: Emergency assistance & Ride share active.'),
                            backgroundColor: LocalLensColors.primaryTealDark,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

          // 3. Driver Arrived Banner (When Arrived)
          if (status == RideStatus.arrived)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: LocalLensColors.successGreen,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                  boxShadow: LocalLensDimensions.floatingShadow,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_taxi_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your ride has arrived!',
                            style: LocalLensTypography.titleSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${rider.name} is waiting at pickup location.',
                            style: LocalLensTypography.caption.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. Bottom Floating Live Ride Sheet
          Positioned(
            bottom: 20,
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
                  // Drag indicator
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rider profile info
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: LocalLensColors.primaryTeal, width: 2),
                          image: DecorationImage(
                            image: rider.profileImage.startsWith('http')
                                ? NetworkImage(rider.profileImage) as ImageProvider
                                : AssetImage(rider.profileImage.isNotEmpty ? rider.profileImage : 'assets/images/characters/solo.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    rider.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: LocalLensTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                Text('${rider.rating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            Text(
                              '${vehicle.name} • ${rider.vehicleNumber}',
                              style: LocalLensTypography.caption.copyWith(fontWeight: FontWeight.bold, color: LocalLensColors.primaryTeal),
                            ),
                            Text(
                              rider.vehicleType.isNotEmpty ? rider.vehicleType : '${vehicle.name} (${rider.vehicleNumber})',
                              style: LocalLensTypography.caption.copyWith(color: LocalLensColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            status == RideStatus.arrived ? '0 min' : (status == RideStatus.inProgress ? '5 min' : '3 min'),
                            style: LocalLensTypography.titleLarge.copyWith(
                              color: LocalLensColors.primaryTeal,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            status == RideStatus.inProgress ? '2.4 km left' : 'Pickup in 300m',
                            style: LocalLensTypography.caption.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Action Buttons
                  if (status == RideStatus.arrived) ...[
                    LocalLensPrimaryButton(
                      text: 'Driver Arrived • Board Vehicle',
                      isOrange: true,
                      icon: Icons.play_arrow_rounded,
                      onPressed: () {
                        ref.read(rideProvider.notifier).startTrip();
                      },
                    ),
                  ] else if (status == RideStatus.inProgress || status == RideStatus.started) ...[
                    LocalLensPrimaryButton(
                      text: 'Heading to Destination...',
                      isOrange: false,
                      icon: Icons.navigation_rounded,
                      onPressed: () {
                        context.pushReplacement(AppRoutes.travelerRideCompleted);
                      },
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Calling ${rider.name} (${rider.phone})...'),
                                  backgroundColor: LocalLensColors.primaryTeal,
                                ),
                              );
                            },
                            icon: const Icon(Icons.phone_rounded, color: LocalLensColors.primaryTeal, size: 18),
                            label: const Text('Call', style: TextStyle(color: LocalLensColors.primaryTeal, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: LocalLensColors.primaryTeal),
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Live ride location shared with your trusted contacts.'),
                                  backgroundColor: LocalLensColors.primaryTealDark,
                                ),
                              );
                            },
                            icon: const Icon(Icons.share_location_rounded, color: LocalLensColors.textPrimary, size: 18),
                            label: const Text('Share', style: TextStyle(color: LocalLensColors.textPrimary, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: LocalLensColors.border),
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: LocalLensColors.errorRed),
                          tooltip: 'Cancel Ride',
                          onPressed: () {
                            ref.read(rideProvider.notifier).cancelRide();
                            context.pop();
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }
}
