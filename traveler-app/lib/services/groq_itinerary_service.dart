import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Result parsed from Groq LLM analyzing traveler optimization & place info requests
class GroqOptimizationResult {
  final String reply;
  final bool isInfoQuery;
  final List<String> removeInterests;
  final List<String> addInterests;
  final String? customNotes;
  final double? updatedBudget;
  final double? updatedDurationHours;
  final bool shouldRegenerate;
  final bool isRouteReorderOnly;

  const GroqOptimizationResult({
    required this.reply,
    this.isInfoQuery = false,
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

    final isInfo = json['is_info_query'] == true;
    final explicitRegen = json['should_regenerate'] == true;
    final hasInterestChanges = (json['add_interests'] is List && (json['add_interests'] as List).isNotEmpty) ||
        (json['remove_interests'] is List && (json['remove_interests'] as List).isNotEmpty);

    return GroqOptimizationResult(
      reply: json['reply']?.toString() ?? 'Namaste! I am LocalLens Saathi. How can I guide you today?',
      isInfoQuery: isInfo,
      removeInterests: isInfo && !explicitRegen ? const [] : parseStringList(json['remove_interests']),
      addInterests: isInfo && !explicitRegen ? const [] : parseStringList(json['add_interests']),
      customNotes: json['custom_notes']?.toString(),
      updatedBudget: parseDouble(json['updated_budget']),
      updatedDurationHours: parseDouble(json['updated_duration_hours']),
      shouldRegenerate: !isInfo && (explicitRegen || hasInterestChanges),
      isRouteReorderOnly: json['is_route_reorder_only'] == true,
    );
  }
}

/// Service to interact with Groq AI API for LocalLens Saathi (Indian Travel Companion & Optimizer)
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
      connectTimeout: const Duration(seconds: 14),
      receiveTimeout: const Duration(seconds: 16),
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

  /// Sends the traveler's natural language request to Groq LLM (LocalLens Saathi)
  static Future<GroqOptimizationResult> analyzeRequest({
    required String prompt,
    required String destination,
    required List<String> currentInterests,
    required double budget,
    required double durationHours,
    required List<String> currentPlaceNames,
    List<Map<String, String>> chatHistory = const [],
    List<Map<String, dynamic>> placesDetails = const [],
  }) async {
    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty) {
      return const GroqOptimizationResult(
        reply: 'Namaste! 🙏 Please let me know what you would like to ask or change!',
        isInfoQuery: true,
      );
    }

    final key = apiKey;

    // Construct rich stop details for insider knowledge
    final stopsDetailsList = <String>[];
    if (placesDetails.isNotEmpty) {
      for (int i = 0; i < placesDetails.length; i++) {
        final p = placesDetails[i];
        final name = p['name'] ?? p['experience_name'] ?? 'Stop ${i + 1}';
        final cat = p['category'] ?? 'Experience';
        final loc = p['location'] ?? '';
        final desc = p['description'] ?? '';
        final cost = p['price_inr'] ?? p['price'] ?? 0;
        final time = p['time_window'] ?? '';
        stopsDetailsList.add('${i + 1}. $name ($cat, $loc) [Cost: ₹$cost, Time: $time] - $desc');
      }
    } else {
      for (int i = 0; i < currentPlaceNames.length; i++) {
        stopsDetailsList.add('${i + 1}. ${currentPlaceNames[i]}');
      }
    }
    final stopsContext = stopsDetailsList.join('\n');

    final systemPrompt = '''
You are LocalLens Saathi (लोकललेंस साथी) — an authentic, warm, deeply knowledgeable Indian local travel companion, guide, and itinerary assistant.
You speak with authentic Indian hospitality and warmth (using "Namaste 🙏", "Aapka Saathi", Indian cultural context, ₹ INR prices). You understand English, Hindi (हिन्दी), and Hinglish fluently, matching the traveler's language.

Current Trip State:
- Destination / City: $destination
- Current Interests: ${currentInterests.join(', ')}
- Stops in Current Itinerary:
$stopsContext
- Budget: ₹$budget
- Available Time: $durationHours hours

Your Dual Superpower:
1. 🏛️ INFORMATIONAL LOCAL GUIDE (Places, Heritage, Culture, Food & Secrets):
   - Whenever the traveler asks about ANY place, stop, history, culture, what to eat, street food, best photo spots, entry fees, timings, weather tips, dress codes, or local secrets (e.g. "tell me about Belapur Fort", "what food to try nearby?", "history of this place", "best sunset spots"):
   - Provide rich, captivating, authentic insider details!
   - Highlight the history, vibe, and local stories.
   - For food: suggest specific Indian local delicacies (e.g. hot Vada Pav, cutting chai, Bun Maska, local thali, coastal curry, chaat).
   - For heritage/culture: describe architectural highlights, background, significance.
   - For logistics: give practical Indian travel hacks (auto rickshaws, metro, best time of day to avoid crowds/heat).
   - In this mode: "is_info_query": true, "should_regenerate": false, "remove_interests": [], "add_interests": [].

2. ⚡ TRIP OPTIMIZER & MODIFIER:
   - When the traveler asks to change, swap, add, or remove stops/interests (e.g., "swap food with beaches", "no food", "more adventure", "reduce budget to ₹2000", "fastest route"):
   - Identify categories to add or remove:
     ${recognizedInterests.join(', ')}
   - If they want to regenerate/modify the itinerary: "should_regenerate": true, "is_info_query": false.
   - If they only want route sequence optimization: "is_route_reorder_only": true, "is_info_query": false.

Output STRICTLY a single JSON object matching this schema:
{
  "reply": "Your rich, engaging, informative or optimization response as LocalLens Saathi (use ₹ for currency)",
  "is_info_query": true,
  "remove_interests": ["..."],
  "add_interests": ["..."],
  "custom_notes": "...",
  "updated_budget": null,
  "updated_duration_hours": null,
  "should_regenerate": false,
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

    // Try primary models: openai/gpt-oss-20b, openai/gpt-oss-120b, qwen/qwen3.8-27b
    final modelsToTry = ['openai/gpt-oss-20b', 'openai/gpt-oss-120b', 'qwen/qwen3.8-27b'];

    for (final model in modelsToTry) {
      try {
        final payload = {
          'model': model,
          'messages': messages,
          'response_format': {'type': 'json_object'},
          'temperature': 0.4,
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
            debugPrint('[LocalLensSaathi] Success with $model (isInfo: ${result.isInfoQuery}): remove=${result.removeInterests}, add=${result.addInterests}');
            return result;
          }
        }
      } catch (e) {
        if (e is DioException) {
          debugPrint('[LocalLensSaathi] Dio error data: ${e.response?.data}');
        }
        debugPrint('[LocalLensSaathi] Model $model failed: $e. Trying fallback...');
      }
    }

    // Deterministic fallback if API is unreachable or rate limited
    debugPrint('[LocalLensSaathi] Falling back to intelligent local parser');
    return _fallbackLocalParse(trimmedPrompt, currentInterests, destination, currentPlaceNames);
  }

  /// Intelligent local fallback parsing ensuring guaranteed zero downtime, place info, and Indian context
  static GroqOptimizationResult _fallbackLocalParse(
    String prompt,
    List<String> currentInterests,
    String destination,
    List<String> currentPlaceNames,
  ) {
    final lower = prompt.toLowerCase();
    final removeList = <String>[];
    final addList = <String>[];
    bool shouldRegen = false;
    bool isReorderOnly = false;

    // Detect route re-order
    if (lower.contains('route') || lower.contains('order') || lower.contains('fastest') || lower.contains('shortest')) {
      isReorderOnly = true;
    }

    // Informational question detection
    final isInfo = lower.contains('tell me') ||
        lower.contains('about') ||
        lower.contains('history') ||
        lower.contains('what is') ||
        lower.contains("what's") ||
        lower.contains('special') ||
        lower.contains('food to try') ||
        lower.contains('info') ||
        lower.contains('details') ||
        lower.contains('explain') ||
        lower.contains('famous') ||
        lower.contains('story') ||
        lower.contains('timing') ||
        lower.contains('entry') ||
        lower.contains('kya hai') ||
        lower.contains('kaisa hai') ||
        lower.contains('batao') ||
        lower.contains('baare me') ||
        lower.contains('chai') ||
        lower.contains('snack');

    if (isInfo && !isReorderOnly) {
      final firstStop = currentPlaceNames.isNotEmpty ? currentPlaceNames.first : destination;
      return GroqOptimizationResult(
        reply: "Namaste! 🙏 As your LocalLens Saathi, here is what makes $firstStop special:\n\n"
            "• 🏛️ Rich cultural & historical heritage with picturesque surroundings.\n"
            "• 🍛 Must-try eats: Fresh local street food, hot cutting chai, and savory snacks nearby!\n"
            "• 📸 Insider tip: Morning and sunset golden hours offer the most breathtaking views without heavy crowds.",
        isInfoQuery: true,
        shouldRegenerate: false,
      );
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
      reply = "Namaste! 🙏 Got it. I will exclude all ${removeList.join(', ')} experiences and add ${addList.join(', ')} instead. Regenerating fresh recommendations for you!";
    } else if (removeList.isNotEmpty) {
      reply = "Understood! I will ensure no ${removeList.join(', ')} items or experiences are included in your itinerary. Regenerating your fresh trip now!";
    } else if (addList.isNotEmpty) {
      reply = "Added ${addList.join(', ')} to your travel preferences. Let's find exciting new spots for you!";
    } else if (isReorderOnly) {
      reply = "Optimizing your itinerary route for the fastest travel sequence and minimum transit time!";
    } else {
      reply = "Namaste! 🙏 I've updated your trip preferences based on your note: \"$prompt\". Let's refresh your itinerary!";
      shouldRegen = true;
    }

    return GroqOptimizationResult(
      reply: reply,
      isInfoQuery: false,
      removeInterests: removeList,
      addInterests: addList,
      customNotes: prompt,
      shouldRegenerate: shouldRegen,
      isRouteReorderOnly: isReorderOnly,
    );
  }
}
