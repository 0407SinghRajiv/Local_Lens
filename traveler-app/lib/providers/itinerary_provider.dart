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
  final List<String> interests;
  final String preferences;

  // ML Recommendations & Selection Stage
  final List<RecommendationModel> recommendations;
  final Set<String> selectedExperienceIds;
  final String tripDate; // "2026-09-26"
  final String tripStartTime; // "10:30 AM"

  final ItineraryFormStatus status;
  final String? error;
  final Itinerary? generatedItinerary;

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
    this.interests = const ['Food', 'Culture', 'Local Experiences'],
    this.preferences = '',
    this.recommendations = const [],
    this.selectedExperienceIds = const {},
    this.tripDate = '2026-09-26',
    this.tripStartTime = '10:30 AM',
    this.status = ItineraryFormStatus.initial,
    this.error,
    this.generatedItinerary,
  });

  /// Form validation rule:
  /// Requires valid location or destination, available time > 0, and budget > 0
  bool get isValid {
    final hasLocation = locationMode == LocationMode.exact
        ? displayAddress.trim().isNotEmpty
        : destination.trim().isNotEmpty;
    final hasTime = availableTimeMinutes > 0;
    final hasBudget = totalBudgetInr > 0;
    return hasLocation && hasTime && hasBudget;
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
    List<String>? interests,
    String? preferences,
    List<RecommendationModel>? recommendations,
    Set<String>? selectedExperienceIds,
    String? tripDate,
    String? tripStartTime,
    ItineraryFormStatus? status,
    String? error,
    Itinerary? generatedItinerary,
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
      interests: interests ?? this.interests,
      preferences: preferences ?? this.preferences,
      recommendations: recommendations ?? this.recommendations,
      selectedExperienceIds: selectedExperienceIds ?? this.selectedExperienceIds,
      tripDate: tripDate ?? this.tripDate,
      tripStartTime: tripStartTime ?? this.tripStartTime,
      status: status ?? this.status,
      error: error,
      generatedItinerary: generatedItinerary ?? this.generatedItinerary,
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

  void toggleInterest(String interest) {
    final updated = List<String>.from(state.interests);
    if (updated.contains(interest)) {
      updated.remove(interest);
    } else {
      updated.add(interest);
    }
    state = state.copyWith(interests: updated);
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

  void selectAllRecommendations() {
    final allIds = state.recommendations.map((r) => r.experienceId).toSet();
    state = state.copyWith(selectedExperienceIds: allIds);
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
      );

      // By default, select top 3-4 recommendations
      final initialSelected = recs.take(4).map((r) => r.experienceId).toSet();

      state = state.copyWith(
        status: ItineraryFormStatus.recommendationsLoaded,
        recommendations: recs,
        selectedExperienceIds: initialSelected,
      );

      return recs;
    } catch (e) {
      state = state.copyWith(
        status: ItineraryFormStatus.error,
        error: 'Failed to find recommendations. Please try again.',
      );
      return [];
    }
  }

  /// STAGE 2: Generate Chronological Itinerary from selected experiences + start time
  Future<Itinerary?> generateFinalItinerary() async {
    state = state.copyWith(
      status: ItineraryFormStatus.generating,
      error: null,
    );

    try {
      final dest = state.locationMode == LocationMode.exact
          ? state.displayAddress
          : (state.destination.isNotEmpty ? state.destination : 'Mumbai');

      final selectedList = state.selectedExperienceIds.isNotEmpty
          ? state.selectedExperienceIds.toList()
          : (state.recommendations.isNotEmpty
              ? state.recommendations.take(3).map((r) => r.experienceId).toList()
              : ['EXP-DELHI-001', 'EXP-DELHI-002']);

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
        travelerCount: state.travelerCount,
        travelerType: state.groupType,
      );

      state = state.copyWith(
        status: ItineraryFormStatus.generated,
        generatedItinerary: itinerary,
      );
      return itinerary;
    } catch (e) {
      state = state.copyWith(
        status: ItineraryFormStatus.error,
        error: 'Failed to generate itinerary. Please try again.',
      );
      return null;
    }
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

    state = state.copyWith(
      generatedItinerary: state.generatedItinerary!.copyWith(items: updatedItems),
    );
  }

  /// Mark experience completed
  void markItemCompleted(String itemId) {
    if (state.generatedItinerary == null) return;
    final currentItems = state.generatedItinerary!.items;
    final updatedItems = currentItems.map((item) {
      if (item.id == itemId) {
        return item.copyWith(isCompleted: true);
      }
      return item;
    }).toList();

    state = state.copyWith(
      generatedItinerary: state.generatedItinerary!.copyWith(items: updatedItems),
    );
  }

  /// Attaches booked ride to itinerary
  void attachRideToItinerary(String rideId) {
    if (state.generatedItinerary == null) return;
    state = state.copyWith(
      generatedItinerary: state.generatedItinerary!.copyWith(
        hasRideAttached: true,
        attachedRideId: rideId,
      ),
    );
  }
}

final itineraryProvider =
    StateNotifierProvider<ItineraryNotifier, CreateItineraryState>((ref) {
  return ItineraryNotifier();
});
