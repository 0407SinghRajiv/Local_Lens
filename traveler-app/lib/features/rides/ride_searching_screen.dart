import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../models/ride_model.dart';
import '../../providers/ride_provider.dart';

/// Screen: Ride Searching & Matching Radar Screen
class RideSearchingScreen extends ConsumerStatefulWidget {
  const RideSearchingScreen({super.key});

  @override
  ConsumerState<RideSearchingScreen> createState() => _RideSearchingScreenState();
}

class _RideSearchingScreenState extends ConsumerState<RideSearchingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RideState>(rideProvider, (previous, next) {
      if (next.status == RideStatus.accepted || next.status == RideStatus.riderArriving) {
        context.pushReplacement(AppRoutes.travelerRideAccepted);
      } else if (next.status == RideStatus.cancelled || next.status == RideStatus.failed) {
        if (mounted && context.canPop()) {
          context.pop();
        }
      }
    });

    final rideState = ref.watch(rideProvider);
    final vehicle = rideState.selectedVehicle;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LocalLensDimensions.paddingScreen,
            vertical: 20,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Pulsing Radar Circle & Car Icon
              AnimatedBuilder(
                animation: _radarController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ripple 1
                      Container(
                        width: 220 * _radarController.value + 60,
                        height: 220 * _radarController.value + 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: LocalLensColors.primaryTeal.withValues(alpha: 0.22 * (1 - _radarController.value)),
                        ),
                      ),
                      // Outer ripple 2
                      Container(
                        width: 140 * _radarController.value + 40,
                        height: 140 * _radarController.value + 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: LocalLensColors.primaryTeal.withValues(alpha: 0.35 * (1 - _radarController.value)),
                        ),
                      ),
                      // Center vehicle container
                      Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: LocalLensColors.primaryTeal,
                          boxShadow: LocalLensDimensions.floatingShadow,
                        ),
                        child: Icon(
                          vehicle.icon,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),

              Text('Finding your Lens Ride...', style: LocalLensTypography.displayMedium),
              const SizedBox(height: 8),
              Text(
                'Looking for nearby riders for ${vehicle.name}...',
                style: LocalLensTypography.bodyMedium.copyWith(color: LocalLensColors.textSecondary),
              ),

              const SizedBox(height: 20),

              // Trip details card
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rideState.pickupLocation,
                            style: LocalLensTypography.caption.copyWith(fontWeight: FontWeight.bold, color: LocalLensColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Divider(height: 1),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.place_rounded, size: 16, color: LocalLensColors.accentOrange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rideState.dropLocation,
                            style: LocalLensTypography.caption.copyWith(fontWeight: FontWeight.bold, color: LocalLensColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Cancel button
              OutlinedButton(
                onPressed: () {
                  ref.read(rideProvider.notifier).cancelRide();
                  context.pop();
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(color: LocalLensColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text('Cancel Request', style: TextStyle(color: LocalLensColors.errorRed, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
