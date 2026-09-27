import 'package:flutter/material.dart';

/// Category options for itinerary experiences
enum ExperienceCategory {
  food('Food', Icons.restaurant_rounded, Color(0xFFFF6B4A)),
  culture('Culture', Icons.account_balance_rounded, Color(0xFF0E8388)),
  adventure('Adventure', Icons.explore_rounded, Color(0xFFF59E0B)),
  nature('Nature', Icons.park_rounded, Color(0xFF10B981)),
  heritage('Heritage', Icons.castle_rounded, Color(0xFF8B5CF6)),
  beach('Beach', Icons.beach_access_rounded, Color(0xFF06B6D4)),
  shopping('Shopping', Icons.shopping_bag_rounded, Color(0xFFEC4899)),
  nightlife('Nightlife', Icons.nightlife_rounded, Color(0xFF6366F1)),
  photography('Photography', Icons.camera_alt_rounded, Color(0xFF14B8A6)),
  wellness('Wellness', Icons.spa_rounded, Color(0xFF10B981)),
  hiddenGems('Hidden Gems', Icons.auto_awesome_rounded, Color(0xFFF59E0B)),
  localExperiences('Local Experiences', Icons.loyalty_rounded, Color(0xFF0E8388));

  final String label;
  final IconData icon;
  final Color color;

  const ExperienceCategory(this.label, this.icon, this.color);

  static ExperienceCategory fromString(String val) {
    return ExperienceCategory.values.firstWhere(
      (e) => e.label.toLowerCase() == val.toLowerCase(),
      orElse: () => ExperienceCategory.localExperiences,
    );
  }
}

/// Model representing a single stop/experience in an itinerary
class ItineraryItem {
  final String id;
  final String experienceName;
  final String category;
  final String location;
  final String description;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final double price;
  final double distanceKm;
  final String image;
  final bool isCompleted;
  final bool isSelected;
  final bool requiresBooking;
  final double rating;
  final String iconType;
  final int travelToNextMinutes;
  final double travelToNextDistanceKm;
  final double? latitude;
  final double? longitude;
  final double? actualExpense;
  final double? travelerRating;
  final String? travelerReview;
  final DateTime? completedAt;
  final int dwellDurationMinutes;
  final bool arrivedWithinProximity;

  const ItineraryItem({
    required this.id,
    required this.experienceName,
    required this.category,
    required this.location,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.price,
    required this.distanceKm,
    required this.image,
    this.isCompleted = false,
    this.isSelected = true,
    this.requiresBooking = false,
    this.rating = 4.8,
    this.iconType = 'experience',
    this.travelToNextMinutes = 0,
    this.travelToNextDistanceKm = 0.0,
    this.latitude,
    this.longitude,
    this.actualExpense,
    this.travelerRating,
    this.travelerReview,
    this.completedAt,
    this.dwellDurationMinutes = 0,
    this.arrivedWithinProximity = false,
  });

  double get effectiveExpense => actualExpense ?? price;

  bool get isOutdoor {
    final cat = category.toLowerCase();
    final name = experienceName.toLowerCase();
    final desc = description.toLowerCase();
    final combined = '$cat $name $desc';
    return combined.contains('beach') ||
        combined.contains('trek') ||
        combined.contains('hike') ||
        combined.contains('waterfall') ||
        combined.contains('park') ||
        combined.contains('garden') ||
        combined.contains('viewpoint') ||
        combined.contains('promenade') ||
        combined.contains('lake') ||
        combined.contains('outdoor') ||
        combined.contains('coastal') ||
        combined.contains('fort');
  }

  bool get isShelteredIndoor => !isOutdoor;

  ItineraryItem copyWith({
    String? id,
    String? experienceName,
    String? category,
    String? location,
    String? description,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    double? price,
    double? distanceKm,
    String? image,
    bool? isCompleted,
    bool? isSelected,
    bool? requiresBooking,
    double? rating,
    String? iconType,
    int? travelToNextMinutes,
    double? travelToNextDistanceKm,
    double? latitude,
    double? longitude,
    double? actualExpense,
    double? travelerRating,
    String? travelerReview,
    DateTime? completedAt,
    int? dwellDurationMinutes,
    bool? arrivedWithinProximity,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      experienceName: experienceName ?? this.experienceName,
      category: category ?? this.category,
      location: location ?? this.location,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      price: price ?? this.price,
      distanceKm: distanceKm ?? this.distanceKm,
      image: image ?? this.image,
      isCompleted: isCompleted ?? this.isCompleted,
      isSelected: isSelected ?? this.isSelected,
      requiresBooking: requiresBooking ?? this.requiresBooking,
      rating: rating ?? this.rating,
      iconType: iconType ?? this.iconType,
      travelToNextMinutes: travelToNextMinutes ?? this.travelToNextMinutes,
      travelToNextDistanceKm: travelToNextDistanceKm ?? this.travelToNextDistanceKm,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      actualExpense: actualExpense ?? this.actualExpense,
      travelerRating: travelerRating ?? this.travelerRating,
      travelerReview: travelerReview ?? this.travelerReview,
      completedAt: completedAt ?? this.completedAt,
      dwellDurationMinutes: dwellDurationMinutes ?? this.dwellDurationMinutes,
      arrivedWithinProximity: arrivedWithinProximity ?? this.arrivedWithinProximity,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'experienceName': experienceName,
        'category': category,
        'location': location,
        'description': description,
        'startTime': startTime,
        'endTime': endTime,
        'durationMinutes': durationMinutes,
        'price': price,
        'distanceKm': distanceKm,
        'image': image,
        'isCompleted': isCompleted,
        'isSelected': isSelected,
        'requiresBooking': requiresBooking,
        'rating': rating,
        'iconType': iconType,
        'travelToNextMinutes': travelToNextMinutes,
        'travelToNextDistanceKm': travelToNextDistanceKm,
        'latitude': latitude,
        'longitude': longitude,
        'actualExpense': actualExpense,
        'travelerRating': travelerRating,
        'travelerReview': travelerReview,
        'completedAt': completedAt?.toIso8601String(),
        'dwellDurationMinutes': dwellDurationMinutes,
        'arrivedWithinProximity': arrivedWithinProximity,
      };

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    final img = json['image_url'] as String? ??
        json['image'] as String? ??
        'assets/images/destinations/food_trail.png';

    return ItineraryItem(
      id: json['id'] as String? ?? json['experience_id'] as String? ?? '',
      experienceName: json['experience_name'] as String? ??
          json['experienceName'] as String? ??
          json['name'] as String? ??
          '',
      category: json['category'] as String? ?? 'Local Experience',
      location: json['location'] as String? ?? '',
      description: json['description'] as String? ?? '',
      startTime: json['startTime'] as String? ?? json['start_time'] as String? ?? '',
      endTime: json['endTime'] as String? ?? json['end_time'] as String? ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ??
          (json['duration_minutes'] as num?)?.toInt() ??
          60,
      price: (json['price_inr'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0.0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ??
          (json['distanceKm'] as num?)?.toDouble() ??
          (json['travel_to_next_distance_km'] as num?)?.toDouble() ??
          1.0,
      image: img,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isSelected: json['isSelected'] as bool? ?? true,
      requiresBooking: json['requiresBooking'] as bool? ??
          json['booking_required'] as bool? ??
          false,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      iconType: json['iconType'] as String? ?? 'experience',
      travelToNextMinutes: (json['travel_to_next_minutes'] as num?)?.toInt() ?? 0,
      travelToNextDistanceKm: (json['travel_to_next_distance_km'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble() ??
          (json['lat'] as num?)?.toDouble() ??
          double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: (json['longitude'] as num?)?.toDouble() ??
          (json['lon'] as num?)?.toDouble() ??
          (json['lng'] as num?)?.toDouble() ??
          double.tryParse(json['longitude']?.toString() ?? ''),
      actualExpense: (json['actualExpense'] as num?)?.toDouble() ?? (json['actual_expense'] as num?)?.toDouble(),
      travelerRating: (json['travelerRating'] as num?)?.toDouble() ?? (json['traveler_rating'] as num?)?.toDouble(),
      travelerReview: json['travelerReview'] as String? ?? json['traveler_review'] as String?,
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'].toString()) : null,
      dwellDurationMinutes: (json['dwellDurationMinutes'] as num?)?.toInt() ?? 0,
      arrivedWithinProximity: json['arrivedWithinProximity'] as bool? ?? false,
    );
  }

  /// Convenience name getter
  String get name => experienceName;

  /// Formatted time window string
  String get timeWindow => '$startTime - $endTime';

  /// Price in INR
  double get priceInr => price;
}

/// Details of an experience skipped during time/budget optimization
class SkippedExperienceItem {
  final String experienceId;
  final String name;
  final String reason;

  const SkippedExperienceItem({
    required this.experienceId,
    required this.name,
    required this.reason,
  });

  factory SkippedExperienceItem.fromJson(Map<String, dynamic> json) {
    return SkippedExperienceItem(
      experienceId: json['experience_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      reason: json['reason'] as String? ?? 'Insufficient time',
    );
  }
}

/// Model representing the complete generated itinerary
class Itinerary {
  final String id;
  final String destination;
  final String displayAddress;
  final String tripDate;
  final String startTime;
  final String endTime;
  final double? startLat;
  final double? startLon;
  final int totalDurationMinutes;
  final double totalEstimatedCost;
  final double estimatedTransportCost;
  final List<ItineraryItem> items;
  final List<SkippedExperienceItem> skippedExperiences;
  final bool budgetExceeded;
  final String? budgetWarning;
  final DateTime createdAt;
  final bool hasRideAttached;
  final String? attachedRideId;
  final NugenEnhancementData? nugen;

  const Itinerary({
    required this.id,
    required this.destination,
    this.displayAddress = '',
    this.tripDate = '2026-09-26',
    required this.startTime,
    required this.endTime,
    this.startLat,
    this.startLon,
    required this.totalDurationMinutes,
    required this.totalEstimatedCost,
    this.estimatedTransportCost = 0.0,
    required this.items,
    this.skippedExperiences = const [],
    this.budgetExceeded = false,
    this.budgetWarning,
    required this.createdAt,
    this.hasRideAttached = false,
    this.attachedRideId,
    this.nugen,
  });

  /// Returns only items selected by traveler
  List<ItineraryItem> get selectedItems => items.where((item) => item.isSelected).toList();

  /// Dynamic total cost of selected experiences
  double get totalSelectedCost =>
      selectedItems.fold(0.0, (sum, item) => sum + item.price);

  /// Overall total cost (convenience getter)
  double get totalCost => totalSelectedCost > 0 ? totalSelectedCost : totalEstimatedCost;

  /// Dynamic total duration in minutes of selected experiences
  int get totalSelectedDurationMinutes =>
      selectedItems.fold(0, (sum, item) => sum + item.durationMinutes);

  /// Formatted duration string, e.g. "4h 30m"
  String get formattedDuration {
    final totalMins = totalSelectedDurationMinutes > 0
        ? totalSelectedDurationMinutes
        : totalDurationMinutes;
    final hours = totalMins ~/ 60;
    final mins = totalMins % 60;
    if (hours > 0 && mins > 0) {
      return '${hours}h ${mins}m';
    } else if (hours > 0) {
      return '${hours}h';
    }
    return '${mins}m';
  }

  /// Total actual expenses recorded across all stops
  double get totalActualExpenses => items.fold(0.0, (sum, item) => sum + item.effectiveExpense);

  /// Count of stops marked completed
  int get completedStopsCount => items.where((item) => item.isCompleted).length;

  /// Completion progress ratio (0.0 to 1.0)
  double get completionRatio => items.isEmpty ? 0.0 : (completedStopsCount / items.length).clamp(0.0, 1.0);

  /// Whether all scheduled stops are completed
  bool get isFullyCompleted => items.isNotEmpty && completedStopsCount == items.length;

  Itinerary copyWith({
    String? id,
    String? destination,
    String? displayAddress,
    String? tripDate,
    String? startTime,
    String? endTime,
    double? startLat,
    double? startLon,
    int? totalDurationMinutes,
    double? totalEstimatedCost,
    double? estimatedTransportCost,
    List<ItineraryItem>? items,
    List<SkippedExperienceItem>? skippedExperiences,
    bool? budgetExceeded,
    String? budgetWarning,
    DateTime? createdAt,
    bool? hasRideAttached,
    String? attachedRideId,
    NugenEnhancementData? nugen,
  }) {
    return Itinerary(
      id: id ?? this.id,
      destination: destination ?? this.destination,
      displayAddress: displayAddress ?? this.displayAddress,
      tripDate: tripDate ?? this.tripDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startLat: startLat ?? this.startLat,
      startLon: startLon ?? this.startLon,
      totalDurationMinutes: totalDurationMinutes ?? this.totalDurationMinutes,
      totalEstimatedCost: totalEstimatedCost ?? this.totalEstimatedCost,
      estimatedTransportCost: estimatedTransportCost ?? this.estimatedTransportCost,
      items: items ?? this.items,
      skippedExperiences: skippedExperiences ?? this.skippedExperiences,
      budgetExceeded: budgetExceeded ?? this.budgetExceeded,
      budgetWarning: budgetWarning ?? this.budgetWarning,
      createdAt: createdAt ?? this.createdAt,
      hasRideAttached: hasRideAttached ?? this.hasRideAttached,
      attachedRideId: attachedRideId ?? this.attachedRideId,
      nugen: nugen ?? this.nugen,
    );
  }
}

/// Nugen AI Enhancement & Validation Layer outcome
class NugenEnhancementData {
  final bool enabled;
  final String status;
  final Map<String, dynamic> validation;
  final List<Map<String, dynamic>> issues;
  final List<Map<String, dynamic>> enhancements;
  final List<Map<String, dynamic>> personalizedTips;
  final List<Map<String, dynamic>> finalRecommendations;
  final Map<String, dynamic>? weather;

  const NugenEnhancementData({
    this.enabled = true,
    this.status = 'success',
    this.validation = const {},
    this.issues = const [],
    this.enhancements = const [],
    this.personalizedTips = const [],
    this.finalRecommendations = const [],
    this.weather,
  });

  factory NugenEnhancementData.fromJson(Map<String, dynamic> json) {
    return NugenEnhancementData(
      enabled: json['enabled'] as bool? ?? true,
      status: json['status'] as String? ?? 'success',
      validation: (json['validation'] as Map<String, dynamic>?) ?? {},
      issues: (json['issues'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
      enhancements: (json['enhancements'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
      personalizedTips: (json['personalized_tips'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
      finalRecommendations: (json['final_recommendations'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
      weather: (json['weather'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'status': status,
    'validation': validation,
    'issues': issues,
    'enhancements': enhancements,
    'personalized_tips': personalizedTips,
    'final_recommendations': finalRecommendations,
    if (weather != null) 'weather': weather,
  };
}
