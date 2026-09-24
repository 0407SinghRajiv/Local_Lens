import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/realtime_service.dart';
import 'repositories/driver_repository.dart';
import 'repositories/ride_repository.dart';

import 'screens/splash/splash_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/ride_request/ride_request_screen.dart';
import 'screens/pickup/pickup_screen.dart';
import 'screens/arrived/arrived_screen.dart';
import 'screens/active_ride/active_ride_screen.dart';
import 'screens/completed/completed_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Create services (swap these for real implementations later)
  final authService = MockAuthService();
  final locationService = MockLocationService();
  final realtimeService = MockRealtimeService();
  final driverRepo = MockDriverRepository();
  final rideRepo = MockRideRepository();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(
        authService: authService,
        locationService: locationService,
        realtimeService: realtimeService,
        driverRepo: driverRepo,
        rideRepo: rideRepo,
      ),
      child: const NearbyRideDriverApp(),
    ),
  );
}

class NearbyRideDriverApp extends StatelessWidget {
  const NearbyRideDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NearbyRide Driver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/ride-request': (context) => const RideRequestScreen(),
        '/pickup': (context) => const PickupScreen(),
        '/arrived': (context) => const ArrivedScreen(),
        '/active-ride': (context) => const ActiveRideScreen(),
        '/completed': (context) => const CompletedScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
