import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/google_login_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/design_system/design_system_screen.dart';
import '../../features/disruptions/sold_out_screen.dart';
import '../../features/disruptions/weather_change_screen.dart';
import '../../features/experience/experience_details_screen.dart';
import '../../features/experience/experience_map_screen.dart';
import '../../features/explore/explore_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/itinerary/ai_itinerary_screen.dart';
import '../../features/itinerary/ai_replanning_screen.dart';
import '../../features/itinerary/my_itinerary_screen.dart';
import '../../features/navigation/live_trip_mode_screen.dart';
import '../../features/navigation/navigation_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/profile/adventure_complete_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/travel_personality_screen.dart';
import '../../features/rides/driver_assigned_screen.dart';
import '../../features/rides/lens_ride_booking_screen.dart';
import '../../features/rides/ride_searching_screen.dart';
import '../../features/rides/trip_complete_screen.dart';
import '../../features/saved/saved_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/trip_setup/ai_personalization_screen.dart';
import '../../features/trip_setup/budget_screen.dart';
import '../../features/trip_setup/interest_selection_screen.dart';
import '../../features/trip_setup/travel_group_screen.dart';
import '../../features/trip_setup/travel_history_screen.dart';
import '../../features/trip_setup/trip_setup_screen.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      // 1. Splash & Onboarding
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => _buildPage(state, const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        pageBuilder: (context, state) => _buildPage(state, const WelcomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.googleLogin,
        pageBuilder: (context, state) => _buildPage(state, const GoogleLoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => _buildPage(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _buildPage(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (context, state) => _buildPage(state, const SignupScreen()),
      ),

      // 2. Trip Setup Flow
      GoRoute(
        path: AppRoutes.tripSetup,
        pageBuilder: (context, state) => _buildPage(state, const TripSetupScreen()),
      ),
      GoRoute(
        path: AppRoutes.travelGroup,
        pageBuilder: (context, state) => _buildPage(state, const TravelGroupScreen()),
      ),
      GoRoute(
        path: AppRoutes.interestSelection,
        pageBuilder: (context, state) => _buildPage(state, const InterestSelectionScreen()),
      ),
      GoRoute(
        path: AppRoutes.budget,
        pageBuilder: (context, state) => _buildPage(state, const BudgetScreen()),
      ),
      GoRoute(
        path: AppRoutes.travelHistory,
        pageBuilder: (context, state) => _buildPage(state, const TravelHistoryScreen()),
      ),
      GoRoute(
        path: AppRoutes.aiPersonalization,
        pageBuilder: (context, state) => _buildPage(state, const AIPersonalizationScreen()),
      ),

      // 3. Main Discovery & Explore
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) => _buildPage(state, const HomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.explore,
        pageBuilder: (context, state) => _buildPage(state, const ExploreScreen()),
      ),

      // 4. Experience Details & Maps
      GoRoute(
        path: AppRoutes.experienceDetails,
        pageBuilder: (context, state) => _buildPage(state, const ExperienceDetailsScreen()),
      ),
      GoRoute(
        path: AppRoutes.experienceMap,
        pageBuilder: (context, state) => _buildPage(state, const ExperienceMapScreen()),
      ),
      GoRoute(
        path: AppRoutes.saved,
        pageBuilder: (context, state) => _buildPage(state, const SavedScreen()),
      ),

      // 5. Itinerary & AI Replanning
      GoRoute(
        path: AppRoutes.aiItinerary,
        pageBuilder: (context, state) => _buildPage(state, const AIItineraryScreen()),
      ),
      GoRoute(
        path: AppRoutes.myItinerary,
        pageBuilder: (context, state) => _buildPage(state, const MyItineraryScreen()),
      ),
      GoRoute(
        path: AppRoutes.aiReplanning,
        pageBuilder: (context, state) => _buildPage(state, const AIReplanningScreen()),
      ),

      // 6. Live Trip & Navigation
      GoRoute(
        path: AppRoutes.liveTrip,
        pageBuilder: (context, state) => _buildPage(state, const LiveTripModeScreen()),
      ),
      GoRoute(
        path: AppRoutes.navigation,
        pageBuilder: (context, state) => _buildPage(state, const NavigationScreen()),
      ),
      GoRoute(
        path: AppRoutes.weatherChange,
        pageBuilder: (context, state) => _buildPage(state, const WeatherChangeScreen()),
      ),
      GoRoute(
        path: AppRoutes.soldOut,
        pageBuilder: (context, state) => _buildPage(state, const SoldOutScreen()),
      ),

      // 7. Lens Ride & Completion
      GoRoute(
        path: AppRoutes.lensRideBooking,
        pageBuilder: (context, state) => _buildPage(state, const LensRideBookingScreen()),
      ),
      GoRoute(
        path: AppRoutes.rideSearching,
        pageBuilder: (context, state) => _buildPage(state, const RideSearchingScreen()),
      ),
      GoRoute(
        path: AppRoutes.driverAssigned,
        pageBuilder: (context, state) => _buildPage(state, const DriverAssignedScreen()),
      ),
      GoRoute(
        path: AppRoutes.tripComplete,
        pageBuilder: (context, state) => _buildPage(state, const TripCompleteScreen()),
      ),
      GoRoute(
        path: AppRoutes.adventureComplete,
        pageBuilder: (context, state) => _buildPage(state, const AdventureCompleteScreen()),
      ),

      // 8. Notifications, Profile & Settings
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) => _buildPage(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) => _buildPage(state, const ProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.travelPersonality,
        pageBuilder: (context, state) => _buildPage(state, const TravelPersonalityScreen()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) => _buildPage(state, const SettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.designSystem,
        pageBuilder: (context, state) => _buildPage(state, const DesignSystemScreen()),
      ),
    ],
  );
});

Page<dynamic> _buildPage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
        child: child,
      );
    },
  );
}
