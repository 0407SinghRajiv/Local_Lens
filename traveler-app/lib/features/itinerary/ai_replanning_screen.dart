import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 17: AI Replanning Screen
class AIReplanningScreen extends StatelessWidget {
  const AIReplanningScreen({super.key});

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
            vertical: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your plan changed',
                style: LocalLensTypography.displayMedium,
              ),
              const SizedBox(height: 12),

              // Weather Alert Notice Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: LocalLensColors.warmAmberSoft,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                  border: Border.all(color: LocalLensColors.warmAmber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_queue_rounded, color: LocalLensColors.warmAmber, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Rain is expected in 30 minutes. We found a better indoor option for you.',
                        style: LocalLensTypography.bodyMedium.copyWith(
                          color: const Color(0xFF92400E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Original Experience Card
              Text('Original Experience', style: LocalLensTypography.titleMedium),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: LocalLensColors.errorRedSoft,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                  border: Border.all(color: LocalLensColors.errorRed.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/54506.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sunset Point (Outdoor)', style: LocalLensTypography.titleMedium.copyWith(fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('Outdoor Viewpoint • 2.5 hrs', style: LocalLensTypography.caption),
                        ],
                      ),
                    ),
                    const Icon(Icons.close_rounded, color: LocalLensColors.errorRed),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // AI Suggested Replacement Card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('AI Recommended Replacement', style: LocalLensTypography.titleMedium),
                  const MatchBadge(text: 'Indoor Safe'),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: LocalLensColors.successGreenSoft,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                  border: Border.all(color: LocalLensColors.successGreen.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/54511.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Indoor Art Workshop', style: LocalLensTypography.titleMedium.copyWith(fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('Sheltered • Cultural Tasting • ₹350', style: LocalLensTypography.caption),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle_rounded, color: LocalLensColors.successGreen),
                  ],
                ),
              ),

              const Spacer(),

              // Action Buttons
              LocalLensPrimaryButton(
                text: 'Update My Trip',
                isOrange: true,
                onPressed: () {
                  context.push(AppRoutes.liveTrip);
                },
              ),
              const SizedBox(height: 12),
              LocalLensSecondaryButton(
                text: 'Keep Original',
                isOutlined: true,
                onPressed: () {
                  context.pop();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
