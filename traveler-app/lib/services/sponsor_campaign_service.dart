import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/sponsor_campaign_model.dart';

/// Service to fetch sponsored provider campaigns and boosted product listings
/// directly from Supabase table `sponsor_campagin` (and related alias tables).
class SponsorCampaignService {
  final SupabaseClient? client;

  SponsorCampaignService({this.client});

  SupabaseClient? get _supabase => client ?? SupabaseConfig.client;

  /// Fetches sponsored campaigns from Supabase database `sponsor_campagin` table.
  /// Falls back gracefully to default curated sponsored listings if table is empty or offline.
  Future<List<SponsorCampaign>> getSponsoredCampaigns({
    String? category,
    double? userLat,
    double? userLng,
  }) async {
    final supa = _supabase;

    if (supa != null) {
      // Table variations to probe (prioritizing user's exact created table name: sponsor_campagin)
      final tableCandidates = [
        'sponsor_campagin',
        'sponsor_campagins',
        'sponsor_campaigns',
        'sponsor_campaign',
        'sponsored_campaigns',
      ];

      for (final tableName in tableCandidates) {
        try {
          debugPrint('[SponsorCampaignService] Querying Supabase table: $tableName');
          dynamic response;
          try {
            response = await supa.from(tableName).select().limit(25);
          } catch (_) {
            // Retry without strict ordering or limits
            response = await supa.from(tableName).select();
          }

          if (response != null && response is List && response.isNotEmpty) {
            final campaigns = response
                .map((row) => SponsorCampaign.fromJson(row as Map<String, dynamic>))
                .where((c) => c.isActive)
                .toList();

            if (campaigns.isNotEmpty) {
              debugPrint('[SponsorCampaignService] Successfully retrieved ${campaigns.length} campaigns from Supabase table: $tableName');
              return _filterByCategory(campaigns, category);
            }
          }
        } catch (e) {
          debugPrint('[SponsorCampaignService] Table $tableName probe note: $e');
        }
      }
    }

    // Fallback to curated mock sponsored provider campaigns for seamless demo & offline resilience
    debugPrint('[SponsorCampaignService] Using curated sponsored listings');
    final fallbackList = getCuratedSponsoredCampaigns();
    return _filterByCategory(fallbackList, category);
  }

  List<SponsorCampaign> _filterByCategory(List<SponsorCampaign> items, String? category) {
    if (category == null || category.isEmpty || category.toLowerCase() == 'all') {
      return items;
    }
    final filtered = items.where((item) =>
        item.category.toLowerCase().contains(category.toLowerCase()) ||
        category.toLowerCase().contains(item.category.toLowerCase())
    ).toList();

    // If filtered category has no sponsored item, return all to keep UI rich & vibrant
    return filtered.isNotEmpty ? filtered : items;
  }

  /// Curated sponsored provider products matching the LocalLens ecosystem
  static List<SponsorCampaign> getCuratedSponsoredCampaigns() {
    return const [
      SponsorCampaign(
        id: 'sp-1',
        title: 'Sunset Kayaking at Versova Cove',
        providerName: 'SeaBreeze Adventures & Co.',
        category: 'Adventure',
        description: 'Exclusive 2-hour guided twilight paddle with safety gear, dry-bags, and hot cutting chai.',
        imageUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800&q=80',
        priceInr: 1199.0,
        originalPriceInr: 1699.0,
        rating: 4.9,
        reviewCount: 142,
        location: 'Versova Waters, Mumbai',
        distanceKm: 4.8,
        duration: '2.5 hrs',
        badgeText: 'Featured Partner',
        boostTier: 'Festival Surge',
        tags: ['Kayaking', 'Sunset', 'Safety Certified'],
      ),
      SponsorCampaign(
        id: 'sp-2',
        title: 'Authentic Agri-Koli Seafood Thali Masterclass',
        providerName: 'Anandi Mai’s Coastal Kitchen',
        category: 'Food',
        description: 'Taste authentic coastal delicacies with fresh surmai fry, crab masala, and sol kadhi tasting.',
        imageUrl: 'https://images.unsplash.com/photo-1599661046289-e31897846e41?w=800&q=80',
        priceInr: 650.0,
        originalPriceInr: 850.0,
        rating: 4.9,
        reviewCount: 218,
        location: 'Old Panvel Harbor Road',
        distanceKm: 2.1,
        duration: '1.5 hrs',
        badgeText: 'Sponsored Choice',
        boostTier: 'Weekly Push',
        tags: ['Culinary', 'Chef Curated', 'Fresh Catch'],
      ),
      SponsorCampaign(
        id: 'sp-3',
        title: 'Karnala Fortress Guided Eco-Trek & Birding',
        providerName: 'Sahyadri Explorers Guild',
        category: 'Nature',
        description: 'Explore rare bird sanctuaries, 12th-century hill fort ruins, and lush canopy trails with a naturalist.',
        imageUrl: 'https://images.unsplash.com/photo-1587474260584-136574528ed5?w=800&q=80',
        priceInr: 499.0,
        originalPriceInr: 750.0,
        rating: 4.8,
        reviewCount: 384,
        location: 'Karnala Bird Sanctuary, Panvel',
        distanceKm: 9.5,
        duration: '3.5 hrs',
        badgeText: 'Weekend Boost',
        boostTier: 'Weekend Spark',
        tags: ['Eco-Trek', 'Bird Watching', 'Naturalist Guide'],
      ),
      SponsorCampaign(
        id: 'sp-4',
        title: 'Chhatrapati Heritage & Pottery Workshop',
        providerName: 'Artisan Clay Studios & Heritage',
        category: 'Culture',
        description: 'Handcraft your own terracotta pot and tour historic 18th-century wada architecture with master artisans.',
        imageUrl: 'https://images.unsplash.com/photo-1565008447742-97f6f38c985c?w=800&q=80',
        priceInr: 550.0,
        originalPriceInr: 700.0,
        rating: 4.7,
        reviewCount: 96,
        location: 'Heritage Lane, Old Panvel',
        distanceKm: 1.4,
        duration: '2.0 hrs',
        badgeText: 'Verified Provider',
        boostTier: 'Weekly Push',
        tags: ['Hands-on Pottery', 'Culture', 'Take-Home Souvenir'],
      ),
    ];
  }
}
