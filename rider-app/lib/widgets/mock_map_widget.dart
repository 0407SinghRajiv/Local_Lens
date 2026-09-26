import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Mock map widget that visually represents locations, markers, and routes.
/// Designed to be replaced with Google Maps / Mapbox later.
class MockMapWidget extends StatefulWidget {
  final double driverLat;
  final double driverLng;
  final double? pickupLat;
  final double? pickupLng;
  final double? destinationLat;
  final double? destinationLng;
  final bool showRoute;
  final double height;

  const MockMapWidget({
    super.key,
    required this.driverLat,
    required this.driverLng,
    this.pickupLat,
    this.pickupLng,
    this.destinationLat,
    this.destinationLng,
    this.showRoute = false,
    this.height = 300,
  });

  @override
  State<MockMapWidget> createState() => _MockMapWidgetState();
}

class _MockMapWidgetState extends State<MockMapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0E8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            final minLat = _getMinLat() - 0.01;
            final maxLat = _getMaxLat() + 0.01;
            final minLng = _getMinLng() - 0.01;
            final maxLng = _getMaxLng() + 0.01;

            double getX(double lng) {
              if (maxLng == minLng) return width / 2;
              return ((lng - minLng) / (maxLng - minLng) * (width - 60)) + 30;
            }

            double getY(double lat) {
              if (maxLat == minLat) return height / 2;
              return ((maxLat - lat) / (maxLat - minLat) * (height - 60)) + 30;
            }

            return Stack(
              children: [
                // Map grid background
                CustomPaint(
                  size: Size(width, height),
                  painter: _MapGridPainter(),
                ),
                // Road lines
                CustomPaint(
                  size: Size(width, height),
                  painter: _RoadPainter(
                    driverLat: widget.driverLat,
                    driverLng: widget.driverLng,
                    pickupLat: widget.pickupLat,
                    pickupLng: widget.pickupLng,
                    destinationLat: widget.destinationLat,
                    destinationLng: widget.destinationLng,
                    showRoute: widget.showRoute,
                  ),
                ),
                // Driver marker with pulse
                _buildDriverMarker(
                  getX(widget.driverLng),
                  getY(widget.driverLat),
                ),
                // Pickup marker
                if (widget.pickupLat != null && widget.pickupLng != null)
                  _buildPickupMarker(
                    getX(widget.pickupLng!),
                    getY(widget.pickupLat!),
                  ),
                // Destination marker
                if (widget.destinationLat != null && widget.destinationLng != null)
                  _buildDestinationMarker(
                    getX(widget.destinationLng!),
                    getY(widget.destinationLat!),
                  ),
                // Map attribution
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Mock Map • Dev Mode',
                      style: AppTheme.labelSmall.copyWith(
                        fontSize: 8,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDriverMarker(double x, double y) {
    return Positioned(
      left: x - 20,
      top: y - 20,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = 1.0 + (_pulseController.value * 0.3);
          final opacity = 1.0 - _pulseController.value;
          return SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulse ring
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primary
                            .withValues(alpha: opacity * 0.5),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                // Driver dot
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPickupMarker(double x, double y) {
    return Positioned(
      left: x - 14,
      top: y - 28,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'PICKUP',
              style: AppTheme.labelSmall.copyWith(
                color: Colors.white,
                fontSize: 7,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationMarker(double x, double y) {
    return Positioned(
      left: x - 14,
      top: y - 28,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.error,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'DROP',
              style: AppTheme.labelSmall.copyWith(
                color: Colors.white,
                fontSize: 7,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppTheme.error,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      ),
    );
  }

  double _getMinLat() {
    if (widget.pickupLat != null && widget.destinationLat != null) {
      return min(widget.pickupLat!, widget.destinationLat!);
    }
    double m = widget.driverLat;
    if (widget.pickupLat != null) m = min(m, widget.pickupLat!);
    if (widget.destinationLat != null) m = min(m, widget.destinationLat!);
    return m;
  }

  double _getMaxLat() {
    if (widget.pickupLat != null && widget.destinationLat != null) {
      return max(widget.pickupLat!, widget.destinationLat!);
    }
    double m = widget.driverLat;
    if (widget.pickupLat != null) m = max(m, widget.pickupLat!);
    if (widget.destinationLat != null) m = max(m, widget.destinationLat!);
    return m;
  }

  double _getMinLng() {
    if (widget.pickupLng != null && widget.destinationLng != null) {
      return min(widget.pickupLng!, widget.destinationLng!);
    }
    double m = widget.driverLng;
    if (widget.pickupLng != null) m = min(m, widget.pickupLng!);
    if (widget.destinationLng != null) m = min(m, widget.destinationLng!);
    return m;
  }

  double _getMaxLng() {
    if (widget.pickupLng != null && widget.destinationLng != null) {
      return max(widget.pickupLng!, widget.destinationLng!);
    }
    double m = widget.driverLng;
    if (widget.pickupLng != null) m = max(m, widget.pickupLng!);
    if (widget.destinationLng != null) m = max(m, widget.destinationLng!);
    return m;
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Light green background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFE8EFE5),
    );

    // Grid lines (streets)
    final paintLight = Paint()
      ..color = const Color(0xFFD4DDD0)
      ..strokeWidth = 0.5;
    final paintRoad = Paint()
      ..color = const Color(0xFFFAFAFA)
      ..strokeWidth = 3;

    // Horizontal roads
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintLight);
    }
    // Vertical roads
    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintLight);
    }

    // Major roads
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.3),
      paintRoad,
    );
    canvas.drawLine(
      Offset(size.width * 0.4, 0),
      Offset(size.width * 0.4, size.height),
      paintRoad,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      paintRoad,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.7, size.height),
      paintRoad,
    );

    // Park areas
    final parkPaint = Paint()..color = const Color(0xFFCADBC5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            size.width * 0.1, size.height * 0.4, 60, 40),
        const Radius.circular(8),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            size.width * 0.6, size.height * 0.5, 50, 35),
        const Radius.circular(8),
      ),
      parkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoadPainter extends CustomPainter {
  final double driverLat, driverLng;
  final double? pickupLat, pickupLng, destinationLat, destinationLng;
  final bool showRoute;

  _RoadPainter({
    required this.driverLat,
    required this.driverLng,
    this.pickupLat,
    this.pickupLng,
    this.destinationLat,
    this.destinationLng,
    this.showRoute = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showRoute) return;

    final routePaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dashPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final allLats = [driverLat, if (pickupLat != null) pickupLat!, if (destinationLat != null) destinationLat!];
    final allLngs = [driverLng, if (pickupLng != null) pickupLng!, if (destinationLng != null) destinationLng!];

    final minLat = allLats.reduce(min) - 0.01;
    final maxLat = allLats.reduce(max) + 0.01;
    final minLng = allLngs.reduce(min) - 0.01;
    final maxLng = allLngs.reduce(max) + 0.01;

    Offset toOffset(double lat, double lng) {
      final x = ((lng - minLng) / (maxLng - minLng) * (size.width - 60)) + 30;
      final y = ((maxLat - lat) / (maxLat - minLat) * (size.height - 60)) + 30;
      return Offset(x, y);
    }

    final driverPos = toOffset(driverLat, driverLng);

    // Route from driver to pickup
    if (pickupLat != null && pickupLng != null) {
      final pickupPos = toOffset(pickupLat!, pickupLng!);
      final path = Path()
        ..moveTo(driverPos.dx, driverPos.dy)
        ..cubicTo(
          driverPos.dx + (pickupPos.dx - driverPos.dx) * 0.3,
          driverPos.dy,
          pickupPos.dx - (pickupPos.dx - driverPos.dx) * 0.3,
          pickupPos.dy,
          pickupPos.dx,
          pickupPos.dy,
        );
      canvas.drawPath(path, routePaint);

      // Route from pickup to destination
      if (destinationLat != null && destinationLng != null) {
        final destPos = toOffset(destinationLat!, destinationLng!);
        final path2 = Path()
          ..moveTo(pickupPos.dx, pickupPos.dy)
          ..cubicTo(
            pickupPos.dx + (destPos.dx - pickupPos.dx) * 0.3,
            pickupPos.dy,
            destPos.dx - (destPos.dx - pickupPos.dx) * 0.3,
            destPos.dy,
            destPos.dx,
            destPos.dy,
          );
        canvas.drawPath(path2, dashPaint);
      }
    } else if (destinationLat != null && destinationLng != null) {
      // Direct route from driver to destination
      final destPos = toOffset(destinationLat!, destinationLng!);
      final path = Path()
        ..moveTo(driverPos.dx, driverPos.dy)
        ..cubicTo(
          driverPos.dx + (destPos.dx - driverPos.dx) * 0.3,
          driverPos.dy,
          destPos.dx - (destPos.dx - driverPos.dx) * 0.3,
          destPos.dy,
          destPos.dx,
          destPos.dy,
        );
      canvas.drawPath(path, routePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) => true;
}
