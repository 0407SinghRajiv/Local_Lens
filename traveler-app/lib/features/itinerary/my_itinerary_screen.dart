import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../data/mock_data.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen: My Itinerary & Live Tracker Details (Stitch UI)
class MyItineraryScreen extends StatelessWidget {
  const MyItineraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LocalLensColors.background,
      appBar: AppBar(
        backgroundColor: LocalLensColors.background,
        elevation: 0,
        title: Text(
          'My Itinerary',
          style: LocalLensTypography.headlineMedium.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: LocalLensColors.deepInk,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: LocalLensColors.coastalSage.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '3 of 6 completed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: LocalLensColors.coastalSage,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LocalLensDimensions.paddingScreen,
            vertical: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                                      ? LocalLensColors.coastalSage
                                      : (stop.isActive
                                          ? LocalLensColors.terracottaPrimary
                                          : Colors.white),
                                  border: Border.all(
                                    color: stop.isCompleted
                                        ? LocalLensColors.coastalSage
                                        : (stop.isActive
                                            ? LocalLensColors.terracottaPrimary
                                            : LocalLensColors.borderSubtle),
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
                                        ? LocalLensColors.coastalSage
                                        : LocalLensColors.borderSubtle,
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
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: stop.isActive
                                      ? LocalLensColors.terracottaPrimary.withOpacity(0.06)
                                      : (stop.isCompleted
                                          ? LocalLensColors.surfaceContainerLow
                                          : Colors.white),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: stop.isActive
                                        ? LocalLensColors.terracottaPrimary
                                        : LocalLensColors.borderSubtle,
                                    width: stop.isActive ? 1.8 : 1.0,
                                  ),
                                  boxShadow: LocalLensDimensions.softCardShadow,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            stop.title,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              decoration: stop.isCompleted
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              color: stop.isCompleted
                                                  ? LocalLensColors.textSecondary
                                                  : LocalLensColors.deepInk,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${stop.time} • ${stop.durationHours} hrs',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: LocalLensColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (stop.isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: LocalLensColors.terracottaPrimary,
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
                      foregroundColor: LocalLensColors.deepInk,
                      side: const BorderSide(color: LocalLensColors.borderSubtle),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.shuffle_rounded, size: 18),
                    label: const Text('Reorder'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LocalLensColors.deepInk,
                      side: const BorderSide(color: LocalLensColors.borderSubtle),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
