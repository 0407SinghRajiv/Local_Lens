import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/itinerary_model.dart';
import '../models/recommendation_model.dart';

class ItineraryApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  static String? _cachedBaseUrl;

  /// Candidate URLs in priority order for physical devices, emulators, and localhost
  static List<String> get candidateUrls {
    final list = <String>[];
    final envUrl = dotenv.env['API_BASE_URL']?.trim();
    if (envUrl != null && envUrl.isNotEmpty) {
      list.add(envUrl.replaceAll(RegExp(r'/+$'), ''));
    }

    // Wi-Fi LAN & Hotspot host IPs for physical devices
    list.add('http://192.168.137.210:8000');
    list.add('http://192.168.137.1:8000');

    // Android Emulator host loopback
    if (!kIsWeb && Platform.isAndroid) {
      list.add('http://10.0.2.2:8000');
    }

    // Localhost / ADB reverse port forwarding (adb reverse tcp:8000 tcp:8000)
    list.add('http://127.0.0.1:8000');
    list.add('http://localhost:8000');

    return list.toSet().toList();
  }

  /// Automatically discovers the reachable backend endpoint
  static Future<String> resolveBaseUrl() async {
    if (_cachedBaseUrl != null) {
      try {
        final ping = await _dio.get(
          '$_cachedBaseUrl/health',
          options: Options(
            receiveTimeout: const Duration(milliseconds: 1200),
            sendTimeout: const Duration(milliseconds: 1200),
          ),
        );
        if (ping.statusCode == 200) {
          return _cachedBaseUrl!;
        }
      } catch (_) {
        _cachedBaseUrl = null;
      }
    }

    // Probe candidates
    for (final candidate in candidateUrls) {
      try {
        final probeDio = Dio(BaseOptions(
          connectTimeout: const Duration(milliseconds: 1500),
          receiveTimeout: const Duration(milliseconds: 1500),
        ));
        final res = await probeDio.get('$candidate/health');
        if (res.statusCode == 200) {
          debugPrint('[ItineraryApiService] Connected to backend at: $candidate');
          _cachedBaseUrl = candidate;
          return candidate;
        }
      } catch (_) {
        // Try next candidate
      }
    }

    // Default fallback
    final fallback = candidateUrls.isNotEmpty ? candidateUrls.first : 'http://127.0.0.1:8000';
    _cachedBaseUrl = fallback;
    return fallback;
  }

  static String get baseUrl => _cachedBaseUrl ?? (candidateUrls.isNotEmpty ? candidateUrls.first : 'http://127.0.0.1:8000');

  /// 1. Fetch ML Recommendations
  static Future<List<RecommendationModel>> fetchRecommendations({
    required String destination,
    String? startLocation,
    double? startLat,
    double? startLon,
    required double budget,
    required double durationHours,
    required int travelerCount,
    required String travelerType,
    required List<String> interests,
    String? preferences,
  }) async {
    final activeBase = await resolveBaseUrl();
    final url = '$activeBase/api/recommendations';
    final payload = {
      'destination': destination,
      'start_location': startLocation,
      'start_lat': startLat,
      'start_lon': startLon,
      'user_lat': startLat,
      'user_lon': startLon,
      'budget': budget,
      'budget_inr': budget,
      'duration_hours': durationHours,
      'available_time_hours': durationHours,
      'traveler_count': travelerCount,
      'traveler_type': travelerType,
      'group_type': travelerType,
      'interests': interests,
      'radius_km': 25.0,
      'additional_preferences': preferences != null && preferences.isNotEmpty ? {'notes': preferences} : {},
      'top_n': 10,
    };

    try {
      final response = await _dio.post(url, data: payload);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        if (data['success'] == true && data['recommendations'] != null) {
          final List list = data['recommendations'] as List;
          debugPrint('[ItineraryApiService] Received ${list.length} ML recommendations from $activeBase');
          return list.map((item) => RecommendationModel.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('ItineraryApiService.fetchRecommendations error: $e');
    }

    // Fallback if backend is unreachable
    return _buildFallbackRecommendations(destination, interests, budget);
  }

  /// 2. Generate Chronological Itinerary from selected experiences + trip start time
  static Future<Itinerary> generateItinerary({
    required String destination,
    required String tripDate,
    required String startTime,
    required double durationHours,
    required double budget,
    String? startLocation,
    double? startLat,
    double? startLon,
    required List<String> selectedExperienceIds,
    required int travelerCount,
    required String travelerType,
  }) async {
    final activeBase = await resolveBaseUrl();
    final url = '$activeBase/api/itinerary/generate';
    final payload = {
      'destination': destination,
      'trip_date': tripDate,
      'start_time': startTime,
      'duration_hours': durationHours,
      'available_time_hours': durationHours,
      'budget': budget,
      'budget_inr': budget,
      'start_location': startLocation,
      'start_lat': startLat,
      'start_lon': startLon,
      'user_lat': startLat,
      'user_lon': startLon,
      'selected_experience_ids': selectedExperienceIds,
      'traveler_count': travelerCount,
      'traveler_type': travelerType,
      'group_type': travelerType,
    };

    try {
      final response = await _dio.post(url, data: payload);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        if (data['success'] == true) {
          final List rawStops = data['scheduled_experiences'] as List? ?? [];
          final items = rawStops.map((s) => ItineraryItem.fromJson(s as Map<String, dynamic>)).toList();

          final List rawSkipped = data['skipped_experiences'] as List? ?? [];
          final skipped = rawSkipped.map((s) => SkippedExperienceItem.fromJson(s as Map<String, dynamic>)).toList();

          debugPrint('[ItineraryApiService] Generated itinerary with ${items.length} scheduled stops from $activeBase');
          return Itinerary(
            id: 'itin-${DateTime.now().millisecondsSinceEpoch}',
            destination: data['destination'] as String? ?? destination,
            displayAddress: startLocation ?? '',
            tripDate: data['trip_date'] as String? ?? tripDate,
            startTime: data['start_time'] as String? ?? startTime,
            endTime: data['end_time'] as String? ?? '05:00 PM',
            totalDurationMinutes: (data['total_duration_minutes'] as num?)?.toInt() ?? 360,
            totalEstimatedCost: (data['total_experience_cost'] as num?)?.toDouble() ?? budget,
            estimatedTransportCost: (data['estimated_transport_cost'] as num?)?.toDouble() ?? 0.0,
            budgetExceeded: data['budget_exceeded'] as bool? ?? false,
            budgetWarning: data['budget_warning'] as String?,
            items: items,
            skippedExperiences: skipped,
            createdAt: DateTime.now(),
          );
        }
      }
    } catch (e) {
      debugPrint('ItineraryApiService.generateItinerary error: $e');
    }

    // Fallback if backend is unreachable
    return _buildFallbackItinerary(
      destination: destination,
      tripDate: tripDate,
      startTime: startTime,
      durationHours: durationHours,
      budget: budget,
      selectedIds: selectedExperienceIds,
    );
  }

  static List<RecommendationModel> _buildFallbackRecommendations(
    String destination,
    List<String> interests,
    double budget,
  ) {
    final dest = destination.isNotEmpty ? destination : 'Mumbai';
    return [
      RecommendationModel(
        experienceId: 'EXP-DELHI-001',
        name: 'Heritage Fortress & Walk',
        category: 'Heritage',
        location: '$dest Old Quarter',
        city: dest,
        durationMinutes: 90,
        durationHours: 1.5,
        price: 350.0,
        rating: 4.8,
        reviewCount: 450,
        reason: 'Top-rated historical landmark matching your interests',
        score: 0.94,
        image: 'assets/images/destinations/heritage_walk.png',
        latitude: 18.9894,
        longitude: 73.1175,
        localExperience: true,
        hiddenGem: false,
      ),
      RecommendationModel(
        experienceId: 'EXP-DELHI-002',
        name: 'Authentic Local Breakfast & Chai Walk',
        category: 'Food',
        location: '$dest Market',
        city: dest,
        durationMinutes: 60,
        durationHours: 1.0,
        price: 250.0,
        rating: 4.9,
        reviewCount: 620,
        reason: 'Matches your food interest and fits your budget',
        score: 0.92,
        image: 'assets/images/destinations/food_trail.png',
        latitude: 18.9950,
        longitude: 73.1200,
        localExperience: true,
        hiddenGem: true,
      ),
      RecommendationModel(
        experienceId: 'EXP-DELHI-003',
        name: 'Artisan Workshop & Crafts',
        category: 'Culture',
        location: '$dest Craft Village',
        city: dest,
        durationMinutes: 75,
        durationHours: 1.25,
        price: 450.0,
        rating: 4.7,
        reviewCount: 280,
        reason: 'Interactive hands-on cultural workshop with local artisans',
        score: 0.88,
        image: 'assets/images/destinations/beach_cafe.png',
        latitude: 19.0010,
        longitude: 73.1250,
        localExperience: true,
        hiddenGem: true,
      ),
      RecommendationModel(
        experienceId: 'EXP-DELHI-004',
        name: 'Scenic Valley Trail & Sunset View',
        category: 'Nature',
        location: '$dest Foothills',
        city: dest,
        durationMinutes: 90,
        durationHours: 1.5,
        price: 200.0,
        rating: 4.9,
        reviewCount: 510,
        reason: 'Peaceful nature experience with panoramic viewpoint',
        score: 0.86,
        image: 'assets/images/destinations/waterfall.png',
        latitude: 19.0100,
        longitude: 73.1300,
        localExperience: true,
        hiddenGem: false,
      ),
    ];
  }

  static Itinerary _buildFallbackItinerary({
    required String destination,
    required String tripDate,
    required String startTime,
    required double durationHours,
    required double budget,
    required List<String> selectedIds,
  }) {
    final recs = _buildFallbackRecommendations(destination, [], budget);
    final chosen = recs.where((r) => selectedIds.contains(r.experienceId) || selectedIds.isEmpty).toList();
    final itemsToUse = chosen.isNotEmpty ? chosen : recs.take(3).toList();

    // Parse start time (e.g. 10:30 AM)
    int curHour = 10;
    int curMin = 30;
    final parts = startTime.replaceAll(RegExp(r'[^\d:]'), '').split(':');
    if (parts.isNotEmpty) {
      curHour = int.tryParse(parts[0]) ?? 10;
      if (startTime.toUpperCase().contains('PM') && curHour < 12) curHour += 12;
      if (startTime.toUpperCase().contains('AM') && curHour == 12) curHour = 0;
      if (parts.length > 1) curMin = int.tryParse(parts[1]) ?? 30;
    }

    final List<ItineraryItem> items = [];
    double totalCost = 0;
    int totalMins = 0;

    for (int i = 0; i < itemsToUse.length; i++) {
      final r = itemsToUse[i];
      final startStr = _formatTime(curHour, curMin);

      curMin += r.durationMinutes;
      curHour += curMin ~/ 60;
      curMin = curMin % 60;

      final endStr = _formatTime(curHour, curMin);

      // 15 min travel to next
      curMin += 15;
      curHour += curMin ~/ 60;
      curMin = curMin % 60;

      items.add(ItineraryItem(
        id: r.experienceId,
        experienceName: r.name,
        category: r.category,
        location: r.location,
        description: r.reason,
        startTime: startStr,
        endTime: endStr,
        durationMinutes: r.durationMinutes,
        price: r.price,
        distanceKm: 2.5,
        image: r.image,
        rating: r.rating ?? 4.8,
        travelToNextMinutes: i < itemsToUse.length - 1 ? 15 : 0,
        travelToNextDistanceKm: i < itemsToUse.length - 1 ? 2.5 : 0.0,
      ));

      totalCost += r.price;
      totalMins += r.durationMinutes + 15;
    }

    return Itinerary(
      id: 'itin-${DateTime.now().millisecondsSinceEpoch}',
      destination: destination.isNotEmpty ? destination : 'Mumbai',
      tripDate: tripDate,
      startTime: startTime,
      endTime: items.isNotEmpty ? items.last.endTime : '05:00 PM',
      totalDurationMinutes: totalMins,
      totalEstimatedCost: totalCost,
      estimatedTransportCost: 120.0,
      items: items,
      createdAt: DateTime.now(),
    );
  }

  static String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }
}
