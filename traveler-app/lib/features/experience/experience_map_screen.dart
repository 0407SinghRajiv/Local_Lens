import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 13: Experience Map Screen with Route & Bottom Detail Card
class ExperienceMapScreen extends StatelessWidget {
  const ExperienceMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen Stylized Interactive Map Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/54506.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: Colors.teal.withValues(alpha: 0.15),
            ),
          ),

          // Custom Map Route Polyline & Pins Canvas
          CustomPaint(
            size: Size.infinite,
            painter: _MapRoutePainter(),
          ),

          // Top Floating Navigation Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: LocalLensColors.textPrimary, size: 18),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                        boxShadow: LocalLensDimensions.softCardShadow,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: LocalLensColors.primaryTeal, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Panvel Coastline & Trails',
                            style: LocalLensTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Floating Experience Preview Card
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(LocalLensDimensions.radiusLarge),
                boxShadow: LocalLensDimensions.floatingShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/54506.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sunset by the Coast',
                              style: LocalLensTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹899 • 2.5 hrs • 4.8 ★',
                              style: LocalLensTypography.caption.copyWith(
                                color: LocalLensColors.primaryTeal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LocalLensPrimaryButton(
                    text: 'View Details',
                    isOrange: false,
                    onPressed: () {
                      context.push(AppRoutes.experienceDetails);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simulated Map Path Painter with waypoints
class _MapRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = LocalLensColors.primaryTeal
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.25, size.height * 0.35)
      ..lineTo(size.width * 0.50, size.height * 0.45)
      ..lineTo(size.width * 0.40, size.height * 0.60)
      ..lineTo(size.width * 0.70, size.height * 0.68);

    canvas.drawPath(path, paint);

    // Draw Map Pin Nodes
    final pinPaint = Paint()..color = LocalLensColors.accentOrange;
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.35), 8, pinPaint);
    canvas.drawCircle(Offset(size.width * 0.50, size.height * 0.45), 6, pinPaint);
    canvas.drawCircle(Offset(size.width * 0.70, size.height * 0.68), 10, pinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
