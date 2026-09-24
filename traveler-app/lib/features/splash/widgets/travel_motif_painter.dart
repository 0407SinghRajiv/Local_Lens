import 'dart:math' as math;
import 'package:flutter/material.dart';

class TravelMotifPainter extends CustomPainter {
  final double animationProgress;
  final Brightness brightness;

  TravelMotifPainter({
    required this.animationProgress,
    required this.brightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final strokeColor = (isDark ? Colors.tealAccent : Colors.white).withValues(alpha: 0.18);
    final dotColor = (isDark ? Colors.amberAccent : Colors.white).withValues(alpha: 0.35);

    final linePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw stylized curved flight path
    final path = Path();
    path.moveTo(-20, size.height * 0.3);
    path.cubicTo(
      size.width * 0.35,
      size.height * 0.15,
      size.width * 0.65,
      size.height * 0.5,
      size.width + 20,
      size.height * 0.35,
    );

    // Draw dashed path effect
    _drawDashedPath(canvas, path, linePaint, animationProgress);

    // Draw secondary gentle wave path
    final secondPath = Path();
    secondPath.moveTo(-20, size.height * 0.75);
    secondPath.cubicTo(
      size.width * 0.3,
      size.height * 0.85,
      size.width * 0.7,
      size.height * 0.65,
      size.width + 20,
      size.height * 0.78,
    );
    _drawDashedPath(canvas, secondPath, linePaint, (animationProgress + 0.5) % 1.0);

    // Draw glowing waypoint nodes
    final nodePaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.23), 3.5, nodePaint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.44), 4.0, nodePaint);
    canvas.drawCircle(Offset(size.width * 0.45, size.height * 0.75), 3.0, nodePaint);
  }

  void _drawDashedPath(Canvas canvas, Path source, Paint paint, double offsetPhase) {
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    final pathMetrics = source.computeMetrics();

    for (final metric in pathMetrics) {
      final length = metric.length;
      double distance = (offsetPhase * (dashWidth + dashSpace)) % (dashWidth + dashSpace);

      while (distance < length) {
        final currentDash = math.min(dashWidth, length - distance);
        final extractPath = metric.extractPath(distance, distance + currentDash);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant TravelMotifPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.brightness != brightness;
  }
}
