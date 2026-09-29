import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Coordinates record containing latitude and longitude
class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);

  @override
  String toString() => '($latitude, $longitude)';
}

/// Geocoding & City Coordinates Resolution Service
/// Single source of truth for converting city names to geographic coordinates
/// and GPS coordinates to human-readable names.
class GeocodingService {
  static final Map<String, String> _reverseCache = {};

  /// Comprehensive coordinates dictionary for Indian and global destinations
  static const Map<String, GeoPoint> cityCoordinates = {
    'mumbai': GeoPoint(19.0760, 72.8777),
    'south mumbai': GeoPoint(18.9220, 72.8347),
    'navi mumbai': GeoPoint(19.0330, 73.0297),
    'thane': GeoPoint(19.2183, 72.9781),
    'pune': GeoPoint(18.5204, 73.8567),
    'nashik': GeoPoint(19.9975, 73.7898),
    'delhi': GeoPoint(28.6139, 77.2090),
    'new delhi': GeoPoint(28.6139, 77.2090),
    'jaipur': GeoPoint(26.9124, 75.7873),
    'udaipur': GeoPoint(24.5854, 73.7125),
    'jodhpur': GeoPoint(26.2389, 73.0243),
    'jaisalmer': GeoPoint(26.9157, 70.9083),
    'goa': GeoPoint(15.2993, 74.1240),
    'north goa': GeoPoint(15.4909, 73.8278),
    'south goa': GeoPoint(15.2736, 73.9582),
    'panaji': GeoPoint(15.4909, 73.8278),
    'calangute': GeoPoint(15.5439, 73.7553),
    'baga': GeoPoint(15.5553, 73.7517),
    'bangalore': GeoPoint(12.9716, 77.5946),
    'bengaluru': GeoPoint(12.9716, 77.5946),
    'hyderabad': GeoPoint(17.3850, 78.4867),
    'kolkata': GeoPoint(22.5726, 88.3639),
    'chennai': GeoPoint(13.0827, 80.2707),
    'ahmedabad': GeoPoint(23.0225, 72.5714),
    'agra': GeoPoint(27.1767, 78.0081),
    'varanasi': GeoPoint(25.3176, 82.9739),
    'kochi': GeoPoint(9.9312, 76.2673),
    'cochin': GeoPoint(9.9312, 76.2673),
    'munnar': GeoPoint(10.0889, 77.0595),
    'alleppey': GeoPoint(9.4981, 76.3388),
    'alappuzha': GeoPoint(9.4981, 76.3388),
    'shimla': GeoPoint(31.1048, 77.1734),
    'manali': GeoPoint(32.2432, 77.1892),
    'rishikesh': GeoPoint(30.0869, 78.2676),
    'haridwar': GeoPoint(29.9457, 78.1642),
    'amritsar': GeoPoint(31.6340, 74.8723),
    'mysore': GeoPoint(12.2958, 76.6394),
    'mysuru': GeoPoint(12.2958, 76.6394),
    'pondicherry': GeoPoint(11.9416, 79.8083),
    'puducherry': GeoPoint(11.9416, 79.8083),
    'darjeeling': GeoPoint(27.0410, 88.2663),
    'gangtok': GeoPoint(27.3389, 88.6065),
    'ooty': GeoPoint(11.4102, 76.6950),
    'kodaikanal': GeoPoint(10.2381, 77.4892),
    'lonavala': GeoPoint(18.7557, 73.4091),
    'khandala': GeoPoint(18.7610, 73.3757),
    'alibaug': GeoPoint(18.6414, 72.8722),
    'alibag': GeoPoint(18.6414, 72.8722),
    'ratnagiri': GeoPoint(16.9902, 73.3120),
    'chiplun': GeoPoint(17.5323, 73.5186),
    'malvan': GeoPoint(16.0592, 73.4699),
    'tarkarli': GeoPoint(16.0357, 73.4913),
    'dapoli': GeoPoint(17.7600, 73.1873),
    'matheran': GeoPoint(18.9866, 73.2678),
    'karjat': GeoPoint(18.9102, 73.3283),
    'mahabaleshwar': GeoPoint(17.9237, 73.6586),
    'panvel': GeoPoint(18.9894, 73.1175),
  };

  /// Resolve city/destination text to exact coordinates
  static GeoPoint resolveCoordinatesForCity(String cityName) {
    if (cityName.trim().isEmpty) {
      return const GeoPoint(19.0760, 72.8777); // Default Mumbai
    }

    final lower = cityName.trim().toLowerCase();

    // 1. Exact dictionary match
    if (cityCoordinates.containsKey(lower)) {
      final p = cityCoordinates[lower]!;
      debugPrint('[DESTINATION RESOLUTION] City: $cityName, Lat: ${p.latitude}, Lng: ${p.longitude}');
      return p;
    }

    // 2. Partial / substring match
    for (final entry in cityCoordinates.entries) {
      if (lower.contains(entry.key) || entry.key.contains(lower)) {
        debugPrint('[DESTINATION RESOLUTION] City: $cityName (matched ${entry.key}), Lat: ${entry.value.latitude}, Lng: ${entry.value.longitude}');
        return entry.value;
      }
    }

    // Default to Mumbai if unknown
    debugPrint('[DESTINATION RESOLUTION] City: $cityName (unrecognized, default Mumbai), Lat: 19.0760, Lng: 72.8777');
    return const GeoPoint(19.0760, 72.8777);
  }

  /// Convert (lat, lon) into a clean human-readable Location Name
  static Future<String> getLocationName(double lat, double lon, {String fallbackCity = ''}) async {
    if (lat == 0.0 || lon == 0.0) {
      return fallbackCity.isNotEmpty ? fallbackCity : 'Mumbai, Maharashtra';
    }

    final key = '${lat.toStringAsFixed(3)},${lon.toStringAsFixed(3)}';
    if (_reverseCache.containsKey(key)) {
      return _reverseCache[key]!;
    }

    // 1. Fast local coordinate boundary lookup
    String? localName = _getLocalAreaName(lat, lon);
    if (localName != null) {
      _reverseCache[key] = localName;
    }

    // 2. Async reverse-geocoding fetch from OpenStreetMap
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1');
      final response = await http.get(uri, headers: {
        'User-Agent': 'LocalLensTravelerApp/1.0',
      }).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final neighbourhood = addr['suburb'] ??
              addr['neighbourhood'] ??
              addr['residential'] ??
              addr['commercial'] ??
              addr['quarter'] ??
              addr['district'] ??
              addr['city_district'];
          final city = addr['city'] ?? addr['town'] ?? addr['county'] ?? addr['state_district'] ?? 'Mumbai';

          String resolved;
          if (neighbourhood != null && neighbourhood.toString().isNotEmpty) {
            resolved = '${neighbourhood.toString()}, ${city.toString()}';
          } else {
            resolved = city.toString();
          }

          _reverseCache[key] = resolved;
          return resolved;
        }
      }
    } catch (e) {
      debugPrint('[GeocodingService] Reverse geocode fetch notice: $e');
    }

    return localName ?? (fallbackCity.isNotEmpty ? fallbackCity : 'Mumbai, Maharashtra');
  }

  /// Instant local area boundary lookup
  static String? _getLocalAreaName(double lat, double lon) {
    if (lat >= 18.95 && lat <= 19.03 && lon >= 73.08 && lon <= 73.15) {
      return 'Panvel, Navi Mumbai';
    }
    if (lat >= 19.02 && lat <= 19.06 && lon >= 73.02 && lon <= 73.08) {
      return 'Kharghar, Navi Mumbai';
    }
    if (lat >= 19.06 && lat <= 19.10 && lon >= 72.98 && lon <= 73.03) {
      return 'Vashi, Navi Mumbai';
    }
    if (lat >= 19.04 && lat <= 19.08 && lon >= 72.82 && lon <= 72.88) {
      return 'Bandra, Mumbai';
    }
    if (lat >= 19.10 && lat <= 19.15 && lon >= 72.81 && lon <= 72.87) {
      return 'Andheri West, Mumbai';
    }
    if (lat >= 18.90 && lat <= 18.95 && lon >= 72.81 && lon <= 72.85) {
      return 'Colaba, Mumbai';
    }
    if (lat >= 18.98 && lat <= 19.03 && lon >= 72.81 && lon <= 72.85) {
      return 'Worli, Mumbai';
    }
    return null;
  }
}
