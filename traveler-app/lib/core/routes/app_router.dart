import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_state.dart';
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
import '../../features/itinerary/create_itinerary_screen.dart';
import '../../features/itinerary/itinerary_generating_screen.dart';
import '../../features/itinerary/generated_itinerary_screen.dart';
import '../../features/itinerary/ai_replanning_screen.dart';
import '../../features/itinerary/my_itinerary_screen.dart';
import '../../features/navigation/navigation_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/profile/adventure_complete_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/travel_personality_screen.dart';
import '../../features/rides/ride_accepted_screen.dart';
import '../../features/rides/lens_ride_booking_screen.dart';
import '../../features/rides/ride_searching_screen.dart';
import '../../features/rides/live_ride_screen.dart';
import '../../features/rides/ride_completed_screen.dart';
import '../../features/saved/saved_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/trip_setup/ai_personalization_screen.dart';
import '../../features/trip_setup/budget_screen.dart';
import '../../features/trip_setup/interest_selection_screen.dart';
import '../../features/trip_setup/travel_group_screen.dart';
import '../../features/trip_setup/travel_history_screen.dart';
import '../../models/user_role.dart';
import '../../providers/auth_provider.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = authNotifier.state;
      final status = authState.status;
      final role = authState.role ?? UserRole.traveler;
      final location = state.matchedLocation;

      debugPrint('[ROUTER] Evaluating redirect: loc=$location, status=$status, role=${role.value}');

      // 1. Splash / Initializing State
      if (status == AuthStatus.initializing) {
        if (location == AppRoutes.splash) return null;
        return AppRoutes.splash;
      }

      final isSplash = location == AppRoutes.splash;
      final isAuthRoute = location == AppRoutes.welcome ||
          location == AppRoutes.login ||
          location == AppRoutes.signup ||
          location == AppRoutes.googleLogin ||
          location == AppRoutes.onboarding;

      // 2. Unauthenticated State
      if (status == AuthStatus.unauthenticated) {
        if (isSplash) {
          debugPrint('[ROUTER] Redirecting unauthenticated user from splash to ${AppRoutes.welcome}');
          return AppRoutes.welcome;
        }
        if (isAuthRoute) {
          return null; // Allow unauthenticated user on auth pages
        }
        debugPrint('[ROUTER] Protected route $location accessed unauthenticated. Redirecting to ${AppRoutes.login}');
        return AppRoutes.login;
      }

      // 3. Authenticated State
      if (status == AuthStatus.authenticated) {
        const roleHome = AppRoutes.travelerHome;

        // If on splash or any auth route, automatically redirect to role home
        if (isSplash || isAuthRoute) {
          debugPrint('[ROUTER] Authenticated user on $location. Redirecting to $roleHome');
          return roleHome;
        }

        // Role guards: prevent traveler from accessing other role domains
        if (role == UserRole.traveler) {
          if (location.startsWith('/provider') ||
              location.startsWith('/rider') ||
              location.startsWith('/admin')) {
            debugPrint('[ROUTER] Role guard: traveler attempted to access $location. Redirecting to $roleHome');
            return roleHome;
          }
        }

        // Canonical alias handling
        if (location == AppRoutes.home) {
          return AppRoutes.travelerHome;
        }

        return null;
      }

      // 4. Error State Fallback
      if (status == AuthStatus.error) {
        if (isAuthRoute) return null;
        return AppRoutes.login;
      }

      return null;
    },
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

      // 2. Role Canonical Traveler Routes
      GoRoute(
        path: AppRoutes.travelerHome,
        pageBuilder: (context, state) => _buildPage(state, const HomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.travelerExplore,
        pageBuilder: (context, state) => _buildPage(state, const ExploreScreen()),
      ),
      GoRoute(
        path: AppRoutes.travelerTrips,
        pageBuilder: (context, state) => _buildPage(state, const MyItineraryScreen()),
      ),
      GoRoute(
        path: AppRoutes.travelerSaved,
        pageBuilder: (context, state) => _buildPage(state, const SavedScreen()),
      ),
      GoRoute(
        path: AppRoutes.travelerProfile,
        pageBuilder: (context, state) => _buildPage(state, const ProfileScreen()),
      ),

      // Legacy / Feature Root Aliases
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) => _buildPage(state, const HomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.explore,
        pageBuilder: (context, state) => _buildPage(state, const ExploreScreen()),
      ),

      // 3. Traveler Itinerary Flow (Canonical & Setup)
      GoRoute(
        path: AppRoutes.travelerCreateItinerary,
        pageBuilder: (context, state) => _buildPage(state, const CreateItineraryScreen()),
      ),
      GoRoute(
        path: AppRoutes.aiItineraryGenerating,
        pageBuilder: (context, state) => _buildPage(state, const ItineraryGeneratingScreen()),
      ),
      GoRoute(
        path: AppRoutes.aiItineraryResult,
        pageBuilder: (context, state) => _buildPage(state, const GeneratedItineraryScreen()),
      ),
      GoRoute(
        path: AppRoutes.aiItinerary,
        pageBuilder: (context, state) => _buildPage(state, const GeneratedItineraryScreen()),
      ),

      // Multi-step setup alternatives
      GoRoute(
        path: AppRoutes.tripSetup,
        pageBuilder: (context, state) => _buildPage(state, const CreateItineraryScreen()),
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
        path: AppRoutes.myItinerary,
        pageBuilder: (context, state) => _buildPage(state, const MyItineraryScreen()),
      ),
      GoRoute(
        path: AppRoutes.aiReplanning,
        pageBuilder: (context, state) => _buildPage(state, const AIReplanningScreen()),
      ),

      // 6. Lens Ride & Live Navigation
      GoRoute(
        path: AppRoutes.travelerRideSelect,
        pageBuilder: (context, state) => _buildPage(state, const LensRideBookingScreen()),
      ),
      GoRoute(
        path: AppRoutes.lensRideBooking,
        pageBuilder: (context, state) => _buildPage(state, const LensRideBookingScreen()),
      ),
      GoRoute(
        path: AppRoutes.travelerRideSearching,
        pageBuilder: (context, state) => _buildPage(state, const RideSearchingScreen()),
      ),
      GoRoute(
        path: AppRoutes.rideSearching,
        pageBuilder: (context, state) => _buildPage(state, const RideSearchingScreen()),
      ),
      GoRoute(
        path: AppRoutes.travelerRideAccepted,
        pageBuilder: (context, state) => _buildPage(state, const RideAcceptedScreen()),
      ),
      GoRoute(
        path: AppRoutes.driverAssigned,
        pageBuilder: (context, state) => _buildPage(state, const RideAcceptedScreen()),
      ),
      GoRoute(
        path: AppRoutes.travelerRideLive,
        pageBuilder: (context, state) => _buildPage(state, const LiveRideScreen()),
      ),
      GoRoute(
        path: AppRoutes.liveTrip,
        pageBuilder: (context, state) => _buildPage(state, const LiveRideScreen()),
      ),
      GoRoute(
        path: AppRoutes.travelerRideCompleted,
        pageBuilder: (context, state) => _buildPage(state, const RideCompletedScreen()),
      ),
      GoRoute(
        path: AppRoutes.tripComplete,
        pageBuilder: (context, state) => _buildPage(state, const RideCompletedScreen()),
      ),

      // Disruptions & Navigation Fallbacks
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
      GoRoute(
        path: AppRoutes.adventureComplete,
        pageBuilder: (context, state) => _buildPage(state, const AdventureCompleteScreen()),
      ),

      // 7. Notifications, Profile & Settings
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
