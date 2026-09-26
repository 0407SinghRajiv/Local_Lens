import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../models/ride_model.dart';
import '../../providers/ride_provider.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen: Live Ride Tracking & Status Simulation Screen
class LiveRideScreen extends ConsumerStatefulWidget {
  const LiveRideScreen({super.key});

  @override
  ConsumerState<LiveRideScreen> createState() => _LiveRideScreenState();
}

class _LiveRideScreenState extends ConsumerState<LiveRideScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _carAnimationController;
  Timer? _simulationTimer;
  int _simulationSeconds = 0;

  @override
  void initState() {
    super.initState();

    _carAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..forward();

    // Start ride progression simulation
    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _simulationSeconds++;
      });

      final notifier = ref.read(rideProvider.notifier);
      final currentStatus = ref.read(rideProvider).status;

      // 4 seconds: Driver arrives at pickup
      if (_simulationSeconds == 4 && currentStatus == RideStatus.riderArriving) {
        notifier.markDriverArrived();
      }

      // Update progress value based on animation
      notifier.setRouteProgress(_carAnimationController.value);
    });
  }

  @override
  void dispose() {
    _carAnimationController.dispose();
    _simulationTimer?.cancel();
    super.dispose();
  }

  void _onStartRidePressed() {
    ref.read(rideProvider.notifier).startTrip();
    _carAnimationController.reset();
    _carAnimationController.duration = const Duration(seconds: 8);
    _carAnimationController.forward().then((_) {
      if (mounted) {
        ref.read(rideProvider.notifier).completeTrip();
        context.pushReplacement(AppRoutes.travelerRideCompleted);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideProvider);
    final rider = rideState.activeRider ?? Rider.defaultMockRider;
    final vehicle = rideState.selectedVehicle;
    final status = rideState.status;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Canvas Background with animated Route
          Positioned.fill(
            child: Container(
              color: const Color(0xFFE8ECEF),
              child: Stack(
                children: [
                  // Map Graphic Background
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/54506.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(color: const Color(0xFFE2E8F0)),
                    ),
                  ),

                  // Interactive animated Custom Route Painter
                  AnimatedBuilder(
                    animation: _carAnimationController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size.infinite,
                        painter: _LiveRoutePainter(
                          progress: _carAnimationController.value,
                          isDriverArrived: status == RideStatus.arrived || status == RideStatus.inProgress || status == RideStatus.completed,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 2. Top Header Navigation Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back / Minimize Button
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: LocalLensDimensions.floatingShadow,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: LocalLensColors.textPrimary, size: 18),
                      onPressed: () => context.pop(),
                    ),
                  ),

                  // Live Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                      boxShadow: LocalLensDimensions.floatingShadow,
                      border: Border.all(
                        color: status == RideStatus.arrived
                            ? LocalLensColors.successGreen
                            : LocalLensColors.primaryTeal,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: status == RideStatus.arrived
                                ? LocalLensColors.successGreen
                                : LocalLensColors.accentOrange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status == RideStatus.arrived
                              ? 'Driver has arrived!'
                              : (status == RideStatus.inProgress
                                  ? 'Heading to destination'
                                  : 'Driver arriving • ETA 3 min'),
                          style: LocalLensTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: LocalLensColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // SOS / Safety Shield Button
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: LocalLensDimensions.floatingShadow,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.shield_outlined, color: LocalLensColors.accentOrange, size: 20),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('LocalLens Safety: Emergency assistance & Ride share active.'),
                            backgroundColor: LocalLensColors.primaryTealDark,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Driver Arrived Banner (When Arrived)
          if (status == RideStatus.arrived)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: LocalLensColors.successGreen,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                  boxShadow: LocalLensDimensions.floatingShadow,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_taxi_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your ride has arrived!',
                            style: LocalLensTypography.titleSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${rider.name} is waiting at pickup location.',
                            style: LocalLensTypography.caption.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. Bottom Floating Live Ride Sheet
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(LocalLensDimensions.radiusLarge),
                boxShadow: LocalLensDimensions.floatingShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag indicator
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rider profile info
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: LocalLensColors.primaryTeal, width: 2),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/characters/solo.png'),
                            fit: BoxFit.cover,
                          ),
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
                                  rider.name,
                                  style: LocalLensTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                Text('${rider.rating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            Text(
                              '${vehicle.name} • ${rider.vehicleNumber}',
                              style: LocalLensTypography.caption.copyWith(fontWeight: FontWeight.bold, color: LocalLensColors.primaryTeal),
                            ),
                            Text(
                              'White Sedan (Maruti Dzire)',
                              style: LocalLensTypography.caption.copyWith(color: LocalLensColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            status == RideStatus.arrived ? '0 min' : (status == RideStatus.inProgress ? '5 min' : '3 min'),
                            style: LocalLensTypography.titleLarge.copyWith(
                              color: LocalLensColors.primaryTeal,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            status == RideStatus.inProgress ? '2.4 km left' : 'Pickup in 300m',
                            style: LocalLensTypography.caption.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Action Buttons
                  if (status == RideStatus.arrived) ...[
                    LocalLensPrimaryButton(
                      text: 'Start Ride',
                      isOrange: true,
                      icon: Icons.play_arrow_rounded,
                      onPressed: _onStartRidePressed,
                    ),
                  ] else if (status == RideStatus.inProgress) ...[
                    LocalLensPrimaryButton(
                      text: 'Heading to Experience...',
                      isOrange: false,
                      icon: Icons.navigation_rounded,
                      onPressed: () {
                        ref.read(rideProvider.notifier).completeTrip();
                        context.pushReplacement(AppRoutes.travelerRideCompleted);
                      },
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Calling ${rider.name} (${rider.phone})...'),
                                  backgroundColor: LocalLensColors.primaryTeal,
                                ),
                              );
                            },
                            icon: const Icon(Icons.phone_rounded, color: LocalLensColors.primaryTeal, size: 18),
                            label: const Text('Call', style: TextStyle(color: LocalLensColors.primaryTeal, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: LocalLensColors.primaryTeal),
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Live ride location shared with your trusted contacts.'),
                                  backgroundColor: LocalLensColors.primaryTealDark,
                                ),
                              );
                            },
                            icon: const Icon(Icons.share_location_rounded, color: LocalLensColors.textPrimary, size: 18),
                            label: const Text('Share', style: TextStyle(color: LocalLensColors.textPrimary, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: LocalLensColors.border),
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: LocalLensColors.errorRed),
                          tooltip: 'Cancel Ride',
                          onPressed: () {
                            ref.read(rideProvider.notifier).cancelRide();
                            context.pop();
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Route Painter with animated car marker
class _LiveRoutePainter extends CustomPainter {
  final double progress;
  final bool isDriverArrived;

  _LiveRoutePainter({required this.progress, required this.isDriverArrived});

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(size.width * 0.25, size.height * 0.65);
    final control1 = Offset(size.width * 0.4, size.height * 0.45);
    final control2 = Offset(size.width * 0.65, size.height * 0.55);
    final end = Offset(size.width * 0.8, size.height * 0.3);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(control1.dx, control1.dy, control2.dx, control2.dy, end.dx, end.dy);

    // 1. Draw Route Background Glow Line
    final bgLinePaint = Paint()
      ..color = LocalLensColors.primaryTeal.withValues(alpha: 0.25)
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, bgLinePaint);

    // 2. Draw Main Route Line
    final mainLinePaint = Paint()
      ..color = LocalLensColors.primaryTeal
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, mainLinePaint);

    // 3. Draw Pickup Marker (Circle with Teal)
    final pickupPaint = Paint()..color = LocalLensColors.primaryTealDark;
    canvas.drawCircle(start, 9.0, pickupPaint);
    final pickupInner = Paint()..color = Colors.white;
    canvas.drawCircle(start, 4.5, pickupInner);

    // 4. Draw Drop Destination Marker (Orange Pin)
    final dropPaint = Paint()..color = LocalLensColors.accentOrange;
    canvas.drawCircle(end, 10.0, dropPaint);
    final dropInner = Paint()..color = Colors.white;
    canvas.drawCircle(end, 5.0, dropInner);

    // 5. Calculate animated car position along cubic bezier path
    final t = progress.clamp(0.0, 1.0);
    final currentPos = _calculateCubicBezierPoint(start, control1, control2, end, t);

    // Draw Animated Vehicle Dot & Wave
    final carGlow = Paint()..color = LocalLensColors.accentOrange.withValues(alpha: 0.3);
    canvas.drawCircle(currentPos, 18.0, carGlow);

    final carPaint = Paint()..color = LocalLensColors.accentOrange;
    canvas.drawCircle(currentPos, 10.0, carPaint);
    final carCenter = Paint()..color = Colors.white;
    canvas.drawCircle(currentPos, 5.0, carCenter);
  }

  Offset _calculateCubicBezierPoint(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final u = 1 - t;
    final tt = t * t;
    final uu = u * u;
    final uuu = uu * u;
    final ttt = tt * t;

    final x = uuu * p0.dx + 3 * uu * t * p1.dx + 3 * u * tt * p2.dx + ttt * p3.dx;
    final y = uuu * p0.dy + 3 * uu * t * p1.dy + 3 * u * tt * p2.dy + ttt * p3.dy;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant _LiveRoutePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDriverArrived != isDriverArrived;
  }
}
