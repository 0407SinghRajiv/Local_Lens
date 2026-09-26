import 'package:flutter/material.dart';

/// Lifecycle status for a Lens Ride request
enum RideStatus {
  idle,
  vehicleSelected,
  requesting,
  searching,
  accepted,
  riderArriving,
  arrived,
  started,
  inProgress,
  completed,
  cancelled,
  failed;

  String get label {
    switch (this) {
      case RideStatus.idle:
        return 'Select Ride';
      case RideStatus.vehicleSelected:
        return 'Vehicle Selected';
      case RideStatus.requesting:
        return 'Requesting Ride...';
      case RideStatus.searching:
        return 'Finding your Lens Ride...';
      case RideStatus.accepted:
        return 'Ride Confirmed';
      case RideStatus.riderArriving:
        return 'Driver is Arriving';
      case RideStatus.arrived:
        return 'Driver has Arrived';
      case RideStatus.started:
        return 'Ride Started';
      case RideStatus.inProgress:
        return 'Heading to Destination';
      case RideStatus.completed:
        return 'Arrived at Destination';
      case RideStatus.cancelled:
        return 'Ride Cancelled';
      case RideStatus.failed:
        return 'Ride Request Failed';
    }
  }
}

/// Vehicle type options for Lens Ride
enum VehicleType {
  sedan('Sedan', '4 seats', '5 min away', 180.0, Icons.directions_car_rounded),
  hatchback('Hatchback', '4 seats', '4 min away', 150.0, Icons.directions_car_filled_rounded),
  suv('SUV', '6 seats', '7 min away', 280.0, Icons.airport_shuttle_rounded),
  auto('Auto Rickshaw', '3 seats', '3 min away', 110.0, Icons.electric_rickshaw_rounded),
  bike('Bike', '1 passenger', '2 min away', 80.0, Icons.two_wheeler_rounded);

  final String title;
  final String capacity;
  final String etaText;
  final double baseFare;
  final IconData icon;

  const VehicleType(this.title, this.capacity, this.etaText, this.baseFare, this.icon);
}

/// Vehicle Option model with pricing and arrival
class VehicleOption {
  final VehicleType type;
  final String name;
  final double estimatedFare;
  final int etaMinutes;
  final String capacity;
  final IconData icon;

  const VehicleOption({
    required this.type,
    required this.name,
    required this.estimatedFare,
    required this.etaMinutes,
    required this.capacity,
    required this.icon,
  });

  static List<VehicleOption> get defaultOptions => [
        const VehicleOption(
          type: VehicleType.sedan,
          name: 'Sedan',
          estimatedFare: 180.0,
          etaMinutes: 5,
          capacity: '4 seats',
          icon: Icons.directions_car_rounded,
        ),
        const VehicleOption(
          type: VehicleType.hatchback,
          name: 'Hatchback',
          estimatedFare: 150.0,
          etaMinutes: 4,
          capacity: '4 seats',
          icon: Icons.directions_car_filled_rounded,
        ),
        const VehicleOption(
          type: VehicleType.suv,
          name: 'SUV',
          estimatedFare: 280.0,
          etaMinutes: 7,
          capacity: '6 seats',
          icon: Icons.airport_shuttle_rounded,
        ),
        const VehicleOption(
          type: VehicleType.auto,
          name: 'Auto Rickshaw',
          estimatedFare: 110.0,
          etaMinutes: 3,
          capacity: '3 seats',
          icon: Icons.electric_rickshaw_rounded,
        ),
        const VehicleOption(
          type: VehicleType.bike,
          name: 'Bike',
          estimatedFare: 80.0,
          etaMinutes: 2,
          capacity: '1 passenger',
          icon: Icons.two_wheeler_rounded,
        ),
      ];
}

/// Model representing a verified local rider/driver
class Rider {
  final String id;
  final String name;
  final double rating;
  final String vehicleType;
  final String vehicleNumber;
  final String profileImage;
  final String phone;

  const Rider({
    required this.id,
    required this.name,
    required this.rating,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.profileImage,
    required this.phone,
  });

  static const Rider defaultMockRider = Rider(
    id: 'rider-amit-01',
    name: 'Amit Sharma',
    rating: 4.8,
    vehicleType: 'White Sedan (Maruti Dzire)',
    vehicleNumber: 'MH 04 AB 1234',
    profileImage: 'assets/images/characters/solo.png',
    phone: '+91 98201 23456',
  );
}

/// Model representing a single Lens Ride booking request
class RideRequest {
  final String id;
  final String travelerId;
  final String pickup;
  final String drop;
  final VehicleOption vehicle;
  final double estimatedFare;
  final RideStatus status;
  final Rider? rider;
  final DateTime createdAt;

  const RideRequest({
    required this.id,
    required this.travelerId,
    required this.pickup,
    required this.drop,
    required this.vehicle,
    required this.estimatedFare,
    required this.status,
    this.rider,
    required this.createdAt,
  });

  RideRequest copyWith({
    String? id,
    String? travelerId,
    String? pickup,
    String? drop,
    VehicleOption? vehicle,
    double? estimatedFare,
    RideStatus? status,
    Rider? rider,
    DateTime? createdAt,
  }) {
    return RideRequest(
      id: id ?? this.id,
      travelerId: travelerId ?? this.travelerId,
      pickup: pickup ?? this.pickup,
      drop: drop ?? this.drop,
      vehicle: vehicle ?? this.vehicle,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      status: status ?? this.status,
      rider: rider ?? this.rider,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
