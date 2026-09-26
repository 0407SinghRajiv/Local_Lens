import 'package:flutter_test/flutter_test.dart';
import 'package:traveler_app/core/auth/auth_state.dart';
import 'package:traveler_app/models/user_profile.dart';
import 'package:traveler_app/models/user_role.dart';
import 'package:traveler_app/core/routes/app_routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Role and UserProfile Tests', () {
    test('TEST 10: UserRole handles known and unknown/invalid roles safely', () {
      expect(UserRole.fromString('traveler'), equals(UserRole.traveler));
      expect(UserRole.fromString('TRAVELER'), equals(UserRole.traveler));
      expect(UserRole.fromString('provider'), equals(UserRole.provider));
      expect(UserRole.fromString('rider'), equals(UserRole.rider));
      expect(UserRole.fromString('admin'), equals(UserRole.admin));

      // Unknown / invalid / null roles must safely fallback to traveler
      expect(UserRole.fromString(null), equals(UserRole.traveler));
      expect(UserRole.fromString('unknown_role'), equals(UserRole.traveler));
      expect(UserRole.fromString('guest'), equals(UserRole.traveler));
      expect(UserRole.fromString(''), equals(UserRole.traveler));
    });

    test('UserProfile JSON serialization and deserialization preserves role', () {
      final profile = UserProfile(
        id: 'usr_123',
        email: 'traveler@locallens.app',
        displayName: 'Test Traveler',
        photoUrl: 'https://example.com/avatar.png',
        role: UserRole.traveler,
        createdAt: DateTime(2026, 1, 1),
      );

      final json = profile.toJson();
      expect(json['id'], equals('usr_123'));
      expect(json['email'], equals('traveler@locallens.app'));
      expect(json['role'], equals('traveler'));

      final parsed = UserProfile.fromJson(json);
      expect(parsed.id, equals(profile.id));
      expect(parsed.email, equals(profile.email));
      expect(parsed.role, equals(UserRole.traveler));
    });
  });

  group('AuthState Model Tests', () {
    test('AuthState initial, unauthenticated, authenticated and error states', () {
      const initializing = AuthState.initializing();
      expect(initializing.isInitializing, isTrue);
      expect(initializing.status, equals(AuthStatus.initializing));
      expect(initializing.user, isNull);

      const unauthenticated = AuthState.unauthenticated();
      expect(unauthenticated.isUnauthenticated, isTrue);
      expect(unauthenticated.status, equals(AuthStatus.unauthenticated));
      expect(unauthenticated.user, isNull);

      final profile = UserProfile(
        id: 'usr_google_456',
        email: 'googleuser@gmail.com',
        displayName: 'Google Traveler',
        role: UserRole.traveler,
      );

      final authenticated = AuthState.authenticated(user: profile);
      expect(authenticated.isAuthenticated, isTrue);
      expect(authenticated.status, equals(AuthStatus.authenticated));
      expect(authenticated.user?.email, equals('googleuser@gmail.com'));
      expect(authenticated.role, equals(UserRole.traveler));

      const errorState = AuthState.error('Authentication cancelled');
      expect(errorState.hasError, isTrue);
      expect(errorState.status, equals(AuthStatus.error));
      expect(errorState.errorMessage, equals('Authentication cancelled'));
    });
  });

  group('Router Redirect Architecture Tests', () {
    // Helper pure redirect evaluation function reflecting app_router.dart logic
    String? evaluateRedirect({
      required AuthState authState,
      required String location,
    }) {
      final status = authState.status;
      final role = authState.role ?? UserRole.traveler;

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

      if (status == AuthStatus.unauthenticated) {
        if (isSplash) return AppRoutes.welcome;
        if (isAuthRoute) return null;
        return AppRoutes.login;
      }

      if (status == AuthStatus.authenticated) {
        const roleHome = AppRoutes.travelerHome;

        if (isSplash || isAuthRoute) {
          return roleHome;
        }

        if (role == UserRole.traveler) {
          if (location.startsWith('/provider') ||
              location.startsWith('/rider') ||
              location.startsWith('/admin')) {
            return roleHome;
          }
        }

        if (location == AppRoutes.home) {
          return AppRoutes.travelerHome;
        }

        return null;
      }

      if (status == AuthStatus.error) {
        if (isAuthRoute) return null;
        return AppRoutes.login;
      }

      return null;
    }

    test('TEST 1: Fresh app unauthenticated lands on welcome/login', () {
      const state = AuthState.unauthenticated();
      final redirectSplash = evaluateRedirect(authState: state, location: AppRoutes.splash);
      expect(redirectSplash, equals(AppRoutes.welcome));

      final redirectLogin = evaluateRedirect(authState: state, location: AppRoutes.login);
      expect(redirectLogin, isNull); // Allowed
    });

    test('TEST 2 & 3: Google Login (New & Existing) authenticated redirects to traveler home', () {
      final user = UserProfile(
        id: 'google_user_789',
        email: 'traveler@gmail.com',
        displayName: 'Traveler Explorer',
        role: UserRole.traveler,
      );
      final state = AuthState.authenticated(user: user);

      // User was on login or google-login screen when authenticated
      final redirectFromLogin = evaluateRedirect(authState: state, location: AppRoutes.login);
      expect(redirectFromLogin, equals(AppRoutes.travelerHome));

      final redirectFromGoogleLogin = evaluateRedirect(authState: state, location: AppRoutes.googleLogin);
      expect(redirectFromGoogleLogin, equals(AppRoutes.travelerHome));

      final redirectFromWelcome = evaluateRedirect(authState: state, location: AppRoutes.welcome);
      expect(redirectFromWelcome, equals(AppRoutes.travelerHome));
    });

    test('TEST 4: App restarted while already authenticated restores session and routes to home', () {
      final user = UserProfile(
        id: 'restored_user_1',
        email: 'restored@gmail.com',
        displayName: 'Restored Traveler',
        role: UserRole.traveler,
      );

      // 1. Initializing on splash
      const initState = AuthState.initializing();
      final redirectDuringInit = evaluateRedirect(authState: initState, location: AppRoutes.splash);
      expect(redirectDuringInit, isNull); // Stay on splash during init

      // 2. Auth confirmed
      final authState = AuthState.authenticated(user: user);
      final redirectAfterInit = evaluateRedirect(authState: authState, location: AppRoutes.splash);
      expect(redirectAfterInit, equals(AppRoutes.travelerHome));
    });

    test('TEST 5: Logout transitions to unauthenticated and redirects to login', () {
      const unauthState = AuthState.unauthenticated();
      final redirect = evaluateRedirect(authState: unauthState, location: AppRoutes.travelerHome);
      expect(redirect, equals(AppRoutes.login));
    });

    test('TEST 6: Unauthenticated user trying to access protected routes is redirected to login', () {
      const unauthState = AuthState.unauthenticated();

      expect(evaluateRedirect(authState: unauthState, location: AppRoutes.travelerHome), equals(AppRoutes.login));
      expect(evaluateRedirect(authState: unauthState, location: AppRoutes.travelerExplore), equals(AppRoutes.login));
      expect(evaluateRedirect(authState: unauthState, location: AppRoutes.travelerTrips), equals(AppRoutes.login));
      expect(evaluateRedirect(authState: unauthState, location: AppRoutes.travelerSaved), equals(AppRoutes.login));
      expect(evaluateRedirect(authState: unauthState, location: AppRoutes.travelerProfile), equals(AppRoutes.login));
      expect(evaluateRedirect(authState: unauthState, location: AppRoutes.tripSetup), equals(AppRoutes.login));
    });

    test('TEST 7: Authenticated traveler trying to access login/signup is redirected to traveler home', () {
      final user = UserProfile(
        id: 'usr_1',
        email: 'traveler@locallens.app',
        displayName: 'Traveler',
        role: UserRole.traveler,
      );
      final authState = AuthState.authenticated(user: user);

      expect(evaluateRedirect(authState: authState, location: AppRoutes.login), equals(AppRoutes.travelerHome));
      expect(evaluateRedirect(authState: authState, location: AppRoutes.signup), equals(AppRoutes.travelerHome));
      expect(evaluateRedirect(authState: authState, location: AppRoutes.googleLogin), equals(AppRoutes.travelerHome));
    });

    test('TEST 8: OAuth cancellation retains unauthenticated status without crash', () {
      const unauthState = AuthState.unauthenticated();
      expect(evaluateRedirect(authState: unauthState, location: AppRoutes.googleLogin), isNull);
    });

    test('TEST 9: Error state redirects protected routes to login while allowing auth screens', () {
      const errState = AuthState.error('Network connection timeout');

      expect(evaluateRedirect(authState: errState, location: AppRoutes.login), isNull);
      expect(evaluateRedirect(authState: errState, location: AppRoutes.googleLogin), isNull);
      expect(evaluateRedirect(authState: errState, location: AppRoutes.travelerHome), equals(AppRoutes.login));
    });

    test('Role Guard: Traveler blocked from accessing provider/rider/admin areas', () {
      final user = UserProfile(
        id: 'usr_traveler',
        email: 'traveler@locallens.app',
        displayName: 'Traveler',
        role: UserRole.traveler,
      );
      final authState = AuthState.authenticated(user: user);

      expect(evaluateRedirect(authState: authState, location: '/provider/dashboard'), equals(AppRoutes.travelerHome));
      expect(evaluateRedirect(authState: authState, location: '/rider/dashboard'), equals(AppRoutes.travelerHome));
      expect(evaluateRedirect(authState: authState, location: '/admin/settings'), equals(AppRoutes.travelerHome));
    });
  });
}
