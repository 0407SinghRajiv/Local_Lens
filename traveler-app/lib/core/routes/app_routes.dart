class AppRoutes {
  AppRoutes._();

  // Onboarding & Authentication
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String googleLogin = '/google-login';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String onboarding = '/onboarding';

  // Trip Setup Flow
  static const String tripSetup = '/trip-setup';
  static const String travelGroup = '/travel-group';
  static const String interestSelection = '/interests';
  static const String budget = '/budget';
  static const String travelHistory = '/travel-history';
  static const String aiPersonalization = '/ai-personalization';

  // Main Shell & Discovery
  static const String home = '/home';
  static const String explore = '/explore';

  // Experience Details & Map
  static const String experienceDetails = '/experience-details';
  static const String experienceMap = '/experience-map';
  static const String saved = '/saved';

  // Itinerary
  static const String aiItinerary = '/ai-itinerary';
  static const String myItinerary = '/my-itinerary';
  static const String aiReplanning = '/ai-replanning';

  // Live Trip & Navigation
  static const String liveTrip = '/live-trip';
  static const String navigation = '/navigation';
  static const String weatherChange = '/weather-change';
  static const String soldOut = '/sold-out';

  // Lens Ride Transportation
  static const String lensRideBooking = '/lens-ride-booking';
  static const String rideSearching = '/ride-searching';
  static const String driverAssigned = '/driver-assigned';
  static const String tripComplete = '/trip-complete';

  // Wrap-up, Profile, Notifications & Settings
  static const String adventureComplete = '/adventure-complete';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String travelPersonality = '/travel-personality';
  static const String settings = '/settings';
  static const String designSystem = '/design-system';
  static const String error = '/error';
}
