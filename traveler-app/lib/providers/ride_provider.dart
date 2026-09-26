import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ride_model.dart';

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
    this.pickupLocation = 'Current Location (Panvel Station)',
    this.dropLocation = 'Local Food Experience',
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
      errorMessage: errorMessage,
    );
  }
}

class RideNotifier extends StateNotifier<RideState> {
  Timer? _searchTimer;
  Timer? _progressTimer;

  RideNotifier() : super(const RideState());

  @override
  void dispose() {
    _searchTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  void selectVehicle(VehicleOption vehicle) {
    state = state.copyWith(
      selectedVehicle: vehicle,
      status: RideStatus.vehicleSelected,
      etaMinutes: vehicle.etaMinutes,
      etaText: '${vehicle.etaMinutes} min',
    );
  }

  void setLocations({required String pickup, required String drop}) {
    state = state.copyWith(
      pickupLocation: pickup,
      dropLocation: drop,
    );
  }

  /// Initiates ride request and begins matching simulation
  void requestRide({String? pickup, String? drop}) {
    final finalPickup = pickup ?? state.pickupLocation;
    final finalDrop = drop ?? state.dropLocation;

    final request = RideRequest(
      id: 'ride-${DateTime.now().millisecondsSinceEpoch}',
      travelerId: 'traveler-user-01',
      pickup: finalPickup,
      drop: finalDrop,
      vehicle: state.selectedVehicle,
      estimatedFare: state.selectedVehicle.estimatedFare,
      status: RideStatus.searching,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      status: RideStatus.searching,
      currentRequest: request,
      pickupLocation: finalPickup,
      dropLocation: finalDrop,
      routeProgress: 0.0,
    );

    _searchTimer?.cancel();
    // Simulate rider matching (2.5 seconds)
    _searchTimer = Timer(const Duration(milliseconds: 2500), () {
      if (state.status == RideStatus.searching) {
        state = state.copyWith(
          status: RideStatus.accepted,
          activeRider: Rider.defaultMockRider,
          currentRequest: state.currentRequest?.copyWith(
            status: RideStatus.accepted,
            rider: Rider.defaultMockRider,
          ),
        );
      }
    });
  }

  /// Sets rider arriving status and begins approach
  void startDriverApproach() {
    state = state.copyWith(
      status: RideStatus.riderArriving,
      etaMinutes: 3,
      etaText: '3 min',
    );
  }

  /// Marks driver as arrived at pickup location
  void markDriverArrived() {
    state = state.copyWith(
      status: RideStatus.arrived,
      etaMinutes: 0,
      etaText: 'Arrived',
    );
  }

  /// Starts trip progression towards destination
  void startTrip() {
    state = state.copyWith(
      status: RideStatus.inProgress,
      routeProgress: 0.1,
      etaMinutes: 8,
      etaText: '8 min',
    );
  }

  /// Updates animated route progress
  void setRouteProgress(double progress) {
    state = state.copyWith(
      routeProgress: progress.clamp(0.0, 1.0),
    );
  }

  /// Completes trip
  void completeTrip() {
    _progressTimer?.cancel();
    state = state.copyWith(
      status: RideStatus.completed,
      routeProgress: 1.0,
      etaMinutes: 0,
      etaText: 'Arrived',
    );
  }

  /// Cancels ride
  void cancelRide() {
    _searchTimer?.cancel();
    _progressTimer?.cancel();
    state = state.copyWith(
      status: RideStatus.cancelled,
      activeRider: null,
      currentRequest: null,
      routeProgress: 0.0,
    );
  }

  /// Resets back to idle
  void resetRide() {
    _searchTimer?.cancel();
    _progressTimer?.cancel();
    state = const RideState();
  }
}

final rideProvider = StateNotifierProvider<RideNotifier, RideState>((ref) {
  return RideNotifier();
});
