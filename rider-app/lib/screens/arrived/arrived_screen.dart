import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/mock_map_widget.dart';

class ArrivedScreen extends StatelessWidget {
  const ArrivedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final ride = state.activeRide;
        if (ride == null) {
          return const Scaffold(
            body: Center(child: Text('No active ride')),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Top bar
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.tertiary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: AppTheme.tertiary, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'ARRIVED AT PICKUP',
                              style: AppTheme.labelMedium.copyWith(
                                color: AppTheme.tertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                // Map
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: MockMapWidget(
                      driverLat: ride.pickupLat,
                      driverLng: ride.pickupLng,
                      pickupLat: ride.pickupLat,
                      pickupLng: ride.pickupLng,
                      destinationLat: ride.destinationLat,
                      destinationLng: ride.destinationLng,
                      showRoute: true,
                      height: double.infinity,
                    ),
                  ),
                ),

                // Bottom card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.tertiary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.tertiary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: AppTheme.tertiary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You have arrived at the pickup point. Waiting for passenger...',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.tertiary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Passenger info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor:
                                AppTheme.secondary.withValues(alpha: 0.1),
                            child: Text(
                              ride.passengerName.substring(0, 1),
                              style: AppTheme.headlineSmall.copyWith(
                                color: AppTheme.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ride.passengerName,
                                    style: AppTheme.titleLarge),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: AppTheme.tertiary,
                                        size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      ride.passengerRating
                                          .toStringAsFixed(1),
                                      style: AppTheme.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.phone,
                                  color: AppTheme.primary, size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.secondary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.message_rounded,
                                  color: AppTheme.secondary, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Route summary
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(ride.pickupAddress,
                                style: AppTheme.bodyMedium),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: SizedBox(
                          height: 20,
                          child: VerticalDivider(
                            color: AppTheme.outline.withValues(alpha: 0.5),
                            thickness: 2,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppTheme.error,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(ride.destinationAddress,
                                style: AppTheme.bodyMedium),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Start Ride button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            state.startRide();
                            Navigator.pushReplacementNamed(
                                context, '/active-ride');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondary,
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            'START RIDE',
                            style: AppTheme.labelLarge.copyWith(
                              color: Colors.white,
                              fontSize: 16,
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
        );
      },
    );
  }
}
