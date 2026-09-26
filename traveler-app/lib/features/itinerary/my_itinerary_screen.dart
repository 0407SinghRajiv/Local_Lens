import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../data/mock_data.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 16: My Itinerary / Live Tracker Details Screen
class MyItineraryScreen extends StatelessWidget {
  const MyItineraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
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
                  Text(
                    'My Itinerary',
                    style: LocalLensTypography.displayMedium,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: LocalLensColors.successGreenSoft,
                      borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                    ),
                    child: Text(
                      '3 of 6 completed',
                      style: LocalLensTypography.badge.copyWith(
                        color: LocalLensColors.successGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Vertical Step Timeline
              Expanded(
                child: ListView.builder(
                  itemCount: LocalLensMockData.dayItineraryStops.length,
                  itemBuilder: (context, index) {
                    final stop = LocalLensMockData.dayItineraryStops[index];
                    final isLast = index == LocalLensMockData.dayItineraryStops.length - 1;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timeline Node & Connecting Line
                          Column(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: stop.isCompleted
                                      ? LocalLensColors.successGreen
                                      : (stop.isActive
                                          ? LocalLensColors.accentOrange
                                          : Colors.white),
                                  border: Border.all(
                                    color: stop.isCompleted
                                        ? LocalLensColors.successGreen
                                        : (stop.isActive
                                            ? LocalLensColors.accentOrange
                                            : LocalLensColors.border),
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: stop.isCompleted
                                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                      : (stop.isActive
                                          ? const Icon(Icons.location_pin, color: Colors.white, size: 14)
                                          : null),
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: stop.isCompleted
                                        ? LocalLensColors.successGreen
                                        : LocalLensColors.border,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),

                          // Stop Content Card
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: stop.isActive
                                      ? LocalLensColors.accentOrangeSoft
                                      : (stop.isCompleted
                                          ? LocalLensColors.surfaceSecondary
                                          : Colors.white),
                                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                                  border: Border.all(
                                    color: stop.isActive
                                        ? LocalLensColors.accentOrange
                                        : LocalLensColors.border,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            stop.title,
                                            style: LocalLensTypography.titleMedium.copyWith(
                                              fontSize: 14,
                                              decoration: stop.isCompleted
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              color: stop.isCompleted
                                                  ? LocalLensColors.textMuted
                                                  : LocalLensColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${stop.time} • ${stop.durationHours} hrs',
                                            style: LocalLensTypography.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (stop.isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: LocalLensColors.accentOrange,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Active',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
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

              // Bottom Action Bar: + Add, Reorder, Start Navigation
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LocalLensColors.textPrimary,
                      side: const BorderSide(color: LocalLensColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.shuffle_rounded, size: 18),
                    label: const Text('Reorder'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LocalLensColors.textPrimary,
                      side: const BorderSide(color: LocalLensColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LocalLensPrimaryButton(
                      text: 'Navigate',
                      isOrange: true,
                      height: 44,
                      onPressed: () {
                        context.push(AppRoutes.liveTrip);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
