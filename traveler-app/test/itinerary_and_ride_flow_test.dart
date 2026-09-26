import 'package:flutter_test/flutter_test.dart';
import 'package:traveler_app/models/itinerary_model.dart';
import 'package:traveler_app/models/ride_model.dart';
import 'package:traveler_app/providers/itinerary_provider.dart';
import 'package:traveler_app/providers/ride_provider.dart';
import 'package:traveler_app/services/dummy_itinerary_service.dart';

void main() {
  group('Itinerary Domain & DummyItineraryService Tests', () {
    test('DummyItineraryService generates tailored stops based on user parameters', () async {
      final itinerary = await DummyItineraryService.generateItinerary(
        destination: 'Panvel, Maharashtra',
        availableTimeMinutes: 180,
        totalBudgetInr: 2500,
        groupType: 'Solo',
        travelerCount: 1,
        interests: ['Food', 'Culture'],
      );

      expect(itinerary.id.isNotEmpty, isTrue);
      expect(itinerary.destination, 'Panvel, Maharashtra');
      expect(itinerary.items.isNotEmpty, isTrue);
      expect(itinerary.totalDurationMinutes, greaterThan(0));
      expect(itinerary.totalEstimatedCost, greaterThan(0));
      expect(itinerary.selectedItems.length, itinerary.items.length);
    });

    test('Itinerary model dynamically recalculates cost and duration when items are unselected', () {
      final item1 = ItineraryItem(
        id: '1',
        experienceName: 'Breakfast',
        category: 'Food',
        location: 'Panvel',
        description: 'Chai and poha',
        startTime: '09:00',
        endTime: '09:45',
        durationMinutes: 45,
        price: 250,
        distanceKm: 1.0,
        image: 'assets/images/destinations/food_trail.png',
        isSelected: true,
      );

      final item2 = ItineraryItem(
        id: '2',
        experienceName: 'Heritage Walk',
        category: 'Culture',
        location: 'Old Town',
        description: 'Ancient trail',
        startTime: '10:00',
        endTime: '11:15',
        durationMinutes: 75,
        price: 350,
        distanceKm: 2.0,
        image: 'assets/images/destinations/heritage_walk.png',
        isSelected: true,
      );

      var itinerary = Itinerary(
        id: 'itin-test',
        destination: 'Panvel',
        startTime: '09:00',
        endTime: '11:15',
        totalDurationMinutes: 120,
        totalEstimatedCost: 600,
        items: [item1, item2],
        createdAt: DateTime.now(),
      );

      expect(itinerary.totalSelectedCost, 600.0);
      expect(itinerary.totalSelectedDurationMinutes, 120);
      expect(itinerary.formattedDuration, '2h');

      // Unselect item 2
      itinerary = itinerary.copyWith(
        items: [item1, item2.copyWith(isSelected: false)],
      );

      expect(itinerary.selectedItems.length, 1);
      expect(itinerary.totalSelectedCost, 250.0);
      expect(itinerary.totalSelectedDurationMinutes, 45);
      expect(itinerary.formattedDuration, '45m');
    });

    test('ItineraryNotifier state management and form validation', () {
      final notifier = ItineraryNotifier();
      expect(notifier.state.isValid, isTrue);

      notifier.setTime('5', 'Hours');
      expect(notifier.state.availableTimeMinutes, 300);

      notifier.setBudget(5000);
      expect(notifier.state.totalBudgetInr, 5000.0);

      notifier.setDestination('Alibaug');
      expect(notifier.state.destination, 'Alibaug');
      expect(notifier.state.locationMode, LocationMode.destination);

      notifier.toggleInterest('Photography');
      expect(notifier.state.interests.contains('Photography'), isTrue);

      notifier.toggleInterest('Photography');
      expect(notifier.state.interests.contains('Photography'), isFalse);
    });
  });

  group('Lens Ride State & Simulation Tests', () {
    test('RideNotifier vehicle selection and simulated booking flow', () async {
      final notifier = RideNotifier();
      expect(notifier.state.status, RideStatus.idle);

      final suv = VehicleOption.defaultOptions.firstWhere((v) => v.type == VehicleType.suv);
      notifier.selectVehicle(suv);
      expect(notifier.state.selectedVehicle.name, 'SUV');
      expect(notifier.state.status, RideStatus.vehicleSelected);

      await notifier.requestRide(
        pickup: 'Current Location',
        drop: 'Heritage Walk',
      );
      expect(notifier.state.status, RideStatus.searching);
      expect(notifier.state.currentRequest != null, isTrue);

      // Advance to driver arrival
      notifier.startDriverApproach();
      expect(notifier.state.status, RideStatus.riderArriving);

      notifier.markDriverArrived();
      expect(notifier.state.status, RideStatus.arrived);

      notifier.startTrip();
      expect(notifier.state.status, RideStatus.inProgress);

      notifier.completeTrip();
      expect(notifier.state.status, RideStatus.completed);

      notifier.resetRide();
      expect(notifier.state.status, RideStatus.idle);
    });
  });
}
