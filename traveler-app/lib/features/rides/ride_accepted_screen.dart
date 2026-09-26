import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../models/ride_model.dart';
import '../../providers/ride_provider.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen: Rider Accepted & Confirmed Screen
class RideAcceptedScreen extends ConsumerWidget {
  const RideAcceptedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideState = ref.watch(rideProvider);
    final rider = rideState.activeRider ?? Rider.defaultMockRider;
    final vehicle = rideState.selectedVehicle;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: LocalLensColors.textPrimary, size: 20),
          onPressed: () => context.go(AppRoutes.travelerHome),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LocalLensDimensions.paddingScreen,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Confirmed badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: LocalLensColors.successGreenSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: LocalLensColors.successGreen,
                  size: 42,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Your ride is confirmed!',
                style: LocalLensTypography.displayMedium.copyWith(
                  color: LocalLensColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${rider.name} is on the way to pick you up.',
                style: LocalLensTypography.bodyMedium.copyWith(color: LocalLensColors.textSecondary),
              ),

              const SizedBox(height: 24),

              // RIDER CARD
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusLarge),
                  border: Border.all(color: LocalLensColors.border),
                  boxShadow: LocalLensDimensions.floatingShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: LocalLensColors.primaryTeal, width: 2),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/characters/solo.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    rider.name,
                                    style: LocalLensTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: LocalLensColors.warmAmberSoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${rider.rating}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${vehicle.name} • ${rider.vehicleType}',
                                style: LocalLensTypography.caption.copyWith(color: LocalLensColors.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                rider.vehicleNumber,
                                style: LocalLensTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: LocalLensColors.primaryTeal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    // ETA & Fare Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('Estimated Arrival', style: LocalLensTypography.caption),
                            const SizedBox(height: 2),
                            Text('3 mins away', style: LocalLensTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: LocalLensColors.primaryTeal)),
                          ],
                        ),
                        Container(width: 1, height: 30, color: LocalLensColors.border),
                        Column(
                          children: [
                            Text('Estimated Fare', style: LocalLensTypography.caption),
                            const SizedBox(height: 2),
                            Text('₹${vehicle.estimatedFare.toInt()}', style: LocalLensTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: LocalLensColors.textPrimary)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Route Preview Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: LocalLensColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                  border: Border.all(color: LocalLensColors.borderLight),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.my_location_rounded, size: 16, color: LocalLensColors.primaryTeal),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pickup Location', style: LocalLensTypography.caption.copyWith(fontSize: 10)),
                              Text(rideState.pickupLocation, style: LocalLensTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Divider(height: 1),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.place_rounded, size: 16, color: LocalLensColors.accentOrange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Drop Destination', style: LocalLensTypography.caption.copyWith(fontSize: 10)),
                              Text(rideState.dropLocation, style: LocalLensTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Track Ride Button
              LocalLensPrimaryButton(
                text: 'Track Ride',
                isOrange: true,
                icon: Icons.navigation_rounded,
                onPressed: () {
                  context.push(AppRoutes.travelerRideLive);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
