import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 26: Adventure Complete & Day Wrap-up Summary Screen
class AdventureCompleteScreen extends StatelessWidget {
  const AdventureCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LocalLensDimensions.paddingScreen,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              Text('Adventure complete! 🎉', style: LocalLensTypography.displayLarge),
              const SizedBox(height: 6),
              Text(
                'You\'ve explored the best authentic gems of Panvel today.',
                textAlign: TextAlign.center,
                style: LocalLensTypography.bodyMedium,
              ),

              const SizedBox(height: 16),

              // Group of Travelers Illustration
              Container(
                width: double.infinity,
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusLarge),
                  boxShadow: LocalLensDimensions.softCardShadow,
                  image: const DecorationImage(
                    image: AssetImage('assets/images/54506.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Summary Stats Card Grid (Experiences, Time, Spend, Steps)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: LocalLensColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('5', 'Experiences'),
                    _buildStat('6h 45m', 'Duration'),
                    _buildStat('₹1,850', 'Total Spent'),
                    _buildStat('8,420', 'Steps Walked'),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Mini Route Path Map Thumbnail
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: LocalLensColors.primaryTealSoft,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                  border: Border.all(color: LocalLensColors.primaryTeal.withValues(alpha: 0.3)),
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.route_rounded, color: LocalLensColors.primaryTeal),
                      SizedBox(width: 8),
                      Text(
                        'Full 14.8 km Route Recorded',
                        style: TextStyle(
                          color: LocalLensColors.primaryTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // View Trip Memories CTA (Teal)
              LocalLensPrimaryButton(
                text: 'View Trip Memories',
                isOrange: false,
                onPressed: () {
                  context.go(AppRoutes.home);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: LocalLensTypography.titleLarge.copyWith(
            color: LocalLensColors.primaryTeal,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: LocalLensTypography.caption.copyWith(fontSize: 11)),
      ],
    );
  }
}
