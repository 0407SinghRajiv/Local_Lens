import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../data/mock_data.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 15: AI Itinerary Synthesis Screen
class AIItineraryScreen extends StatelessWidget {
  const AIItineraryScreen({super.key});

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
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: LocalLensColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LocalLensDimensions.paddingScreen,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your perfect day',
                style: LocalLensTypography.displayMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Built around your time, budget and interests.',
                style: LocalLensTypography.bodyMedium,
              ),
              const SizedBox(height: 14),

              // Metric Badges (Duration, Budget, Experience count)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMetricBadge(Icons.schedule_rounded, '6h 30m'),
                    const SizedBox(width: 8),
                    _buildMetricBadge(Icons.currency_rupee_rounded, '₹1,450'),
                    const SizedBox(width: 8),
                    _buildMetricBadge(Icons.local_activity_rounded, '4 experiences'),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Timeline List of Stops
              Expanded(
                child: ListView.separated(
                  itemCount: 4,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final stop = LocalLensMockData.dayItineraryStops[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                        border: Border.all(color: LocalLensColors.border),
                        boxShadow: LocalLensDimensions.softCardShadow,
                      ),
                      child: Row(
                        children: [
                          // Time Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: LocalLensColors.primaryTealSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              stop.time,
                              style: const TextStyle(
                                color: LocalLensColors.primaryTeal,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stop.title,
                                  style: LocalLensTypography.titleMedium.copyWith(fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${stop.durationHours} hrs • ₹${stop.priceInr.toInt()}',
                                  style: LocalLensTypography.caption,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: LocalLensColors.textMuted),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Start Trip Button
              LocalLensPrimaryButton(
                text: 'Start Trip',
                isOrange: false,
                icon: Icons.navigation_rounded,
                onPressed: () {
                  context.push(AppRoutes.liveTrip);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: LocalLensColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: LocalLensColors.primaryTeal),
          const SizedBox(width: 6),
          Text(
            text,
            style: LocalLensTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: LocalLensColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
