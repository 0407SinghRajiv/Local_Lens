import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/routes/app_routes.dart';
import 'services_provider.dart';

/// Represents the initialization state and resolved destination route.
class AppInitState {
  final bool isInitialized;
  final String targetRoute;
  final bool isFirstLaunch;
  final bool isAuthenticated;
  final String? errorMessage;

  const AppInitState({
    required this.isInitialized,
    required this.targetRoute,
    this.isFirstLaunch = false,
    this.isAuthenticated = false,
    this.errorMessage,
  });

  factory AppInitState.initial() => const AppInitState(
        isInitialized: false,
        targetRoute: AppRoutes.splash,
      );

  factory AppInitState.error(String message) => AppInitState(
        isInitialized: false,
        targetRoute: AppRoutes.error,
        errorMessage: message,
      );
}

/// FutureProvider that initializes core app dependencies and determines the initial destination.
final initializationProvider = FutureProvider<AppInitState>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  final configService = ref.watch(configServiceProvider);

  // Minimum splash duration enforced: 5 seconds (5000 ms)
  final minimumDurationFuture = Future<void>.delayed(const Duration(milliseconds: 5000));

  final tasksFuture = Future.wait([
    authService.checkAuthToken(),
    storageService.isFirstLaunch(),
    configService.fetchRemoteConfig(),
    authService.loadCachedSession(),
  ]);

  try {
    // Run both the initialization tasks and the minimum splash timer concurrently
    final results = await Future.wait([
      tasksFuture,
      minimumDurationFuture,
    ]);

    final taskResults = results[0] as List<dynamic>;
    final bool isAuthenticated = taskResults[0] as bool;
    final bool isFirstLaunch = taskResults[1] as bool;
    final Map<String, dynamic> remoteConfig = taskResults[2] as Map<String, dynamic>;

    if (remoteConfig['maintenance'] == true) {
      return AppInitState.error('Server is currently undergoing scheduled maintenance.');
    }

    // Navigation logic:
    // 1. If first launch -> Onboarding
    // 2. If already launched & logged in -> Home (/home)
    // 3. If already launched & NOT logged in -> Login (/login)
    String targetRoute;
    if (isFirstLaunch) {
      targetRoute = AppRoutes.onboarding;
    } else if (isAuthenticated) {
      targetRoute = AppRoutes.home;
    } else {
      targetRoute = AppRoutes.login;
    }

    return AppInitState(
      isInitialized: true,
      targetRoute: targetRoute,
      isFirstLaunch: isFirstLaunch,
      isAuthenticated: isAuthenticated,
    );
  } catch (e) {
    // Return error state without silent crashing
    return AppInitState.error(e.toString());
  }
});
