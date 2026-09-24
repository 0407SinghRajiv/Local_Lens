import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/ride.dart';

/// Abstract realtime service for future Supabase/WebSocket integration
abstract class RealtimeService {
  Stream<Ride> get rideRequestStream;
  Future<void> connect();
  Future<void> disconnect();
  bool get isConnected;
  void dispose();
}

/// Mock realtime service that generates ride requests for testing
class MockRealtimeService extends RealtimeService {
  final StreamController<Ride> _controller =
      StreamController<Ride>.broadcast();
  bool _isConnected = false;
  final _random = Random();

  @override
  Stream<Ride> get rideRequestStream => _controller.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> connect() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _isConnected = true;
    debugPrint('[MockRealtime] Connected');
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;
    debugPrint('[MockRealtime] Disconnected');
  }

  /// Manually trigger a ride request (for TEST RIDE REQUEST button)
  void triggerMockRideRequest() {
    if (!_isConnected) {
      debugPrint('[MockRealtime] Not connected, cannot trigger ride');
      return;
    }

    final rides = Ride.mockRidePool();
    final ride = rides[_random.nextInt(rides.length)];
    final newRide = ride.copyWith(
      id: 'ride_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );

    debugPrint('[MockRealtime] Triggering ride request: ${newRide.id}');
    _controller.add(newRide);
  }

  @override
  void dispose() {
    _controller.close();
  }
}
