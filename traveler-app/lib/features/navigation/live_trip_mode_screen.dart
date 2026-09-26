import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 18: Live Trip Mode Screen
class LiveTripModeScreen extends StatelessWidget {
  const LiveTripModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Live Map Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/54511.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),

          // Top App Bar Controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: LocalLensColors.textPrimary),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                      boxShadow: LocalLensDimensions.softCardShadow,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: LocalLensColors.successGreen, size: 10),
                        SizedBox(width: 6),
                        Text(
                          'Live Trip Mode',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.alt_route_rounded, color: LocalLensColors.primaryTeal),
                      onPressed: () {
                        context.push(AppRoutes.aiReplanning);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Next Stop Card with Progress
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Next Experience',
                        style: LocalLensTypography.caption.copyWith(
                          color: LocalLensColors.primaryTeal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: LocalLensColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '2/5 completed',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Local Food Experience',
                    style: LocalLensTypography.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 14, color: LocalLensColors.textMuted),
                      const SizedBox(width: 4),
                      Text('1.2 km • 6 min transit', style: LocalLensTypography.caption),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: LocalLensPrimaryButton(
                          text: 'Start Navigation',
                          isOrange: false,
                          icon: Icons.navigation_rounded,
                          height: 48,
                          onPressed: () {
                            context.push(AppRoutes.navigation);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: LocalLensColors.accentOrangeSoft,
                          borderRadius: BorderRadius.circular(LocalLensDimensions.buttonRadius),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.local_taxi_rounded, color: LocalLensColors.accentOrange),
                          tooltip: 'Book Lens Ride',
                          onPressed: () {
                            context.push(AppRoutes.lensRideBooking);
                          },
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
    );
  }
}
