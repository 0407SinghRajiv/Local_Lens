import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import '../models/sponsored_experience.dart';

class SponsorService {
  SponsorService._();

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

        if (data is List) {
          for (final row in data) {
            final map = Map<String, dynamic>.from(row as Map);
            
            // Query related experience if listing_id exists
            if (map['listing_id'] != null) {
              try {
                final expData = await client
                    .from('experience')
                    .select()
                    .eq('experience_id', map['listing_id'])
                    .maybeSingle();

                if (expData != null) {
                  map['experience_details'] = {
                    'image_url': expData['image_url'],
                    'rating': expData['rating'],
                    'review_count': expData['review_count'],
                    'location': expData['city'] ?? 'Mumbai',
                    'original_price': expData['price_inr_clean'] ?? 1200,
                  };
                }
              } catch (_) {}
            }

            results.add(SponsoredExperience.fromJson(map));
          }
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
      final response = await http
          .get(Uri.parse('$host/api/sponsors/active'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] is List) {
          final list = (decoded['data'] as List)
              .map((item) => SponsoredExperience.fromJson(Map<String, dynamic>.from(item)))
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
