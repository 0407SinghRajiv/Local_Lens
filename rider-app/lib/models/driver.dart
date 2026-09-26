class Driver {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String email;
  final String vehicleType;
  final String vehicleNumber;
  final String vehicleModel;
  final String vehicleColor;
  final String profileImageUrl;
  final String licenseNumber;
  final String licenseVerificationStatus;
  final String licenseVerificationMethod;
  final DateTime? licenseVerifiedAt;
  final String city;
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
    this.vehicleColor = 'White',
    this.profileImageUrl = '',
    this.licenseNumber = '',
    this.licenseVerificationStatus = 'not_uploaded',
    this.licenseVerificationMethod = 'ocr',
    this.licenseVerifiedAt,
    this.city = '',
    this.rating = 4.8,
    this.totalRides = 0,
    this.todayEarnings = 0.0,
    this.todayRides = 0,
    this.isOnline = false,
    this.isAvailable = false,
    this.latitude = 19.0760,
    this.longitude = 72.8777,
    this.updatedAt,
  });

  /// Check if the driver has completed onboarding (valid real phone, vehicle plate & DL)
  bool get isProfileCompleted {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final cleanVehicle = vehicleNumber.replaceAll(RegExp(r'\s+'), '');
    final cleanLicense = licenseNumber.replaceAll(RegExp(r'\s+'), '');
    return name.trim().isNotEmpty &&
        cleanPhone.isNotEmpty &&
        cleanPhone != '+919876543210' &&
        cleanVehicle.isNotEmpty &&
        cleanVehicle != 'MH04AB1234' &&
        vehicleModel.trim().isNotEmpty &&
        cleanLicense.isNotEmpty;
  }

  Driver copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? email,
    String? vehicleType,
    String? vehicleNumber,
    String? vehicleModel,
    String? vehicleColor,
    String? profileImageUrl,
    String? licenseNumber,
    String? licenseVerificationStatus,
    String? licenseVerificationMethod,
    DateTime? licenseVerifiedAt,
    String? city,
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
    final newId = id ?? this.id;
    return Driver(
      id: newId,
      userId: userId ?? id ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseVerificationStatus: licenseVerificationStatus ?? this.licenseVerificationStatus,
      licenseVerificationMethod: licenseVerificationMethod ?? this.licenseVerificationMethod,
      licenseVerifiedAt: licenseVerifiedAt ?? this.licenseVerifiedAt,
      city: city ?? this.city,
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
      vehicleColor: 'White',
      profileImageUrl: '',
      licenseNumber: 'MH1420210012345',
      licenseVerificationStatus: 'verified_format',
      licenseVerificationMethod: 'ocr',
      licenseVerifiedAt: DateTime.now(),
      city: 'Mumbai',
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
