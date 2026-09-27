import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../models/itinerary_model.dart';
import '../../providers/itinerary_provider.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen: Trips Section (Home tab index 2 & /traveler/trips)
/// Shows all saved itineraries, live tracker timeline, and allows tapping any itinerary
/// to view its full details with expense tracking and live demo controls.
class MyItineraryScreen extends ConsumerStatefulWidget {
  final bool isStormy;
  const MyItineraryScreen({super.key, this.isStormy = false});

  @override
  ConsumerState<MyItineraryScreen> createState() => _MyItineraryScreenState();
}

class _MyItineraryScreenState extends ConsumerState<MyItineraryScreen> {
  int _viewMode = 0; // 0 = All Saved Trips, 1 = Active Trip Timeline

  @override
  Widget build(BuildContext context) {
    final itineraryState = ref.watch(itineraryProvider);
    final notifier = ref.read(itineraryProvider.notifier);

    // Collect all saved trips
    final savedTrips = List<Itinerary>.from(itineraryState.savedTrips);
    if (itineraryState.generatedItinerary != null &&
        !savedTrips.any((t) => t.id == itineraryState.generatedItinerary!.id)) {
      savedTrips.insert(0, itineraryState.generatedItinerary!);
    }

    final activeTrip = itineraryState.generatedItinerary ??
        (savedTrips.isNotEmpty ? savedTrips.first : null);

    final completedCount = activeTrip?.completedStopsCount ?? 0;
    final totalStops = activeTrip?.items.length ?? 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      color: widget.isStormy ? const Color(0xFF0F172A) : LocalLensColors.background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: widget.isStormy ? const Color(0xFF1E293B) : Colors.white,
          elevation: 0,
          title: Text(
            'My Trips & Itineraries',
            style: LocalLensTypography.headlineMedium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: widget.isStormy ? Colors.white : LocalLensColors.deepInk,
            ),
          ),
          actions: [
            if (activeTrip != null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.isStormy
                          ? const Color(0xFF0288D1).withValues(alpha: 0.25)
                          : LocalLensColors.coastalSage.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$completedCount of $totalStops done',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: widget.isStormy ? const Color(0xFF38BDF8) : LocalLensColors.coastalSage,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Segmented Switcher (All Saved Trips vs Active Timeline)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: widget.isStormy ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.isStormy ? const Color(0xFF334155) : LocalLensColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _viewMode = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _viewMode == 0
                                ? (widget.isStormy ? const Color(0xFF0288D1) : LocalLensColors.primaryTeal)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Saved Trips (${savedTrips.length})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _viewMode == 0
                                    ? Colors.white
                                    : (widget.isStormy ? Colors.white70 : LocalLensColors.textSecondary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _viewMode = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _viewMode == 1
                                ? (widget.isStormy ? const Color(0xFF0288D1) : LocalLensColors.primaryTeal)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Live Timeline',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _viewMode == 1
                                    ? Colors.white
                                    : (widget.isStormy ? Colors.white70 : LocalLensColors.textSecondary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Body
              Expanded(
                child: _viewMode == 0
                    ? _buildSavedTripsList(savedTrips, notifier)
                    : _buildLiveTimelineView(activeTrip, notifier),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. List of All Saved Trips
  Widget _buildSavedTripsList(List<Itinerary> trips, ItineraryNotifier notifier) {
    if (trips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.route_rounded,
                size: 64,
                color: widget.isStormy ? const Color(0xFF475569) : LocalLensColors.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                'No saved trips yet',
                style: LocalLensTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.isStormy ? Colors.white : LocalLensColors.deepInk,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create an itinerary and save it to access all your trips and track expenses here.',
                textAlign: TextAlign.center,
                style: LocalLensTypography.bodyMedium.copyWith(
                  color: widget.isStormy ? const Color(0xFF94A3B8) : LocalLensColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              LocalLensPrimaryButton(
                text: 'Plan a New Trip',
                isOrange: true,
                onPressed: () => context.push(AppRoutes.travelerCreateItinerary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: trips.length + 1,
      itemBuilder: (context, index) {
        if (index == trips.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.travelerCreateItinerary),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Plan Another Trip', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(
                  color: widget.isStormy ? const Color(0xFF334155) : LocalLensColors.primaryTeal,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          );
        }

        final trip = trips[index];
        final completed = trip.completedStopsCount;
        final total = trip.items.length;
        final actualSpent = trip.totalActualExpenses;
        final budget = trip.totalEstimatedCost;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 14),
          color: widget.isStormy ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: widget.isStormy ? const Color(0xFF334155) : LocalLensColors.border,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Set active itinerary and view full details with expense tracking
              notifier.setActiveItinerary(trip);
              context.push(AppRoutes.generatedItinerary);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          trip.destination,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: widget.isStormy ? Colors.white : LocalLensColors.deepInk,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: trip.isFullyCompleted
                              ? LocalLensColors.coastalSage.withValues(alpha: 0.15)
                              : LocalLensColors.accentOrangeSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          trip.isFullyCompleted ? 'COMPLETED' : 'IN PROGRESS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: trip.isFullyCompleted
                                ? LocalLensColors.coastalSage
                                : LocalLensColors.accentOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${trip.tripDate} • Starts at ${trip.startTime} • ${trip.formattedDuration}',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isStormy ? const Color(0xFF94A3B8) : LocalLensColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Metrics Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricItem(
                        icon: Icons.place_rounded,
                        label: 'Places',
                        val: '$total stops',
                        isStormy: widget.isStormy,
                      ),
                      _buildMetricItem(
                        icon: Icons.check_circle_rounded,
                        label: 'Progress',
                        val: '$completed of $total done',
                        isStormy: widget.isStormy,
                      ),
                      _buildMetricItem(
                        icon: Icons.currency_rupee_rounded,
                        label: 'Expenses',
                        val: '₹${actualSpent.toInt()} / ₹${budget.toInt()}',
                        isStormy: widget.isStormy,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: trip.completionRatio,
                      backgroundColor: widget.isStormy ? const Color(0xFF334155) : LocalLensColors.surfaceSecondary,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        trip.isFullyCompleted ? LocalLensColors.coastalSage : LocalLensColors.primaryTeal,
                      ),
                      minHeight: 6,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Action Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tap to view full itinerary & track expenses',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: widget.isStormy ? const Color(0xFF38BDF8) : LocalLensColors.primaryTeal,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: widget.isStormy ? const Color(0xFF38BDF8) : LocalLensColors.primaryTeal,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String val,
    required bool isStormy,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: isStormy ? const Color(0xFF38BDF8) : LocalLensColors.primaryTeal),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isStormy ? const Color(0xFF94A3B8) : LocalLensColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isStormy ? Colors.white : LocalLensColors.deepInk,
          ),
        ),
      ],
    );
  }

  /// 2. Live Timeline View for active trip
  Widget _buildLiveTimelineView(Itinerary? activeTrip, ItineraryNotifier notifier) {
    if (activeTrip == null || activeTrip.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timeline_rounded, size: 54, color: LocalLensColors.textMuted),
            const SizedBox(height: 12),
            Text('No active itinerary to track', style: LocalLensTypography.titleMedium),
            const SizedBox(height: 6),
            const Text('Generate or select an itinerary to see the live timeline here.'),
          ],
        ),
      );
    }

    final stops = activeTrip.items;

    return Column(
      children: [
        // Action Bar (View Full Details & Live Demo)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    notifier.setActiveItinerary(activeTrip);
                    context.push(AppRoutes.generatedItinerary);
                  },
                  icon: const Icon(Icons.fullscreen_rounded, size: 18),
                  label: const Text('View Full Itinerary', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LocalLensColors.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Timeline items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: stops.length,
            itemBuilder: (context, index) {
              final stop = stops[index];
              final isLast = index == stops.length - 1;
              final isCompleted = stop.isCompleted;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? (widget.isStormy ? const Color(0xFF0288D1) : LocalLensColors.coastalSage)
                                : (widget.isStormy ? const Color(0xFF1E293B) : Colors.white),
                            border: Border.all(
                              color: isCompleted
                                  ? (widget.isStormy ? const Color(0xFF0288D1) : LocalLensColors.coastalSage)
                                  : LocalLensColors.terracottaPrimary,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                : Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: LocalLensColors.terracottaPrimary,
                                    ),
                                  ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: isCompleted
                                  ? (widget.isStormy ? const Color(0xFF0288D1) : LocalLensColors.coastalSage)
                                  : LocalLensColors.borderSubtle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.isStormy ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCompleted
                                  ? LocalLensColors.coastalSage.withValues(alpha: 0.5)
                                  : LocalLensColors.border,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      stop.experienceName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                                        color: isCompleted
                                            ? (widget.isStormy ? const Color(0xFF64748B) : LocalLensColors.textSecondary)
                                            : (widget.isStormy ? Colors.white : LocalLensColors.deepInk),
                                      ),
                                    ),
                                  ),
                                  if (stop.travelerRating != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                        Text('${stop.travelerRating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${stop.startTime} - ${stop.endTime} • ${stop.category}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.isStormy ? const Color(0xFF94A3B8) : LocalLensColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Est: ₹${stop.price.toInt()} | Actual: ₹${stop.effectiveExpense.toInt()}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: LocalLensColors.primaryTeal,
                                    ),
                                  ),
                                  if (!isCompleted)
                                    TextButton(
                                      onPressed: () => notifier.completeExperience(stop.id),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('Mark Done', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
