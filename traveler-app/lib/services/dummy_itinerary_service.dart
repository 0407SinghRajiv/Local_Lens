import 'dart:async';
import 'dart:math';
import '../models/itinerary_model.dart';

/// Mock / Dummy Itinerary Generator Service
///
/// NOTE: ML is not connected yet. This service simulates the future
/// MLItineraryService / FastAPI ML recommendation engine with realistic delay
/// and dynamic rule-based output based on user inputs.
class DummyItineraryService {
  /// Generates a mock itinerary tailored to the traveler's inputs
  static Future<Itinerary> generateItinerary({
    required String destination,
    String displayAddress = '',
    required int availableTimeMinutes,
    required double totalBudgetInr,
    required String groupType,
    required int travelerCount,
    required List<String> interests,
    String? preferences,
  }) async {
    // 1. Simulate AI processing / recommendation synthesis delay (1.4s)
    await Future.delayed(const Duration(milliseconds: 1400));

    final normalizedDestination = destination.trim().isEmpty
        ? (displayAddress.isNotEmpty ? displayAddress : 'Panvel, Maharashtra')
        : destination.trim();

    // 2. Build tailored list of experiences based on interests, time, and budget
    final items = _buildDynamicItems(
      destination: normalizedDestination,
      availableTimeMinutes: availableTimeMinutes,
      totalBudgetInr: totalBudgetInr,
      interests: interests,
      groupType: groupType,
      preferences: preferences,
    );

    // 3. Compute total cost and duration
    final totalCost = items.fold(0.0, (sum, item) => sum + item.price);
    final totalDuration = items.fold(0, (sum, item) => sum + item.durationMinutes);

    return Itinerary(
      id: 'itin-${DateTime.now().millisecondsSinceEpoch}',
      destination: normalizedDestination,
      displayAddress: displayAddress,
      startTime: items.isNotEmpty ? items.first.startTime : '09:00',
      endTime: items.isNotEmpty ? items.last.endTime : '17:00',
      totalDurationMinutes: totalDuration,
      totalEstimatedCost: totalCost,
      items: items,
      createdAt: DateTime.now(),
    );
  }

  static List<ItineraryItem> _buildDynamicItems({
    required String destination,
    required int availableTimeMinutes,
    required double totalBudgetInr,
    required List<String> interests,
    required String groupType,
    String? preferences,
  }) {
    final lowerInterests = interests.map((e) => e.toLowerCase()).toList();

    // Candidate pool of rich experiences with local flavor
    final List<_ExperienceTemplate> pool = [
      // Food
      _ExperienceTemplate(
        name: 'Authentic Local Breakfast & Chai',
        category: 'Food',
        location: '$destination Old Town',
        description:
            'Start your morning with legendary hot local snacks, fresh filter chai, and century-old recipe delicacies.',
        durationMinutes: 45,
        basePrice: 250,
        distanceKm: 1.2,
        image: 'assets/images/destinations/food_trail.png',
        tags: ['food', 'local experiences', 'wellness'],
        iconType: 'breakfast',
        rating: 4.9,
      ),
      // Culture / Heritage
      _ExperienceTemplate(
        name: 'Heritage Walk & Ancient Temple',
        category: 'Culture',
        location: '$destination Historical Quarter',
        description:
            'A peaceful guided walking tour through stone pathways, traditional architecture, and centuries of preserved folklore.',
        durationMinutes: 75,
        basePrice: 350,
        distanceKm: 2.4,
        image: 'assets/images/destinations/heritage_walk.png',
        tags: ['culture', 'heritage', 'photography', 'hidden gems'],
        iconType: 'walk',
        rating: 4.7,
      ),
      // Nature / Adventure
      _ExperienceTemplate(
        name: 'Scenic Valley & Nature Trail',
        category: 'Nature',
        location: '$destination Foothills',
        description:
            'Breathe in fresh open air along lush green trails, hidden streams, and stunning mountain views.',
        durationMinutes: 90,
        basePrice: 300,
        distanceKm: 4.8,
        image: 'assets/images/destinations/waterfall.png',
        tags: ['nature', 'adventure', 'wellness', 'photography'],
        iconType: 'nature',
        rating: 4.8,
      ),
      // Local Market / Shopping
      _ExperienceTemplate(
        name: 'Artisanal Bazaar & Local Crafts',
        category: 'Shopping',
        location: '$destination Main Market',
        description:
            'Explore vibrant stalls of handcrafted souvenirs, fragrant spices, and authentic local goods.',
        durationMinutes: 60,
        basePrice: 400,
        distanceKm: 1.8,
        image: 'assets/images/destinations/food_trail.png',
        tags: ['shopping', 'local experiences', 'hidden gems'],
        iconType: 'market',
        rating: 4.6,
      ),
      // Food Trail
      _ExperienceTemplate(
        name: 'Secret Culinary Tasting Tour',
        category: 'Food',
        location: '$destination Spice Bazaar',
        description:
            'Taste 5+ signature regional dishes curated by passionate family-run culinary hosts.',
        durationMinutes: 75,
        basePrice: 450,
        distanceKm: 2.1,
        image: 'assets/images/destinations/beach_cafe.png',
        tags: ['food', 'local experiences', 'nightlife'],
        iconType: 'food',
        rating: 4.9,
      ),
      // Coastal / Sunset Viewpoint
      _ExperienceTemplate(
        name: 'Panoramic Sunset by Coastal Viewpoint',
        category: 'Nature',
        location: '$destination Ridge Road',
        description:
            'Witness a breathtaking sunset overlooking the horizon with soothing coastal breeze and local snacks.',
        durationMinutes: 60,
        basePrice: 200,
        distanceKm: 3.5,
        image: 'assets/images/destinations/sunset_coast.png',
        tags: ['nature', 'beach', 'photography', 'wellness', 'nightlife'],
        iconType: 'sunset',
        rating: 4.9,
      ),
    ];

    // Score candidates based on traveler's selected interests
    final scoredPool = pool.map((item) {
      int score = 0;
      for (final tag in item.tags) {
        if (lowerInterests.contains(tag)) score += 3;
      }
      if (lowerInterests.contains(item.category.toLowerCase())) score += 5;
      return _ScoredExperience(template: item, score: score);
    }).toList();

    // Sort by relevance score descending
    scoredPool.sort((a, b) => b.score.compareTo(a.score));

    // Determine how many items to return based on available time
    // e.g. < 180 min (3h) -> 2-3 items
    // 180 - 360 min (3h - 6h) -> 3-4 items
    // > 360 min (6h+) -> 4-5 items
    int maxItems;
    if (availableTimeMinutes <= 120) {
      maxItems = 2;
    } else if (availableTimeMinutes <= 240) {
      maxItems = 3;
    } else if (availableTimeMinutes <= 480) {
      maxItems = 4;
    } else {
      maxItems = 5;
    }

    final selectedTemplates = scoredPool.take(maxItems).map((e) => e.template).toList();

    // Re-order temporally: Morning/Breakfast first, Afternoon/Walk/Market, Sunset last
    selectedTemplates.sort((a, b) {
      final orderMap = {'breakfast': 0, 'walk': 1, 'nature': 2, 'market': 3, 'food': 4, 'sunset': 5};
      final orderA = orderMap[a.iconType] ?? 3;
      final orderB = orderMap[b.iconType] ?? 3;
      return orderA.compareTo(orderB);
    });

    // Budget scaling factor if traveler specified low/high budget
    final budgetMultiplier = totalBudgetInr > 0 && totalBudgetInr < 1000
        ? 0.7
        : (totalBudgetInr > 4000 ? 1.3 : 1.0);

    // Build timeline items with realistic starting hours
    int currentHour = 9;
    int currentMinute = 0;

    final List<ItineraryItem> result = [];

    for (int i = 0; i < selectedTemplates.length; i++) {
      final t = selectedTemplates[i];
      final startStr = _formatTime(currentHour, currentMinute);

      currentMinute += t.durationMinutes;
      currentHour += currentMinute ~/ 60;
      currentMinute = currentMinute % 60;

      final endStr = _formatTime(currentHour, currentMinute);

      // Add 20 min transit between stops
      currentMinute += 20;
      currentHour += currentMinute ~/ 60;
      currentMinute = currentMinute % 60;

      final scaledPrice = (t.basePrice * budgetMultiplier).roundToDouble();

      result.add(
        ItineraryItem(
          id: 'item-${i + 1}-${Random().nextInt(9999)}',
          experienceName: t.name,
          category: t.category,
          location: t.location,
          description: t.description,
          startTime: startStr,
          endTime: endStr,
          durationMinutes: t.durationMinutes,
          price: scaledPrice,
          distanceKm: t.distanceKm,
          image: t.image,
          rating: t.rating,
          iconType: t.iconType,
          isSelected: true,
          isCompleted: false,
          requiresBooking: t.category == 'Culture' || t.category == 'Food',
        ),
      );
    }

    return result;
  }

  static String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ExperienceTemplate {
  final String name;
  final String category;
  final String location;
  final String description;
  final int durationMinutes;
  final double basePrice;
  final double distanceKm;
  final String image;
  final List<String> tags;
  final String iconType;
  final double rating;

  const _ExperienceTemplate({
    required this.name,
    required this.category,
    required this.location,
    required this.description,
    required this.durationMinutes,
    required this.basePrice,
    required this.distanceKm,
    required this.image,
    required this.tags,
    required this.iconType,
    required this.rating,
  });
}

class _ScoredExperience {
  final _ExperienceTemplate template;
  final int score;
  const _ScoredExperience({required this.template, required this.score});
}
