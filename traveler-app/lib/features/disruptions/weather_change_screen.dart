import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 20: Weather Change Alert Screen
class WeatherChangeScreen extends StatelessWidget {
  const WeatherChangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: LocalLensColors.textPrimary),
          onPressed: () => context.pop(),
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
              // Weather Cloud Illustration
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFEBF5FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.cloudy_snowing,
                    color: Color(0xFF3B82F6),
                    size: 52,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Weather changed.',
                style: LocalLensTypography.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Don\'t worry — we\'ve adjusted your plan to keep your adventure seamless.',
                textAlign: TextAlign.center,
                style: LocalLensTypography.bodyMedium,
              ),

              const SizedBox(height: 32),

              // Original vs Adjusted Plan
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: LocalLensColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.beach_access_rounded, color: LocalLensColors.textMuted),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Beach Visit (Outdoor)',
                            style: TextStyle(decoration: TextDecoration.lineThrough, color: LocalLensColors.textMuted),
                          ),
                        ),
                        Text('Original', style: LocalLensTypography.caption),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.museum_rounded, color: LocalLensColors.primaryTeal),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Indoor Museum & Craft Hall',
                            style: LocalLensTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: LocalLensColors.successGreenSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'New Plan',
                            style: LocalLensTypography.caption.copyWith(
                              color: LocalLensColors.successGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              LocalLensPrimaryButton(
                text: 'View New Plan',
                isOrange: true,
                onPressed: () {
                  context.push(AppRoutes.aiItinerary);
                },
              ),
              const SizedBox(height: 12),
              LocalLensSecondaryButton(
                text: 'Keep Original',
                isOutlined: true,
                onPressed: () => context.pop(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
