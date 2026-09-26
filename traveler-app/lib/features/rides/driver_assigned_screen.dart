import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';

/// Screen 24: Driver Assigned & Live Ride Tracking Screen
class DriverAssignedScreen extends StatelessWidget {
  const DriverAssignedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/54506.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: Colors.black.withValues(alpha: 0.1),
            ),
          ),

          // Top Header Pill
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                  boxShadow: LocalLensDimensions.floatingShadow,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: LocalLensColors.successGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Driver Assigned • ETA 3 mins',
                      style: LocalLensTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Floating Driver Details Sheet
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
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: LocalLensColors.primaryTealSoft,
                        child: const Icon(Icons.person_rounded, color: LocalLensColors.primaryTeal, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Rahul Rampart', style: LocalLensTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 6),
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                const Text('4.9', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('Maruti Suzuki Swift • White', style: LocalLensTypography.caption),
                            Text('MH 12 AB 3456', style: LocalLensTypography.caption.copyWith(fontWeight: FontWeight.bold, color: LocalLensColors.textPrimary)),
                          ],
                        ),
                      ),
                      Text('₹120', style: LocalLensTypography.titleLarge.copyWith(color: LocalLensColors.primaryTeal, fontWeight: FontWeight.bold)),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Call, Emergency & Complete buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.call_rounded, size: 18, color: LocalLensColors.primaryTeal),
                          label: const Text('Call Driver', style: TextStyle(color: LocalLensColors.primaryTeal)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: LocalLensColors.primaryTeal),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.push(AppRoutes.tripComplete);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LocalLensColors.primaryTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Arrived', style: TextStyle(fontWeight: FontWeight.bold)),
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
