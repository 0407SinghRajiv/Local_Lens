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

  /// Checks whether this experience matches a category to exclude (e.g. "Food", "Beach", "Heritage")
  bool matchesExcludedCategory(String excludedCategory) {
    final ex = excludedCategory.trim().toLowerCase();
    if (ex.isEmpty) return false;

    final cat = category.toLowerCase();
    final sub = (subCategory ?? '').toLowerCase();
    final nm = name.toLowerCase();
    final tg = (tags ?? '').toLowerCase();
    final reas = reason.toLowerCase();

    final allText = '$cat $sub $nm $tg $reas';

    if (ex == 'food' || ex == 'dining' || ex == 'cuisine') {
      const foodKeywords = [
        'food', 'street food', 'local cuisine', 'seafood', 'dining', 'restaurant',
        'cafe', 'eatery', 'bakery', 'snack', 'breakfast', 'lunch', 'dinner',
        'misal', 'pav', 'dish', 'tasting', 'eats', 'culinary', 'chaat', 'dhaba'
      ];
      return foodKeywords.any((k) => allText.contains(k));
    }

    if (ex == 'beach' || ex == 'beaches' || ex == 'coastal') {
      const beachKeywords = ['beach', 'coastal', 'shore', 'sea', 'ocean', 'coast', 'water sports'];
      return beachKeywords.any((k) => allText.contains(k));
    }

    if (ex == 'adventure' || ex == 'trek' || ex == 'trekking') {
      const advKeywords = ['adventure', 'trek', 'trekking', 'hiking', 'climb', 'sports', 'boat ride', 'kayak', 'rafting'];
      return advKeywords.any((k) => allText.contains(k));
    }

    if (ex == 'heritage' || ex == 'fort' || ex == 'monument') {
      const herKeywords = ['heritage', 'fort', 'monument', 'palace', 'historic', 'caves', 'ruins'];
      return herKeywords.any((k) => allText.contains(k));
    }

    if (ex == 'culture' || ex == 'temple' || ex == 'spiritual') {
      const cultKeywords = ['culture', 'temple', 'museum', 'spiritual', 'religious', 'monastery', 'art', 'workshop'];
      return cultKeywords.any((k) => allText.contains(k));
    }

    if (ex == 'nature' || ex == 'wildlife' || ex == 'park') {
      const natureKeywords = ['nature', 'wildlife', 'waterfall', 'bird watching', 'park', 'garden', 'forest', 'lake', 'viewpoint'];
      return natureKeywords.any((k) => allText.contains(k));
    }

    if (ex == 'shopping' || ex == 'market') {
      const shopKeywords = ['shopping', 'market', 'bazaar', 'mall', 'handicraft', 'souvenir'];
      return shopKeywords.any((k) => allText.contains(k));
    }

    if (ex == 'nightlife' || ex == 'pub' || ex == 'club') {
      const nightKeywords = ['nightlife', 'bar', 'pub', 'club', 'lounge', 'brewery'];
      return nightKeywords.any((k) => allText.contains(k));
    }

    return allText.contains(ex);
  }

  /// Checks whether this experience matches a specific interest category (e.g. "Beach", "Food", "Adventure")
  bool matchesInterest(String interest) {
    final intr = interest.trim().toLowerCase();
    if (intr.isEmpty) return true;

    final cat = category.toLowerCase();
    final sub = (subCategory ?? '').toLowerCase();
    final nm = name.toLowerCase();
    final tg = (tags ?? '').toLowerCase();
    final reas = reason.toLowerCase();
    final allText = '$cat $sub $nm $tg $reas';

    if (intr == 'beach' || intr == 'beaches' || intr == 'coastal') {
      const beachKw = ['beach', 'coastal', 'shore', 'sea', 'ocean', 'coast', 'water sports'];
      return beachKw.any((k) => allText.contains(k));
    }
    if (intr == 'food' || intr == 'dining' || intr == 'cuisine') {
      const foodKw = [
        'food', 'street food', 'local cuisine', 'seafood', 'dining', 'restaurant',
        'cafe', 'eatery', 'bakery', 'snack', 'breakfast', 'lunch', 'dinner',
        'misal', 'pav', 'dish', 'tasting', 'eats', 'culinary', 'chaat', 'dhaba'
      ];
      return foodKw.any((k) => allText.contains(k));
    }
    if (intr == 'adventure' || intr == 'trek' || intr == 'trekking') {
      const advKw = ['adventure', 'trek', 'trekking', 'hiking', 'climb', 'sports', 'boat ride', 'kayak', 'rafting', 'water sports'];
      return advKw.any((k) => allText.contains(k));
    }
    if (intr == 'heritage' || intr == 'fort' || intr == 'monument') {
      const herKw = ['heritage', 'fort', 'monument', 'palace', 'historic', 'caves', 'ruins', 'history'];
      return herKw.any((k) => allText.contains(k));
    }
    if (intr == 'culture' || intr == 'temple' || intr == 'spiritual') {
      const cultKw = ['culture', 'temple', 'museum', 'spiritual', 'religious', 'monastery', 'art', 'workshop', 'handicraft'];
      return cultKw.any((k) => allText.contains(k));
    }
    if (intr == 'nature' || intr == 'wildlife' || intr == 'park') {
      const natKw = ['nature', 'wildlife', 'waterfall', 'bird watching', 'park', 'garden', 'forest', 'lake', 'viewpoint', 'valley', 'hills'];
      return natKw.any((k) => allText.contains(k));
    }
    if (intr == 'shopping' || intr == 'market') {
      const shopKw = ['shopping', 'market', 'bazaar', 'mall', 'handicraft', 'souvenir', 'bazaars'];
      return shopKw.any((k) => allText.contains(k));
    }
    if (intr == 'nightlife' || intr == 'pub' || intr == 'club') {
      const nightKw = ['nightlife', 'bar', 'pub', 'club', 'lounge', 'brewery'];
      return nightKw.any((k) => allText.contains(k));
    }
    if (intr == 'wellness' || intr == 'spa') {
      const wellKw = ['wellness', 'spa', 'yoga', 'meditation', 'retreat'];
      return wellKw.any((k) => allText.contains(k));
    }
    return allText.contains(intr);
  }

  /// Checks whether this experience matches ANY of the traveler's selected interests
  bool matchesAnyInterest(List<String> interests) {
    if (interests.isEmpty) return true;
    return interests.any((intr) => matchesInterest(intr));
  }

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
