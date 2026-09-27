import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/locallens_design_system.dart';
import '../models/ride_model.dart';
import '../providers/ride_provider.dart';

/// Uber / Ola Style Persistent Active Ride Floating Bar (Div Card)
/// Appears smoothly at the bottom of screens when a ride is active.
class ActiveRideFloatingBar extends ConsumerStatefulWidget {
  final bool isStormy;
  final VoidCallback? onTap;

  const ActiveRideFloatingBar({
    super.key,
    this.isStormy = false,
    this.onTap,
  });

  @override
  ConsumerState<ActiveRideFloatingBar> createState() => _ActiveRideFloatingBarState();
}

class _ActiveRideFloatingBarState extends ConsumerState<ActiveRideFloatingBar> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideProvider);
    final status = rideState.status;

    // Do not show floating bar if idle, completed, or cancelled
    if (status == RideStatus.idle ||
        status == RideStatus.completed ||
        status == RideStatus.cancelled ||
        status == RideStatus.failed) {
      return const SizedBox.shrink();
    }

    final rider = rideState.activeRider ?? Rider.defaultMockRider;
    final vehicle = rideState.selectedVehicle;

    // Dynamic Title & Colors based on Ride Status
    String statusTitle;
    String statusSubtitle;
    Color themeColor;
    IconData statusIcon;

    switch (status) {
      case RideStatus.searching:
        statusTitle = 'Searching for nearby driver...';
        statusSubtitle = '${vehicle.name} • Est. ₹${vehicle.estimatedFare.toInt()}';
        themeColor = LocalLensColors.terracottaPrimary;
        statusIcon = Icons.radar_rounded;
        break;
      case RideStatus.accepted:
      case RideStatus.riderArriving:
        statusTitle = '${rider.name} is on the way';
        statusSubtitle = '${rider.vehicleNumber} • ${rideState.etaText} away';
        themeColor = LocalLensColors.coastalSage;
        statusIcon = Icons.directions_car_rounded;
        break;
      case RideStatus.arrived:
        statusTitle = 'Driver Arrived!';
        statusSubtitle = 'Share OTP 4729 to start ride';
        themeColor = LocalLensColors.successGreen;
        statusIcon = Icons.check_circle_rounded;
        break;
      case RideStatus.started:
      case RideStatus.inProgress:
        statusTitle = 'Ride in progress';
        statusSubtitle = 'Heading to ${rideState.dropLocation}';
        themeColor = LocalLensColors.coastalSage;
        statusIcon = Icons.navigation_rounded;
        break;
      default:
        statusTitle = 'Active Ride';
        statusSubtitle = rideState.dropLocation;
        themeColor = LocalLensColors.coastalSage;
        statusIcon = Icons.directions_car_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isStormy ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.18),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isStormy ? 0.4 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap ??
              () {
                if (status == RideStatus.searching) {
                  context.push(AppRoutes.travelerRideSearching);
                } else if (status == RideStatus.started || status == RideStatus.inProgress) {
                  context.push(AppRoutes.travelerRideLive);
                } else {
                  context.push(AppRoutes.driverAssigned);
                }
              },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Animated Pulsing Icon Badge
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: themeColor, width: 1.5),
                    ),
                    child: Icon(statusIcon, color: themeColor, size: 22),
                  ),
                ),
                const SizedBox(width: 12),

                // Ride Info Text Column
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              statusTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: widget.isStormy ? Colors.white : LocalLensColors.deepInk,
                              ),
                            ),
                          ),
                          if (status == RideStatus.arrived) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: LocalLensColors.successGreen,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'OTP 4729',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: widget.isStormy ? const Color(0xFF94A3B8) : LocalLensColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Quick Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status != RideStatus.searching && rider.phone.isNotEmpty)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.call_rounded, color: themeColor, size: 16),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: rider.phone));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Calling ${rider.name} (${rider.phone})...')),
                          );
                        },
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: widget.onTap ??
                          () {
                            if (status == RideStatus.searching) {
                              context.push(AppRoutes.travelerRideSearching);
                            } else if (status == RideStatus.started || status == RideStatus.inProgress) {
                              context.push(AppRoutes.travelerRideLive);
                            } else {
                              context.push(AppRoutes.driverAssigned);
                            }
                          },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Track',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(Icons.arrow_forward_ios_rounded, size: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
