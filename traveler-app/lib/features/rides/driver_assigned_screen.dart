import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../models/ride_model.dart';
import '../../providers/ride_provider.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Screen: Driver Assigned & Live Ride Tracking (Stitch UI)
class DriverAssignedScreen extends ConsumerStatefulWidget {
  const DriverAssignedScreen({super.key});

  @override
  ConsumerState<DriverAssignedScreen> createState() => _DriverAssignedScreenState();
}

class _DriverAssignedScreenState extends ConsumerState<DriverAssignedScreen> {
  GoogleMapController? _mapController;
  bool _hasShownOtpPopup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentStatus = ref.read(rideProvider).status;
      if (currentStatus == RideStatus.arrived && !_hasShownOtpPopup) {
        _hasShownOtpPopup = true;
        _showOtpDialog(context, '4729');
      }
    });
  }

  void _showOtpDialog(BuildContext context, String otp) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: LocalLensColors.successGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.near_me_rounded,
                  color: LocalLensColors.successGreen,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Driver Has Arrived! 🚗',
                style: LocalLensTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: LocalLensColors.deepInk,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please share this 4-digit OTP with your driver so they can verify and start your ride.',
                style: LocalLensTypography.bodyMedium.copyWith(
                  color: LocalLensColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: LocalLensColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: LocalLensColors.successGreen, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: otp.split('').map((digit) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: LocalLensColors.successGreen, width: 1.5),
                      ),
                      child: Text(
                        digit,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: LocalLensColors.successGreen,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: otp));
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('OTP $otp copied to clipboard!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LocalLensColors.terracottaPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'SHARE OTP WITH DRIVER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  IconData _getVehicleIcon(VehicleType type) {
    switch (type) {
      case VehicleType.bike:
        return Icons.two_wheeler_rounded;
      case VehicleType.auto:
        return Icons.electric_rickshaw_rounded;
      case VehicleType.suv:
        return Icons.airport_shuttle_rounded;
      case VehicleType.hatchback:
        return Icons.directions_car_filled_rounded;
      case VehicleType.sedan:
        return Icons.directions_car_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RideState>(rideProvider, (previous, next) {
      if (next.status == RideStatus.arrived && previous?.status != RideStatus.arrived) {
        if (!_hasShownOtpPopup) {
          _hasShownOtpPopup = true;
          _showOtpDialog(context, '4729');
        }
      } else if (next.status == RideStatus.started || next.status == RideStatus.inProgress) {
        if (_hasShownOtpPopup && Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        context.pushReplacement(AppRoutes.travelerRideLive);
      } else if (next.status == RideStatus.completed) {
        context.pushReplacement(AppRoutes.travelerRideCompleted);
      }
    });

    final rideState = ref.watch(rideProvider);
    final rider = rideState.activeRider ?? Rider.defaultMockRider;
    final vehicle = rideState.selectedVehicle;
    final status = rideState.status;

    final riderPos = LatLng(rideState.riderLat, rideState.riderLng);
    final pickupPos = LatLng(rideState.pickupLat, rideState.pickupLng);

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('user_pickup_location'),
        position: pickupPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        infoWindow: InfoWindow(
          title: 'Your Location (Pickup Point)',
          snippet: rideState.pickupLocation,
        ),
      ),
      Marker(
        markerId: const MarkerId('rider_live_location'),
        position: riderPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: '${rider.name} (Driver)',
          snippet: rider.vehicleType,
        ),
      ),
    };

    final polylines = <Polyline>{};

    final String statusTitle = status == RideStatus.arrived
        ? 'Your Rider has arrived!'
        : (status == RideStatus.riderArriving
            ? 'Your Rider is arriving • 1 min'
            : 'Driver on the way • ${rideState.etaText}');

    return Scaffold(
      backgroundColor: LocalLensColors.background,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Live Real Google Map Background Layer with Polylines
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: pickupPos,
                  zoom: 14.5,
                ),
                markers: markers,
                polylines: polylines,
                zoomControlsEnabled: false,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onMapCreated: (controller) {
                  _mapController = controller;
                  final bounds = LatLngBounds(
                    southwest: LatLng(
                      [riderPos.latitude, pickupPos.latitude].reduce(min) - 0.005,
                      [riderPos.longitude, pickupPos.longitude].reduce(min) - 0.005,
                    ),
                    northeast: LatLng(
                      [riderPos.latitude, pickupPos.latitude].reduce(max) + 0.005,
                      [riderPos.longitude, pickupPos.longitude].reduce(max) + 0.005,
                    ),
                  );
                  controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
                },
              ),
            ),

            // Map Recenter on User Location Button
            Positioned(
              top: 90,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'recenter_user_loc',
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location_rounded, color: LocalLensColors.coastalSage),
                onPressed: () {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(pickupPos, 15.5),
                  );
                },
              ),
            ),

            // Top Navigation & Live Status Bar
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
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: LocalLensColors.deepInk),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: LocalLensDimensions.floatingShadow,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: status == RideStatus.arrived
                                  ? LocalLensColors.successGreen
                                  : LocalLensColors.coastalSage,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              statusTitle,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: LocalLensColors.deepInk,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: Icon(Icons.shield_outlined, color: LocalLensColors.terracottaPrimary),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Safety tools active. Ride is monitored.')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

          // Bottom Driver Details & Start Ride PIN Sheet
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: LocalLensDimensions.floatingShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Driver Profile Card
                  Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: LocalLensColors.surfaceContainerLow,
                            backgroundImage: rider.profileImage.startsWith('http')
                                ? NetworkImage(rider.profileImage) as ImageProvider
                                : AssetImage(rider.profileImage.isNotEmpty ? rider.profileImage : 'assets/images/characters/solo.png'),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: LocalLensColors.terracottaPrimary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_getVehicleIcon(vehicle.type), color: Colors.white, size: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rider.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: LocalLensColors.deepInk,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${rider.rating}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: LocalLensColors.deepInk,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(Verified Local Guide)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: LocalLensColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              rider.vehicleType,
                              style: TextStyle(
                                fontSize: 11,
                                color: LocalLensColors.sandTertiary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: LocalLensColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              rider.vehicleNumber,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: LocalLensColors.deepInk,
                              ),
                            ),
                            Text(
                              vehicle.name,
                              style: TextStyle(
                                fontSize: 10,
                                color: LocalLensColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // USER LOCATION & TRIP OVERVIEW CARD
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: LocalLensColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: LocalLensColors.borderSubtle),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: LocalLensColors.coastalSage.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.my_location_rounded,
                                color: LocalLensColors.coastalSage,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'YOUR PICKUP LOCATION',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                          color: LocalLensColors.coastalSage,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: LocalLensColors.coastalSage.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'User',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: LocalLensColors.coastalSage),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    rideState.pickupLocation,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: LocalLensColors.deepInk,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Divider(height: 1),
                        ),
                        if (status == RideStatus.arrived || status == RideStatus.started || status == RideStatus.inProgress) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: LocalLensColors.terracottaPrimary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.place_rounded,
                                  color: LocalLensColors.terracottaPrimary,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DESTINATION',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                        color: LocalLensColors.terracottaPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      rideState.dropLocation,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: LocalLensColors.deepInk,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Icon(Icons.lock_outline_rounded, size: 14, color: LocalLensColors.terracottaPrimary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Destination hidden until rider arrives',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.italic,
                                    color: LocalLensColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Language / Feature Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: LocalLensColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Hindi', style: TextStyle(fontSize: 10, color: LocalLensColors.textSecondary)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: LocalLensColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('English', style: TextStyle(fontSize: 10, color: LocalLensColors.textSecondary)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: LocalLensColors.coastalSage.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined, size: 10, color: LocalLensColors.coastalSage),
                            const SizedBox(width: 2),
                            Text(
                              'Verified Local Lens',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: LocalLensColors.coastalSage),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Start Ride OTP Banner (Displayed for Driver Verification before trip start)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: status == RideStatus.arrived
                          ? LocalLensColors.successGreen.withValues(alpha: 0.1)
                          : LocalLensColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: status == RideStatus.arrived
                            ? LocalLensColors.successGreen
                            : LocalLensColors.terracottaPrimary.withValues(alpha: 0.3),
                        width: status == RideStatus.arrived ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              status == RideStatus.arrived ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                              color: status == RideStatus.arrived ? LocalLensColors.successGreen : LocalLensColors.terracottaPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                status == RideStatus.arrived
                                    ? 'DRIVER ARRIVED! SHARE THIS OTP TO START RIDE'
                                    : 'YOUR RIDE VERIFICATION OTP',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: status == RideStatus.arrived ? LocalLensColors.successGreen : LocalLensColors.terracottaPrimary,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: rideState.otp));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Ride OTP ${rideState.otp} copied to clipboard!')),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: status == RideStatus.arrived ? LocalLensColors.successGreen : LocalLensColors.terracottaPrimary,
                                  ),
                                ),
                                child: Text(
                                  'Copy OTP',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: status == RideStatus.arrived ? LocalLensColors.successGreen : LocalLensColors.terracottaPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: rideState.otp.split('').map((digit) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: status == RideStatus.arrived
                                      ? LocalLensColors.successGreen
                                      : LocalLensColors.deepInk.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                digit,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: status == RideStatus.arrived ? LocalLensColors.successGreen : LocalLensColors.deepInk,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Contact & Trip Navigation Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Calling ${rider.name} (${rider.phone})...')),
                            );
                          },
                          icon: Icon(Icons.call_rounded, size: 14, color: LocalLensColors.terracottaPrimary),
                          label: Text(
                            'Call',
                            style: TextStyle(color: LocalLensColors.terracottaPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            side: BorderSide(color: LocalLensColors.terracottaPrimary.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Messaging driver...')),
                            );
                          },
                          icon: Icon(Icons.chat_bubble_outline_rounded, size: 14, color: LocalLensColors.deepInk),
                          label: Text(
                            'Message',
                            style: TextStyle(color: LocalLensColors.deepInk, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            side: BorderSide(color: LocalLensColors.borderSubtle),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.push(AppRoutes.travelerRideLive);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LocalLensColors.terracottaPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Track Live',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
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
