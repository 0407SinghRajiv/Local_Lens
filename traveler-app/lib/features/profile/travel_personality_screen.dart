import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 29: Travel Personality / Style Showcase Screen
class TravelPersonalityScreen extends StatelessWidget {
  const TravelPersonalityScreen({super.key});

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
            vertical: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Your travel style', style: LocalLensTypography.caption.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('THE CURIOUS EXPLORER', style: LocalLensTypography.displayMedium.copyWith(color: LocalLensColors.primaryTeal)),
              const SizedBox(height: 16),

              // 3 Illustrated Cards Row
              Row(
                children: [
                  Expanded(child: _buildStyleCard('assets/images/characters/brand_characters.png', 'Offbeat Gems')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStyleCard('assets/images/destinations/food_trail.png', 'Local Food')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStyleCard('assets/images/destinations/sunset_coast.png', 'Culture Walks')),
                ],
              ),

              const SizedBox(height: 20),

              // Trait Pills
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTraitPill('Local Food'),
                  const SizedBox(width: 8),
                  _buildTraitPill('Hidden Gems'),
                  const SizedBox(width: 8),
                  _buildTraitPill('Culture'),
                ],
              ),

              const SizedBox(height: 18),

              Text(
                'You love discovering real places, authentic local food and unique stories over standard tourist traps.',
                textAlign: TextAlign.center,
                style: LocalLensTypography.bodyLarge.copyWith(height: 1.45),
              ),

              const Spacer(),

              LocalLensPrimaryButton(
                text: 'View More Insights',
                isOrange: false,
                onPressed: () => context.pop(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyleCard(String imagePath, String title) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.all(6),
        child: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTraitPill(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: LocalLensColors.primaryTealSoft,
        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
      ),
      child: Text(
        title,
        style: LocalLensTypography.caption.copyWith(
          color: LocalLensColors.primaryTeal,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
