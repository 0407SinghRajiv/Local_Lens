import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traveler_app/models/recommendation_model.dart';
import 'package:traveler_app/providers/itinerary_provider.dart';
import 'package:traveler_app/services/groq_itinerary_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Groq AI Itinerary Optimizer & Category Exclusion Tests', () {
    test('TEST 1: GroqItineraryService analyzes "i want to change food with beaches so generate it"', () async {
      final result = await GroqItineraryService.analyzeRequest(
        prompt: 'i want to change food with beaches so generate it',
        destination: 'Mumbai',
        currentInterests: ['Food', 'Culture'],
        budget: 5000.0,
        durationHours: 6.0,
        currentPlaceNames: ['Local Cafe', 'Street Food Tour', 'Gateway of India'],
      );

      expect(result.reply, isNotEmpty);
      expect(result.removeInterests.any((i) => i.toLowerCase().contains('food')), isTrue);
      expect(result.addInterests.any((i) => i.toLowerCase().contains('beach')), isTrue);
      expect(result.shouldRegenerate, isTrue);
    });

    test('TEST 2: "he dont need the food" -> GroqItineraryService excludes Food for all categories', () async {
      final result = await GroqItineraryService.analyzeRequest(
        prompt: 'he dont need the food so generate it',
        destination: 'Mumbai',
        currentInterests: ['Food', 'Culture', 'Local Experiences'],
        budget: 4000.0,
        durationHours: 5.0,
        currentPlaceNames: ['Misal Pav Center', 'Fort Walk'],
      );

      expect(result.removeInterests.any((i) => i.toLowerCase().contains('food')), isTrue);
      expect(result.shouldRegenerate, isTrue);
    });

    test('TEST 3: Negative constraint parsing works for ALL categories', () async {
      final beachRes = await GroqItineraryService.analyzeRequest(
        prompt: 'no beaches in my trip',
        destination: 'Mumbai',
        currentInterests: ['Beach', 'Culture'],
        budget: 3000.0,
        durationHours: 4.0,
        currentPlaceNames: [],
      );
      expect(beachRes.removeInterests.contains('Beach'), isTrue);

      final advRes = await GroqItineraryService.analyzeRequest(
        prompt: 'dont want adventure or trekking',
        destination: 'Mumbai',
        currentInterests: ['Adventure', 'Nature'],
        budget: 3000.0,
        durationHours: 4.0,
        currentPlaceNames: [],
      );
      expect(advRes.removeInterests.contains('Adventure'), isTrue);

      final shopRes = await GroqItineraryService.analyzeRequest(
        prompt: 'skip shopping and markets',
        destination: 'Mumbai',
        currentInterests: ['Shopping', 'Heritage'],
        budget: 3000.0,
        durationHours: 4.0,
        currentPlaceNames: [],
      );
      expect(shopRes.removeInterests.contains('Shopping'), isTrue);

      final nightRes = await GroqItineraryService.analyzeRequest(
        prompt: 'exclude nightlife and bars',
        destination: 'Mumbai',
        currentInterests: ['Nightlife', 'Food'],
        budget: 3000.0,
        durationHours: 4.0,
        currentPlaceNames: [],
      );
      expect(nightRes.removeInterests.contains('Nightlife'), isTrue);
    });

    test('TEST 4: RecommendationModel.matchesExcludedCategory filters out ALL food experiences', () {
      const foodExp = RecommendationModel(
        experienceId: 'EXP-1',
        name: 'Famous Vada Pav & Misal Stall',
        category: 'Food',
        subCategory: 'Street Food',
        location: 'Dadar, Mumbai',
        city: 'Mumbai',
        durationMinutes: 45,
        durationHours: 0.75,
        price: 150.0,
        reason: 'Iconic spicy misal pav tasting',
        score: 0.95,
        image: 'assets/food.png',
      );

      const beachExp = RecommendationModel(
        experienceId: 'EXP-2',
        name: 'Juhu Beach Sunset Walk',
        category: 'Beach',
        subCategory: 'Coastal Walk',
        location: 'Juhu, Mumbai',
        city: 'Mumbai',
        durationMinutes: 90,
        durationHours: 1.5,
        price: 0.0,
        reason: 'Scenic sunset view by the sea',
        score: 0.92,
        image: 'assets/beach.png',
      );

      const fortExp = RecommendationModel(
        experienceId: 'EXP-3',
        name: 'Karnala Fort Trek',
        category: 'Heritage',
        subCategory: 'Fort',
        location: 'Panvel, Maharashtra',
        city: 'Panvel',
        durationMinutes: 180,
        durationHours: 3.0,
        price: 50.0,
        reason: 'Historic hill fort and sanctuary',
        score: 0.88,
        image: 'assets/fort.png',
      );

      // Verify Food exclusion matches food item but NOT beach or fort
      expect(foodExp.matchesExcludedCategory('Food'), isTrue);
      expect(beachExp.matchesExcludedCategory('Food'), isFalse);
      expect(fortExp.matchesExcludedCategory('Food'), isFalse);

      // Verify Beach exclusion matches beach item but NOT food or fort
      expect(beachExp.matchesExcludedCategory('Beach'), isTrue);
      expect(foodExp.matchesExcludedCategory('Beach'), isFalse);
      expect(fortExp.matchesExcludedCategory('Beach'), isFalse);

      // Filtering a candidate list with 'Food' excluded results in exactly ZERO food experiences
      final mixedList = [foodExp, beachExp, fortExp];
      final filteredList = mixedList.where((item) => !item.matchesExcludedCategory('Food')).toList();

      expect(filteredList.length, 2);
      expect(filteredList.any((item) => item.category == 'Food'), isFalse);
      expect(filteredList.any((item) => item.matchesExcludedCategory('Food')), isFalse);
      expect(filteredList.map((e) => e.name), contains('Juhu Beach Sunset Walk'));
      expect(filteredList.map((e) => e.name), contains('Karnala Fort Trek'));
    });

    test('TEST 5: ItineraryNotifier applyOptimizationChanges updates excludedCategories and purges existing food recommendations', () {
      final container = ProviderContainer();
      final notifier = container.read(itineraryProvider.notifier);

      const foodExp = RecommendationModel(
        experienceId: 'EXP-FOOD',
        name: 'Chowpatty Street Food Feast',
        category: 'Food',
        location: 'Girgaum Chowpatty',
        city: 'Mumbai',
        durationMinutes: 60,
        durationHours: 1.0,
        price: 300,
        reason: 'Delicious kulfi and chaat',
        score: 0.90,
        image: 'assets/food.png',
      );

      const beachExp = RecommendationModel(
        experienceId: 'EXP-BEACH',
        name: 'Girgaum Chowpatty Sea View',
        category: 'Beach',
        location: 'Girgaum',
        city: 'Mumbai',
        durationMinutes: 60,
        durationHours: 1.0,
        price: 0,
        reason: 'Relaxing Arabian Sea views',
        score: 0.89,
        image: 'assets/beach.png',
      );

      // Manually set initial recommendations containing food and beach
      notifier.setSelectedPlaces([foodExp]);

      // Apply optimization: Traveler says he doesn't need food
      notifier.applyOptimizationChanges(
        removeInterests: ['Food'],
        addInterests: ['Beach'],
        customNotes: 'No food items or dining experiences wanted',
      );

      final state = container.read(itineraryProvider);
      expect(state.excludedCategories, contains('Food'));
      expect(state.interests, isNot(contains('Food')));
      expect(state.interests, contains('Beach'));
      expect(state.selectedPlaces, isEmpty);
      expect(state.selectedExperienceIds, isEmpty);
    });

    test('TEST 6: RecommendationModel.matchesInterest strictly matches traveler interests across categories', () {
      const beachExp = RecommendationModel(
        experienceId: 'EXP-B',
        name: 'Kashid White Sand Beach Walk',
        category: 'Beach',
        subCategory: 'Beach Walk',
        location: 'Kashid',
        city: 'Kashid',
        durationMinutes: 120,
        durationHours: 2.0,
        price: 400,
        reason: 'Scenic white sand beach coastline',
        score: 0.94,
        image: 'assets/beach.png',
      );

      const foodExp = RecommendationModel(
        experienceId: 'EXP-F',
        name: 'Authentic Misal Pav Tasting',
        category: 'Food',
        subCategory: 'Street Food',
        location: 'Panvel',
        city: 'Panvel',
        durationMinutes: 45,
        durationHours: 0.75,
        price: 150,
        reason: 'Local breakfast delicacy',
        score: 0.91,
        image: 'assets/food.png',
      );

      const advExp = RecommendationModel(
        experienceId: 'EXP-A',
        name: 'Valley Rappelling & Climbing',
        category: 'Adventure',
        subCategory: 'Climbing',
        location: 'Kharghar',
        city: 'Kharghar',
        durationMinutes: 90,
        durationHours: 1.5,
        price: 600,
        reason: 'Thrilling adventure',
        score: 0.89,
        image: 'assets/adv.png',
      );

      // Verify individual interest matches
      expect(beachExp.matchesInterest('Beach'), isTrue);
      expect(beachExp.matchesInterest('Food'), isFalse);
      expect(foodExp.matchesInterest('Food'), isTrue);
      expect(foodExp.matchesInterest('Beach'), isFalse);
      expect(advExp.matchesInterest('Adventure'), isTrue);
      expect(advExp.matchesInterest('Food'), isFalse);

      // Verify list matching (traveler selected only Beach)
      final candidates = [beachExp, foodExp, advExp];
      final beachOnly = candidates.where((c) => c.matchesAnyInterest(['Beach'])).toList();
      expect(beachOnly.length, equals(1));
      expect(beachOnly.first.name, equals('Kashid White Sand Beach Walk'));

      // Verify list matching (traveler selected Food and Adventure)
      final foodAndAdv = candidates.where((c) => c.matchesAnyInterest(['Food', 'Adventure'])).toList();
      expect(foodAndAdv.length, equals(2));
      expect(foodAndAdv.any((c) => c.name.contains('Beach')), isFalse);
    });
  });
}

