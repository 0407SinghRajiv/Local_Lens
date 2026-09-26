import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/sponsored_experience.dart';

class SponsorService {
  SponsorService._();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
    ),
  );

  /// Fetches ONLY active, paid, and currently valid sponsored campaigns for travelers.
  /// 
  /// Conditions:
  /// - campaign_status = 'active'
  /// - payment_status = 'paid'
  /// - start_at <= NOW()
  /// - end_at > NOW()
  static Future<List<SponsoredExperience>> fetchActiveSponsoredExperiences() async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final List<SponsoredExperience> results = [];

    // 1. Direct Supabase Query
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final data = await client
            .from('sponsor_campaigns')
            .select()
            .eq('campaign_status', 'active')
            .eq('payment_status', 'paid')
            .lte('start_at', nowIso)
            .gt('end_at', nowIso);

        for (final row in data) {
          final map = Map<String, dynamic>.from(row as Map);
          
          // Query related experience if listing_id exists
          if (map['listing_id'] != null) {
            try {
              var expData = await client
                  .from('experience')
                  .select()
                  .eq('experience_id', map['listing_id'])
                  .maybeSingle();

              expData ??= await client
                  .from('experience')
                  .select()
                  .eq('id', map['listing_id'])
                  .maybeSingle();

              if (expData != null) {
                map['experience_details'] = {
                  'image_url': expData['image_url'] ??
                      (expData['images'] is List && (expData['images'] as List).isNotEmpty
                          ? (expData['images'] as List)[0]
                          : null),
                  'rating': expData['rating'] ?? 4.8,
                  'review_count': expData['review_count'] ?? 120,
                  'location': expData['city'] ?? expData['meeting_point'] ?? 'Mumbai',
                  'original_price': expData['price_inr_clean'] ?? expData['price_inr'] ?? 1200,
                };
              }
            } catch (_) {}
          }

          results.add(SponsoredExperience.fromJson(map));
        }
        if (results.isNotEmpty) {
          return results;
        }
      } catch (err) {
        debugPrint('[LocalLens] Supabase direct query notice: $err');
      }
    }

    // 2. LocalLens Active Sponsors API Fallback
    try {
      final host = kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
      final response = await _dio.get('$host/api/sponsors/active');

      if (response.statusCode == 200 && response.data != null) {
        final dynamic data = response.data;
        if (data is Map && data['success'] == true && data['data'] is List) {
          final list = (data['data'] as List)
              .map((item) => SponsoredExperience.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
          return list;
        }
      }
    } catch (e) {
      debugPrint('[LocalLens] Sponsor API fallback notice: $e');
    }

    return results;
  }
}

