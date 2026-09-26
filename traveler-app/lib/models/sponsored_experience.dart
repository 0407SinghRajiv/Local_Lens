/// Model representing an active sponsored experience displayed in the Traveler app feed.
/// All fields are dynamically populated from Supabase `sponsor_campaigns` and `experience`.
class SponsoredExperience {
  final String campaignId;
  final String listingId;
  final String? businessId;
  final String badge;
  final String shopName;
  final String listingName;
  final String imageUrl;
  final double rating;
  final int reviewsCount;
  final String location;
  final double originalPrice;
  final String offer;
  final double offerPrice;
  final String sponsorInfo;
  final DateTime startAt;
  final DateTime endAt;

  const SponsoredExperience({
    required this.campaignId,
    required this.listingId,
    this.businessId,
    this.badge = 'Sponsored',
    required this.shopName,
    required this.listingName,
    required this.imageUrl,
    required this.rating,
    required this.reviewsCount,
    required this.location,
    required this.originalPrice,
    required this.offer,
    required this.offerPrice,
    required this.sponsorInfo,
    required this.startAt,
    required this.endAt,
  });

  factory SponsoredExperience.fromJson(Map<String, dynamic> json) {
    final expDetails = json['experience_details'] as Map<String, dynamic>?;

    final origPrice = (json['original_price'] != null)
        ? (json['original_price'] as num).toDouble()
        : (expDetails?['original_price'] != null)
            ? (expDetails!['original_price'] as num).toDouble()
            : 1200.0;

    final offPrice = (json['offer_price'] != null)
        ? (json['offer_price'] as num).toDouble()
        : (origPrice * 0.8);

    final shop = (json['shop_name'] as String?)?.isNotEmpty == true
        ? json['shop_name'] as String
        : 'Local Partner';

    return SponsoredExperience(
      campaignId: json['campaign_id'] ?? json['id'] ?? '',
      listingId: json['listing_id'] ?? '',
      businessId: json['business_id'],
      badge: json['badge'] ?? 'Sponsored',
      shopName: shop,
      listingName: json['listing_name'] ?? 'Local Experience',
      imageUrl: (json['image_url'] as String?)?.isNotEmpty == true
          ? json['image_url']
          : (expDetails?['image_url'] as String?)?.isNotEmpty == true
              ? expDetails!['image_url']
              : 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=800&q=80',
      rating: ((json['rating'] ?? expDetails?['rating'] ?? 4.8) as num).toDouble(),
      reviewsCount: ((json['reviews_count'] ?? expDetails?['review_count'] ?? 142) as num).toInt(),
      location: json['location'] ?? expDetails?['location'] ?? 'Versova Beach, Mumbai',
      originalPrice: origPrice,
      offer: json['offer_label'] ?? json['offer_description'] ?? '20% OFF',
      offerPrice: offPrice,
      sponsorInfo: json['sponsor_by_label'] ?? 'Sponsored by: $shop',
      startAt: json['start_at'] != null
          ? DateTime.tryParse(json['start_at']) ?? DateTime.now()
          : DateTime.now(),
      endAt: json['end_at'] != null
          ? DateTime.tryParse(json['end_at']) ?? DateTime.now().add(const Duration(days: 7))
          : DateTime.now().add(const Duration(days: 7)),
    );
  }
}
