import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Result parsed from Groq LLM analyzing traveler optimization requests
class GroqOptimizationResult {
  final String reply;
  final List<String> removeInterests;
  final List<String> addInterests;
  final String? customNotes;
  final double? updatedBudget;
  final double? updatedDurationHours;
  final bool shouldRegenerate;
  final bool isRouteReorderOnly;

  const GroqOptimizationResult({
    required this.reply,
    this.removeInterests = const [],
    this.addInterests = const [],
    this.customNotes,
    this.updatedBudget,
    this.updatedDurationHours,
    this.shouldRegenerate = false,
    this.isRouteReorderOnly = false,
  });

  bool get hasInterestChanges => removeInterests.isNotEmpty || addInterests.isNotEmpty;

  factory GroqOptimizationResult.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
      if (value is String && value.isNotEmpty) {
        return [value.trim()];
      }
      return [];
    }

    double? parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    return GroqOptimizationResult(
      reply: json['reply']?.toString() ?? 'I have updated your preferences based on your request.',
      removeInterests: parseStringList(json['remove_interests']),
      addInterests: parseStringList(json['add_interests']),
      customNotes: json['custom_notes']?.toString(),
      updatedBudget: parseDouble(json['updated_budget']),
      updatedDurationHours: parseDouble(json['updated_duration_hours']),
      shouldRegenerate: json['should_regenerate'] == true ||
          (json['add_interests'] is List && (json['add_interests'] as List).isNotEmpty) ||
          (json['remove_interests'] is List && (json['remove_interests'] as List).isNotEmpty),
      isRouteReorderOnly: json['is_route_reorder_only'] == true,
    );
  }
}

/// Service to interact with Groq AI API for conversational itinerary optimization
class GroqItineraryService {
  GroqItineraryService._();

  static const String _defaultApiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
  static const String _groqCompletionsUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static String get apiKey {
    try {
      if (dotenv.isInitialized) {
        final key = dotenv.env['GROQ_API_KEY']?.trim();
        if (key != null && key.isNotEmpty) return key;
      }
    } catch (_) {}
    return _defaultApiKey;
  }

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'LocalLens/1.0',
      },
    ),
  );

  /// Available recognized categories/interests in LocalLens ML model
  static const List<String> recognizedInterests = [
    'Beach',
    'Food',
    'Culture',
    'Adventure',
    'Nature',
    'Heritage',
    'Shopping',
    'Nightlife',
    'Photography',
    'Wellness',
    'Hidden Gems',
    'Local Experiences',
  ];

  /// Sends the traveler's natural language request to Groq LLM
  static Future<GroqOptimizationResult> analyzeRequest({
    required String prompt,
    required String destination,
    required List<String> currentInterests,
    required double budget,
    required double durationHours,
    required List<String> currentPlaceNames,
    List<Map<String, String>> chatHistory = const [],
  }) async {
    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty) {
      return const GroqOptimizationResult(reply: 'Please let me know how you would like to adjust your trip!');
    }

    final key = apiKey;
    final systemPrompt = '''
You are LocalLens AI Itinerary Optimizer Assistant.
The traveler is viewing their generated trip itinerary and wants changes/optimizations.

Current Trip State:
- Destination: $destination
- Current Interests: ${currentInterests.join(', ')}
- Current Stops in Itinerary: ${currentPlaceNames.join(', ')}
- Budget: INR $budget
- Available Time: $durationHours hours

Recognized Interest Categories in LocalLens:
${recognizedInterests.join(', ')}

Guidelines:
1. EXCLUSIONS & NEGATIVE CONSTRAINTS (CRITICAL - APPLIES TO ALL CATEGORIES):
   If the traveler indicates they do not need, do not want, dislike, or want to exclude ANY category or experience type:
   (e.g., "i dont need the food", "he dont need the food", "no food", "dont want beaches", "no shopping", "dont need temples", "skip adventure", etc.):
   - remove_interests MUST contain that category (e.g., ["Food"], ["Beach"], ["Shopping"]).
   - should_regenerate MUST be true.
   - reply: Provide a clear confirmation that all [Category] items and experiences will be completely excluded from their recommendations and itinerary.
2. REPLACEMENTS & ADDITIONS:
   If traveler says "change food with beaches so generate it" or "replace X with Y":
   - remove_interests: ["Food"]
   - add_interests: ["Beach"]
   - should_regenerate: true
   - reply: Friendly confirmation that food spots will be replaced with beaches.
3. ROUTE SEQUENCING:
   If they ask to optimize the route order/sequence without changing places:
   - is_route_reorder_only: true
   - reply: Explain that the route will be sequenced for the shortest travel time.
4. Output STRICTLY a JSON object matching this schema:
{
  "reply": "Your conversational response to traveler",
  "remove_interests": ["..."],
  "add_interests": ["..."],
  "custom_notes": "...",
  "updated_budget": null,
  "updated_duration_hours": null,
  "should_regenerate": true,
  "is_route_reorder_only": false
}
''';

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    // Include recent conversation turns for context
    for (final turn in chatHistory.take(6)) {
      messages.add(turn);
    }

    messages.add({'role': 'user', 'content': trimmedPrompt});

    // Try primary model (openai/gpt-oss-120b), then fallback (openai/gpt-oss-20b)
    final modelsToTry = ['openai/gpt-oss-120b', 'openai/gpt-oss-20b'];

    for (final model in modelsToTry) {
      try {
        final payload = {
          'model': model,
          'messages': messages,
          'response_format': {'type': 'json_object'},
          'temperature': 0.3,
        };

        final response = await _dio.post(
          _groqCompletionsUrl,
          data: jsonEncode(payload),
          options: Options(
            contentType: 'application/json',
            responseType: ResponseType.json,
            headers: {
              'Authorization': 'Bearer $key',
            },
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data;
          final content = data['choices']?[0]?['message']?['content']?.toString() ?? '';
          if (content.isNotEmpty) {
            final parsedJson = jsonDecode(content) as Map<String, dynamic>;
            final result = GroqOptimizationResult.fromJson(parsedJson);
            debugPrint('[GroqItineraryService] Success with $model: remove=${result.removeInterests}, add=${result.addInterests}');
            return result;
          }
        }
      } catch (e) {
        if (e is DioException) {
          debugPrint('[GroqItineraryService] Dio error data: ${e.response?.data}');
        }
        debugPrint('[GroqItineraryService] Model $model failed: $e. Trying fallback...');
      }
    }

    // Deterministic fallback if API is unreachable or rate limited
    debugPrint('[GroqItineraryService] Falling back to intelligent local parser');
    return _fallbackLocalParse(trimmedPrompt, currentInterests);
  }

  /// Intelligent local fallback parsing ensuring guaranteed zero downtime and all-category exclusions
  static GroqOptimizationResult _fallbackLocalParse(String prompt, List<String> currentInterests) {
    final lower = prompt.toLowerCase();
    final removeList = <String>[];
    final addList = <String>[];
    bool shouldRegen = false;
    bool isReorderOnly = false;

    // Detect route re-order
    if (lower.contains('route') || lower.contains('order') || lower.contains('fastest') || lower.contains('shortest')) {
      isReorderOnly = true;
    }

    // Helper to check if a category is negated (e.g. "dont need food", "no food", "dont want beaches")
    bool isNegated(String term, List<String> synonyms) {
      final allTerms = [term, ...synonyms];
      final negationPrefixes = [
        'dont need', "don't need", 'dont want', "don't want", 'do not need', 'do not want',
        'no', 'not need', 'not want', 'without', 'remove', 'skip', 'exclude', 'drop',
        'avoid', 'stop', 'hate', 'dislike', 'delete'
      ];
      for (final t in allTerms) {
        for (final neg in negationPrefixes) {
          final p = neg.trim();
          if (lower.contains('$p $t') ||
              lower.contains('$p the $t') ||
              lower.contains('$t $p') ||
              lower.contains('replace $t') ||
              lower.contains('change $t')) {
            return true;
          }
        }
      }
      return false;
    }

    // Check all categories for exclusion vs addition:
    final categoriesMap = {
      'Food': ['food', 'eat', 'dining', 'restaurant', 'restaurants', 'cafe', 'dishes', 'snack', 'meals'],
      'Beach': ['beach', 'beaches', 'sea', 'coastal', 'shore', 'ocean'],
      'Adventure': ['adventure', 'trek', 'trekking', 'hike', 'hiking', 'climb', 'sports'],
      'Heritage': ['heritage', 'fort', 'forts', 'monument', 'monuments', 'palace', 'history', 'caves'],
      'Culture': ['culture', 'temple', 'temples', 'museum', 'museums', 'spiritual', 'religious'],
      'Nature': ['nature', 'park', 'parks', 'garden', 'gardens', 'waterfall', 'waterfalls', 'wildlife', 'forest'],
      'Shopping': ['shopping', 'market', 'markets', 'bazaar', 'bazaars', 'mall', 'malls'],
      'Nightlife': ['nightlife', 'bar', 'bars', 'pub', 'pubs', 'club', 'clubs', 'lounge'],
      'Wellness': ['wellness', 'spa', 'yoga', 'meditation'],
    };

    for (final entry in categoriesMap.entries) {
      final cat = entry.key;
      final syns = entry.value;

      if (isNegated(cat.toLowerCase(), syns)) {
        if (!removeList.contains(cat)) removeList.add(cat);
        shouldRegen = true;
      } else if (syns.any((s) => lower.contains(s))) {
        if (!addList.contains(cat) && !removeList.contains(cat)) {
          addList.add(cat);
          shouldRegen = true;
        }
      }
    }

    String reply;
    if (removeList.isNotEmpty && addList.isNotEmpty) {
      reply = "Got it! I will exclude all ${removeList.join(', ')} experiences and add ${addList.join(', ')} instead. Regenerating fresh recommendations for you!";
    } else if (removeList.isNotEmpty) {
      reply = "Understood! I will ensure no ${removeList.join(', ')} items or experiences are included in your recommendations and itinerary. Regenerating your fresh trip now!";
    } else if (addList.isNotEmpty) {
      reply = "Added ${addList.join(', ')} to your travel preferences. Let's find exciting new spots for you!";
    } else if (isReorderOnly) {
      reply = "Optimizing your itinerary route for the fastest travel sequence and minimum transit time!";
    } else {
      reply = "I've updated your trip preferences based on your note: \"$prompt\". Let's regenerate your recommendations!";
      shouldRegen = true;
    }

    return GroqOptimizationResult(
      reply: reply,
      removeInterests: removeList,
      addInterests: addList,
      customNotes: prompt,
      shouldRegenerate: shouldRegen,
      isRouteReorderOnly: isReorderOnly,
    );
  }
}
