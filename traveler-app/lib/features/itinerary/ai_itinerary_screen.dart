import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../models/itinerary_model.dart';
import '../../providers/itinerary_provider.dart';
import '../../widgets/common/locallens_components.dart';
import '../../widgets/itinerary_map.dart';

/// Screen 15: AI Itinerary Synthesis Screen
class AIItineraryScreen extends ConsumerStatefulWidget {
  const AIItineraryScreen({super.key});

  @override
  ConsumerState<AIItineraryScreen> createState() => _AIItineraryScreenState();
}

class _AIItineraryScreenState extends ConsumerState<AIItineraryScreen> {
  int? _selectedStopIndex;

  @override
  Widget build(BuildContext context) {
    final itineraryState = ref.watch(itineraryProvider);
    final itinerary = itineraryState.generatedItinerary;
    final items = itinerary?.items ?? <ItineraryItem>[];

    final totalHours = itinerary != null ? (itinerary.totalDurationMinutes / 60.0) : itineraryState.durationHours;
    final totalCost = itinerary?.totalEstimatedCost ?? itineraryState.totalBudgetInr;
    final itemCount = items.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: LocalLensColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: LocalLensColors.textPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Itinerary link copied to clipboard!'),
                  backgroundColor: LocalLensColors.primaryTeal,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LocalLensDimensions.paddingScreen,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your perfect day',
                style: LocalLensTypography.displayMedium,
              ),
              const SizedBox(height: 4),
              Text(
                itinerary?.destination.isNotEmpty == true
                    ? 'AI optimized itinerary for ${itinerary!.destination} based on your preferences & weather.'
                    : 'Built around your time, budget, weather and interests.',
                style: LocalLensTypography.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Metric Badges (Duration, Budget, Experience count)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMetricBadge(
                      Icons.schedule_rounded,
                      '${totalHours.toStringAsFixed(1)}h',
                    ),
                    const SizedBox(width: 8),
                    _buildMetricBadge(
                      Icons.currency_rupee_rounded,
                      '₹${totalCost.toInt()}',
                    ),
                    const SizedBox(width: 8),
                    _buildMetricBadge(
                      Icons.local_activity_rounded,
                      '$itemCount experiences',
                    ),
                    if (itineraryState.tripDate.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _buildMetricBadge(
                        Icons.calendar_today_rounded,
                        itineraryState.tripDate,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Interactive Route Map
              if (items.isNotEmpty)
                Container(
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                    boxShadow: LocalLensDimensions.softCardShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ItineraryMapWidget(
                    items: items,
                    startLocation: (itineraryState.latitude != null && itineraryState.longitude != null && itineraryState.latitude != 0.0 && itineraryState.longitude != 0.0)
                        ? LatLng(itineraryState.latitude!, itineraryState.longitude!)
                        : null,
                    startAddress: itineraryState.displayAddress.isNotEmpty
                        ? itineraryState.displayAddress
                        : (itineraryState.destination.isNotEmpty ? itineraryState.destination : 'Start'),
                    selectedIndex: _selectedStopIndex,
                    height: 200,
                    onExperienceSelected: (index) {
                      setState(() {
                        _selectedStopIndex = index;
                      });
                    },
                  ),
                ),

              // Timeline List of Stops
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.map_rounded, size: 48, color: LocalLensColors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'No stops generated yet.',
                              style: LocalLensTypography.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Swipe on recommendations to build your route.',
                              style: LocalLensTypography.bodyMedium.copyWith(color: LocalLensColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final stop = items[index];
                          final isSelected = _selectedStopIndex == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedStopIndex = index;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? LocalLensColors.primaryTealSoft : Colors.white,
                                borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                                border: Border.all(
                                  color: isSelected ? LocalLensColors.primaryTeal : LocalLensColors.border,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                                boxShadow: LocalLensDimensions.softCardShadow,
                              ),
                              child: Row(
                                children: [
                                  // Stop Number / Time Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected ? LocalLensColors.primaryTeal : LocalLensColors.primaryTealSoft,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '#${index + 1}',
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : LocalLensColors.primaryTeal,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11,
                                          ),
                                        ),
                                        if (stop.startTime.isNotEmpty)
                                          Text(
                                            stop.startTime,
                                            style: TextStyle(
                                              color: isSelected ? Colors.white70 : LocalLensColors.textSecondary,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Place Image Thumbnail
                                  if (stop.image.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        stop.image,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 50,
                                          height: 50,
                                          color: LocalLensColors.surfaceSecondary,
                                          child: const Icon(Icons.place_rounded, color: LocalLensColors.primaryTeal, size: 22),
                                        ),
                                      ),
                                    ),
                                  if (stop.image.isNotEmpty) const SizedBox(width: 10),

                                  // Place Name & Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          stop.experienceName,
                                          style: LocalLensTypography.titleMedium.copyWith(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${(stop.durationMinutes / 60.0).toStringAsFixed(1)} hrs • ₹${stop.price.toInt()} • ${stop.category}',
                                          style: LocalLensTypography.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: LocalLensColors.textMuted),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 8),

              // Start Trip Button
              LocalLensPrimaryButton(
                text: 'Start Trip',
                isOrange: false,
                icon: Icons.navigation_rounded,
                onPressed: () {
                  context.push(AppRoutes.liveTrip);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: LocalLensColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: LocalLensColors.primaryTeal),
          const SizedBox(width: 6),
          Text(
            text,
            style: LocalLensTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: LocalLensColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
