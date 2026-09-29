import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/ride_model.dart';

abstract class TravelerRideRepository {
  Future<RideRequest?> createRideRequest({
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String dropAddress,
    required double dropLat,
    required double dropLng,
    required VehicleOption vehicle,
  });

  Future<void> cancelRide(String rideId);
  Stream<Map<String, dynamic>> listenToRideUpdates(String rideId);
  Stream<Map<String, dynamic>> listenToRiderLocation(String riderId);
  Future<Rider?> getRiderProfile(String riderId);
}

class SupabaseTravelerRideRepository extends TravelerRideRepository {
  SupabaseClient? get _client => SupabaseConfig.client;

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Future<RideRequest?> createRideRequest({
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String dropAddress,
    required double dropLat,
    required double dropLng,
    required VehicleOption vehicle,
  }) async {
    final client = _client;
    final user = client?.auth.currentUser;

    final travelerId = user?.id ?? 'traveler-${DateTime.now().millisecondsSinceEpoch}';
    final travelerName = user?.userMetadata?['full_name'] as String? ?? user?.email?.split('@').first ?? 'Traveler';

    final double rawTripDist = (pickupLat != 0.0 && pickupLng != 0.0 && dropLat != 0.0 && dropLng != 0.0)
        ? _haversineKm(pickupLat, pickupLng, dropLat, dropLng)
        : 4.2;
    final double realTripDistance = rawTripDist < 0.5 ? 0.5 : rawTripDist;
    final double computedFare = vehicle.type.calculateFare(realTripDistance);

    final payload = <String, dynamic>{
      'passenger_id': user?.id,
      'passenger_name': travelerName,
      'passenger_rating': 4.8,
      'pickup_address': pickupAddress,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'destination_address': dropAddress,
      'destination_lat': dropLat,
      'destination_lng': dropLng,
      'fare': double.parse(computedFare.toStringAsFixed(2)),
      'pickup_distance': 1.5,
      'trip_distance': double.parse(realTripDistance.toStringAsFixed(2)),
      'eta_minutes': vehicle.etaMinutes,
      'status': 'searching',
      'created_at': DateTime.now().toIso8601String(),
    };

    if (client == null) {
      // Offline fallback
      return RideRequest(
        id: 'ride-${DateTime.now().millisecondsSinceEpoch}',
        travelerId: travelerId,
        pickup: pickupAddress,
        drop: dropAddress,
        vehicle: vehicle,
        estimatedFare: vehicle.estimatedFare,
        status: RideStatus.searching,
        createdAt: DateTime.now(),
      );
    }

    try {
      final response = await client.from('rides').insert(payload).select().single();
      final rideId = response['id']?.toString() ?? 'ride-${DateTime.now().millisecondsSinceEpoch}';

      return RideRequest(
        id: rideId,
        travelerId: travelerId,
        pickup: pickupAddress,
        drop: dropAddress,
        vehicle: vehicle,
        estimatedFare: (response['fare'] as num?)?.toDouble() ?? vehicle.estimatedFare,
        status: RideStatus.searching,
        rider: null,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[TravelerRideRepo] Error creating ride in Supabase: $e');
      return RideRequest(
        id: 'ride-${DateTime.now().millisecondsSinceEpoch}',
        travelerId: travelerId,
        pickup: pickupAddress,
        drop: dropAddress,
        vehicle: vehicle,
        estimatedFare: vehicle.estimatedFare,
        status: RideStatus.searching,
        createdAt: DateTime.now(),
      );
    }
  }


  @override
  Future<void> cancelRide(String rideId) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('rides').update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', rideId);
    } catch (e) {
      debugPrint('[TravelerRideRepo] Error cancelling ride: $e');
    }
  }

  @override
  Stream<Map<String, dynamic>> listenToRideUpdates(String rideId) {
    final client = _client;
    if (client == null) return const Stream.empty();

    final controller = StreamController<Map<String, dynamic>>.broadcast();

    final channel = client.channel('public:rides:$rideId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'rides',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: rideId),
      callback: (payload) {
        controller.add(payload.newRecord);
      },
    ).subscribe();

    controller.onCancel = () {
      client.removeChannel(channel);
    };

    return controller.stream;
  }

  @override
  Stream<Map<String, dynamic>> listenToRiderLocation(String riderId) {
    final client = _client;
    if (client == null) return const Stream.empty();

    final controller = StreamController<Map<String, dynamic>>.broadcast();

    final channel = client.channel('public:riders:$riderId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'riders',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: riderId),
      callback: (payload) {
        controller.add(payload.newRecord);
      },
    ).subscribe();

    controller.onCancel = () {
      client.removeChannel(channel);
    };

    return controller.stream;
  }

  @override
  Future<Rider?> getRiderProfile(String riderId) async {
    final client = _client;
    if (client == null) return null;

    try {
      final response = await client.from('riders').select().eq('id', riderId).single();
      final vehicleModel = response['vehicle_model'] as String? ?? '';
      final vehicleTypeStr = response['vehicle_type'] as String? ?? 'Sedan';
      final fullVehicleType = vehicleModel.isNotEmpty ? '$vehicleTypeStr ($vehicleModel)' : vehicleTypeStr;
      final imgUrl = (response['profile_image_url'] as String?) ?? (response['avatar_url'] as String?);

      return Rider(
        id: response['id'],
        name: response['name'] ?? 'Driver',
        rating: (response['rating'] as num?)?.toDouble() ?? 4.8,
        vehicleType: fullVehicleType,
        vehicleNumber: response['vehicle_number'] ?? 'MH 04 AB 1234',
        profileImage: (imgUrl != null && imgUrl.isNotEmpty) ? imgUrl : 'assets/images/characters/solo.png',
        phone: response['phone'] ?? '+91 98201 23456',
        latitude: (response['latitude'] as num?)?.toDouble() ?? 19.0760,
        longitude: (response['longitude'] as num?)?.toDouble() ?? 72.8777,
      );
    } catch (e) {
      debugPrint('[TravelerRideRepo] Error fetching rider profile: $e');
      return null;
    }
  }
}
