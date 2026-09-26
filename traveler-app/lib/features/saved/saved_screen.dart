import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../data/mock_data.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen: Saved Places & Wishlist (Stitch UI)
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  String _activeTab = 'All';

  final List<String> _tabs = ['All', 'Jaipur', 'Udaipur', 'Custom Itineraries'];

  @override
  Widget build(BuildContext context) {
    final experiences = LocalLensMockData.featuredExperiences;
    final filtered = _activeTab == 'All' || _activeTab == 'Custom Itineraries'
        ? experiences
        : experiences
            .where((e) => e.location.toLowerCase().contains(_activeTab.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: LocalLensColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LocalLensDimensions.paddingScreen,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.bookmark_added_rounded,
                              color: LocalLensColors.terracottaPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'SAVED COLLECTION',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: LocalLensColors.terracottaPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: LocalLensColors.surfaceContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            color: LocalLensColors.deepInk,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'My Saved Places',
                      style: LocalLensTypography.displayMedium.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: LocalLensColors.deepInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${experiences.length} places & experiences saved across 3 trips',
                      style: TextStyle(
                        fontSize: 13,
                        color: LocalLensColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chips Carousel
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: LocalLensDimensions.paddingScreen),
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
                            color: isSelected
                                ? LocalLensColors.deepInk
                                : LocalLensColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                          ),
                          child: Text(
                            tab,
                            style: TextStyle(
                              color: isSelected ? Colors.white : LocalLensColors.textSecondary,
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

              // Featured AI Itinerary Bento Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: LocalLensDimensions.paddingScreen),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LocalLensColors.borderSubtle),
                    boxShadow: LocalLensDimensions.softCardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: LocalLensColors.coastalSage.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: LocalLensColors.coastalSage,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Curated AI Itinerary',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: LocalLensColors.coastalSage,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: LocalLensColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Ready to launch',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: LocalLensColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '3-Day Jaipur Heritage & Bazaars',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: LocalLensColors.deepInk,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stepwells, gemstone markets, royal astronomy & rooftop sunsets.',
                        style: TextStyle(
                          fontSize: 12,
                          color: LocalLensColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: LocalLensColors.terracottaPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.alt_route_rounded,
                              color: LocalLensColors.terracottaPrimary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '12 Curated Stops',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: LocalLensColors.deepInk,
                                  ),
                                ),
                                Text(
                                  'Optimized driving & walking route',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: LocalLensColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => context.push(AppRoutes.aiItinerary),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LocalLensColors.terracottaPrimary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            label: const Icon(Icons.arrow_forward_rounded, size: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Saved Places Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: LocalLensDimensions.paddingScreen),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saved Places',
                      style: LocalLensTypography.headlineMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: LocalLensColors.deepInk,
                      ),
                    ),
                    Text(
                      '${filtered.length} saved',
                      style: TextStyle(
                        fontSize: 12,
                        color: LocalLensColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Grid of Saved Items
              filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: EmptyStateWidget(
                        icon: Icons.bookmark_border_rounded,
                        title: 'No saved places found',
                        message: 'Explore experiences and tap the heart icon to save them to your wishlist.',
                        buttonText: 'Explore Places',
                        onButtonTap: () => context.push(AppRoutes.explore),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: LocalLensDimensions.paddingScreen),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.78,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final exp = filtered[index];
                          return _SavedItemCard(
                            title: exp.title,
                            location: exp.location,
                            price: '₹${exp.priceInr.toInt()}',
                            rating: exp.rating,
                            category: exp.category,
                            imageUrl: exp.imageUrl,
                            onTap: () => context.push(AppRoutes.experienceDetails),
                          );
                        },
                      ),
                    ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedItemCard extends StatelessWidget {
  final String title;
  final String location;
  final String price;
  final double rating;
  final String category;
  final String imageUrl;
  final VoidCallback onTap;

  const _SavedItemCard({
    required this.title,
    required this.location,
    required this.price,
    required this.rating,
    required this.category,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LocalLensColors.borderSubtle),
          boxShadow: LocalLensDimensions.softCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    color: LocalLensColors.surfaceContainerLow,
                    child: Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: LocalLensColors.terracottaPrimary.withOpacity(0.1),
                        child: Icon(Icons.landscape_rounded, color: LocalLensColors.terracottaPrimary, size: 36),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.favorite_rounded, color: LocalLensColors.terracottaPrimary, size: 16),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: LocalLensColors.deepInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: LocalLensColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: LocalLensColors.terracottaPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                          const SizedBox(width: 2),
                          Text(
                            rating.toString(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: LocalLensColors.deepInk,
                            ),
                          ),
                        ],
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
  }
}
