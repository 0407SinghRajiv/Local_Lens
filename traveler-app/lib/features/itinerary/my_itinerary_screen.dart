import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../data/mock_data.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen: My Itinerary & Live Tracker Details (Stitch UI)
class MyItineraryScreen extends StatelessWidget {
  final bool isStormy;
  const MyItineraryScreen({super.key, this.isStormy = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      color: isStormy ? const Color(0xFF0F172A) : LocalLensColors.background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: isStormy ? const Color(0xFF1E293B) : LocalLensColors.background,
          elevation: 0,
          title: Text(
            'My Itinerary',
            style: LocalLensTypography.headlineMedium.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isStormy ? Colors.white : LocalLensColors.deepInk,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isStormy
                        ? const Color(0xFF0288D1).withValues(alpha: 0.25)
                        : LocalLensColors.coastalSage.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '3 of 6 completed',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isStormy ? const Color(0xFF38BDF8) : LocalLensColors.coastalSage,
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
                                        ? (isStormy ? const Color(0xFF0288D1) : LocalLensColors.coastalSage)
                                        : (stop.isActive
                                            ? (isStormy ? const Color(0xFF38BDF8) : LocalLensColors.terracottaPrimary)
                                            : (isStormy ? const Color(0xFF1E293B) : Colors.white)),
                                    border: Border.all(
                                      color: stop.isCompleted
                                          ? (isStormy ? const Color(0xFF0288D1) : LocalLensColors.coastalSage)
                                          : (stop.isActive
                                              ? (isStormy ? const Color(0xFF38BDF8) : LocalLensColors.terracottaPrimary)
                                              : (isStormy ? const Color(0xFF334155) : LocalLensColors.borderSubtle)),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: stop.isCompleted
                                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                        : (stop.isActive
                                            ? Icon(Icons.location_pin, color: isStormy ? const Color(0xFF0F172A) : Colors.white, size: 14)
                                            : null),
                                  ),
                                ),
                                if (!isLast)
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: stop.isCompleted
                                          ? (isStormy ? const Color(0xFF0288D1) : LocalLensColors.coastalSage)
                                          : (isStormy ? const Color(0xFF334155) : LocalLensColors.borderSubtle),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),

                            // Stop Content Card
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 350),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: stop.isActive
                                        ? (isStormy ? const Color(0xFF0288D1).withValues(alpha: 0.2) : LocalLensColors.terracottaPrimary.withValues(alpha: 0.06))
                                        : (stop.isCompleted
                                            ? (isStormy ? const Color(0xFF1E293B).withValues(alpha: 0.6) : LocalLensColors.surfaceContainerLow)
                                            : (isStormy ? const Color(0xFF1E293B) : Colors.white)),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: stop.isActive
                                          ? (isStormy ? const Color(0xFF38BDF8) : LocalLensColors.terracottaPrimary)
                                          : (isStormy ? const Color(0xFF334155) : LocalLensColors.borderSubtle),
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
                                                    ? (isStormy ? const Color(0xFF64748B) : LocalLensColors.textSecondary)
                                                    : (isStormy ? Colors.white : LocalLensColors.deepInk),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${stop.time} • ${stop.durationHours} hrs',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isStormy ? const Color(0xFF94A3B8) : LocalLensColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (stop.isActive)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isStormy ? const Color(0xFF0288D1) : LocalLensColors.terracottaPrimary,
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
                      icon: Icon(Icons.add_rounded, size: 18, color: isStormy ? Colors.white : LocalLensColors.deepInk),
                      label: Text('Add', style: TextStyle(color: isStormy ? Colors.white : LocalLensColors.deepInk)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isStormy ? Colors.white : LocalLensColors.deepInk,
                        side: BorderSide(color: isStormy ? const Color(0xFF334155) : LocalLensColors.borderSubtle),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.shuffle_rounded, size: 18, color: isStormy ? Colors.white : LocalLensColors.deepInk),
                      label: Text('Reorder', style: TextStyle(color: isStormy ? Colors.white : LocalLensColors.deepInk)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isStormy ? Colors.white : LocalLensColors.deepInk,
                        side: BorderSide(color: isStormy ? const Color(0xFF334155) : LocalLensColors.borderSubtle),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LocalLensPrimaryButton(
                        text: 'Navigate',
                        isOrange: !isStormy,
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
      ),
    );
  }
}
