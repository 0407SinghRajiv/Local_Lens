import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../data/mock_data.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 11: Explore Screen with Real-Time Search, Filters, and Interactive Cards (Stitch UI)
class ExploreScreen extends StatefulWidget {
  final bool isStormy;
  const ExploreScreen({super.key, this.isStormy = false});

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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      color: widget.isStormy ? const Color(0xFF0F172A) : LocalLensColors.background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      decoration: BoxDecoration(
                        color: widget.isStormy ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                        boxShadow: LocalLensDimensions.softCardShadow,
                        border: Border.all(
                          color: widget.isStormy ? const Color(0xFF334155) : LocalLensColors.borderSubtle,
                        ),
                      ),
                      child: TextField(
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: widget.isStormy ? Colors.white : LocalLensColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'What do you want to experience?',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.isStormy ? const Color(0xFF94A3B8) : LocalLensColors.textSecondary,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: widget.isStormy ? const Color(0xFF38BDF8) : LocalLensColors.terracottaPrimary,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: widget.isStormy ? const Color(0xFF38BDF8) : LocalLensColors.textMuted,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : IconButton(
                                  icon: Icon(
                                    Icons.tune_rounded,
                                    color: widget.isStormy ? const Color(0xFF38BDF8) : LocalLensColors.textMuted,
                                  ),
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
                                        color: widget.isStormy
                                            ? (isSelected ? const Color(0xFF38BDF8) : const Color(0xFF1E293B))
                                            : (isSelected ? LocalLensColors.deepInk : Colors.white),
                                        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                                        border: Border.all(
                                          color: widget.isStormy
                                              ? (isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155))
                                              : (isSelected ? LocalLensColors.deepInk : LocalLensColors.borderSubtle),
                                        ),
                                        boxShadow: isSelected ? LocalLensDimensions.softCardShadow : null,
                                      ),
                                      child: Text(
                                        filter,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                          fontSize: 12,
                                          color: widget.isStormy
                                              ? (isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1))
                                              : (isSelected ? Colors.white : LocalLensColors.textPrimary),
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
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: widget.isStormy ? const Color(0xFF0288D1) : LocalLensColors.terracottaPrimary,
                              borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                              boxShadow: [
                                BoxShadow(
                                  color: (widget.isStormy ? const Color(0xFF0288D1) : LocalLensColors.terracottaPrimary).withValues(alpha: 0.3),
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

              Divider(
                height: 1,
                color: widget.isStormy ? const Color(0xFF334155) : LocalLensColors.borderSubtle,
              ),

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
                            isStormy: widget.isStormy,
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
