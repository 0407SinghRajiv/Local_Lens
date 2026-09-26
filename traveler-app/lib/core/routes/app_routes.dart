class AppRoutes {
  AppRoutes._();

  // Onboarding & Authentication
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String googleLogin = '/google-login';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String onboarding = '/onboarding';

  // Canonical Role Routes
  static const String travelerHome = '/traveler/home';
  static const String travelerExplore = '/traveler/explore';
  static const String travelerTrips = '/traveler/trips';
  static const String travelerSaved = '/traveler/saved';
  static const String travelerProfile = '/traveler/profile';

  // Future Role Guarded Placeholders
  static const String providerHome = '/provider/home';
  static const String riderHome = '/rider/home';
  static const String adminHome = '/admin/home';

  // Main Shell & Discovery Aliases
  static const String home = '/home';
  static const String explore = '/explore';
  static const String saved = '/saved';
  static const String profile = '/profile';
  static const String myItinerary = '/my-itinerary';

  // Canonical Traveler Flow Routes
  static const String travelerCreateItinerary = '/traveler/create-itinerary';
  static const String aiItineraryGenerating = '/traveler/itinerary/generating';
  static const String aiItineraryResult = '/traveler/itinerary/result';
  static const String travelerRideSelect = '/traveler/ride/select';
  static const String travelerRideSearching = '/traveler/ride/searching';
  static const String travelerRideAccepted = '/traveler/ride/accepted';
  static const String travelerRideLive = '/traveler/ride/live';
  static const String travelerRideCompleted = '/traveler/ride/completed';

  // Trip Setup Aliases
  static const String tripSetup = '/trip-setup';
  static const String travelGroup = '/travel-group';
  static const String interestSelection = '/interests';
  static const String budget = '/budget';
  static const String travelHistory = '/travel-history';
  static const String aiPersonalization = '/ai-personalization';

  // Experience Details & Map
  static const String experienceDetails = '/experience-details';
  static const String experienceMap = '/experience-map';

  // Itinerary Aliases
  static const String aiItinerary = '/ai-itinerary';
  static const String aiReplanning = '/ai-replanning';

  // Live Trip & Navigation Aliases
  static const String liveTrip = '/live-trip';
  static const String navigation = '/navigation';
  static const String weatherChange = '/weather-change';
  static const String soldOut = '/sold-out';

  // Lens Ride Transportation Aliases
  static const String lensRideBooking = '/lens-ride-booking';
  static const String rideSearching = '/ride-searching';
  static const String driverAssigned = '/driver-assigned';
  static const String tripComplete = '/trip-complete';

  // Wrap-up, Profile, Notifications & Settings
  static const String adventureComplete = '/adventure-complete';
  static const String notifications = '/notifications';
  static const String travelPersonality = '/travel-personality';
  static const String settings = '/settings';
  static const String designSystem = '/design-system';
  static const String error = '/error';
}
