import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 31: Reusable UI Components Gallery & Design System Reference
class DesignSystemScreen extends StatelessWidget {
  const DesignSystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LocalLensColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Design System & UI Gallery', style: LocalLensTypography.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: LocalLensColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: LocalLensDimensions.paddingScreen,
            vertical: 16,
          ),
          children: [
            // Brand Style Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                boxShadow: LocalLensDimensions.softCardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LocalLensLogo(size: 44, showTagline: true),
                  const SizedBox(height: 16),
                  Text('Color Palette Tokens', style: LocalLensTypography.titleMedium),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildColorSwatch(LocalLensColors.primaryTeal, 'Teal'),
                      const SizedBox(width: 8),
                      _buildColorSwatch(LocalLensColors.accentOrange, 'Orange'),
                      const SizedBox(width: 8),
                      _buildColorSwatch(LocalLensColors.textPrimary, 'Navy'),
                      const SizedBox(width: 8),
                      _buildColorSwatch(LocalLensColors.successGreen, 'Green'),
                      const SizedBox(width: 8),
                      _buildColorSwatch(LocalLensColors.warmAmber, 'Amber'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Buttons Gallery
            Text('Action Buttons', style: LocalLensTypography.titleLarge),
            const SizedBox(height: 12),
            LocalLensPrimaryButton(
              text: 'Primary CTA (Orange)',
              isOrange: true,
              onPressed: () {},
            ),
            const SizedBox(height: 10),
            LocalLensPrimaryButton(
              text: 'Primary Action (Teal)',
              isOrange: false,
              onPressed: () {},
            ),
            const SizedBox(height: 10),
            LocalLensSecondaryButton(
              text: 'Secondary Outlined',
              isOutlined: true,
              onPressed: () {},
            ),

            const SizedBox(height: 24),

            // Chips & Badges
            Text('Chips & Badges', style: LocalLensTypography.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                const MatchBadge(text: '100% Match'),
                LocalLensCategoryChip(
                  name: 'Food',
                  icon: Icons.restaurant_rounded,
                  isSelected: true,
                  onTap: () {},
                ),
                LocalLensCategoryChip(
                  name: 'Culture',
                  icon: Icons.account_balance_rounded,
                  isSelected: false,
                  onTap: () {},
                ),
                LocalLensCategoryChip(
                  name: 'Adventure',
                  icon: Icons.explore_rounded,
                  isSelected: false,
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Experience Card Preview
            Text('Experience Card Component', style: LocalLensTypography.titleLarge),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                boxShadow: LocalLensDimensions.softCardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 140,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(LocalLensDimensions.radiusMedium)),
                      image: DecorationImage(
                        image: AssetImage('assets/images/54506.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sunset by the Coast', style: LocalLensTypography.titleMedium),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const Text(' 4.8 (2.3k) • 2.5 hrs • 12 km', style: TextStyle(fontSize: 12)),
                            const Spacer(),
                            Text('₹899', style: LocalLensTypography.titleMedium.copyWith(color: LocalLensColors.primaryTeal, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSwatch(Color color, String label) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: LocalLensDimensions.softCardShadow,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
