import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../data/mock_data.dart';
import '../../widgets/common/locallens_components.dart';
import '../explore/explore_screen.dart';
import '../itinerary/my_itinerary_screen.dart';
import '../saved/saved_screen.dart';
import '../profile/profile_screen.dart';

/// Screen 10: Home Screen & Main Shell
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentTabIndex = 0;
  String _selectedCategory = 'Food';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LocalLensColors.background,
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildHomeTab(context),
          const ExploreScreen(),
          const MyItineraryScreen(),
          const SavedScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: LocalLensBottomNav(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: LocalLensDimensions.paddingScreen,
          vertical: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Greeting + Location + Notification & Avatar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Good morning, Traveler',
                          style: LocalLensTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('✨', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: LocalLensColors.primaryTeal,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Panvel, Maharashtra',
                          style: LocalLensTypography.caption.copyWith(
                            color: LocalLensColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: LocalLensColors.textPrimary,
                        size: 26,
                      ),
                      onPressed: () {
                        context.push(AppRoutes.notifications);
                      },
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentTabIndex = 4; // Go to Profile tab
                        });
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: LocalLensColors.primaryTeal, width: 1.5),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/54511.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Hero Discovery Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LocalLensColors.heroCardGradient,
                borderRadius: BorderRadius.circular(LocalLensDimensions.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: LocalLensColors.primaryTealDark.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your next local\nadventure is waiting',
                          style: LocalLensTypography.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentTabIndex = 1; // Go to Explore
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: LocalLensColors.accentOrange,
                              borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Explore Now',
                                  style: LocalLensTypography.badge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 10),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/54506.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Category Icons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: LocalLensMockData.categories.map((cat) {
                final isSelected = _selectedCategory == cat.name;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat.name),
                  child: Column(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: isSelected ? cat.color : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? cat.color : LocalLensColors.border,
                            width: 1.2,
                          ),
                          boxShadow: LocalLensDimensions.softCardShadow,
                        ),
                        child: Icon(
                          cat.icon,
                          color: isSelected ? Colors.white : cat.color,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat.name,
                        style: LocalLensTypography.caption.copyWith(
                          color: isSelected ? LocalLensColors.textPrimary : LocalLensColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Section: Picked for you
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Picked for you',
                  style: LocalLensTypography.titleLarge,
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentTabIndex = 1;
                    });
                  },
                  child: Text(
                    'See all',
                    style: LocalLensTypography.caption.copyWith(
                      color: LocalLensColors.primaryTeal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Horizontal Experience Cards
            SizedBox(
              height: 175,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: LocalLensMockData.featuredExperiences.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final exp = LocalLensMockData.featuredExperiences[index];
                  return GestureDetector(
                    onTap: () {
                      context.push(AppRoutes.experienceDetails);
                    },
                    child: Container(
                      width: 220,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                        boxShadow: LocalLensDimensions.softCardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail Image with Rating Pill
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
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                      const SizedBox(width: 2),
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
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exp.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: LocalLensTypography.titleMedium.copyWith(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.schedule_rounded, size: 12, color: LocalLensColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text('${exp.durationHours} hrs', style: LocalLensTypography.caption.copyWith(fontSize: 11)),
                                    const SizedBox(width: 8),
                                    Text('₹${exp.priceInr.toInt()}', style: LocalLensTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.bold, color: LocalLensColors.primaryTeal)),
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

            const SizedBox(height: 24),

            // Section: Your Trip
            Text('Your trip', style: LocalLensTypography.titleLarge),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentTabIndex = 2; // Go to Trips
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                  boxShadow: LocalLensDimensions.softCardShadow,
                  border: Border.all(color: LocalLensColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: LocalLensColors.primaryTealSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.route_rounded, color: LocalLensColors.primaryTeal, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Panvel Local Discovery',
                            style: LocalLensTypography.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '4 experiences • 6h 30m • ₹1,450',
                            style: LocalLensTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: LocalLensColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
