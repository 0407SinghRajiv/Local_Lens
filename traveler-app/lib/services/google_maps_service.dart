import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/itinerary_model.dart';

class GoogleMapsService {
  /// Calculate camera bounds enclosing start position and all itinerary experiences
  static LatLngBounds? calculateBounds({
    LatLng? startLocation,
    required List<ItineraryItem> items,
  }) {
    final points = <LatLng>[];

    final validItems = items.where((i) => i.latitude != null && i.longitude != null).toList();

    for (final item in validItems) {
      points.add(LatLng(item.latitude!, item.longitude!));
    }

    if (startLocation != null) {
      // If we have items, only include startLocation if within 100km of the first stop
      if (points.isNotEmpty) {
        final dist = _approxDistanceKm(startLocation, points.first);
        if (dist <= 100.0) {
          points.insert(0, startLocation);
        }
      } else {
        points.add(startLocation);
      }
    }

    if (points.isEmpty) return null;
    if (points.length == 1) {
      final p = points.first;
      return LatLngBounds(
        southwest: LatLng(p.latitude - 0.015, p.longitude - 0.015),
        northeast: LatLng(p.latitude + 0.015, p.longitude + 0.015),
      );
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      minLat = min(minLat, p.latitude);
      maxLat = max(maxLat, p.latitude);
      minLng = min(minLng, p.longitude);
      maxLng = max(maxLng, p.longitude);
    }

    // Add margin if bounds are too tight
    if ((maxLat - minLat).abs() < 0.005) {
      minLat -= 0.005;
      maxLat += 0.005;
    }
    if ((maxLng - minLng).abs() < 0.005) {
      minLng -= 0.005;
      maxLng += 0.005;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Create connected polyline points following exact visit order:
  /// Start -> [1] -> [2] -> [3] -> [4]
  static List<LatLng> buildItineraryRoutePoints({
    LatLng? startLocation,
    required List<ItineraryItem> items,
  }) {
    final route = <LatLng>[];
    final validItems = items.where((i) => i.latitude != null && i.longitude != null).toList();

    if (startLocation != null && validItems.isNotEmpty) {
      final dist = _approxDistanceKm(startLocation, LatLng(validItems.first.latitude!, validItems.first.longitude!));
      if (dist <= 100.0) {
        route.add(startLocation);
      }
    } else if (startLocation != null) {
      route.add(startLocation);
    }

    for (final item in validItems) {
      route.add(LatLng(item.latitude!, item.longitude!));
    }

    return route;
  }

  static double _approxDistanceKm(LatLng p1, LatLng p2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((p2.latitude - p1.latitude) * p) / 2 +
        cos(p1.latitude * p) * cos(p2.latitude * p) * (1 - cos((p2.longitude - p1.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  /// Create custom canvas numbered marker icon (e.g. [1], [2], [START]) with reliable fallback
  static Future<BitmapDescriptor> createCustomNumberedMarker({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    bool isStart = false,
    bool isSelected = false,
  }) async {
    try {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      final size = isSelected ? 120.0 : 100.0;
      final radius = size / 2.0;

      final paint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = isSelected ? 6.0 : 4.0
        ..style = PaintingStyle.stroke;

      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      // Draw shadow circle
      canvas.drawCircle(Offset(radius, radius + 4), radius - 8, shadowPaint);

      // Draw main background circle
      canvas.drawCircle(Offset(radius, radius), radius - 8, paint);
      canvas.drawCircle(Offset(radius, radius), radius - 8, borderPaint);

      if (isStart) {
        // Draw Start Flag / Dot
        final innerDot = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(radius, radius), radius - 24, innerDot);

        final centerDot = Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(radius, radius), radius - 32, centerDot);
      } else {
        // Draw Visit Order Number
        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontSize: isSelected ? 44.0 : 38.0,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(
            radius - (textPainter.width / 2),
            radius - (textPainter.height / 2),
          ),
        );
      }

      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(size.toInt(), (size + 8).toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

      if (bytes != null) {
        return BitmapDescriptor.bytes(bytes.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint('[GoogleMapsService] Custom marker generation fallback: $e');
    }

    // Default vector marker fallback
    return BitmapDescriptor.defaultMarkerWithHue(
      isStart
          ? BitmapDescriptor.hueGreen
          : (isSelected ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueCyan),
    );
  }
}
