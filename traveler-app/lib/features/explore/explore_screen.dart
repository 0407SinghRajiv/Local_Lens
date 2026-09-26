import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../data/mock_data.dart';

/// Screen 11: Explore Screen with Real-Time Search, Filters, and Interactive Cards
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final Set<String> _savedIds = {};

  final List<String> _quickFilters = ['All', 'Food', 'Culture', 'Adventure', 'Nature'];

  @override
  Widget build(BuildContext context) {
    // Filter experiences by search query and category
    final filteredExperiences = LocalLensMockData.featuredExperiences.where((exp) {
      final matchesSearch = _searchQuery.isEmpty ||
          exp.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          exp.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          exp.location.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedFilter == 'All' ||
          exp.category.toLowerCase() == _selectedFilter.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: LocalLensColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Interactive Search Bar & Filters
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
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'What do you want to experience?',
                        hintStyle: LocalLensTypography.bodyMedium,
                        prefixIcon: const Icon(Icons.search_rounded, color: LocalLensColors.primaryTeal),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: LocalLensColors.textMuted),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : IconButton(
                                icon: const Icon(Icons.tune_rounded, color: LocalLensColors.textMuted),
                                onPressed: _showFilterBottomSheet,
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
                              final isSelected = _selectedFilter == filter;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedFilter = filter;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: isSelected ? LocalLensColors.primaryTeal : Colors.white,
                                      borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                                      border: Border.all(
                                        color: isSelected ? LocalLensColors.primaryTeal : LocalLensColors.border,
                                      ),
                                      boxShadow: isSelected ? LocalLensDimensions.softCardShadow : null,
                                    ),
                                    child: Text(
                                      filter,
                                      style: LocalLensTypography.caption.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? Colors.white : LocalLensColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Map View Button
                      GestureDetector(
                        onTap: () {
                          context.push(AppRoutes.experienceMap);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: LocalLensColors.accentOrange,
                            borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                            boxShadow: [
                              BoxShadow(
                                color: LocalLensColors.accentOrange.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
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
              child: filteredExperiences.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: LocalLensColors.textMuted),
                          const SizedBox(height: 12),
                          Text('No experiences found for "$_searchQuery"', style: LocalLensTypography.titleMedium),
                          const SizedBox(height: 4),
                          Text('Try a different keyword or category', style: LocalLensTypography.caption),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: LocalLensDimensions.paddingScreen,
                        vertical: 14,
                      ),
                      itemCount: filteredExperiences.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final exp = filteredExperiences[index];
                        final isSaved = _savedIds.contains(exp.id);

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
                                // Image with Category & Rating Badges + Favorite Button
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(LocalLensDimensions.radiusMedium),
                                      ),
                                      child: SizedBox(
                                        height: 160,
                                        width: double.infinity,
                                        child: _buildExpImage(exp.imageUrl),
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.65),
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
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.65),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                                const SizedBox(width: 3),
                                                Text(
                                                  '${exp.rating}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          // Interactive Heart Button
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                if (isSaved) {
                                                  _savedIds.remove(exp.id);
                                                } else {
                                                  _savedIds.add(exp.id);
                                                }
                                              });
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(isSaved ? 'Removed from saved' : 'Saved to your wishlist!'),
                                                  duration: const Duration(seconds: 1),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.9),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                                color: isSaved ? LocalLensColors.accentOrange : LocalLensColors.textPrimary,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ],
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
                                          const Spacer(),
                                          Text(
                                            'View Details >',
                                            style: LocalLensTypography.caption.copyWith(
                                              color: LocalLensColors.primaryTeal,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter Experiences', style: LocalLensTypography.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: _quickFilters.map((f) {
                final isSelected = _selectedFilter == f;
                return ChoiceChip(
                  label: Text(f),
                  selected: isSelected,
                  selectedColor: LocalLensColors.primaryTeal,
                  onSelected: (_) {
                    setState(() => _selectedFilter = f);
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildExpImage(String imageUrl) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/images/destinations/sunset_coast.png',
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/images/destinations/sunset_coast.png',
        fit: BoxFit.cover,
      ),
    );
  }
}
