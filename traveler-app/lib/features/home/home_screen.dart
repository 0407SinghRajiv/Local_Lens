import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../data/mock_data.dart';
import '../../models/sponsored_experience.dart';
import '../../services/location_service.dart';
import '../../services/sponsor_service.dart';
import '../../widgets/common/locallens_components.dart';
import '../explore/explore_screen.dart';
import '../itinerary/my_itinerary_screen.dart';
import '../saved/saved_screen.dart';
import '../profile/profile_screen.dart';

/// Screen 10: Home Screen & Main Shell with Real Sponsored Experiences
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentTabIndex = 0;
  String _selectedCategory = 'Food';
  late Future<List<SponsoredExperience>> _sponsoredFuture;

  @override
  void initState() {
    super.initState();
    _refreshSponsored();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptLocationOnAppOpen();
    });
  }

  void _refreshSponsored() {
    setState(() {
      _sponsoredFuture = SponsorService.fetchActiveSponsoredExperiences();
    });
  }

  Future<void> _promptLocationOnAppOpen() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      await LocationService.requestLocationPermission(context);
    }
  }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _refreshSponsored(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                      GestureDetector(
                        onTap: () async {
                          final granted = await LocationService.requestLocationPermission(context);
                          if (context.mounted && granted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Location synced: Panvel, Maharashtra'),
                                backgroundColor: LocalLensColors.primaryTeal,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        },
                        child: Row(
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
                                color: LocalLensColors.primaryTeal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: LocalLensColors.primaryTeal,
                            ),
                          ],
                        ),
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
                              image: AssetImage('assets/images/characters/solo.png'),
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

              // Hero Discovery & Custom Itinerary Banner
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
                              context.push(AppRoutes.travelerCreateItinerary);
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
                                    'Plan with Local AI',
                                    style: LocalLensTypography.bodySmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Image.asset(
                      'assets/images/characters/brand_characters.png',
                      width: 90,
                      height: 90,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.explore, color: Colors.white, size: 64),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==============================================================
              // REAL DATABASE-DRIVEN SPONSORED EXPERIENCES SECTION
              // Supabase query: campaign_status = 'active' AND payment_status = 'paid'
              // AND start_at <= NOW() AND end_at > NOW()
              // ==============================================================
              FutureBuilder<List<SponsoredExperience>>(
                future: _sponsoredFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                        border: Border.all(color: LocalLensColors.border),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: LocalLensColors.primaryTeal),
                          ),
                          SizedBox(width: 10),
                          Text('Checking for active sponsored experiences...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  final campaigns = snapshot.data ?? [];
                  if (campaigns.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, size: 13, color: Color(0xFFD97706)),
                                SizedBox(width: 4),
                                Text(
                                  'FEATURED SPOTLIGHT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF92400E),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      ...campaigns.map((camp) => _buildSponsoredCard(context, camp, isDark)),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),

              // Categories Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('Food', '🍱'),
                    _buildCategoryChip('Heritage', '🏛️'),
                    _buildCategoryChip('Culture', '🎭'),
                    _buildCategoryChip('Nature', '🌿'),
                    _buildCategoryChip('Crafts', '🏺'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section: Top Experiences
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Trending near you', style: LocalLensTypography.titleLarge),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentTabIndex = 1; // Go to Explore
                      });
                    },
                    child: Text(
                      'See all',
                      style: LocalLensTypography.bodySmall.copyWith(
                        color: LocalLensColors.primaryTeal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 230,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: MockData.sampleExperiences.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final exp = MockData.sampleExperiences[index];
                    return GestureDetector(
                      onTap: () {
                        context.push(
                          AppRoutes.travelerExperienceDetails,
                          extra: exp,
                        );
                      },
                      child: Container(
                        width: 170,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                          boxShadow: LocalLensDimensions.softCardShadow,
                          border: Border.all(color: LocalLensColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(LocalLensDimensions.radiusMedium)),
                              child: Image.asset(
                                exp.imagePath,
                                height: 110,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  height: 110,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image, color: Colors.grey),
                                ),
                              ),
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
                                    style: LocalLensTypography.titleMedium.copyWith(fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, size: 14, color: LocalLensColors.ratingStar),
                                      const SizedBox(width: 2),
                                      Text(
                                        exp.rating.toString(),
                                        style: LocalLensTypography.caption.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(width: 4),
                                      Text('•', style: LocalLensTypography.caption),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          exp.location,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: LocalLensTypography.caption,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '₹${exp.priceInr.toInt()}',
                                    style: LocalLensTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w800,
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
      ),
    );
  }

  Widget _buildCategoryChip(String label, String emoji) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? LocalLensColors.primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
          border: Border.all(
            color: isSelected ? LocalLensColors.primaryTeal : LocalLensColors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: LocalLensColors.primaryTeal.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: LocalLensTypography.bodySmall.copyWith(
                color: isSelected ? Colors.white : LocalLensColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSponsoredCard(BuildContext context, SponsoredExperience camp, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFBBF24).withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.network(
                  camp.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.image_not_supported_rounded, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        camp.badge.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00875A),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    camp.offer,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  camp.listingName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Sponsored by: ',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    Text(
                      camp.shopName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00875A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      '${camp.rating} (${camp.reviewsCount})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFFEF4444)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        camp.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹${camp.offerPrice.toInt()}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF00875A),
                      ),
                    ),
                    const Text(
                      '/person',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '₹${camp.originalPrice.toInt()}/person',
                      style: const TextStyle(
                        fontSize: 13,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Viewing ${camp.listingName} details'), behavior: SnackBarBehavior.floating),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text('View Experience', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Booking ${camp.listingName} with ${camp.offer} applied!'),
                              backgroundColor: const Color(0xFF00875A),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00875A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Book Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
