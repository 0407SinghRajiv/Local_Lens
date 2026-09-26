import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../data/mock_data.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 11: Explore Screen with Real-Time Search, Filters, and Interactive Cards (Stitch UI)
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
                        prefixIcon: const Icon(Icons.search_rounded, color: LocalLensColors.terracottaPrimary),
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
                                      color: isSelected ? LocalLensColors.deepInk : Colors.white,
                                      borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                                      border: Border.all(
                                        color: isSelected ? LocalLensColors.deepInk : LocalLensColors.borderSubtle,
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
                            color: LocalLensColors.terracottaPrimary,
                            borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                            boxShadow: [
                              BoxShadow(
                                color: LocalLensColors.terracottaPrimary.withOpacity(0.3),
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

            const Divider(height: 1, color: LocalLensColors.borderSubtle),

            // Experience Vertical Card List
            Expanded(
              child: filteredExperiences.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.search_off_rounded,
                      title: 'No experiences found',
                      message: 'We couldn\'t find any match for "$_searchQuery". Try a different category or search term.',
                      buttonText: 'Clear Filters',
                      onButtonTap: () {
                        setState(() {
                          _searchQuery = '';
                          _selectedFilter = 'All';
                        });
                      },
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

                        return ExperienceCard(
                          title: exp.title,
                          imageUrl: exp.imageUrl,
                          rating: exp.rating,
                          category: exp.category,
                          priceInr: exp.priceInr,
                          location: exp.location,
                          distanceKm: exp.distanceKm,
                          durationHours: exp.durationHours,
                          isSaved: isSaved,
                          onTap: () => context.push(AppRoutes.experienceDetails),
                          onSaveTap: () {
                            setState(() {
                              if (isSaved) {
                                _savedIds.remove(exp.id);
                              } else {
                                _savedIds.add(exp.id);
                              }
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isSaved ? 'Removed from wishlist' : 'Saved to wishlist!'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          width: double.infinity,
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
                  selectedColor: LocalLensColors.terracottaPrimary,
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
}
