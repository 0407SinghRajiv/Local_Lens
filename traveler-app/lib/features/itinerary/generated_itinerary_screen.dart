import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../models/itinerary_model.dart';
import '../../models/ride_model.dart';
import '../../providers/itinerary_provider.dart';
import '../../providers/ride_provider.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 2 — Generated Itinerary & Lens Ride Integration
class GeneratedItineraryScreen extends ConsumerStatefulWidget {
  const GeneratedItineraryScreen({super.key});

  @override
  ConsumerState<GeneratedItineraryScreen> createState() => _GeneratedItineraryScreenState();
}

class _GeneratedItineraryScreenState extends ConsumerState<GeneratedItineraryScreen> {
  bool _isRideSectionEnabled = false;
  int _selectedVehicleIndex = 0;

  final List<VehicleOption> _vehicles = VehicleOption.defaultOptions;

  @override
  Widget build(BuildContext context) {
    final itineraryState = ref.watch(itineraryProvider);
    final itineraryNotifier = ref.read(itineraryProvider.notifier);
    final itinerary = itineraryState.generatedItinerary;

    if (itinerary == null) {
      return Scaffold(
        backgroundColor: LocalLensColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: LocalLensColors.textPrimary, size: 20),
            onPressed: () => context.go(AppRoutes.travelerCreateItinerary),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.route_rounded, size: 64, color: LocalLensColors.textMuted),
              const SizedBox(height: 16),
              Text('No active itinerary found', style: LocalLensTypography.titleLarge),
              const SizedBox(height: 8),
              LocalLensPrimaryButton(
                text: 'Create Itinerary',
                isOrange: true,
                onPressed: () => context.go(AppRoutes.travelerCreateItinerary),
              ),
            ],
          ),
        ),
      );
    }

    final selectedCount = itinerary.selectedItems.length;
    final totalCount = itinerary.items.length;
    final dynamicCost = itinerary.totalSelectedCost;
    final dynamicDuration = itinerary.formattedDuration;

    return Scaffold(
      backgroundColor: LocalLensColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: LocalLensColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Your Itinerary',
          style: LocalLensTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: LocalLensColors.primaryTeal),
            tooltip: 'Regenerate',
            onPressed: () async {
              context.push(AppRoutes.aiItineraryGenerating);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: LocalLensColors.textPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Itinerary link copied for ${itinerary.destination}!'),
                  backgroundColor: LocalLensColors.primaryTeal,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: LocalLensDimensions.paddingScreen,
            vertical: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Subtitle
              Text(
                'Your LocalLens itinerary',
                style: LocalLensTypography.displayMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Designed around your time, budget and interests.',
                style: LocalLensTypography.bodyMedium.copyWith(
                  color: LocalLensColors.textSecondary,
                ),
              ),

              const SizedBox(height: 16),

              // TOP SUMMARY HERO CARD
              _buildTopSummaryCard(
                destination: itinerary.destination,
                formattedDuration: dynamicDuration,
                totalCost: dynamicCost,
                selectedCount: selectedCount,
                totalCount: totalCount,
              ),

              const SizedBox(height: 20),

              // Interactive Selection Status Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: LocalLensColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 18, color: LocalLensColors.primaryTeal),
                        const SizedBox(width: 8),
                        Text(
                          'Selected: $selectedCount / $totalCount experiences',
                          style: LocalLensTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: LocalLensColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Total: ₹${dynamicCost.toInt()}',
                          style: LocalLensTypography.caption.copyWith(
                            fontWeight: FontWeight.w800,
                            color: LocalLensColors.primaryTeal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• $dynamicDuration',
                          style: LocalLensTypography.caption.copyWith(
                            color: LocalLensColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // TIMELINE HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Experience Timeline',
                    style: LocalLensTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Toggle to customize',
                    style: LocalLensTypography.caption.copyWith(color: LocalLensColors.textMuted),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // VERTICAL TIMELINE WITH CONNECTED ROUTE
              _buildVerticalTimeline(itinerary, itineraryNotifier),

              const SizedBox(height: 24),

              // LENS RIDE SECTION
              _buildLensRideSection(itinerary),

              const SizedBox(height: 24),

              // BOTTOM ACTION BUTTONS
              _buildBottomActions(context, itineraryNotifier),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSummaryCard({
    required String destination,
    required String formattedDuration,
    required double totalCost,
    required int selectedCount,
    required int totalCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.place_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    destination,
                    style: LocalLensTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded, color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      'Curated',
                      style: LocalLensTypography.badge.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryPill(
                icon: Icons.schedule_rounded,
                label: 'Available Time',
                value: formattedDuration,
              ),
              _buildSummaryPill(
                icon: Icons.currency_rupee_rounded,
                label: 'Estimated Cost',
                value: '₹${totalCost.toInt()}',
              ),
              _buildSummaryPill(
                icon: Icons.local_activity_rounded,
                label: 'Experiences',
                value: '$selectedCount Stops',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: LocalLensTypography.caption.copyWith(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: LocalLensTypography.titleSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalTimeline(Itinerary itinerary, ItineraryNotifier notifier) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itinerary.items.length,
      itemBuilder: (context, index) {
        final item = itinerary.items[index];
        final isLast = index == itinerary.items.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator Column
            Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: item.isSelected
                        ? (item.isCompleted ? LocalLensColors.successGreen : LocalLensColors.primaryTeal)
                        : LocalLensColors.surfaceSecondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.isSelected ? Colors.white : LocalLensColors.border,
                      width: 2,
                    ),
                    boxShadow: item.isSelected ? LocalLensDimensions.softCardShadow : [],
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: item.isSelected ? Colors.white : LocalLensColors.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2.5,
                    height: 125,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: item.isSelected
                          ? LocalLensColors.primaryTeal.withValues(alpha: 0.35)
                          : LocalLensColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Experience Card
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: item.isSelected ? 1.0 : 0.45,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                    border: Border.all(
                      color: item.isSelected ? LocalLensColors.border : LocalLensColors.borderLight,
                      width: 1.0,
                    ),
                    boxShadow: item.isSelected ? LocalLensDimensions.softCardShadow : [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card Top Header: Time + Checkbox
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: item.isSelected ? LocalLensColors.surfaceSecondary : Colors.grey.shade100,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(LocalLensDimensions.radiusMedium),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.schedule_rounded, size: 14, color: LocalLensColors.primaryTeal),
                                const SizedBox(width: 4),
                                Text(
                                  '${item.startTime} - ${item.endTime}',
                                  style: LocalLensTypography.caption.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: LocalLensColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: LocalLensColors.primaryTealSoft,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${item.durationMinutes} min',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: LocalLensColors.primaryTealDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Selection Checkbox
                            Transform.scale(
                              scale: 0.9,
                              child: Checkbox(
                                value: item.isSelected,
                                activeColor: LocalLensColors.primaryTeal,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) {
                                  notifier.toggleItemSelection(item.id);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Card Content Body
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                item.image,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 72,
                                  height: 72,
                                  color: LocalLensColors.primaryTealSoft,
                                  child: const Icon(Icons.image_rounded, color: LocalLensColors.primaryTeal),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: LocalLensColors.accentOrangeSoft,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.category.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: LocalLensColors.accentOrange,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${item.rating}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.experienceName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: LocalLensTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.place_outlined, size: 12, color: LocalLensColors.textMuted),
                                      const SizedBox(width: 2),
                                      Expanded(
                                        child: Text(
                                          '${item.location} • ${item.distanceKm} km',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: LocalLensTypography.caption.copyWith(fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${item.price.toInt()}',
                                    style: LocalLensTypography.titleSmall.copyWith(
                                      color: LocalLensColors.primaryTeal,
                                      fontWeight: FontWeight.w800,
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
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLensRideSection(Itinerary itinerary) {
    final selectedVehicle = _vehicles[_selectedVehicleIndex];
    final nextExperience = itinerary.selectedItems.isNotEmpty
        ? itinerary.selectedItems.first.experienceName
        : itinerary.destination;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusLarge),
        border: Border.all(
          color: _isRideSectionEnabled ? LocalLensColors.primaryTeal : LocalLensColors.border,
          width: _isRideSectionEnabled ? 1.5 : 1.0,
        ),
        boxShadow: LocalLensDimensions.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Toggle
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: LocalLensColors.primaryTealSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_taxi_rounded, color: LocalLensColors.primaryTeal, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need a ride?',
                      style: LocalLensTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Get to your next experience without the hassle.',
                      style: LocalLensTypography.caption,
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isRideSectionEnabled,
                activeTrackColor: LocalLensColors.primaryTeal,
                onChanged: (val) {
                  setState(() => _isRideSectionEnabled = val);
                },
              ),
            ],
          ),

          if (_isRideSectionEnabled) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            Text(
              'Select Lens Ride Vehicle',
              style: LocalLensTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Vehicle Options List
            Column(
              children: List.generate(_vehicles.length, (index) {
                final vehicle = _vehicles[index];
                final isSelected = _selectedVehicleIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedVehicleIndex = index);
                    ref.read(rideProvider.notifier).selectVehicle(vehicle);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? LocalLensColors.primaryTealSoft : LocalLensColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? LocalLensColors.primaryTeal : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isSelected ? LocalLensColors.primaryTeal : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            vehicle.icon,
                            color: isSelected ? Colors.white : LocalLensColors.primaryTeal,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    vehicle.name,
                                    style: LocalLensTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '• ${vehicle.etaMinutes} min away',
                                    style: LocalLensTypography.caption.copyWith(
                                      color: LocalLensColors.primaryTeal,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                vehicle.capacity,
                                style: LocalLensTypography.caption.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${vehicle.estimatedFare.toInt()}',
                          style: LocalLensTypography.titleMedium.copyWith(
                            color: isSelected ? LocalLensColors.primaryTeal : LocalLensColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 12),

            // Confirm Lens Ride Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LocalLensColors.accentOrangeSoft.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: LocalLensColors.accentOrange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.navigation_rounded, color: LocalLensColors.accentOrange, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Confirm Lens Ride',
                        style: LocalLensTypography.titleSmall.copyWith(
                          color: LocalLensColors.accentOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pickup:', style: LocalLensTypography.caption),
                      Text('Current location', style: LocalLensTypography.caption.copyWith(fontWeight: FontWeight.bold, color: LocalLensColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Drop-off:', style: LocalLensTypography.caption),
                      Expanded(
                        child: Text(
                          nextExperience,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: LocalLensTypography.caption.copyWith(fontWeight: FontWeight.bold, color: LocalLensColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Vehicle:', style: LocalLensTypography.caption),
                      Text('${selectedVehicle.name} (₹${selectedVehicle.estimatedFare.toInt()})', style: LocalLensTypography.caption.copyWith(fontWeight: FontWeight.bold, color: LocalLensColors.primaryTeal)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LocalLensPrimaryButton(
                    text: 'Request Ride (₹${selectedVehicle.estimatedFare.toInt()})',
                    isOrange: true,
                    icon: Icons.local_taxi_rounded,
                    onPressed: () {
                      ref.read(rideProvider.notifier).selectVehicle(selectedVehicle);
                      ref.read(rideProvider.notifier).requestRide(
                            pickup: 'Current Location (Panvel)',
                            drop: nextExperience,
                          );
                      context.push(AppRoutes.rideSearching);
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, ItineraryNotifier notifier) {
    return Column(
      children: [
        LocalLensPrimaryButton(
          text: 'Start Trip',
          isOrange: false,
          icon: Icons.directions_walk_rounded,
          onPressed: () {
            context.push(AppRoutes.liveTrip);
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  context.push(AppRoutes.travelerCreateItinerary);
                },
                icon: const Icon(Icons.edit_note_rounded, size: 18, color: LocalLensColors.textPrimary),
                label: const Text('Edit Itinerary', style: TextStyle(color: LocalLensColors.textPrimary, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: LocalLensColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  context.push(AppRoutes.aiItineraryGenerating);
                },
                icon: const Icon(Icons.auto_awesome_rounded, size: 18, color: LocalLensColors.primaryTeal),
                label: const Text('Regenerate', style: TextStyle(color: LocalLensColors.primaryTeal, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: LocalLensColors.primaryTeal),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
