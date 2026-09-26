import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';

/// Screen: Live Trip Mode & AI Assistant (Stitch UI)
class LiveTripModeScreen extends StatefulWidget {
  const LiveTripModeScreen({super.key});

  @override
  State<LiveTripModeScreen> createState() => _LiveTripModeScreenState();
}

class _LiveTripModeScreenState extends State<LiveTripModeScreen> {
  bool _isVisited = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LocalLensColors.background,
      body: Stack(
        children: [
          // Live Map Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/54511.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: Colors.black.withOpacity(0.15),
            ),
          ),

          // Top App Bar Controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: LocalLensColors.deepInk),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                      boxShadow: LocalLensDimensions.softCardShadow,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: LocalLensColors.coastalSage,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Live Trip Mode',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: LocalLensColors.deepInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: Icon(Icons.psychology_rounded, color: LocalLensColors.terracottaPrimary),
                      tooltip: 'AI Replanning',
                      onPressed: () {
                        context.push(AppRoutes.aiReplanning);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Card overlay with Action Grid and Up Next Stop
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: LocalLensDimensions.floatingShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: LocalLensColors.terracottaPrimary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'CURRENT STOP • 2/5',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: LocalLensColors.terracottaPrimary,
                              ),
                            ),
                          ),
                          Text(
                            'ETA 12:45 PM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: LocalLensColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Panna Meena ka Kund Stepwell',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: LocalLensColors.deepInk,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 14, color: LocalLensColors.coastalSage),
                          const SizedBox(width: 4),
                          Text(
                            'Amer, Jaipur • 1.2 km away',
                            style: TextStyle(
                              fontSize: 12,
                              color: LocalLensColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Action Pills Grid
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isVisited = !_isVisited),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isVisited
                                      ? LocalLensColors.coastalSage.withOpacity(0.15)
                                      : LocalLensColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      _isVisited ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                                      size: 20,
                                      color: LocalLensColors.coastalSage,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isVisited ? 'Visited' : 'Mark Visited',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: LocalLensColors.deepInk,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Memory note saved to trip timeline!')),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: LocalLensColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.photo_camera_rounded,
                                      size: 20,
                                      color: LocalLensColors.sandTertiary,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Add Memory',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: LocalLensColors.deepInk,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => context.push(AppRoutes.aiReplanning),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: LocalLensColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.psychology_rounded,
                                      size: 20,
                                      color: LocalLensColors.terracottaPrimary,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ask Docent',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: LocalLensColors.deepInk,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Start Navigation & Transit Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => context.push(AppRoutes.navigation),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: LocalLensColors.terracottaPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.navigation_rounded, size: 18),
                              label: const Text(
                                'Start Navigation',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: LocalLensColors.coastalSage.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.electric_rickshaw_rounded, color: LocalLensColors.coastalSage),
                              tooltip: 'Book Lens Ride',
                              onPressed: () => context.push(AppRoutes.lensRideBooking),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
