import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../rides/ride_booking_bottom_sheet.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 12: Dynamic Experience & Place Details Screen
class ExperienceDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? experienceData;

  const ExperienceDetailsScreen({super.key, this.experienceData});

  @override
  ConsumerState<ExperienceDetailsScreen> createState() => _ExperienceDetailsScreenState();
}

class _ExperienceDetailsScreenState extends ConsumerState<ExperienceDetailsScreen> {
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.experienceData ?? {};

    final title = (data['title'] ?? data['listingName'] ?? 'Panvel Heritage Gem').toString();
    final imageUrl = (data['imageUrl'] ?? data['image'] ?? '').toString();
    final rating = (data['rating'] ?? '4.8').toString();
    final reviewsCount = (data['reviewsCount'] ?? data['reviews'] ?? '1.2k').toString();
    final price = (data['priceInr'] ?? data['offerPrice'] ?? data['price'] ?? '899').toString();
    final originalPrice = data['originalPrice']?.toString();
    final location = (data['location'] ?? 'Panvel, Maharashtra').toString();
    final distanceKm = (data['distanceKm'] ?? '2.5').toString();
    final durationHours = (data['durationHours'] ?? '3.0').toString();
    final category = (data['category'] ?? data['badge'] ?? 'Featured').toString();
    final shopName = (data['shopName'] ?? 'LocalLens Verified Host').toString();
    final description = (data['description'] ?? data['offer'] ??
        'Immerse yourself in an authentic local experience curated by expert hosts. Enjoy regional food, historic landmarks, and scenic spots with seamless transportation access.')
        .toString();

    final hasNetworkImage = imageUrl.isNotEmpty && (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

    return Scaffold(
      backgroundColor: LocalLensColors.background,
      body: AppBackgroundWrapper(
        child: Stack(
          children: [
            // Scrollable Content
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Supabase Image with Back & Share Icons
                  Stack(
                    children: [
                      Container(
                        height: 320,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E293B),
                        ),
                        child: hasNetworkImage
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/images/destinations/sunset_coast.png',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                'assets/images/destinations/sunset_coast.png',
                                fit: BoxFit.cover,
                              ),
                      ),
                      // Gradient Overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.5),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.6),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Top Nav Action Buttons
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white.withValues(alpha: 0.9),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: LocalLensColors.textPrimary, size: 18),
                                  onPressed: () => context.pop(),
                                ),
                              ),
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                                    child: IconButton(
                                      icon: Icon(
                                        _isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                        color: _isSaved ? LocalLensColors.terracottaPrimary : LocalLensColors.textPrimary,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() => _isSaved = !_isSaved);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(_isSaved ? 'Saved $title to favorites!' : 'Removed from saved'),
                                            behavior: SnackBarBehavior.floating,
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  CircleAvatar(
                                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                                    child: IconButton(
                                      icon: const Icon(Icons.share_outlined, color: LocalLensColors.textPrimary, size: 20),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Sharing $title link...'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom Hero Overlay Badges
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: LocalLensColors.terracottaPrimary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white30),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    shopName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Main Info Body
                  Padding(
                    padding: const EdgeInsets.all(LocalLensDimensions.paddingScreen),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          title,
                          style: LocalLensTypography.displayMedium.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Location Address
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 16, color: LocalLensColors.terracottaPrimary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: LocalLensTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: LocalLensColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Metrics Pill Row
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: LocalLensColors.border),
                            boxShadow: AppShadows.card,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                                  const SizedBox(width: 4),
                                  Text(rating, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                  Text(' ($reviewsCount)', style: const TextStyle(color: LocalLensColors.textMuted, fontSize: 11)),
                                ],
                              ),
                              Container(width: 1, height: 16, color: LocalLensColors.border),
                              Row(
                                children: [
                                  const Icon(Icons.near_me_rounded, color: LocalLensColors.coastalSage, size: 16),
                                  const SizedBox(width: 4),
                                  Text('$distanceKm km', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                ],
                              ),
                              Container(width: 1, height: 16, color: LocalLensColors.border),
                              Row(
                                children: [
                                  const Icon(Icons.schedule_rounded, color: LocalLensColors.sandTertiary, size: 16),
                                  const SizedBox(width: 4),
                                  Text('$durationHours hrs', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Pricing Box
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₹$price',
                              style: LocalLensTypography.displayMedium.copyWith(
                                color: LocalLensColors.terracottaPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 28,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '/ person',
                              style: LocalLensTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (originalPrice != null) ...[
                              const SizedBox(width: 10),
                              Text(
                                '₹$originalPrice',
                                style: const TextStyle(
                                  fontSize: 14,
                                  decoration: TextDecoration.lineThrough,
                                  color: LocalLensColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 18),

                        // AI Recommendation / Why LocalLens Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: LocalLensColors.softPeach,
                            borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                            border: Border.all(
                              color: LocalLensColors.terracottaPrimary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Why LocalLens recommends it',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: LocalLensColors.textPrimary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: LocalLensColors.terracottaPrimary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      '98% Match',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildMatchReason('Top-rated authentic local host in Panvel'),
                              _buildMatchReason('Fits your local exploration itinerary window'),
                              _buildMatchReason('Direct LensRide pickup & drop available'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // About Section
                        const Text('About this experience', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: LocalLensTypography.bodyMedium.copyWith(height: 1.5, color: LocalLensColors.textPrimary),
                        ),

                        const SizedBox(height: 20),

                        // Mini Interactive Map Preview
                        GestureDetector(
                          onTap: () {
                            context.push(AppRoutes.experienceMap);
                          },
                          child: Container(
                            height: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                              border: Border.all(color: LocalLensColors.border),
                              image: const DecorationImage(
                                image: AssetImage('assets/images/maps/experience_map.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                              ),
                              child: const Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.map_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'View on Live Weather Map',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Fixed Action Bar: Book Ride to Location
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Save / Favorite Button
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(color: LocalLensColors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: _isSaved ? LocalLensColors.terracottaPrimary : LocalLensColors.textPrimary,
                          ),
                          onPressed: () {
                            setState(() => _isSaved = !_isSaved);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_isSaved ? 'Saved to favorites!' : 'Removed from saved'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Direct Ride Booking CTA
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.directions_car_rounded, size: 20),
                          label: Text('Book LensRide (₹${(double.tryParse(distanceKm) ?? 2.5 * 1.0).round() * 10})'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LocalLensColors.terracottaPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            showRideBookingBottomSheet(
                              context: context,
                              ref: ref,
                              destinationTitle: title,
                              destinationLocation: location,
                              distanceKm: double.tryParse(distanceKm) ?? 2.5,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchReason(String reason) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: LocalLensColors.coastalSage, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reason,
              style: LocalLensTypography.bodyMedium.copyWith(
                fontSize: 12,
                color: LocalLensColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
