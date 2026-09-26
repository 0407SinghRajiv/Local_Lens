import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';

/// Screen 23: Ride Searching & Matching Radar Screen
class RideSearchingScreen extends StatefulWidget {
  const RideSearchingScreen({super.key});

  @override
  State<RideSearchingScreen> createState() => _RideSearchingScreenState();
}

class _RideSearchingScreenState extends State<RideSearchingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  Timer? _navigateTimer;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Auto navigate to Driver Assigned after 2.5s simulated matching
    _navigateTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        context.pushReplacement(AppRoutes.driverAssigned);
      }
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    _navigateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Pulsing Radar Circle
            AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 180 * _radarController.value + 60,
                      height: 180 * _radarController.value + 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: LocalLensColors.primaryTeal.withValues(alpha: 0.25 * (1 - _radarController.value)),
                      ),
                    ),
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: LocalLensColors.primaryTeal,
                        boxShadow: LocalLensDimensions.floatingShadow,
                      ),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 36),

            Text('Finding your Lens Ride', style: LocalLensTypography.displayMedium),
            const SizedBox(height: 8),
            Text(
              'Connecting with top-rated local drivers nearby...',
              style: LocalLensTypography.bodyMedium,
            ),
            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: LocalLensColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('Cancel Request', style: TextStyle(color: LocalLensColors.errorRed)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
