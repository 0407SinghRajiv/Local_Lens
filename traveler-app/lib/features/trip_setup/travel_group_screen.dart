import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../data/mock_data.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 5: Travel Group Selection Screen
class TravelGroupScreen extends StatefulWidget {
  const TravelGroupScreen({super.key});

  @override
  State<TravelGroupScreen> createState() => _TravelGroupScreenState();
}

class _TravelGroupScreenState extends State<TravelGroupScreen> {
  String _selectedGroupId = 'couple';

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
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Who\'s coming along?',
                style: LocalLensTypography.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'We will customize the experience pacing and recommendations.',
                style: LocalLensTypography.bodyMedium,
              ),
              const SizedBox(height: 20),

              // 2-Column Grid of Group Options
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.15,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: LocalLensMockData.groupOptions.length,
                  itemBuilder: (context, index) {
                    final group = LocalLensMockData.groupOptions[index];
                    final isSelected = _selectedGroupId == group.id;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedGroupId = group.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? LocalLensColors.accentOrangeSoft
                              : Colors.white,
                          borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                          border: Border.all(
                            color: isSelected
                                ? LocalLensColors.accentOrange
                                : LocalLensColors.border,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: LocalLensColors.accentOrange.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : LocalLensDimensions.softCardShadow,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? LocalLensColors.accentOrange
                                    : LocalLensColors.surfaceSecondary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                group.icon,
                                color: isSelected ? Colors.white : LocalLensColors.primaryTeal,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              group.title,
                              style: LocalLensTypography.titleMedium.copyWith(
                                color: isSelected
                                    ? LocalLensColors.accentOrange
                                    : LocalLensColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              group.subtitle,
                              style: LocalLensTypography.caption.copyWith(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Next Button (Teal)
              LocalLensPrimaryButton(
                text: 'Next',
                isOrange: false,
                onPressed: () {
                  context.push(AppRoutes.interestSelection);
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
