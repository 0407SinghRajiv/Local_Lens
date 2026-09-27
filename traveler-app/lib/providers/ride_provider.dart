import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import '../models/ride_model.dart';
import '../repositories/traveler_ride_repository.dart';
import '../services/location_service.dart';

class RideState {
  final RideStatus status;
  final VehicleOption selectedVehicle;
  final RideRequest? currentRequest;
  final Rider? activeRider;
  final double routeProgress; // 0.0 (pickup) to 1.0 (destination)
  final int etaMinutes;
  final String etaText;
  final String pickupLocation;
  final String dropLocation;
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;
  final double riderLat;
  final double riderLng;
  final String? errorMessage;

  const RideState({
    this.status = RideStatus.idle,
    this.selectedVehicle = const VehicleOption(
      type: VehicleType.sedan,
      name: 'Sedan',
      estimatedFare: 180.0,
      etaMinutes: 5,
      capacity: '4 seats',
      icon: Icons.directions_car_rounded,
    ),
    this.currentRequest,
    this.activeRider,
    this.routeProgress = 0.0,
    this.etaMinutes = 5,
    this.etaText = '5 min',
    this.pickupLocation = 'Panvel Station, Mumbai',
    this.dropLocation = 'Local Food Experience, Bandra',
    this.pickupLat = 19.0760,
    this.pickupLng = 72.8777,
    this.dropLat = 19.0596,
    this.dropLng = 72.8295,
    this.riderLat = 19.0760,
    this.riderLng = 72.8777,
    this.errorMessage,
  });

  RideState copyWith({
    RideStatus? status,
    VehicleOption? selectedVehicle,
    RideRequest? currentRequest,
    Rider? activeRider,
    double? routeProgress,
    int? etaMinutes,
    String? etaText,
    String? pickupLocation,
    String? dropLocation,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
    double? riderLat,
    double? riderLng,
    String? errorMessage,
  }) {
    return RideState(
      status: status ?? this.status,
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
      currentRequest: currentRequest ?? this.currentRequest,
      activeRider: activeRider ?? this.activeRider,
      routeProgress: routeProgress ?? this.routeProgress,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      etaText: etaText ?? this.etaText,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropLocation: dropLocation ?? this.dropLocation,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropLat: dropLat ?? this.dropLat,
      dropLng: dropLng ?? this.dropLng,
      riderLat: riderLat ?? this.riderLat,
      riderLng: riderLng ?? this.riderLng,
      errorMessage: errorMessage,
    );
  }
}

class RideNotifier extends StateNotifier<RideState> {
  final TravelerRideRepository _repository;
  StreamSubscription? _rideSub;
  StreamSubscription? _riderLocationSub;
  StreamSubscription? _userLocationSub;
  Timer? _timeoutTimer;
  Timer? _pollTimer;
  Timer? _riderPollTimer;

  RideNotifier([TravelerRideRepository? repository])
      : _repository = repository ?? SupabaseTravelerRideRepository(),
        super(const RideState()) {
    _listenToUserLocation();
    checkActiveRide();
  }

  void _listenToUserLocation() {
    _userLocationSub?.cancel();
    _userLocationSub = LocationService.positionStream.listen((pos) {
      if (pos.latitude != 0.0 && pos.longitude != 0.0) {
        state = state.copyWith(
          pickupLat: pos.latitude,
          pickupLng: pos.longitude,
        );
      }
    });
  }

  @override
  void dispose() {
    _rideSub?.cancel();
    _riderLocationSub?.cancel();
    _userLocationSub?.cancel();
    _timeoutTimer?.cancel();
    _pollTimer?.cancel();
    _riderPollTimer?.cancel();
    super.dispose();
  }

  void startDriverApproach() {
    state = state.copyWith(
      status: RideStatus.riderArriving,
      etaMinutes: 3,
      etaText: '3 min',
    );
  }

  void markDriverArrived() {
    state = state.copyWith(
      status: RideStatus.arrived,
      etaMinutes: 0,
      etaText: 'Arrived',
    );
  }

  void startTrip() {
    state = state.copyWith(
      status: RideStatus.inProgress,
      routeProgress: 0.1,
      etaMinutes: 12,
      etaText: '12 min',
    );
  }

  void setRouteProgress(double progress) {
    state = state.copyWith(
      routeProgress: progress.clamp(0.0, 1.0),
    );
  }

  void completeTrip() {
    state = state.copyWith(
      status: RideStatus.completed,
      routeProgress: 1.0,
      etaMinutes: 0,
      etaText: 'Arrived',
    );
  }

  void selectVehicle(VehicleOption vehicle) {
    state = state.copyWith(
      selectedVehicle: vehicle,
      status: RideStatus.vehicleSelected,
      etaMinutes: vehicle.etaMinutes,
      etaText: '${vehicle.etaMinutes} min',
    );
  }

  void setLocations({
    required String pickup,
    required String drop,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
  }) {
    state = state.copyWith(
      pickupLocation: pickup,
      dropLocation: drop,
      pickupLat: pickupLat ?? state.pickupLat,
      pickupLng: pickupLng ?? state.pickupLng,
      dropLat: dropLat ?? state.dropLat,
      dropLng: dropLng ?? state.dropLng,
    );
  }

  /// Initiates real ride request in Supabase and listens to realtime updates
  Future<void> requestRide({String? pickup, String? drop}) async {
    final finalPickup = pickup ?? state.pickupLocation;
    final finalDrop = drop ?? state.dropLocation;

    state = state.copyWith(
      status: RideStatus.searching,
      pickupLocation: finalPickup,
      dropLocation: finalDrop,
      routeProgress: 0.0,
      errorMessage: null,
    );

    try {
      final request = await _repository.createRideRequest(
        pickupAddress: finalPickup,
        pickupLat: state.pickupLat,
        pickupLng: state.pickupLng,
        dropAddress: finalDrop,
        dropLat: state.dropLat,
        dropLng: state.dropLng,
        vehicle: state.selectedVehicle,
      );

      final finalRequest = request ?? RideRequest(
        id: 'mock_ride_${DateTime.now().millisecondsSinceEpoch}',
        travelerId: 'traveler_mock',
        pickup: finalPickup,
        drop: finalDrop,
        vehicle: state.selectedVehicle,
        estimatedFare: state.selectedVehicle.estimatedFare,
        status: RideStatus.searching,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(currentRequest: finalRequest);
      if (request != null) {
        _listenToRide(request.id);
      }

      // 60-second request timeout
      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(const Duration(seconds: 60), () {
        if (state.status == RideStatus.searching) {
          cancelRide();
          state = state.copyWith(
            status: RideStatus.failed,
            errorMessage: 'No riders accepted your request. Please try again.',
          );
        }
      });
    } catch (e) {
      debugPrint('[RideNotifier] Error creating ride: $e');
    }
  }

  void _listenToRide(String rideId) {
    _rideSub?.cancel();
    _pollTimer?.cancel();

    _rideSub = _repository.listenToRideUpdates(rideId).listen((row) {
      _handleRideRow(row);
    });

    // 3-second polling fallback
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final client = SupabaseConfig.client;
      if (client == null) return;
      try {
        final response = await client.from('rides').select().eq('id', rideId).maybeSingle();
        if (response != null) {
          _handleRideRow(response);
        }
      } catch (e) {
        debugPrint('[RideNotifier] Error polling ride state: $e');
      }
    });
  }

  /// Automatically queries Supabase to check and restore active ride state without needing app restart
  Future<void> checkActiveRide() async {
    final client = SupabaseConfig.client;
    if (client == null) return;
    try {
      final user = client.auth.currentUser;
      final query = client.from('rides').select().order('created_at', ascending: false).limit(1);
      List<dynamic> rides;
      if (user != null) {
        rides = await client.from('rides').select().eq('passenger_id', user.id).order('created_at', ascending: false).limit(1);
      } else {
        rides = await query;
      }

      if (rides.isNotEmpty) {
        final row = Map<String, dynamic>.from(rides.first);
        final statusStr = row['status'] as String? ?? '';
        if (['searching', 'accepted', 'arrived', 'started'].contains(statusStr)) {
          final rideId = row['id']?.toString() ?? '';
          final riderId = row['rider_id']?.toString();

          Rider? rider;
          if (riderId != null && riderId.isNotEmpty) {
            rider = await _repository.getRiderProfile(riderId);
          }

          RideStatus parsedStatus = RideStatus.searching;
          if (statusStr == 'accepted') parsedStatus = RideStatus.accepted;
          if (statusStr == 'arrived') parsedStatus = RideStatus.arrived;
          if (statusStr == 'started') parsedStatus = RideStatus.started;

          final vehicle = VehicleOption(
            type: VehicleType.sedan,
            name: row['vehicle_type'] ?? 'Sedan',
            estimatedFare: (row['fare'] as num?)?.toDouble() ?? 180.0,
            etaMinutes: row['eta_minutes'] ?? 5,
            capacity: '4 seats',
            icon: Icons.directions_car_rounded,
          );

          final req = RideRequest(
            id: rideId,
            travelerId: row['passenger_id'] ?? '',
            pickup: row['pickup_address'] ?? 'Pickup',
            drop: row['destination_address'] ?? 'Destination',
            vehicle: vehicle,
            estimatedFare: (row['fare'] as num?)?.toDouble() ?? 180.0,
            status: parsedStatus,
            rider: rider,
            createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
          );

          state = state.copyWith(
            status: parsedStatus,
            currentRequest: req,
            activeRider: rider ?? state.activeRider,
            pickupLocation: row['pickup_address'] ?? state.pickupLocation,
            dropLocation: row['destination_address'] ?? state.dropLocation,
            pickupLat: (row['pickup_lat'] as num?)?.toDouble() ?? state.pickupLat,
            pickupLng: (row['pickup_lng'] as num?)?.toDouble() ?? state.pickupLng,
            dropLat: (row['destination_lat'] as num?)?.toDouble() ?? state.dropLat,
            dropLng: (row['destination_lng'] as num?)?.toDouble() ?? state.dropLng,
            riderLat: rider?.latitude ?? state.riderLat,
            riderLng: rider?.longitude ?? state.riderLng,
          );

          if (rideId.isNotEmpty) {
            _listenToRide(rideId);
          }
          if (riderId != null && riderId.isNotEmpty) {
            _listenToRiderLocation(riderId);
          }
        } else {
          // Latest ride is completed, cancelled, or inactive -> reset state to idle
          state = state.copyWith(
            status: RideStatus.idle,
            currentRequest: null,
            activeRider: null,
          );
        }
      } else {
        // No rides exist in database -> reset state to idle
        state = state.copyWith(
          status: RideStatus.idle,
          currentRequest: null,
          activeRider: null,
        );
      }
    } catch (e) {
      debugPrint('[RideNotifier] Error checking active ride: $e');
    }
  }

  Future<void> _handleRideRow(Map<String, dynamic> row) async {
    final statusStr = row['status'] as String? ?? '';
    final riderId = row['rider_id'] as String?;
    debugPrint('[RideNotifier] Received ride status update: $statusStr (rider: $riderId)');

    switch (statusStr) {
      case 'searching':
        if (riderId != null && riderId.isNotEmpty) {
          final rider = await _repository.getRiderProfile(riderId);
          if (rider != null) {
            _listenToRiderLocation(riderId);
            state = state.copyWith(
              status: RideStatus.accepted,
              activeRider: rider,
              riderLat: rider.latitude,
              riderLng: rider.longitude,
            );
          }
        }
        break;

      case 'accepted':
        _timeoutTimer?.cancel();
        Rider? rider;
        if (riderId != null && riderId.isNotEmpty) {
          rider = await _repository.getRiderProfile(riderId);
          _listenToRiderLocation(riderId);
        }
        rider ??= Rider.defaultMockRider;

        state = state.copyWith(
          status: RideStatus.accepted,
          activeRider: rider,
          riderLat: rider.latitude,
          riderLng: rider.longitude,
          currentRequest: state.currentRequest?.copyWith(
            status: RideStatus.accepted,
            rider: rider,
          ),
        );
        break;

      case 'arrived':
        state = state.copyWith(
          status: RideStatus.arrived,
          etaMinutes: 0,
          etaText: 'Arrived',
        );
        break;

      case 'started':
        state = state.copyWith(
          status: RideStatus.started,
          routeProgress: 0.1,
          etaMinutes: 12,
          etaText: '12 min',
        );
        break;

      case 'completed':
        _pollTimer?.cancel();
        state = state.copyWith(
          status: RideStatus.completed,
          routeProgress: 1.0,
          etaMinutes: 0,
          etaText: 'Arrived',
        );
        break;

      case 'cancelled':
      case 'expired':
        _timeoutTimer?.cancel();
        _pollTimer?.cancel();
        state = state.copyWith(
          status: RideStatus.cancelled,
          errorMessage: 'Ride was cancelled or expired.',
        );
        break;
    }
  }

  void _listenToRiderLocation(String riderId) {
    _riderLocationSub?.cancel();
    _riderPollTimer?.cancel();
    if (riderId.isEmpty) return;

    // 1. Supabase Realtime channel on public:riders:$riderId
    _riderLocationSub = _repository.listenToRiderLocation(riderId).listen((row) {
      final lat = (row['latitude'] as num?)?.toDouble();
      final lng = (row['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null && (lat != 0.0 || lng != 0.0)) {
        state = state.copyWith(riderLat: lat, riderLng: lng);
      }
    });

    // 2. 3-second periodic polling fallback on riders table
    _riderPollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final client = SupabaseConfig.client;
      if (client == null) return;
      try {
        final res = await client.from('riders').select('latitude, longitude').eq('id', riderId).maybeSingle();
        if (res != null) {
          final lat = (res['latitude'] as num?)?.toDouble();
          final lng = (res['longitude'] as num?)?.toDouble();
          if (lat != null && lng != null && (lat != 0.0 || lng != 0.0)) {
            state = state.copyWith(riderLat: lat, riderLng: lng);
          }
        }
      } catch (e) {
        debugPrint('[RideNotifier] Error polling rider location: $e');
      }
    });
  }

  /// Cancels ride
  Future<void> cancelRide() async {
    _timeoutTimer?.cancel();
    _rideSub?.cancel();
    _riderLocationSub?.cancel();
    _riderPollTimer?.cancel();

    final reqId = state.currentRequest?.id;
    if (reqId != null) {
      await _repository.cancelRide(reqId);
    }

    state = state.copyWith(
      status: RideStatus.cancelled,
      activeRider: null,
      currentRequest: null,
      routeProgress: 0.0,
    );
  }

  /// Resets back to idle
  void resetRide() {
    _timeoutTimer?.cancel();
    _rideSub?.cancel();
    _riderLocationSub?.cancel();
    _riderPollTimer?.cancel();
    state = const RideState();
  }
}

final travelerRideRepositoryProvider = Provider<TravelerRideRepository>((ref) {
  return SupabaseTravelerRideRepository();
});

final rideProvider = StateNotifierProvider<RideNotifier, RideState>((ref) {
  final repo = ref.watch(travelerRideRepositoryProvider);
  return RideNotifier(repo);
});
