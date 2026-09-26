/// Recommendation Model for ML-ranked experiences
class RecommendationModel {
  final String experienceId;
  final String name;
  final String? imageUrl;
  final String image;
  final String category;
  final String? subCategory;
  final String location;
  final String city;
  final int durationMinutes;
  final double durationHours;
  final double price;
  final double? priceInr;
  final double? rating;
  final int? reviewCount;
  final String reason;
  final double score;
  final double? recommendationScore;
  final double? latitude;
  final double? longitude;
  final String? tags;
  final String? bestFor;
  final double? distanceKm;
  final bool localExperience;
  final bool hiddenGem;
  final String indoorOutdoor;
  final bool bookingRequired;

  const RecommendationModel({
    required this.experienceId,
    required this.name,
    this.imageUrl,
    required this.image,
    required this.category,
    this.subCategory,
    required this.location,
    required this.city,
    required this.durationMinutes,
    required this.durationHours,
    required this.price,
    this.priceInr,
    this.rating,
    this.reviewCount,
    required this.reason,
    required this.score,
    this.recommendationScore,
    this.latitude,
    this.longitude,
    this.tags,
    this.bestFor,
    this.distanceKm,
    this.localExperience = true,
    this.hiddenGem = false,
    this.indoorOutdoor = 'Flexible',
    this.bookingRequired = false,
  });

  String get experienceName => name;

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    final imgUrl = json['image_url'] as String? ?? json['image'] as String?;
    final resolvedImage = imgUrl != null && imgUrl.isNotEmpty
        ? imgUrl
        : 'assets/images/destinations/food_trail.png';

    final p = (json['price_inr'] as num?)?.toDouble() ??
        (json['price'] as num?)?.toDouble() ??
        0.0;

    final sc = (json['recommendation_score'] as num?)?.toDouble() ??
        (json['score'] as num?)?.toDouble() ??
        0.85;

    final durH = (json['duration_hours'] as num?)?.toDouble() ?? 1.0;
    final durM = (json['duration_minutes'] as num?)?.toInt() ?? (durH * 60).toInt();

    return RecommendationModel(
      experienceId: json['experience_id'] as String? ?? '',
      name: json['experience_name'] as String? ?? json['name'] as String? ?? 'Local Experience',
      imageUrl: imgUrl,
      image: resolvedImage,
      category: json['category'] as String? ?? 'Local Experience',
      subCategory: json['sub_category'] as String?,
      location: json['location'] as String? ?? json['city'] as String? ?? '',
      city: json['city'] as String? ?? '',
      durationMinutes: durM,
      durationHours: durH,
      price: p,
      priceInr: p,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['review_count'] as num?)?.toInt(),
      reason: json['reason'] as String? ?? 'Recommended for you based on your preferences',
      score: sc,
      recommendationScore: sc,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      tags: json['tags'] is List ? (json['tags'] as List).join('; ') : json['tags'] as String?,
      bestFor: json['best_for'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      localExperience: json['local_experience'] as bool? ?? true,
      hiddenGem: json['hidden_gem'] as bool? ?? false,
      indoorOutdoor: json['indoor_outdoor'] as String? ?? 'Flexible',
      bookingRequired: json['booking_required'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'experience_id': experienceId,
        'experience_name': name,
        'name': name,
        'image_url': imageUrl,
        'image': image,
        'category': category,
        'sub_category': subCategory,
        'location': location,
        'city': city,
        'duration_minutes': durationMinutes,
        'duration_hours': durationHours,
        'price': price,
        'price_inr': priceInr,
        'rating': rating,
        'review_count': reviewCount,
        'reason': reason,
        'score': score,
        'recommendation_score': recommendationScore,
        'latitude': latitude,
        'longitude': longitude,
        'tags': tags,
        'best_for': bestFor,
        'distance_km': distanceKm,
        'local_experience': localExperience,
        'hidden_gem': hiddenGem,
        'indoor_outdoor': indoorOutdoor,
        'booking_required': bookingRequired,
      };
}
