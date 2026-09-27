import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../models/itinerary_model.dart';
import '../../models/ride_model.dart';
import '../../providers/itinerary_provider.dart';
import '../../providers/ride_provider.dart';
import '../../services/itinerary_pdf_service.dart';
import '../../widgets/common/locallens_components.dart';
import '../../widgets/itinerary_map.dart';
import '../../widgets/itinerary_optimizer_chat_sheet.dart';

/// Screen 2 — Generated Itinerary & Lens Ride Integration
class GeneratedItineraryScreen extends ConsumerStatefulWidget {
  const GeneratedItineraryScreen({super.key});

  @override
  ConsumerState<GeneratedItineraryScreen> createState() => _GeneratedItineraryScreenState();
}

class _GeneratedItineraryScreenState extends ConsumerState<GeneratedItineraryScreen> {
  bool _isRideSectionEnabled = false;
  int _selectedVehicleIndex = 0;
  int? _selectedExperienceIndex;
  final GlobalKey<ItineraryMapWidgetState> _mapKey = GlobalKey<ItineraryMapWidgetState>();

  bool _isDownloadingPdf = false;
  bool _isSaving = false;
  bool _isSaved = false;

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
            onPressed: () => context.go(AppRoutes.travelerHome),
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
          onPressed: () => context.go(AppRoutes.travelerHome),
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
                tripDate: itinerary.tripDate,
                startTime: itinerary.startTime,
                formattedDuration: dynamicDuration,
                totalCost: dynamicCost,
                selectedCount: selectedCount,
                totalCount: totalCount,
              ),

              const SizedBox(height: 16),

              // BUDGET WARNING BANNER IF EXCEEDED
              if (itinerary.budgetExceeded || itinerary.budgetWarning != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: LocalLensColors.warmAmberSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: LocalLensColors.warmAmber, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: LocalLensColors.warmAmber, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          itinerary.budgetWarning ?? 'Your selected experiences exceed the available budget.',
                          style: LocalLensTypography.caption.copyWith(
                            color: LocalLensColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // SKIPPED EXPERIENCES CARD IF CONSTRAINTS EXCEEDED TIME
              if (itinerary.skippedExperiences.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: LocalLensColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: LocalLensColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: LocalLensColors.textSecondary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Skipped Experiences (${itinerary.skippedExperiences.length})',
                            style: LocalLensTypography.caption.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...itinerary.skippedExperiences.map((sk) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '• ${sk.name}: ${sk.reason}',
                              style: LocalLensTypography.caption.copyWith(
                                color: LocalLensColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

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

              // INTERACTIVE GOOGLE MAP ITINERARY VISUALIZATION
              ItineraryMapWidget(
                key: _mapKey,
                items: itinerary.items,
                startLocation: (itinerary.startLat != null && itinerary.startLon != null)
                    ? LatLng(itinerary.startLat!, itinerary.startLon!)
                    : null,
                startAddress: itinerary.displayAddress,
                height: 290,
                onExperienceSelected: (index) {
                  setState(() {
                    _selectedExperienceIndex = index;
                  });
                },
              ),

              const SizedBox(height: 18),

              // LIVE BUDGET & EXPENSES TRACKER WITH DEMO SIMULATOR BUTTON
              _buildBudgetAndSimulatorBanner(itinerary, itineraryNotifier),

              // NUGEN AI VALIDATION & ENHANCEMENT LAYER
              if (itinerary.nugen != null && itinerary.nugen!.enabled) ...[
                const SizedBox(height: 18),
                _buildNugenValidationCard(itinerary.nugen!),
              ],

              const SizedBox(height: 20),

              // TIMELINE HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Experience Timeline',
                    style: LocalLensTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Starts at ${itinerary.startTime}',
                    style: LocalLensTypography.caption.copyWith(
                      color: LocalLensColors.primaryTeal,
                      fontWeight: FontWeight.bold,
                    ),
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
              _buildBottomActions(context, itineraryNotifier, itinerary),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSummaryCard({
    required String destination,
    required String tripDate,
    required String startTime,
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
                    const Icon(Icons.schedule_rounded, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      startTime,
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
                icon: Icons.calendar_today_rounded,
                label: 'Trip Date',
                value: tripDate,
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
        final isHighlighted = _selectedExperienceIndex == index;

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
                        ? (item.isCompleted ? LocalLensColors.successGreen : (isHighlighted ? LocalLensColors.accentOrange : LocalLensColors.primaryTeal))
                        : LocalLensColors.surfaceSecondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isHighlighted ? LocalLensColors.accentOrange : (item.isSelected ? Colors.white : LocalLensColors.border),
                      width: isHighlighted ? 3 : 2,
                    ),
                    boxShadow: item.isSelected ? LocalLensDimensions.softCardShadow : [],
                  ),
                  child: Center(
                    child: item.isCompleted
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: item.isSelected ? Colors.white : LocalLensColors.textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
                if (!isLast) ...[
                  Container(
                    width: 2.5,
                    height: item.travelToNextMinutes > 0 ? 30 : 200,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: item.isSelected
                          ? (item.isCompleted ? const Color(0xFF86EFAC) : LocalLensColors.primaryTeal.withValues(alpha: 0.35))
                          : LocalLensColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  if (item.travelToNextMinutes > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: LocalLensColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: LocalLensColors.borderLight),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.directions_car_rounded, size: 12, color: LocalLensColors.textSecondary),
                          Text(
                            '${item.travelToNextMinutes}m',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: LocalLensColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 2.5,
                      height: 30,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: item.isSelected
                            ? LocalLensColors.primaryTeal.withValues(alpha: 0.35)
                            : LocalLensColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ],
              ],
            ),
            const SizedBox(width: 12),

            // Experience Card
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: item.isSelected ? 1.0 : 0.45,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                    onTap: () {
                      setState(() {
                        _selectedExperienceIndex = index;
                      });
                      _mapKey.currentState?.animateToExperienceIndex(index);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                        border: Border.all(
                          color: isHighlighted
                              ? LocalLensColors.primaryTeal
                              : (item.isSelected ? LocalLensColors.border : LocalLensColors.borderLight),
                          width: isHighlighted ? 2.0 : 1.0,
                        ),
                        boxShadow: isHighlighted
                            ? [
                                BoxShadow(
                                  color: LocalLensColors.primaryTeal.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : (item.isSelected ? LocalLensDimensions.softCardShadow : []),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Top Header: Time + Checkbox
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isHighlighted
                                  ? LocalLensColors.primaryTealSoft.withValues(alpha: 0.3)
                                  : (item.isSelected ? LocalLensColors.surfaceSecondary : Colors.grey.shade100),
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
                                // Thumbnail Image (Remote Supabase URL with fallback)
                                LocalLensNetworkImage(
                                  imageUrl: item.image,
                                  width: 72,
                                  height: 72,
                                  borderRadius: BorderRadius.circular(10),
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

                          // EXPENSE TRACKING & PROGRESS SECTION UNDER EACH EXPERIENCE
                          _buildExperienceExpenseSection(item, notifier),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExperienceExpenseSection(ItineraryItem item, ItineraryNotifier notifier) {
    final hasExpense = item.actualExpense != null && item.actualExpense! > 0;
    final isCompleted = item.isCompleted;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFF0FDF4) : LocalLensColors.surfaceSecondary.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCompleted ? const Color(0xFF86EFAC) : LocalLensColors.borderLight,
        ),
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
                    isCompleted ? Icons.check_circle_rounded : Icons.receipt_long_rounded,
                    size: 15,
                    color: isCompleted ? const Color(0xFF16A34A) : LocalLensColors.primaryTeal,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isCompleted ? 'Completed (Stayed 5m in 2km)' : 'Expense Tracking',
                    style: LocalLensTypography.caption.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isCompleted ? const Color(0xFF166534) : LocalLensColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (isCompleted)
                InkWell(
                  onTap: () => _showExperienceRatingDialog(item, notifier),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          '${(item.travelerRating ?? 5.0).toStringAsFixed(1)} ★',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Expense Input Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: LocalLensColors.border),
                  ),
                  child: TextFormField(
                    key: ValueKey('exp_${item.id}_${item.actualExpense}'),
                    initialValue: item.actualExpense != null ? item.actualExpense!.toInt().toString() : '',
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 10, right: 6, top: 9),
                        child: Text('₹', style: TextStyle(fontWeight: FontWeight.bold, color: LocalLensColors.primaryTeal)),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      hintText: 'Est. ₹${item.price.toInt()}',
                      hintStyle: const TextStyle(fontSize: 12, color: LocalLensColors.textMuted, fontWeight: FontWeight.normal),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      isDense: true,
                    ),
                    onFieldSubmitted: (val) {
                      final amount = double.tryParse(val.trim());
                      if (amount != null) {
                        notifier.updateExperienceExpense(item.id, amount);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Quick Set chip
              InkWell(
                onTap: () {
                  notifier.updateExperienceExpense(item.id, item.price);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                  decoration: BoxDecoration(
                    color: hasExpense ? LocalLensColors.primaryTealSoft : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: LocalLensColors.primaryTeal),
                  ),
                  child: Text(
                    'Set ₹${item.price.toInt()}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: LocalLensColors.primaryTeal),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Quick +50 chip
              InkWell(
                onTap: () {
                  final current = item.actualExpense ?? item.price;
                  notifier.updateExperienceExpense(item.id, current + 50);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: LocalLensColors.border),
                  ),
                  child: const Text(
                    '+₹50',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: LocalLensColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),

          if (hasExpense) ...[
            const SizedBox(height: 5),
            Text(
              'Tracked Expense: ₹${item.actualExpense!.toInt()} (Est. ₹${item.price.toInt()})',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: LocalLensColors.primaryTeal),
            ),
          ],

          if (isCompleted && item.travelerReview != null && item.travelerReview!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Review: "${item.travelerReview}"',
              style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Color(0xFF15803D)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBudgetAndSimulatorBanner(Itinerary itinerary, ItineraryNotifier notifier) {
    final totalBudget = itinerary.totalCost;
    final totalSpent = itinerary.totalActualExpenses;
    final remaining = (totalBudget - totalSpent).clamp(0.0, 999999.0);
    final completedCount = itinerary.completedStopsCount;
    final totalCount = itinerary.items.length;
    final progress = totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusLarge),
        border: Border.all(color: LocalLensColors.border),
        boxShadow: LocalLensDimensions.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: LocalLensColors.primaryTealSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, size: 18, color: LocalLensColors.primaryTeal),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Budget & Expenses Tracker',
                    style: LocalLensTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: completedCount == totalCount && totalCount > 0
                      ? const Color(0xFFDCFCE7)
                      : LocalLensColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$completedCount / $totalCount Completed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: completedCount == totalCount && totalCount > 0
                        ? const Color(0xFF16A34A)
                        : LocalLensColors.primaryTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 3-Metric Tiles Row: Budget, Spent, Remaining
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: LocalLensColors.surfaceSecondary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Est. Budget', style: LocalLensTypography.caption.copyWith(fontSize: 10)),
                      const SizedBox(height: 2),
                      Text(
                        '₹${totalBudget.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: LocalLensColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: totalSpent > totalBudget ? const Color(0xFFFEE2E2) : LocalLensColors.primaryTealSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Actual Spent', style: LocalLensTypography.caption.copyWith(fontSize: 10)),
                      const SizedBox(height: 2),
                      Text(
                        '₹${totalSpent.toInt()}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: totalSpent > totalBudget ? LocalLensColors.errorRed : LocalLensColors.primaryTeal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Remaining', style: LocalLensTypography.caption.copyWith(fontSize: 10)),
                      const SizedBox(height: 2),
                      Text(
                        '₹${remaining.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: LocalLensColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(LocalLensColors.primaryTeal),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),
          // Demo Simulation Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _simulateGeofenceArrivalAndCompletion(itinerary, notifier),
              icon: const Icon(Icons.bolt_rounded, size: 18, color: Colors.white),
              label: const Text(
                '⚡ Live Demo: Simulate Arrival (<2km for 5m)',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E), // Emerald Teal
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _simulateGeofenceArrivalAndCompletion(Itinerary itinerary, ItineraryNotifier notifier) async {
    // Find first uncompleted experience (or selected one)
    ItineraryItem? targetItem;
    if (_selectedExperienceIndex != null &&
        _selectedExperienceIndex! < itinerary.items.length &&
        !itinerary.items[_selectedExperienceIndex!].isCompleted) {
      targetItem = itinerary.items[_selectedExperienceIndex!];
    } else {
      targetItem = itinerary.items.cast<ItineraryItem?>().firstWhere(
            (item) => item != null && !item.isCompleted,
            orElse: () => null,
          );
    }

    if (targetItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 All experiences in this itinerary are already completed!'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Step 1: In-app arrival simulation notice
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '📍 Traveler entered within 2 km of "${targetItem.experienceName}". Tracking 5 min dwell time...',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: LocalLensColors.accentOrange,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Wait short simulated dwell delay
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // Step 2: Mark completed in state
    notifier.completeExperience(
      targetItem.id,
      expense: targetItem.actualExpense ?? targetItem.price,
    );

    // Step 3: Trigger in-app Push Notification banner & Rating Dialog
    _showInAppPushNotification(targetItem, notifier);
  }

  void _showInAppPushNotification(ItineraryItem item, ItineraryNotifier notifier) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _showExperienceRatingDialog(item, notifier);
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active_rounded, color: Colors.amber, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text(
                          'LocalLens • Push Notification',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                        Spacer(),
                        Text('Just now', style: TextStyle(fontSize: 9, color: Colors.white54)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Completed: ${item.experienceName}!',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                    const Text(
                      'Traveler stayed >5 min within 2 km. Tap to rate your experience ⭐',
                      style: TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        action: SnackBarAction(
          label: 'RATE NOW',
          textColor: Colors.amber,
          onPressed: () => _showExperienceRatingDialog(item, notifier),
        ),
      ),
    );

    // Directly open interactive Rating Dialog
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _showExperienceRatingDialog(item, notifier);
      }
    });
  }

  void _showExperienceRatingDialog(ItineraryItem item, ItineraryNotifier notifier) {
    double currentRating = item.travelerRating ?? 5.0;
    final reviewController = TextEditingController(text: item.travelerReview ?? '');
    final expenseController = TextEditingController(
      text: item.actualExpense != null ? item.actualExpense!.toInt().toString() : item.price.toInt().toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: LocalLensColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Experience Completed!',
                                style: LocalLensTypography.caption.copyWith(
                                  color: const Color(0xFF16A34A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                item.experienceName,
                                style: LocalLensTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: LocalLensColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.location_on_rounded, size: 14, color: LocalLensColors.primaryTeal),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Verified: Reached within 2 km & stayed for >5 mins',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: LocalLensColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Rate this experience',
                      style: LocalLensTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    // 5 Star rating row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (starIndex) {
                        final starValue = starIndex + 1.0;
                        final isFilled = starValue <= currentRating;
                        return IconButton(
                          iconSize: 36,
                          icon: Icon(
                            isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setModalState(() {
                              currentRating = starValue;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Actual Expense Incurred (₹)',
                      style: LocalLensTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: LocalLensColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: LocalLensColors.border),
                      ),
                      child: TextFormField(
                        controller: expenseController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.currency_rupee_rounded, size: 18, color: LocalLensColors.primaryTeal),
                          hintText: 'Enter expense',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Leave a brief review',
                      style: LocalLensTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: LocalLensColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: LocalLensColors.border),
                      ),
                      child: TextFormField(
                        controller: reviewController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'How was the food, crowd, or view?',
                          hintStyle: TextStyle(fontSize: 12, color: LocalLensColors.textMuted),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    LocalLensPrimaryButton(
                      text: 'Submit Rating & Save Expense',
                      isOrange: true,
                      icon: Icons.check_circle_rounded,
                      onPressed: () {
                        final expense = double.tryParse(expenseController.text.trim()) ?? item.price;
                        notifier.completeExperience(
                          item.id,
                          rating: currentRating,
                          review: reviewController.text.trim(),
                          expense: expense,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('Thank you! ${currentRating.toInt()}★ rating & ₹${expense.toInt()} expense logged for ${item.experienceName}'),
                                ),
                              ],
                            ),
                            backgroundColor: LocalLensColors.primaryTeal,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
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
                      setState(() => _isRideSectionEnabled = true);
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

  Future<void> _downloadPdf(Itinerary itinerary) async {
    setState(() => _isDownloadingPdf = true);
    try {
      await ItineraryPdfService.downloadOrPrintPdf(context, itinerary);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: LocalLensColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloadingPdf = false);
    }
  }

  void _openOptimizerChatbot(Itinerary itinerary) {
    ItineraryOptimizerChatSheet.show(context, itinerary);
  }

  Future<void> _saveItinerary(ItineraryNotifier notifier, Itinerary itinerary) async {
    setState(() => _isSaving = true);
    try {
      await notifier.saveCurrentItinerary();
      if (mounted) {
        setState(() => _isSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.bookmark_added_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Itinerary saved to database successfully!',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            backgroundColor: LocalLensColors.primaryTeal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save to database: $e'),
            backgroundColor: LocalLensColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _optForRide(Itinerary itinerary) {
    setState(() => _isRideSectionEnabled = true);
    final nextExp = itinerary.items.isNotEmpty ? itinerary.items.first.name : itinerary.destination;
    final selectedVehicle = _vehicles[_selectedVehicleIndex];
    ref.read(rideProvider.notifier).selectVehicle(selectedVehicle);
    ref.read(rideProvider.notifier).requestRide(
          pickup: itinerary.displayAddress.isNotEmpty ? itinerary.displayAddress : 'Current Location (Panvel)',
          drop: nextExp,
        );
    context.push(AppRoutes.rideSearching);
  }

  Widget _buildBottomActions(BuildContext context, ItineraryNotifier notifier, Itinerary itinerary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. DOWNLOAD AS PDF BUTTON
        OutlinedButton.icon(
          onPressed: _isDownloadingPdf ? null : () => _downloadPdf(itinerary),
          icon: _isDownloadingPdf
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: LocalLensColors.primaryTeal),
                )
              : const Icon(Icons.picture_as_pdf_rounded, size: 20, color: LocalLensColors.primaryTeal),
          label: Text(
            _isDownloadingPdf ? 'Generating PDF...' : 'Download as PDF',
            style: LocalLensTypography.bodyMedium.copyWith(
              color: LocalLensColors.primaryTeal,
              fontWeight: FontWeight.w800,
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            side: const BorderSide(color: LocalLensColors.primaryTeal, width: 1.6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: LocalLensColors.primaryTealSoft.withValues(alpha: 0.3),
          ),
        ),

        const SizedBox(height: 12),

        // 2. THREE BUTTONS ROW (Optimize Itinerary, Opt for Ride, Save Itinerary)
        Row(
          children: [
            // Optimize Itinerary Button (Opens AI Optimizer Chatbot)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openOptimizerChatbot(itinerary),
                icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: LocalLensColors.primaryTeal),
                label: Text(
                  'Optimize',
                  style: LocalLensTypography.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: LocalLensColors.textPrimary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: LocalLensColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Opt for Ride Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _optForRide(itinerary),
                icon: const Icon(Icons.local_taxi_rounded, size: 16, color: LocalLensColors.accentOrange),
                label: Text(
                  'Opt for Ride',
                  style: LocalLensTypography.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: LocalLensColors.accentOrange,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: LocalLensColors.accentOrange.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: LocalLensColors.accentOrangeSoft.withValues(alpha: 0.3),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Save Itinerary Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _saveItinerary(notifier, itinerary),
                icon: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        _isSaved ? Icons.bookmark_added_rounded : Icons.bookmark_add_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                label: Text(
                  _isSaved ? 'Saved' : 'Save',
                  style: LocalLensTypography.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: _isSaved ? const Color(0xFF0F766E) : LocalLensColors.primaryTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),

        // 3. START TRIP ACTION (Only visible when traveler opts for a ride)
        if (_isRideSectionEnabled || itinerary.hasRideAttached) ...[
          const SizedBox(height: 14),
          LocalLensPrimaryButton(
            text: 'Start Trip',
            isOrange: false,
            icon: Icons.directions_walk_rounded,
            onPressed: () {
              context.push(AppRoutes.liveTrip);
            },
          ),
          const SizedBox(height: 10),
        ] else ...[
          const SizedBox(height: 14),
        ],

        // 4. SECONDARY CONTROLS
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
                  minimumSize: const Size.fromHeight(46),
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
                icon: const Icon(Icons.refresh_rounded, size: 18, color: LocalLensColors.textSecondary),
                label: const Text('Regenerate', style: TextStyle(color: LocalLensColors.textSecondary, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: const BorderSide(color: LocalLensColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // NUGEN AI VALIDATION & ENHANCEMENT WIDGETS
  // ==========================================
  Widget _buildNugenValidationCard(NugenEnhancementData nugen) {
    final validation = nugen.validation;
    final issues = nugen.issues;
    final enhancements = nugen.enhancements;
    final tips = nugen.personalizedTips;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LocalLensColors.primaryTeal.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: LocalLensColors.primaryTeal.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: LocalLensColors.primaryTeal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: LocalLensColors.primaryTeal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Nugen AI Verification',
                          style: LocalLensTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: LocalLensColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: LocalLensColors.primaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Active',
                            style: LocalLensTypography.caption.copyWith(
                              color: LocalLensColors.primaryTeal,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Validation & smart suggestions for Rajiv\'s ML itinerary',
                      style: LocalLensTypography.caption.copyWith(
                        color: LocalLensColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: LocalLensColors.border),
          const SizedBox(height: 12),

          // Weather Forecast Context (if provided by Nugen)
          if (nugen.weather != null && nugen.weather!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wb_sunny_rounded, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nugen Weather Forecast: ${nugen.weather!['condition'] ?? 'Clear'} • ${nugen.weather!['temperature'] ?? '28°C'} • Wind ${nugen.weather!['wind_speed_kmh'] ?? '10 km/h'}',
                      style: LocalLensTypography.caption.copyWith(
                        color: LocalLensColors.textPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 1. Validation Grid/Rows
          Text(
            'Constraint & Plan Validation',
            style: LocalLensTypography.caption.copyWith(
              fontWeight: FontWeight.w800,
              color: LocalLensColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),

          _buildNugenValidationItemRow(
            'Budget',
            validation['budget'] as Map<String, dynamic>?,
            Icons.account_balance_wallet_outlined,
          ),
          _buildNugenValidationItemRow(
            'Time & Schedule',
            validation['available_time'] as Map<String, dynamic>? ?? validation['schedule'] as Map<String, dynamic>?,
            Icons.access_time_rounded,
          ),
          _buildNugenValidationItemRow(
            'Interests Matched',
            validation['interests'] as Map<String, dynamic>?,
            Icons.interests_outlined,
          ),
          _buildNugenValidationItemRow(
            'Group Fit',
            validation['group_type'] as Map<String, dynamic>?,
            Icons.groups_outlined,
          ),

          // 2. Issues flagged (if any)
          if (issues.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: LocalLensColors.accentOrange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: LocalLensColors.accentOrange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 16, color: LocalLensColors.accentOrange),
                      const SizedBox(width: 6),
                      Text(
                        'Schedule & Budget Observations (${issues.length})',
                        style: LocalLensTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: LocalLensColors.accentOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...issues.take(3).map((issue) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• ${issue['message'] ?? 'Notice flagged'}',
                          style: LocalLensTypography.caption.copyWith(
                            color: LocalLensColors.textPrimary,
                            fontSize: 11,
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ],

          // 3. Smart Enhancements
          if (enhancements.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Smart Suggestions',
              style: LocalLensTypography.caption.copyWith(
                fontWeight: FontWeight.w800,
                color: LocalLensColors.textPrimary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            ...enhancements.take(3).map((enh) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, size: 14, color: LocalLensColors.primaryTeal),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          enh['suggestion']?.toString() ?? enh['reason']?.toString() ?? '',
                          style: LocalLensTypography.caption.copyWith(
                            color: LocalLensColors.textPrimary,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          // 4. Personalized Tips
          if (tips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Personalized Tips',
              style: LocalLensTypography.caption.copyWith(
                fontWeight: FontWeight.w800,
                color: LocalLensColors.textPrimary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            ...tips.take(2).map((tip) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.star_outline_rounded, size: 14, color: LocalLensColors.accentOrange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          tip['tip']?.toString() ?? '',
                          style: LocalLensTypography.caption.copyWith(
                            color: LocalLensColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildNugenValidationItemRow(
    String title,
    Map<String, dynamic>? data,
    IconData icon,
  ) {
    final status = (data?['status'] as String? ?? 'pass').toLowerCase();
    final message = data?['message'] as String? ?? 'Verified';

    Color statusColor;
    IconData statusIcon;
    if (status == 'pass') {
      statusColor = LocalLensColors.primaryTeal;
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'warning') {
      statusColor = LocalLensColors.accentOrange;
      statusIcon = Icons.error_outline_rounded;
    } else if (status == 'fail') {
      statusColor = Colors.redAccent;
      statusIcon = Icons.cancel_outlined;
    } else {
      statusColor = LocalLensColors.textSecondary;
      statusIcon = Icons.help_outline_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: LocalLensColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            '$title: ',
            style: LocalLensTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: LocalLensColors.textPrimary,
              fontSize: 11.5,
            ),
          ),
          Expanded(
            child: Text(
              message,
              style: LocalLensTypography.caption.copyWith(
                color: LocalLensColors.textSecondary,
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Icon(statusIcon, size: 14, color: statusColor),
        ],
      ),
    );
  }
}
