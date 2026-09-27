import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 2: Welcome Screen faithfully implementing Stitch welcome_onboarding layout
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.82);
  int _activePageIndex = 0;

  final List<Map<String, String>> _slides = [
    {
      'location': 'JAIPUR, INDIA',
      'tag': 'Day 2 Discovery',
      'title': 'Amber Fort Sunrise Walk',
      'image': 'assets/images/destinations/jaipur.png',
      'badgeColor': 'orange',
    },
    {
      'location': 'PANVEL, MAHARASHTRA',
      'tag': 'Local Curated',
      'title': 'Local Food & Heritage Trail',
      'image': 'assets/images/destinations/food_trail.png',
      'badgeColor': 'green',
    },
    {
      'location': 'ALIBAG, COASTAL',
      'tag': 'Scenic Route',
      'title': 'Kashid Sunset Beach Trail',
      'image': 'assets/images/destinations/hawa_mahal.png',
      'badgeColor': 'amber',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LocalLensColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Navigation & Identity Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const LocalLensLogo(size: 32, showTagline: false),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.home),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: LocalLensColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          'Skip',
                          style: LocalLensTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: LocalLensColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Hero Visual Stack Carousel
              SizedBox(
                height: 320,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) {
                    setState(() {
                      _activePageIndex = idx;
                    });
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppShadows.card,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: LocalLensNetworkImage(
                                imageUrl: slide['image'],
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.2),
                                      Colors.black.withValues(alpha: 0.8),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ),
                            // Location Badge
                            Positioned(
                              top: 14,
                              left: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: LocalLensColors.accentOrange,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      slide['location']!,
                                      style: LocalLensTypography.badge.copyWith(
                                        color: LocalLensColors.textPrimary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Title & Tag Footer
                            Positioned(
                              bottom: 16,
                              left: 16,
                              right: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    slide['tag']!.toUpperCase(),
                                    style: LocalLensTypography.badge.copyWith(
                                      color: LocalLensColors.primaryTealLight,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    slide['title']!,
                                    style: LocalLensTypography.titleMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
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

              const SizedBox(height: 12),

              // Page Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (idx) {
                  final isSelected = _activePageIndex == idx;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: isSelected ? 24 : 6,
                    decoration: BoxDecoration(
                      color: isSelected ? LocalLensColors.accentOrange : LocalLensColors.border,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Narrative Section Headline
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: LocalLensColors.accentOrangeSoft,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 14, color: LocalLensColors.accentOrange),
                          const SizedBox(width: 4),
                          Text(
                            'YOUR INTELLIGENT TRAVEL COMPANION',
                            style: LocalLensTypography.badge.copyWith(
                              color: LocalLensColors.accentOrange,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Travel like a cultured local, not a tourist.',
                      textAlign: TextAlign.center,
                      style: LocalLensTypography.displayLarge.copyWith(
                        fontSize: 26,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI curated day-by-day itineraries, swipe-to-discover hidden gems, and seamless local transit.',
                      textAlign: TextAlign.center,
                      style: LocalLensTypography.bodyMedium.copyWith(
                        color: LocalLensColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Micro-Highlights Feature Pills
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildPill('✨ Smart AI Itineraries'),
                  _buildPill('🗺️ Offline Maps'),
                  _buildPill('🛺 Instant Local Rides'),
                ],
              ),

              const SizedBox(height: 28),

              // Action Deck
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    LocalLensPrimaryButton(
                      text: 'Get Started with Google',
                      isOrange: true,
                      icon: Icons.g_mobiledata_rounded,
                      onPressed: () {
                        context.push(AppRoutes.googleLogin);
                      },
                    ),
                    const SizedBox(height: 12),
                    LocalLensSecondaryButton(
                      text: 'Continue with Email',
                      isOutlined: true,
                      icon: Icons.mail_outline_rounded,
                      onPressed: () {
                        context.push(AppRoutes.login);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Terms & Privacy Note
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'By continuing, you agree to LocalLens Terms & Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: LocalLensTypography.caption.copyWith(
                    color: LocalLensColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: LocalLensColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Text(
        text,
        style: LocalLensTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: LocalLensColors.textPrimary,
        ),
      ),
    );
  }
}

