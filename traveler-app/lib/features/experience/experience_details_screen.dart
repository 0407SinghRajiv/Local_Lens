import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 12: Experience Details Screen
class ExperienceDetailsScreen extends StatefulWidget {
  const ExperienceDetailsScreen({super.key});

  @override
  State<ExperienceDetailsScreen> createState() => _ExperienceDetailsScreenState();
}

class _ExperienceDetailsScreenState extends State<ExperienceDetailsScreen> {
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image with Back and Share Icons
                Stack(
                  children: [
                    Container(
                      height: 300,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/54506.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white.withValues(alpha: 0.9),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: LocalLensColors.textPrimary, size: 18),
                                onPressed: () => context.pop(),
                              ),
                            ),
                            CircleAvatar(
                              backgroundColor: Colors.white.withValues(alpha: 0.9),
                              child: IconButton(
                                icon: const Icon(Icons.share_outlined, color: LocalLensColors.textPrimary, size: 20),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Main Info Container
                Padding(
                  padding: const EdgeInsets.all(LocalLensDimensions.paddingScreen),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Badges
                      Text(
                        'Sunset by the Coast',
                        style: LocalLensTypography.displayMedium,
                      ),
                      const SizedBox(height: 8),

                      // Metrics Row: Rating, Duration, Distance
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text('4.8', style: LocalLensTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                          Text(' (2.3k)', style: LocalLensTypography.caption),
                          const SizedBox(width: 12),
                          const Icon(Icons.schedule_rounded, size: 16, color: LocalLensColors.textMuted),
                          const SizedBox(width: 4),
                          Text('2.5 hrs', style: LocalLensTypography.caption.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 12),
                          const Icon(Icons.place_outlined, size: 16, color: LocalLensColors.textMuted),
                          const SizedBox(width: 4),
                          Text('12 km', style: LocalLensTypography.caption.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Pricing
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹899',
                            style: LocalLensTypography.displayMedium.copyWith(
                              color: LocalLensColors.primaryTeal,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'per person',
                            style: LocalLensTypography.bodyMedium,
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // "Why LocalLens recommends it" AI Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: LocalLensColors.primaryTealSoft,
                          borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                          border: Border.all(
                            color: LocalLensColors.primaryTeal.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Why LocalLens recommends it',
                                  style: LocalLensTypography.titleMedium.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const MatchBadge(text: '100% Match'),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildMatchReason('Matches your interest in scenic views'),
                            _buildMatchReason('Fits your 3-hour afternoon window'),
                            _buildMatchReason('Within your set budget range'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Description
                      Text('About this experience', style: LocalLensTypography.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Enjoy a beautiful sunset with authentic local food, coastal views, and a rich cultural experience curated by experienced local hosts.',
                        style: LocalLensTypography.bodyMedium.copyWith(height: 1.5),
                      ),

                      const SizedBox(height: 18),

                      // Mini Map Preview card
                      GestureDetector(
                        onTap: () {
                          context.push(AppRoutes.experienceMap);
                        },
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                            border: Border.all(color: LocalLensColors.border),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/54511.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.map_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'View on Interactive Map',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Fixed Action Bar (Save + Add to Trip)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Save Button
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        border: Border.all(color: LocalLensColors.border),
                        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: _isSaved ? LocalLensColors.accentOrange : LocalLensColors.textPrimary,
                        ),
                        onPressed: () {
                          setState(() => _isSaved = !_isSaved);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isSaved ? 'Saved to your favorites!' : 'Removed from saved'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Add to Trip CTA (Orange)
                    Expanded(
                      child: LocalLensPrimaryButton(
                        text: 'Add to Trip',
                        isOrange: true,
                        onPressed: () {
                          context.push(AppRoutes.aiItinerary);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchReason(String reason) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: LocalLensColors.successGreen, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reason,
              style: LocalLensTypography.bodyMedium.copyWith(
                fontSize: 13,
                color: LocalLensColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
