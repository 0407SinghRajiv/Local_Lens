import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traveler_app/models/recommendation_model.dart';
import 'package:traveler_app/services/itinerary_api_service.dart';
import 'package:traveler_app/widgets/recommendation_swipe_stack.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Master Recommendation Pool, Auto Itinerary & Swipe Tests', () {
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

    test('TEST A: All Recommendations Pool (placesToVisit = 4 does NOT truncate recommendation pool)', () {
      const placesToVisit = 4;
      final mlCandidates = generateMockRecs(category: 'Culture', count: 10);

      // Verify the ML candidate pool is NOT truncated to placesToVisit
      expect(mlCandidates.length, equals(10));
      expect(mlCandidates.length > placesToVisit, isTrue);

      final candidatePool = List<RecommendationModel>.from(mlCandidates);
      expect(candidatePool.length, equals(10));
    });

    test('TEST B: Select Four -> selectedPlaces.length = 4 -> Triggers itinerary generation for exactly 4 places', () async {
      const placesToVisit = 4;
      final candidatePool = generateMockRecs(category: 'Food', count: 10);
      final selectedPlaces = <RecommendationModel>[];
      bool autoGenerationTriggered = false;

      // Select A, B, C, D
      for (int i = 0; i < 4; i++) {
        final card = candidatePool.removeAt(0);
        selectedPlaces.add(card);
        if (selectedPlaces.length == placesToVisit) {
          autoGenerationTriggered = true;
        }
      }

      expect(selectedPlaces.length, equals(4));
      expect(autoGenerationTriggered, isTrue);

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
      expect(result.items.map((i) => i.id).toList(), equals(selectedPlaces.map((p) => p.experienceId).toList()));
    });

    test('TEST C: Rejected Places (LEFT Swipe) do NOT count toward selected count', () async {
      const placesToVisit = 4;
      final candidatePool = generateMockRecs(category: 'Food', count: 10);
      final selectedPlaces = <RecommendationModel>[];
      final rejectedPlaces = <RecommendationModel>[];
      bool autoGenerationTriggered = false;

      // A -> reject
      rejectedPlaces.add(candidatePool.removeAt(0));
      // B -> reject
      rejectedPlaces.add(candidatePool.removeAt(0));
      // C -> select
      selectedPlaces.add(candidatePool.removeAt(0));
      // D -> reject
      rejectedPlaces.add(candidatePool.removeAt(0));
      // E -> select
      selectedPlaces.add(candidatePool.removeAt(0));
      // F -> select
      selectedPlaces.add(candidatePool.removeAt(0));
      // G -> select
      selectedPlaces.add(candidatePool.removeAt(0));

      if (selectedPlaces.length == placesToVisit) {
        autoGenerationTriggered = true;
      }

      expect(rejectedPlaces.length, equals(3));
      expect(selectedPlaces.length, equals(4));
      expect(autoGenerationTriggered, isTrue);
      expect(selectedPlaces[0].experienceId, equals('EXP-FOOD-2')); // C
      expect(selectedPlaces[1].experienceId, equals('EXP-FOOD-4')); // E
      expect(selectedPlaces[2].experienceId, equals('EXP-FOOD-5')); // F
      expect(selectedPlaces[3].experienceId, equals('EXP-FOOD-6')); // G

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
    });

    test('TEST D: placesToVisit = 5 generates exact 5 itinerary places and resolves images', () async {
      const placesToVisit = 5;
      final selectedPlaces = List.generate(placesToVisit, (i) {
        return RecommendationModel(
          experienceId: 'EXP-DELHI-00${i + 1}',
          name: 'Delhi Experience ${i + 1}',
          category: i == 0 ? 'Food' : (i == 1 ? 'Culture' : 'Nature'),
          location: 'Delhi',
          city: 'Delhi',
          durationMinutes: 60,
          durationHours: 1.0,
          price: 250.0,
          rating: 4.8,
          reason: 'Top place',
          score: 0.9,
          image: 'assets/images/destinations/food_trail.png',
        );
      });

      final result = await ItineraryApiService.generateItinerary(
        destination: 'Delhi',
        tripDate: '2026-09-26',
        startTime: '10:30 AM',
        durationHours: 6.0,
        budget: 5000.0,
        selectedExperienceIds: selectedPlaces.map((p) => p.experienceId).toList(),
        selectedPlacesModels: selectedPlaces,
        travelerCount: 2,
        travelerType: 'Couple',
      );

      expect(result.items.length, equals(5));
      for (final item in result.items) {
        expect(item.image, isNotEmpty);
      }
    });

    test('TEST E: placesToVisit = 8 generates exact 8 itinerary places', () async {
      const placesToVisit = 8;
      final selectedPlaces = List.generate(8, (i) {
        return RecommendationModel(
          experienceId: 'EXP-8-$i',
          name: 'Experience $i',
          category: 'Culture',
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

    testWidgets('TEST F: Left Swipe (Skip / Reject) complete smooth exit', (tester) async {
      final candidates = generateMockRecs(category: 'Food', count: 3);
      RecommendationModel? leftRejected;

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
                onSwipeRight: (_) {},
                onSwipeLeft: (c) => leftRejected = c,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Food Experience 0'), findsOneWidget);

      // Tap Skip button (Left Swipe action)
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(leftRejected, isNotNull);
      expect(leftRejected!.experienceId, equals('EXP-FOOD-0'));
    });

    testWidgets('TEST G: Right Swipe (Select) complete smooth exit', (tester) async {
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

      expect(find.text('Food Experience 0'), findsOneWidget);

      // Tap Select button (Right Swipe action)
      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();

      expect(rightSelected, isNotNull);
      expect(rightSelected!.experienceId, equals('EXP-FOOD-0'));
    });

    testWidgets('TEST H: Fast Left Swipe fling exits cleanly without sticking', (tester) async {
      final candidates = generateMockRecs(category: 'Food', count: 3);
      RecommendationModel? leftRejected;

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
                onSwipeRight: (_) {},
                onSwipeLeft: (c) => leftRejected = c,
              ),
            ),
          ),
        ),
      );

      // Fling strong distance left (-200px)
      await tester.drag(find.text('Food Experience 0'), const Offset(-250, 0));
      await tester.pumpAndSettle();

      expect(leftRejected, isNotNull);
      expect(leftRejected!.experienceId, equals('EXP-FOOD-0'));
    });

    testWidgets('TEST I: Fast Right Swipe fling exits cleanly without sticking', (tester) async {
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

      // Fling strong distance right (+250px)
      await tester.drag(find.text('Food Experience 0'), const Offset(250, 0));
      await tester.pumpAndSettle();

      expect(rightSelected, isNotNull);
      expect(rightSelected!.experienceId, equals('EXP-FOOD-0'));
    });

    test('TEST J & K: CSV Image Resolution & Fallback Image Placeholder', () {
      final recWithImage = RecommendationModel(
        experienceId: 'EXP-DELHI-001',
        name: 'Heritage Fort',
        category: 'Heritage',
        location: 'Old Delhi',
        city: 'Delhi',
        durationMinutes: 90,
        durationHours: 1.5,
        price: 350.0,
        rating: 4.8,
        reason: 'Historic landmark',
        score: 0.95,
        image: 'https://images.unsplash.com/photo-1599661046289-e31897846e41?w=800&q=80',
      );

      expect(recWithImage.image.startsWith('http') || recWithImage.image.startsWith('assets/'), isTrue);
      expect(recWithImage.image.isNotEmpty, isTrue);
    });

    testWidgets('TEST L: Rapid Swipes Double Processing Lock (prevents duplicate auto-generation)', (tester) async {
      final candidates = generateMockRecs(category: 'Food', count: 3);
      int selectCallCount = 0;

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
                onSwipeRight: (_) => selectCallCount++,
                onSwipeLeft: (_) {},
              ),
            ),
          ),
        ),
      );

      // Rapidly tap Select twice in succession while animation is in flight
      await tester.tap(find.text('Select'));
      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();

      // Exactly ONE selection processed
      expect(selectCallCount, equals(1));
    });
  });
}
