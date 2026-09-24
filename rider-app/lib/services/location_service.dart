import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/location.dart';

/// Abstract location service for future Geolocator integration
abstract class LocationService {
  Stream<AppLocation> get locationStream;
  Future<AppLocation> getCurrentLocation();
  Future<void> startUpdates();
  Future<void> stopUpdates();
  bool get isTracking;
  void dispose();
}

/// Mock location service with simulated movement
class MockLocationService extends LocationService {
  final StreamController<AppLocation> _controller =
      StreamController<AppLocation>.broadcast();
  Timer? _timer;
  bool _isTracking = false;

  double _currentLat = 19.0760;
  double _currentLng = 72.8777;

  double? _targetLat;
  double? _targetLng;

  @override
  Stream<AppLocation> get locationStream => _controller.stream;

  @override
  bool get isTracking => _isTracking;

  @override
  Future<AppLocation> getCurrentLocation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return AppLocation(
      latitude: _currentLat,
      longitude: _currentLng,
      address: 'Current Location',
    );
  }

  @override
  Future<void> startUpdates() async {
    if (_isTracking) return;
    _isTracking = true;

    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _simulateMovement();
      _controller.add(AppLocation(
        latitude: _currentLat,
        longitude: _currentLng,
        address: 'Moving...',
      ));
    });

    debugPrint('[MockLocation] Started location updates');
  }

  @override
  Future<void> stopUpdates() async {
    _isTracking = false;
    _timer?.cancel();
    _timer = null;
    debugPrint('[MockLocation] Stopped location updates');
  }

  /// Set a target for simulated movement
  void setTarget(double lat, double lng) {
    _targetLat = lat;
    _targetLng = lng;
  }

  void setPosition(double lat, double lng) {
    _currentLat = lat;
    _currentLng = lng;
  }

  void _simulateMovement() {
    if (_targetLat == null || _targetLng == null) return;

    const stepSize = 0.001; // ~100m per update

    final dLat = _targetLat! - _currentLat;
    final dLng = _targetLng! - _currentLng;

    if (dLat.abs() < stepSize && dLng.abs() < stepSize) {
      _currentLat = _targetLat!;
      _currentLng = _targetLng!;
      return;
    }

    final distance = (dLat * dLat + dLng * dLng);
    if (distance > 0) {
      final ratio = stepSize / (dLat.abs() + dLng.abs());
      _currentLat += dLat * ratio;
      _currentLng += dLng * ratio;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
