import 'package:flutter/foundation.dart';

/// Model representing a sponsored campaign / provider product listing
/// fetched from Supabase `sponsor_campagins` (or `sponsor_campaigns`) table.
@immutable
class SponsorCampaign {
  final String id;
  final String title;
  final String providerName;
  final String category;
  final String description;
  final String imageUrl;
  final double priceInr;
  final double? originalPriceInr;
  final double rating;
  final int reviewCount;
  final String location;
  final double distanceKm;
  final String duration;
  final String badgeText;
  final String? boostTier;
  final bool isActive;
  final List<String> tags;

  const SponsorCampaign({
    required this.id,
    required this.title,
    required this.providerName,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.priceInr,
    this.originalPriceInr,
    required this.rating,
    required this.reviewCount,
    required this.location,
    required this.distanceKm,
    required this.duration,
    this.badgeText = 'Sponsored',
    this.boostTier,
    this.isActive = true,
    this.tags = const [],
  });

  /// Calculates discount percentage if original price is available
  int? get discountPercentage {
    if (originalPriceInr != null && originalPriceInr! > priceInr && originalPriceInr! > 0) {
      final diff = originalPriceInr! - priceInr;
      return ((diff / originalPriceInr!) * 100).round();
    }
    return null;
  }

  /// Deserializes from Supabase JSON map supporting both snake_case and camelCase column aliases
  factory SponsorCampaign.fromJson(Map<String, dynamic> json) {
    return SponsorCampaign(
      id: (json['id'] ?? json['campaign_id'] ?? json['experience_id'] ?? '').toString(),
      title: (json['title'] ??
              json['experience_name'] ??
              json['product_name'] ??
              json['name'] ??
              'Sponsored Local Experience')
          .toString(),
      providerName: (json['provider_name'] ??
              json['provider'] ??
              json['vendor_name'] ??
              'LocalLens Verified Host')
          .toString(),
      category: (json['category'] ?? 'Adventure').toString(),
      description: (json['description'] ??
              json['tagline'] ??
              'Featured exclusive local experience curated by top verified hosts.')
          .toString(),
      imageUrl: (json['image_url'] ??
              json['image'] ??
              json['thumbnail_url'] ??
              'assets/images/destinations/sunset_coast.png')
          .toString(),
      priceInr: (json['price_inr'] ??
              json['price'] ??
              json['price_inr_clean'] ??
              json['amount'] ??
              499.0)
          .toDouble(),
      originalPriceInr: json['original_price'] != null
          ? (json['original_price'] as num).toDouble()
          : (json['original_price_inr'] != null
              ? (json['original_price_inr'] as num).toDouble()
              : null),
      rating: ((json['rating'] ?? 4.8) as num).toDouble(),
      reviewCount: (json['review_count'] ??
              json['reviews_count'] ??
              json['reviews'] ??
              120)
          .toInt(),
      location: (json['location'] ??
              json['city'] ??
              json['address'] ??
              'Panvel, Maharashtra')
          .toString(),
      distanceKm: ((json['distance_km'] ??
              json['distance'] ??
              3.5) as num)
          .toDouble(),
      duration: (json['duration'] ??
              (json['duration_hours'] != null
                  ? '${json['duration_hours']} hrs'
                  : '2-3 hrs'))
          .toString(),
      badgeText: (json['badge_text'] ??
              json['badge'] ??
              (json['boost_tier'] != null
                  ? '${json['boost_tier']} Boost'
                  : 'Sponsored'))
          .toString(),
      boostTier: json['boost_tier']?.toString() ?? json['tier']?.toString(),
      isActive: json['is_active'] ??
          (json['status'] == 'active' ||
              json['status'] == 'boosted' ||
              json['status'] == null),
      tags: json['tags'] != null
          ? (json['tags'] as List).map((e) => e.toString()).toList()
          : <String>[],
    );
  }

  /// Serializes to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'provider_name': providerName,
      'category': category,
      'description': description,
      'image_url': imageUrl,
      'price_inr': priceInr,
      'original_price_inr': originalPriceInr,
      'rating': rating,
      'review_count': reviewCount,
      'location': location,
      'distance_km': distanceKm,
      'duration': duration,
      'badge_text': badgeText,
      'boost_tier': boostTier,
      'is_active': isActive,
      'tags': tags,
    };
  }
}
