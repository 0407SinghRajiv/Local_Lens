import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/itinerary_model.dart';
import '../models/recommendation_model.dart';
import '../services/itinerary_api_service.dart';

enum LocationMode { exact, destination }

enum ItineraryFormStatus {
  initial,
  editing,
  fetchingRecommendations,
  recommendationsLoaded,
  generating,
  generated,
  error,
}

class CreateItineraryState {
  final LocationMode locationMode;
  final double? latitude;
  final double? longitude;
  final String destination;
  final String displayAddress;
  final String availableTime; // e.g. "6"
  final String availableTimeUnit; // "Hours" or "Days"
  final int availableTimeMinutes; // e.g. 360
  final double totalBudgetInr; // e.g. 3000
  final int travelerCount; // e.g. 2
  final String groupType; // "Solo", "Couple", "Friends", "Family"
  final int desiredExperienceCount; // e.g. 4 (Number of experiences wanted in itinerary)
  final List<String> interests;
  final List<String> excludedCategories;
  final String preferences;

  // ML Recommendations & Selection Stage
  final List<RecommendationModel> recommendations;
  final Set<String> selectedExperienceIds;
  final List<RecommendationModel> selectedPlaces;
  final String tripDate; // "2026-09-26"
  final String tripStartTime; // "10:30 AM"

  final ItineraryFormStatus status;
  final String? error;
  final Itinerary? generatedItinerary;
  final List<Itinerary> savedTrips;
  final String activeWeatherCondition;

  const CreateItineraryState({
    this.locationMode = LocationMode.destination,
    this.latitude = 18.9894,
    this.longitude = 73.1175,
    this.destination = 'Mumbai',
    this.displayAddress = 'Panvel, Maharashtra',
    this.availableTime = '6',
    this.availableTimeUnit = 'Hours',
    this.availableTimeMinutes = 360,
    this.totalBudgetInr = 3000,
    this.travelerCount = 2,
    this.groupType = 'Couple',
    this.desiredExperienceCount = 4,
    this.interests = const ['Food', 'Culture', 'Local Experiences'],
    this.excludedCategories = const [],
    this.preferences = '',
    this.recommendations = const [],
    this.selectedExperienceIds = const {},
    this.selectedPlaces = const [],
    this.tripDate = '2026-09-26',
    this.tripStartTime = '10:30 AM',
    this.status = ItineraryFormStatus.initial,
    this.error,
    this.generatedItinerary,
    this.savedTrips = const [],
    this.activeWeatherCondition = 'Live',
  });

  /// Form validation rule:
  /// Requires valid location or destination, available time > 0, and budget > 0
  bool get isValid {
    final hasLocation = locationMode == LocationMode.exact
        ? displayAddress.trim().isNotEmpty
        : destination.trim().isNotEmpty;
    final hasTime = availableTimeMinutes > 0;
    final hasBudget = totalBudgetInr > 0;
    final hasTravelers = travelerCount > 0;
    final hasExperiences = desiredExperienceCount > 0;
    return hasLocation && hasTime && hasBudget && hasTravelers && hasExperiences;
  }

  /// Total duration in hours
  double get durationHours => availableTimeMinutes / 60.0;

  CreateItineraryState copyWith({
    LocationMode? locationMode,
    double? latitude,
    double? longitude,
    String? destination,
    String? displayAddress,
    String? availableTime,
    String? availableTimeUnit,
    int? availableTimeMinutes,
    double? totalBudgetInr,
    int? travelerCount,
    String? groupType,
    int? desiredExperienceCount,
    List<String>? interests,
    List<String>? excludedCategories,
    String? preferences,
    List<RecommendationModel>? recommendations,
    Set<String>? selectedExperienceIds,
    List<RecommendationModel>? selectedPlaces,
    String? tripDate,
    String? tripStartTime,
    ItineraryFormStatus? status,
    String? error,
    Itinerary? generatedItinerary,
    List<Itinerary>? savedTrips,
    String? activeWeatherCondition,
  }) {
    return CreateItineraryState(
      locationMode: locationMode ?? this.locationMode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      destination: destination ?? this.destination,
      displayAddress: displayAddress ?? this.displayAddress,
      availableTime: availableTime ?? this.availableTime,
      availableTimeUnit: availableTimeUnit ?? this.availableTimeUnit,
      availableTimeMinutes: availableTimeMinutes ?? this.availableTimeMinutes,
      totalBudgetInr: totalBudgetInr ?? this.totalBudgetInr,
      travelerCount: travelerCount ?? this.travelerCount,
      groupType: groupType ?? this.groupType,
      desiredExperienceCount: desiredExperienceCount ?? this.desiredExperienceCount,
      interests: interests ?? this.interests,
      excludedCategories: excludedCategories ?? this.excludedCategories,
      preferences: preferences ?? this.preferences,
      recommendations: recommendations ?? this.recommendations,
      selectedExperienceIds: selectedExperienceIds ?? this.selectedExperienceIds,
      selectedPlaces: selectedPlaces ?? this.selectedPlaces,
      tripDate: tripDate ?? this.tripDate,
      tripStartTime: tripStartTime ?? this.tripStartTime,
      status: status ?? this.status,
      error: error,
      generatedItinerary: generatedItinerary ?? this.generatedItinerary,
      savedTrips: savedTrips ?? this.savedTrips,
      activeWeatherCondition: activeWeatherCondition ?? this.activeWeatherCondition,
    );
  }
}

class ItineraryNotifier extends StateNotifier<CreateItineraryState> {
  ItineraryNotifier() : super(const CreateItineraryState());

  void setLocationMode(LocationMode mode) {
    state = state.copyWith(locationMode: mode);
  }

  void setExactLocation(double lat, double lng, String address) {
    state = state.copyWith(
      locationMode: LocationMode.exact,
      latitude: lat,
      longitude: lng,
      displayAddress: address,
    );
  }

  void setDestination(String destination) {
    state = state.copyWith(
      destination: destination,
      locationMode: LocationMode.destination,
    );
  }

  void setTime(String timeValue, String unit) {
    final parsed = int.tryParse(timeValue) ?? 6;
    final minutes = unit == 'Days' ? parsed * 1440 : parsed * 60;
    state = state.copyWith(
      availableTime: timeValue,
      availableTimeUnit: unit,
      availableTimeMinutes: minutes,
    );
  }

  void setBudget(double budget) {
    state = state.copyWith(totalBudgetInr: budget);
  }

  void setGroup(String groupType, int travelerCount) {
    state = state.copyWith(
      groupType: groupType,
      travelerCount: travelerCount,
    );
  }

  void setTravelerCount(int travelerCount) {
    final clamped = travelerCount.clamp(1, 20);
    String detectedGroup = state.groupType;
    if (clamped == 1) {
      detectedGroup = 'Solo';
    } else if (clamped == 2) {
      detectedGroup = 'Couple';
    } else if (clamped <= 5) {
      detectedGroup = 'Friends';
    } else {
      detectedGroup = 'Family';
    }
    state = state.copyWith(
      travelerCount: clamped,
      groupType: detectedGroup,
    );
  }

  void setDesiredExperienceCount(int count) {
    state = state.copyWith(desiredExperienceCount: count.clamp(1, 12));
  }

  void toggleInterest(String interest) {
    final updated = List<String>.from(state.interests);
    if (updated.contains(interest)) {
      updated.remove(interest);
    } else {
      updated.add(interest);
    }
    state = state.copyWith(interests: updated);
  }

  /// Apply conversational optimization changes from Groq Chatbot
  void applyOptimizationChanges({
    List<String>? removeInterests,
    List<String>? addInterests,
    String? customNotes,
    double? budget,
    double? durationHours,
  }) {
    final currentInterests = List<String>.from(state.interests);
    final currentExcluded = List<String>.from(state.excludedCategories);

    if (removeInterests != null) {
      for (final r in removeInterests) {
        currentInterests.removeWhere((i) => i.toLowerCase() == r.toLowerCase());
        if (!currentExcluded.any((e) => e.toLowerCase() == r.toLowerCase())) {
          currentExcluded.add(r);
        }
      }
    }
    if (addInterests != null) {
      for (final a in addInterests) {
        currentExcluded.removeWhere((e) => e.toLowerCase() == a.toLowerCase());
        if (!currentInterests.any((i) => i.toLowerCase() == a.toLowerCase())) {
          currentInterests.add(a);
        }
      }
    }

    String updatedPref = state.preferences;
    if (customNotes != null && customNotes.trim().isNotEmpty) {
      updatedPref = updatedPref.isNotEmpty
          ? '$updatedPref; ${customNotes.trim()}'
          : customNotes.trim();
    }

    // Filter existing recommendations to purge any excluded items
    final filteredRecs = state.recommendations.where((rec) {
      for (final ex in currentExcluded) {
        if (rec.matchesExcludedCategory(ex)) return false;
      }
      return true;
    }).toList();

    state = state.copyWith(
      interests: currentInterests,
      excludedCategories: currentExcluded,
      preferences: updatedPref,
      totalBudgetInr: budget ?? state.totalBudgetInr,
      availableTimeMinutes: durationHours != null ? (durationHours * 60).round() : state.availableTimeMinutes,
      recommendations: filteredRecs,
      // Clear previous swipe selections so user can swipe fresh recommendations
      selectedPlaces: const [],
      selectedExperienceIds: const {},
    );
  }

  void setPreferences(String preferences) {
    state = state.copyWith(preferences: preferences);
  }

  void setTripDate(String date) {
    state = state.copyWith(tripDate: date);
  }

  void setTripStartTime(String time) {
    state = state.copyWith(tripStartTime: time);
  }

  void toggleExperienceSelection(String experienceId) {
    final current = Set<String>.from(state.selectedExperienceIds);
    if (current.contains(experienceId)) {
      current.remove(experienceId);
    } else {
      current.add(experienceId);
    }
    state = state.copyWith(selectedExperienceIds: current);
  }

  void setSelectedExperienceIds(Set<String> ids) {
    state = state.copyWith(selectedExperienceIds: ids);
  }

  void setSelectedPlaces(List<RecommendationModel> places) {
    final ids = places.map((p) => p.experienceId).toSet();
    state = state.copyWith(
      selectedPlaces: places,
      selectedExperienceIds: ids,
    );
  }

  void selectAllRecommendations() {
    final allIds = state.recommendations.map((r) => r.experienceId).toSet();
    state = state.copyWith(
      selectedExperienceIds: allIds,
      selectedPlaces: state.recommendations,
    );
  }

  /// STAGE 1: Fetch ML Recommendations based on traveler preferences
  Future<List<RecommendationModel>> fetchRecommendations() async {
    state = state.copyWith(
      status: ItineraryFormStatus.fetchingRecommendations,
      error: null,
    );

    try {
      final dest = state.locationMode == LocationMode.exact
          ? state.displayAddress
          : (state.destination.isNotEmpty ? state.destination : 'Mumbai');

      final recs = await ItineraryApiService.fetchRecommendations(
        destination: dest,
        startLocation: state.displayAddress,
        startLat: state.latitude,
        startLon: state.longitude,
        budget: state.totalBudgetInr,
        durationHours: state.durationHours,
        travelerCount: state.travelerCount,
        travelerType: state.groupType,
        interests: state.interests,
        preferences: state.preferences,
        excludedCategories: state.excludedCategories,
        topN: 50,
      );

      // Strictly purge any items matching excluded categories
      var filteredRecs = recs.where((rec) {
        for (final ex in state.excludedCategories) {
          if (rec.matchesExcludedCategory(ex)) return false;
        }
        return true;
      }).toList();

      // If traveler selected specific interests, ensure recommendations match those interests
      if (state.interests.isNotEmpty) {
        final interestMatches = filteredRecs.where((r) => r.matchesAnyInterest(state.interests)).toList();
        if (interestMatches.isNotEmpty) {
          filteredRecs = interestMatches;
        }
      }

      state = state.copyWith(
        status: ItineraryFormStatus.recommendationsLoaded,
        recommendations: filteredRecs,
        selectedPlaces: const [],
        selectedExperienceIds: const {},
      );

      return filteredRecs;
    } catch (e) {
      state = state.copyWith(
        status: ItineraryFormStatus.error,
        error: 'Failed to find recommendations. Please try again.',
      );
      return [];
    }
  }

  void setWeatherCondition(String condition) {
    state = state.copyWith(activeWeatherCondition: condition);
  }

  /// Adapt current itinerary according to specified weather condition
  Future<Itinerary?> adaptItineraryForWeather(String weatherCondition) async {
    state = state.copyWith(activeWeatherCondition: weatherCondition);
    final currentItin = state.generatedItinerary;
    if (currentItin == null) return null;

    final isRainOrStorm = weatherCondition.toLowerCase().contains('rain') ||
        weatherCondition.toLowerCase().contains('storm');

    // Adapt items ordering for weather
    List<ItineraryItem> adaptedItems = List.from(currentItin.items);
    if (isRainOrStorm) {
      adaptedItems.sort((a, b) {
        if (a.isShelteredIndoor && b.isOutdoor) return -1;
        if (a.isOutdoor && b.isShelteredIndoor) return 1;
        return 0;
      });
    }

    try {
      final updatedItin = await generateFinalItinerary(weatherOverride: weatherCondition);
      return updatedItin ?? currentItin.copyWith(items: adaptedItems);
    } catch (_) {
      final fallbackAdapted = currentItin.copyWith(items: adaptedItems);
      state = state.copyWith(generatedItinerary: fallbackAdapted);
      return fallbackAdapted;
    }
  }

  /// STAGE 2: Generate Chronological Itinerary from selected experiences + start time
  Future<Itinerary?> generateFinalItinerary({String? weatherOverride}) async {
    state = state.copyWith(
      status: ItineraryFormStatus.generating,
      error: null,
    );

    try {
      final dest = state.locationMode == LocationMode.exact
          ? state.displayAddress
          : (state.destination.isNotEmpty ? state.destination : 'Mumbai');

      final selectedPlacesList = state.selectedPlaces.isNotEmpty
          ? state.selectedPlaces
          : (state.recommendations.isNotEmpty
              ? state.recommendations.where((r) => state.selectedExperienceIds.contains(r.experienceId)).toList()
              : <RecommendationModel>[]);

      final targetCount = state.desiredExperienceCount > 0 ? state.desiredExperienceCount : 4;
      final selectedList = selectedPlacesList.isNotEmpty
          ? selectedPlacesList.map((p) => p.experienceId).toList()
          : (state.selectedExperienceIds.isNotEmpty
              ? state.selectedExperienceIds.toList()
              : (state.recommendations.isNotEmpty
                  ? state.recommendations.take(targetCount).map((r) => r.experienceId).toList()
                  : List.generate(targetCount, (i) => 'EXP-DELHI-${(i + 1).toString().padLeft(3, '0')}')));

      debugPrint('[ItineraryProvider] Requested: $targetCount, Selected: ${selectedPlacesList.length}, Sent to backend: ${selectedList.length}');

      final activeCondition = weatherOverride ?? (state.activeWeatherCondition != 'Live' ? state.activeWeatherCondition : null);

      final itinerary = await ItineraryApiService.generateItinerary(
        destination: dest,
        tripDate: state.tripDate,
        startTime: state.tripStartTime,
        durationHours: state.durationHours,
        budget: state.totalBudgetInr,
        startLocation: state.displayAddress,
        startLat: state.latitude,
        startLon: state.longitude,
        selectedExperienceIds: selectedList,
        selectedPlacesModels: selectedPlacesList,
        travelerCount: state.travelerCount,
        travelerType: state.groupType,
        weatherCondition: activeCondition,
      );

      debugPrint('[ItineraryProvider] Returned itinerary stops: ${itinerary.items.length}');

      // Automatically save to database & user trips
      ItineraryApiService.saveItineraryToDatabase(itinerary);
      final currentTrips = List<Itinerary>.from(state.savedTrips);
      final existingIndex = currentTrips.indexWhere((t) => t.id == itinerary.id);
      if (existingIndex >= 0) {
        currentTrips[existingIndex] = itinerary;
      } else {
        currentTrips.insert(0, itinerary);
      }

      state = state.copyWith(
        status: ItineraryFormStatus.generated,
        generatedItinerary: itinerary,
        savedTrips: currentTrips,
      );
      return itinerary;
    } catch (e) {
      // Fallback generator ensures user is never blocked
      final dest = state.locationMode == LocationMode.exact
          ? state.displayAddress
          : (state.destination.isNotEmpty ? state.destination : 'Panvel, Maharashtra');
      final fallbackItin = ItineraryApiService.generateItinerary(
        destination: dest,
        tripDate: state.tripDate,
        startTime: state.tripStartTime,
        durationHours: state.durationHours,
        budget: state.totalBudgetInr,
        selectedExperienceIds: state.selectedPlaces.isNotEmpty
            ? state.selectedPlaces.map((p) => p.experienceId).toList()
            : state.selectedExperienceIds.toList(),
        selectedPlacesModels: state.selectedPlaces,
        travelerCount: state.travelerCount,
        travelerType: state.groupType,
      );
      final resolved = await fallbackItin;
      ItineraryApiService.saveItineraryToDatabase(resolved);

      final currentTrips = List<Itinerary>.from(state.savedTrips);
      final existingIndex = currentTrips.indexWhere((t) => t.id == resolved.id);
      if (existingIndex >= 0) {
        currentTrips[existingIndex] = resolved;
      } else {
        currentTrips.insert(0, resolved);
      }

      state = state.copyWith(
        status: ItineraryFormStatus.generated,
        generatedItinerary: resolved,
        savedTrips: currentTrips,
      );
      return resolved;
    }
  }

  /// Optimize current itinerary route and update database
  Future<Itinerary?> optimizeCurrentItinerary() async {
    if (state.generatedItinerary == null) return null;
    try {
      final optimized = await ItineraryApiService.optimizeItinerary(
        currentItinerary: state.generatedItinerary!,
      );
      await ItineraryApiService.saveItineraryToDatabase(optimized);
      saveItineraryToTrips(optimized);
      state = state.copyWith(generatedItinerary: optimized);
      return optimized;
    } catch (e) {
      debugPrint('[ItineraryNotifier] Error optimizing itinerary: $e');
      return state.generatedItinerary;
    }
  }

  /// Save given itinerary into savedTrips collection
  void saveItineraryToTrips(Itinerary itinerary) {
    final currentList = List<Itinerary>.from(state.savedTrips);
    final idx = currentList.indexWhere((t) => t.id == itinerary.id);
    if (idx >= 0) {
      currentList[idx] = itinerary;
    } else {
      currentList.insert(0, itinerary);
    }
    state = state.copyWith(savedTrips: currentList);
  }

  /// Explicitly save current itinerary to database and Trips collection
  Future<bool> saveCurrentItinerary() async {
    if (state.generatedItinerary == null) return false;
    final itin = state.generatedItinerary!;
    saveItineraryToTrips(itin);
    return await ItineraryApiService.saveItineraryToDatabase(itin);
  }

  /// Update actual expense for a specific experience stop
  void updateExperienceExpense(String itemId, double expense) {
    if (state.generatedItinerary == null) return;
    final currentItin = state.generatedItinerary!;
    final updatedItems = currentItin.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(actualExpense: expense);
      }
      return item;
    }).toList();
    final updatedItin = currentItin.copyWith(items: updatedItems);
    saveItineraryToTrips(updatedItin);
    state = state.copyWith(generatedItinerary: updatedItin);
    ItineraryApiService.saveItineraryToDatabase(updatedItin);
  }

  /// Mark experience as completed with rating, review, and expense tracking
  void completeExperience(String itemId, {double? rating, String? review, double? expense}) {
    if (state.generatedItinerary == null) return;
    final currentItin = state.generatedItinerary!;
    final updatedItems = currentItin.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
          travelerRating: rating ?? item.travelerRating ?? 5.0,
          travelerReview: review ?? item.travelerReview,
          actualExpense: expense ?? item.actualExpense,
          arrivedWithinProximity: true,
          dwellDurationMinutes: 5,
        );
      }
      return item;
    }).toList();
    final updatedItin = currentItin.copyWith(items: updatedItems);
    saveItineraryToTrips(updatedItin);
    state = state.copyWith(generatedItinerary: updatedItin);
    ItineraryApiService.saveItineraryToDatabase(updatedItin);
  }

  /// Sets the active itinerary for viewing and editing
  void setActiveItinerary(Itinerary itinerary) {
    state = state.copyWith(generatedItinerary: itinerary);
  }

  /// Toggle item selection in generated itinerary
  void toggleItemSelection(String itemId) {
    if (state.generatedItinerary == null) return;
    final currentItems = state.generatedItinerary!.items;
    final updatedItems = currentItems.map((item) {
      if (item.id == itemId) {
        return item.copyWith(isSelected: !item.isSelected);
      }
      return item;
    }).toList();

    final updatedItin = state.generatedItinerary!.copyWith(items: updatedItems);
    saveItineraryToTrips(updatedItin);
    state = state.copyWith(
      generatedItinerary: updatedItin,
    );
    ItineraryApiService.saveItineraryToDatabase(updatedItin);
  }

  /// Mark experience completed
  void markItemCompleted(String itemId) {
    completeExperience(itemId);
  }

  /// Attaches booked ride to itinerary
  void attachRideToItinerary(String rideId) {
    if (state.generatedItinerary == null) return;
    final updatedItin = state.generatedItinerary!.copyWith(
      hasRideAttached: true,
      attachedRideId: rideId,
    );
    saveItineraryToTrips(updatedItin);
    state = state.copyWith(
      generatedItinerary: updatedItin,
    );
    ItineraryApiService.saveItineraryToDatabase(updatedItin);
  }
}

final itineraryProvider =
    StateNotifierProvider<ItineraryNotifier, CreateItineraryState>((ref) {
  return ItineraryNotifier();
});

/// Alias for backward compatibility
final createItineraryProvider = itineraryProvider;
