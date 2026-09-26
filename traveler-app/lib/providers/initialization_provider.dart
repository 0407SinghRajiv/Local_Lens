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

  // Minimum splash duration: 1000ms for smooth branding transition without sluggish waiting
  final minimumDurationFuture = Future<void>.delayed(const Duration(milliseconds: 1000));

  final tasksFuture = Future.wait([
    authService.checkAuthToken(),
    storageService.isFirstLaunch(),
    configService.fetchRemoteConfig(),
    authService.loadCachedSession(),
  ]);

  try {
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

    String targetRoute;
    if (isFirstLaunch) {
      targetRoute = AppRoutes.welcome;
    } else if (isAuthenticated) {
      targetRoute = AppRoutes.travelerHome;
    } else {
      targetRoute = AppRoutes.welcome;
    }

    return AppInitState(
      isInitialized: true,
      targetRoute: targetRoute,
      isFirstLaunch: isFirstLaunch,
      isAuthenticated: isAuthenticated,
    );
  } catch (e) {
    return const AppInitState(
      isInitialized: true,
      targetRoute: AppRoutes.welcome,
      isFirstLaunch: false,
      isAuthenticated: false,
      errorMessage: null,
    );
  }
});
