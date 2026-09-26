import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../data/mock_data.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 6: Interest / Discovery Preferences Screen
class InterestSelectionScreen extends StatefulWidget {
  const InterestSelectionScreen({super.key});

  @override
  State<InterestSelectionScreen> createState() => _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends State<InterestSelectionScreen> {
  final Set<String> _selectedInterests = {'Food', 'Culture'};

  final Map<String, IconData> _interestIcons = {
    'Food': Icons.restaurant_rounded,
    'Culture': Icons.account_balance_rounded,
    'Adventure': Icons.explore_rounded,
    'Nature': Icons.park_rounded,
    'Heritage': Icons.fort_rounded,
    'Beach': Icons.beach_access_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Nightlife': Icons.nightlife_rounded,
    'Photography': Icons.camera_alt_rounded,
  };

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
                'What do you love\ndiscovering?',
                style: LocalLensTypography.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Select 2 or more interests to guide our AI recommendations.',
                style: LocalLensTypography.bodyMedium,
              ),
              const SizedBox(height: 20),

              // 3-Column Grid of Interests
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.95,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: LocalLensMockData.interestsList.length,
                  itemBuilder: (context, index) {
                    final interest = LocalLensMockData.interestsList[index];
                    final isSelected = _selectedInterests.contains(interest);
                    final icon = _interestIcons[interest] ?? Icons.place_rounded;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            if (_selectedInterests.length > 1) {
                              _selectedInterests.remove(interest);
                            }
                          } else {
                            _selectedInterests.add(interest);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? LocalLensColors.primaryTealSoft
                              : Colors.white,
                          borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                          border: Border.all(
                            color: isSelected
                                ? LocalLensColors.primaryTeal
                                : LocalLensColors.border,
                            width: isSelected ? 1.8 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: LocalLensColors.primaryTeal.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : LocalLensDimensions.softCardShadow,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? LocalLensColors.primaryTeal
                                    : LocalLensColors.surfaceSecondary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                icon,
                                color: isSelected ? Colors.white : LocalLensColors.primaryTeal,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              interest,
                              style: LocalLensTypography.bodyLarge.copyWith(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? LocalLensColors.primaryTeal : LocalLensColors.textPrimary,
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
                  context.push(AppRoutes.budget);
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
