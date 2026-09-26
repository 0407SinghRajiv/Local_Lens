import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../data/mock_data.dart';

/// Screen 11: Explore Screen with Filters and Experience List
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final List<String> _quickFilters = ['Time', 'Budget', 'Distance', 'Category'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LocalLensColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Search Bar & Toggle
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LocalLensDimensions.paddingScreen,
                vertical: 10,
              ),
              child: Column(
                children: [
                  // Search Box
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                      boxShadow: LocalLensDimensions.softCardShadow,
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'What do you want to experience?',
                        hintStyle: LocalLensTypography.bodyMedium,
                        prefixIcon: const Icon(Icons.search_rounded, color: LocalLensColors.primaryTeal),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.tune_rounded, color: LocalLensColors.textMuted),
                          onPressed: () {},
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Filter Row + Map/List Toggle
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _quickFilters.map((filter) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                                    border: Border.all(color: LocalLensColors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        filter,
                                        style: LocalLensTypography.caption.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: LocalLensColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: LocalLensColors.textMuted),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Map / List Toggle button
                      GestureDetector(
                        onTap: () {
                          context.push(AppRoutes.experienceMap);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: LocalLensColors.primaryTeal,
                            borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.map_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Map',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: LocalLensColors.border),

            // Experience Vertical Card List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: LocalLensDimensions.paddingScreen,
                  vertical: 14,
                ),
                itemCount: LocalLensMockData.featuredExperiences.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final exp = LocalLensMockData.featuredExperiences[index];
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
                          // Image with Rating & Category Badges
                          Stack(
                            children: [
                              Container(
                                height: 160,
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
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    exp.category,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${exp.rating} (${exp.reviewCount})',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        exp.title,
                                        style: LocalLensTypography.titleLarge.copyWith(fontSize: 18),
                                      ),
                                    ),
                                    Text(
                                      '₹${exp.priceInr.toInt()}',
                                      style: LocalLensTypography.titleLarge.copyWith(
                                        color: LocalLensColors.primaryTeal,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  exp.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: LocalLensTypography.bodyMedium,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule_rounded, size: 14, color: LocalLensColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text('${exp.durationHours} hrs', style: LocalLensTypography.caption),
                                    const SizedBox(width: 14),
                                    const Icon(Icons.place_outlined, size: 14, color: LocalLensColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text('${exp.distanceKm} km away', style: LocalLensTypography.caption),
                                  ],
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
    );
  }
}
