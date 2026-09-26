import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 8: Travel History Import Screen
class TravelHistoryScreen extends StatelessWidget {
  const TravelHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: LocalLensColors.textPrimary, size: 20),
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
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Import Google\nTravel History',
                  style: LocalLensTypography.displayMedium,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Use places you\'ve visited to personalize future recommendations and avoid duplicate suggestions.',
                style: LocalLensTypography.bodyMedium,
              ),

              const Spacer(),

              // Google Connector Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: LocalLensColors.primaryTealSoft,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusLarge),
                  border: Border.all(color: LocalLensColors.primaryTeal.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: LocalLensDimensions.softCardShadow,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.timeline_rounded,
                          color: LocalLensColors.primaryTeal,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Google Maps Timeline',
                      style: LocalLensTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sync past visits to unlock AI taste matching',
                      textAlign: TextAlign.center,
                      style: LocalLensTypography.caption,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              LocalLensPrimaryButton(
                text: 'Connect & Import',
                isOrange: false,
                onPressed: () {
                  context.push(AppRoutes.aiPersonalization);
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  context.push(AppRoutes.aiPersonalization);
                },
                child: Text(
                  'Skip for now',
                  style: LocalLensTypography.button.copyWith(
                    color: LocalLensColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
