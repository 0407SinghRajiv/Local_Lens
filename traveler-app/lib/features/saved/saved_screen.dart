import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../data/mock_data.dart';

/// Screen 14: Saved Details & Wishlist Screen
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  String _activeTab = 'All';

  final List<String> _tabs = ['All', 'Food', 'Culture', 'Adventure', 'Nature'];

  @override
  Widget build(BuildContext context) {
    final filtered = _activeTab == 'All'
        ? LocalLensMockData.featuredExperiences
        : LocalLensMockData.featuredExperiences
            .where((e) => e.category.toLowerCase() == _activeTab.toLowerCase())
            .toList();

    return Scaffold(
      backgroundColor: LocalLensColors.background,
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
                'Places you want to\nexperience',
                style: LocalLensTypography.displayMedium,
              ),
              const SizedBox(height: 14),

              // Filter Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _tabs.map((tab) {
                    final isSelected = _activeTab == tab;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = tab),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? LocalLensColors.primaryTeal : Colors.white,
                            borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                            border: Border.all(
                              color: isSelected ? LocalLensColors.primaryTeal : LocalLensColors.border,
                            ),
                          ),
                          child: Text(
                            tab,
                            style: TextStyle(
                              color: isSelected ? Colors.white : LocalLensColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // 2-Column Grid of Saved Experiences
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final exp = filtered[index];
                    return GestureDetector(
                      onTap: () {
                        context.push(AppRoutes.experienceDetails);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                          boxShadow: LocalLensDimensions.softCardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail with Heart icon
                            Stack(
                              children: [
                                Container(
                                  height: 105,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(LocalLensDimensions.radiusMedium),
                                    ),
                                    image: DecorationImage(
                                      image: AssetImage(exp.imageUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.favorite_rounded,
                                      color: LocalLensColors.accentOrange,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exp.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: LocalLensTypography.titleMedium.copyWith(fontSize: 13),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '₹${exp.priceInr.toInt()} • ${exp.durationHours} hrs • ${exp.rating} ★',
                                    style: LocalLensTypography.caption.copyWith(
                                      fontSize: 11,
                                      color: LocalLensColors.primaryTeal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
