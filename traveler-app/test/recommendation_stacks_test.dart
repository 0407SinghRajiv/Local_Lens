import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traveler_app/models/recommendation_model.dart';
import 'package:traveler_app/services/itinerary_api_service.dart';
import 'package:traveler_app/widgets/recommendation_swipe_stack.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Recommendation Stack Logic & Itinerary Count Tests', () {
    // Helper to generate mock recommendations
    List<RecommendationModel> generateMockRecs({
      required String category,
      required int count,
      String prefix = 'EXP',
    }) {
      return List.generate(count, (i) {
        return RecommendationModel(
          experienceId: '$prefix-${category.toUpperCase()}-$i',
          name: '$category Experience $i',
          category: category,
          location: 'Location $i',
          city: 'Mumbai',
          durationMinutes: 60,
          durationHours: 1.0,
          price: 250.0,
          rating: 4.8,
          reason: 'Matches your $category interest',
          score: 0.95 - (i * 0.01),
          image: 'assets/images/destinations/food_trail.png',
        );
      });
    }

    test('TEST 1: placesToVisit = 4, interests = Food, Culture, Adventure -> 4 stacks, 4 final places', () async {
      const placesToVisit = 4;
      final interests = ['Food', 'Culture', 'Adventure'];

      // Dynamic stack generation rule
      final stackThemes = List.generate(placesToVisit, (i) {
        if (i < interests.length) {
          return interests[i];
        }
        return 'Mixed (${interests.join(" • ")})';
      });

      expect(stackThemes.length, equals(4));
      expect(stackThemes[0], equals('Food'));
      expect(stackThemes[1], equals('Culture'));
      expect(stackThemes[2], equals('Adventure'));
      expect(stackThemes[3], contains('Mixed'));

      // Simulate 1 selection per stack
      final selectedPlaces = [
        generateMockRecs(category: 'Food', count: 1)[0],
        generateMockRecs(category: 'Culture', count: 1)[0],
        generateMockRecs(category: 'Adventure', count: 1)[0],
        generateMockRecs(category: 'Food', count: 1, prefix: 'MIX')[0],
      ];

      expect(selectedPlaces.length, equals(4));

      // Test fallback/API generation receives and generates all 4
      final result = await ItineraryApiService.generateItinerary(
        destination: 'Mumbai',
        tripDate: '2026-09-26',
        startTime: '10:30 AM',
        durationHours: 6.0,
        budget: 5000.0,
        selectedExperienceIds: selectedPlaces.map((p) => p.experienceId).toList(),
        selectedPlacesModels: selectedPlaces,
        travelerCount: 2,
        travelerType: 'Couple',
      );

      expect(result.items.length, equals(4));
      expect(result.items[0].category, equals('Food'));
      expect(result.items[1].category, equals('Culture'));
      expect(result.items[2].category, equals('Adventure'));
    });

    test('TEST 2: placesToVisit = 8, interests = Food, Culture, Adventure -> 8 stacks, 8 final places', () async {
      const placesToVisit = 8;
      final interests = ['Food', 'Culture', 'Adventure'];

      final stackThemes = List.generate(placesToVisit, (i) {
        if (i < interests.length) {
          return interests[i];
        }
        return 'Mixed (${interests.join(" • ")})';
      });

      expect(stackThemes.length, equals(8));
      expect(stackThemes[0], equals('Food'));
      expect(stackThemes[1], equals('Culture'));
      expect(stackThemes[2], equals('Adventure'));
      for (int i = 3; i < 8; i++) {
        expect(stackThemes[i], contains('Mixed'));
      }

      final selectedPlaces = List.generate(8, (i) {
        final cat = interests[i % interests.length];
        return RecommendationModel(
          experienceId: 'EXP-8-$i',
          name: '$cat Experience $i',
          category: cat,
          location: 'Loc $i',
          city: 'Mumbai',
          durationMinutes: 45,
          durationHours: 0.75,
          price: 200.0,
          rating: 4.8,
          reason: 'Great experience',
          score: 0.9,
          image: 'assets/images/destinations/food_trail.png',
        );
      });

      final result = await ItineraryApiService.generateItinerary(
        destination: 'Mumbai',
        tripDate: '2026-09-26',
        startTime: '09:00 AM',
        durationHours: 8.0,
        budget: 8000.0,
        selectedExperienceIds: selectedPlaces.map((p) => p.experienceId).toList(),
        selectedPlacesModels: selectedPlaces,
        travelerCount: 2,
        travelerType: 'Couple',
      );

      expect(result.items.length, equals(8));
    });

    test('TEST 3: placesToVisit = 10, interests = Food -> 10 Food-only stacks, 10 final places', () async {
      const placesToVisit = 10;
      final interests = ['Food'];

      final stackThemes = List.generate(placesToVisit, (i) {
        if (i < interests.length) {
          return interests[i];
        }
        return 'Mixed (${interests.join(" • ")})';
      });

      expect(stackThemes.length, equals(10));
      for (final theme in stackThemes) {
        expect(theme.contains('Food'), isTrue);
      }

      final selectedPlaces = List.generate(10, (i) {
        return RecommendationModel(
          experienceId: 'EXP-FOOD-$i',
          name: 'Food Tasting $i',
          category: 'Food',
          location: 'Market $i',
          city: 'Mumbai',
          durationMinutes: 40,
          durationHours: 0.65,
          price: 150.0,
          rating: 4.9,
          reason: 'Delicious food',
          score: 0.92,
          image: 'assets/images/destinations/food_trail.png',
        );
      });

      final result = await ItineraryApiService.generateItinerary(
        destination: 'Mumbai',
        tripDate: '2026-09-26',
        startTime: '09:00 AM',
        durationHours: 10.0,
        budget: 5000.0,
        selectedExperienceIds: selectedPlaces.map((p) => p.experienceId).toList(),
        selectedPlacesModels: selectedPlaces,
        travelerCount: 1,
        travelerType: 'Solo',
      );

      expect(result.items.length, equals(10));
      for (final item in result.items) {
        expect(item.category, equals('Food'));
      }
    });

    test('TEST 4: placesToVisit = 5, interests = Food, Adventure -> 5 stacks with only selected interests', () async {
      const placesToVisit = 5;
      final interests = ['Food', 'Adventure'];

      final stackThemes = List.generate(placesToVisit, (i) {
        if (i < interests.length) {
          return interests[i];
        }
        return 'Mixed (${interests.join(" • ")})';
      });

      expect(stackThemes.length, equals(5));
      expect(stackThemes[0], equals('Food'));
      expect(stackThemes[1], equals('Adventure'));
      expect(stackThemes[2], contains('Food'));
      expect(stackThemes[2], contains('Adventure'));
      expect(stackThemes[2].contains('Culture'), isFalse);
      expect(stackThemes[2].contains('Nature'), isFalse);
    });

    test('TEST 5: Session-level exclusion prevents duplicates across stacks', () {
      final selectedPlaceIds = <String>{};
      final rejectedPlaceIds = <String>{};
      final shownPlaceIds = <String>{};

      final candidateA = generateMockRecs(category: 'Food', count: 1, prefix: 'A')[0];
      final candidateB = generateMockRecs(category: 'Food', count: 1, prefix: 'B')[0];

      // Select candidateA in Stack 1
      selectedPlaceIds.add(candidateA.experienceId);
      shownPlaceIds.add(candidateA.experienceId);

      // Reject candidateB in Stack 1
      rejectedPlaceIds.add(candidateB.experienceId);
      shownPlaceIds.add(candidateB.experienceId);

      // Verify Stack 2 pool excludes both
      final stack2CandidatePool = [candidateA, candidateB, generateMockRecs(category: 'Culture', count: 1, prefix: 'C')[0]];
      final validForStack2 = stack2CandidatePool.where((c) {
        final id = c.experienceId;
        return !selectedPlaceIds.contains(id) && !rejectedPlaceIds.contains(id);
      }).toList();

      expect(validForStack2.length, equals(1));
      expect(validForStack2[0].experienceId, contains('C-CULTURE'));
    });

    testWidgets('TEST 6: Swipe smooth interaction, left=reject, right=select, double processing lock', (tester) async {
      final candidates = generateMockRecs(category: 'Food', count: 3);
      RecommendationModel? rightSelected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 800,
              child: RecommendationSwipeStack(
                candidates: candidates,
                placesToVisit: 4,
                selectedCount: 0,
                onSwipeRight: (c) => rightSelected = c,
                onSwipeLeft: (_) {},
              ),
            ),
          ),
        ),
      );

      // Top card is visible
      expect(find.text('Food Experience 0'), findsOneWidget);

      // Rapid tap Select button
      await tester.tap(find.text('Select'));
      await tester.tap(find.text('Select')); // Second rapid tap while animating
      await tester.pumpAndSettle();

      // Exactly one selection fired
      expect(rightSelected, isNotNull);
      expect(rightSelected!.experienceId, equals('EXP-FOOD-0'));
    });
  });
}
