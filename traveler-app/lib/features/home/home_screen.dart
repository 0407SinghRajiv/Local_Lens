import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../data/mock_data.dart';
import '../../models/sponsored_experience.dart';
import '../../services/location_service.dart';
import '../../services/sponsor_service.dart';
import '../explore/explore_screen.dart';
import '../itinerary/my_itinerary_screen.dart';
import '../saved/saved_screen.dart';
import '../profile/profile_screen.dart';

/// Screen: Home Screen & Main Shell matching reference UI design
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentTabIndex = 0;
  String _selectedCategory = 'Stays';
  bool _displayTotalPrice = true;
  late Future<List<SponsoredExperience>> _sponsoredFuture;
  final Set<String> _wishlistedIds = {};

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Stays', 'icon': Icons.apartment_rounded},
    {'label': 'Flights', 'icon': Icons.flight_takeoff_rounded},
    {'label': 'Rail', 'icon': Icons.train_rounded},
    {'label': 'Cruises', 'icon': Icons.directions_boat_rounded},
    {'label': 'Rides', 'icon': Icons.directions_car_rounded},
    {'label': 'Boats', 'icon': Icons.sailing_rounded},
  ];

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
      bottomNavigationBar: _buildCustomBottomNav(),
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    final experiences = LocalLensMockData.featuredExperiences;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async => _refreshSponsored(),
          color: LocalLensColors.coralPrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Curved Coral Header Card
                _buildHeaderSection(context),

                const SizedBox(height: 16),

                // 2. Black Pill Category Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: LocalLensDimensions.paddingScreen),
                  child: _buildCategoryBar(),
                ),

                const SizedBox(height: 16),

                // 3. "Display total price" Toggle Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: LocalLensDimensions.paddingScreen),
                  child: _buildTotalPriceToggleCard(),
                ),

                const SizedBox(height: 20),

                // 4. Sponsored Experiences Spotlight (If available)
                _buildSponsoredSection(),

                // 5. Featured Experience Listings Grid / Cards matching image layout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: LocalLensDimensions.paddingScreen),
                  child: Column(
                    children: experiences.map((exp) {
                      return _buildListingCard(exp);
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 100), // Bottom padding for floating map button & nav
              ],
            ),
          ),
        ),

        // 6. Floating "📍 Map" Capsule Button
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.experienceMap),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF181818),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.map_rounded, color: LocalLensColors.coralPrimary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Map',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 1. Top Curved Coral Header Card
  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: LocalLensColors.coralPrimary,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Avatar + Welcome Greeting
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _currentTabIndex = 4),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/characters/solo.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () async {
                          final granted = await LocationService.requestLocationPermission(context);
                          if (context.mounted && granted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Location synced: Panvel, Maharashtra'),
                                backgroundColor: LocalLensColors.deepInk,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        },
                        child: Row(
                          children: const [
                            Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
                            SizedBox(width: 4),
                            Text(
                              'Panvel, Maharashtra',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Action Buttons: Search & Notification
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                      onPressed: () => context.push(AppRoutes.explore),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                      onPressed: () => context.push(AppRoutes.notifications),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 2. Black Capsule Category Selection Bar
  Widget _buildCategoryBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat['label'];
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat['label'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  cat['icon'] as IconData,
                  color: isSelected ? const Color(0xFF181818) : Colors.white70,
                  size: 22,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 3. "Display total price" Toggle Card
  Widget _buildTotalPriceToggleCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LocalLensColors.borderSubtle),
        boxShadow: LocalLensDimensions.softCardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Display total price',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: LocalLensColors.deepInk,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Includes all fees, before taxes',
                style: TextStyle(
                  fontSize: 11,
                  color: LocalLensColors.textSecondary,
                ),
              ),
            ],
          ),
          Switch(
            value: _displayTotalPrice,
            activeColor: LocalLensColors.coralPrimary,
            onChanged: (val) => setState(() => _displayTotalPrice = val),
          ),
        ],
      ),
    );
  }

  /// 4. Listing Card matching reference UI image
  Widget _buildListingCard(dynamic exp) {
    final isWishlisted = _wishlistedIds.contains(exp.id);
    final displayPrice = _displayTotalPrice
        ? (exp.priceInr * 1.18).toInt() // Include total estimate
        : exp.priceInr.toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: LocalLensColors.borderSubtle),
        boxShadow: LocalLensDimensions.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image & Wishlist Heart Button
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Container(
                  height: 210,
                  width: double.infinity,
                  color: LocalLensColors.surfaceContainerLow,
                  child: Image.asset(
                    exp.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: LocalLensColors.coralSoft,
                      child: Icon(Icons.landscape_rounded, color: LocalLensColors.coralPrimary, size: 48),
                    ),
                  ),
                ),
              ),
              // Floating Heart Button
              Positioned(
                top: 14,
                right: 14,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isWishlisted) {
                        _wishlistedIds.remove(exp.id);
                      } else {
                        _wishlistedIds.add(exp.id);
                      }
                    });
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: LocalLensColors.coralPrimary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: LocalLensColors.deepInk),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  exp.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: LocalLensColors.deepInk,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${exp.location} • ${exp.durationHours} hrs • ${exp.category}',
                            style: TextStyle(
                              fontSize: 11,
                              color: LocalLensColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: '₹$displayPrice',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: LocalLensColors.deepInk,
                            ),
                            children: [
                              TextSpan(
                                text: _displayTotalPrice ? ' total' : ' /exp',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: LocalLensColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.star_rounded, color: LocalLensColors.coralPrimary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${exp.rating}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: LocalLensColors.deepInk,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${exp.reviewsCount} reviews)',
                      style: TextStyle(
                        fontSize: 11,
                        color: LocalLensColors.textSecondary,
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

  /// 5. Sponsored Section
  Widget _buildSponsoredSection() {
    return FutureBuilder<List<SponsoredExperience>>(
      future: _sponsoredFuture,
      builder: (context, snapshot) {
        final campaigns = snapshot.data ?? [];
        if (campaigns.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: LocalLensDimensions.paddingScreen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: campaigns.map((camp) {
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: LocalLensColors.coralPrimary.withOpacity(0.4)),
                  boxShadow: LocalLensDimensions.softCardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          child: Image.network(
                            camp.imageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 180,
                              color: LocalLensColors.surfaceContainerLow,
                              child: const Icon(Icons.image_not_supported_rounded, size: 40, color: Colors.grey),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: LocalLensColors.coralPrimary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              camp.badge.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            camp.listingName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: LocalLensColors.deepInk,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sponsored by ${camp.shopName}',
                            style: TextStyle(fontSize: 11, color: LocalLensColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// 6. Custom Curved Bottom Navigation Bar
  Widget _buildCustomBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.search_rounded, 'Explore'),
              _buildNavItem(1, Icons.favorite_border_rounded, ''),
              _buildNavItem(2, Icons.explore_outlined, ''),
              _buildNavItem(3, Icons.chat_bubble_outline_rounded, ''),
              _buildNavItem(4, Icons.person_outline_rounded, ''),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentTabIndex == index;

    if (isSelected && label.isNotEmpty) {
      return GestureDetector(
        onTap: () => setState(() => _currentTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: LocalLensColors.coralSoft,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: LocalLensColors.coralPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: LocalLensColors.deepInk,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = index),
      child: Container(
        padding: const EdgeInsets.all(10),
        color: Colors.transparent,
        child: Icon(
          icon,
          size: 22,
          color: LocalLensColors.textSecondary,
        ),
      ),
    );
  }
}
