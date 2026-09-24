import 'package:flutter/foundation.dart';
import '../models/ride.dart';

/// Abstract ride repository for future Supabase integration
abstract class RideRepository {
  Future<Ride> getRide(String id);
  Future<void> updateRide(Ride ride);
  Future<void> updateRideStatus(String rideId, RideStatus status);
  Future<List<Ride>> getDriverRides(String driverId);
}

/// Mock ride repository
class MockRideRepository extends RideRepository {
  final Map<String, Ride> _rides = {};

  @override
  Future<Ride> getRide(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_rides.containsKey(id)) {
      return _rides[id]!;
    }
    throw Exception('Ride not found: $id');
  }

  @override
  Future<void> updateRide(Ride ride) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _rides[ride.id] = ride;
    debugPrint('[MockRideRepo] Ride updated: ${ride.id} - ${ride.status}');
  }

  @override
  Future<void> updateRideStatus(String rideId, RideStatus status) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_rides.containsKey(rideId)) {
      final ride = _rides[rideId]!;
      if (ride.canTransitionTo(status)) {
        _rides[rideId] = ride.copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
      } else {
        throw Exception(
            'Invalid transition: ${ride.status} -> $status');
      }
    }
  }

  @override
  Future<List<Ride>> getDriverRides(String driverId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _rides.values
        .where((r) => r.driverId == driverId)
        .toList();
  }
}
