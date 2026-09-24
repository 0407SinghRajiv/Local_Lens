class Driver {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String email;
  final String vehicleType;
  final String vehicleNumber;
  final String vehicleModel;
  final String profileImageUrl;
  final double rating;
  final int totalRides;
  final double todayEarnings;
  final int todayRides;
  bool isOnline;
  bool isAvailable;
  double latitude;
  double longitude;
  final DateTime? updatedAt;

  Driver({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.vehicleModel,
    this.profileImageUrl = '',
    this.rating = 4.8,
    this.totalRides = 342,
    this.todayEarnings = 1250.0,
    this.todayRides = 5,
    this.isOnline = false,
    this.isAvailable = false,
    this.latitude = 19.0760,
    this.longitude = 72.8777,
    this.updatedAt,
  });

  Driver copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? email,
    String? vehicleType,
    String? vehicleNumber,
    String? vehicleModel,
    String? profileImageUrl,
    double? rating,
    int? totalRides,
    double? todayEarnings,
    int? todayRides,
    bool? isOnline,
    bool? isAvailable,
    double? latitude,
    double? longitude,
    DateTime? updatedAt,
  }) {
    return Driver(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      todayRides: todayRides ?? this.todayRides,
      isOnline: isOnline ?? this.isOnline,
      isAvailable: isAvailable ?? this.isAvailable,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Mock driver for development
  static Driver mock() {
    return Driver(
      id: 'driver_001',
      userId: 'user_001',
      name: 'Amit Verma',
      phone: '+91 98765 43210',
      email: 'driver@nearbyride.com',
      vehicleType: 'Sedan',
      vehicleNumber: 'MH 04 AB 1234',
      vehicleModel: 'Maruti Suzuki Dzire',
      profileImageUrl: '',
      rating: 4.85,
      totalRides: 342,
      todayEarnings: 1250.0,
      todayRides: 5,
      isOnline: false,
      isAvailable: false,
      latitude: 19.0760,
      longitude: 72.8777,
      updatedAt: DateTime.now(),
    );
  }
}
