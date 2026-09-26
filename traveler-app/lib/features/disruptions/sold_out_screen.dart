import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../data/mock_data.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 21: Sold Out Experience Notification & Alternatives Screen
class SoldOutScreen extends StatelessWidget {
  const SoldOutScreen({super.key});

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
            vertical: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Character Illustration
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusLarge),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/illustrations/sold_out_traveler.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text('Sold Out', style: LocalLensTypography.displayMedium),
              const SizedBox(height: 6),
              Text(
                'That experience is no longer available. We found similar curated experiences nearby.',
                textAlign: TextAlign.center,
                style: LocalLensTypography.bodyMedium,
              ),

              const SizedBox(height: 18),

              Align(
                alignment: Alignment.centerLeft,
                child: Text('Available Alternatives', style: LocalLensTypography.titleMedium),
              ),
              const SizedBox(height: 10),

              // Alternative Cards
              Expanded(
                child: ListView.separated(
                  itemCount: 2,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final exp = LocalLensMockData.featuredExperiences[index + 1];
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
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: AssetImage(exp.imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(exp.title, style: LocalLensTypography.titleMedium.copyWith(fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${exp.priceInr.toInt()} • ${exp.durationHours} hrs • ${exp.rating} ★',
                                  style: LocalLensTypography.caption.copyWith(color: LocalLensColors.primaryTeal),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              context.push(AppRoutes.experienceDetails);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LocalLensColors.primaryTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Select', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              LocalLensPrimaryButton(
                text: 'Back to Itinerary',
                isOrange: false,
                onPressed: () => context.pop(),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
