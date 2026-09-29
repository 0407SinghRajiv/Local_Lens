import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import '../core/theme/locallens_design_system.dart';
import '../widgets/common/locallens_components.dart';

class UserLocationResult {
  final double latitude;
  final double longitude;
  final String displayAddress;
  final bool isPermissionGranted;

  const UserLocationResult({
    required this.latitude,
    required this.longitude,
    required this.displayAddress,
    required this.isPermissionGranted,
  });
}

class LocationService {
  static const String _kLocationPermissionKey = 'locallens_location_permission_granted';

  /// Check if location permission is granted in app preferences or device
  static Future<bool> isLocationPermissionGranted() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        return true;
      }
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLocationPermissionKey) ?? false;
  }

  /// Request location permission via bottom sheet
  static Future<bool> requestLocationPermission(BuildContext context, {bool forcePrompt = false}) async {
    if (!forcePrompt) {
      final isGranted = await isLocationPermissionGranted();
      if (isGranted) return true;
    }
    if (!context.mounted) return false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _LocationPermissionSheet(),
    );

    if (result == true) {
      try {
        await Geolocator.requestPermission();
      } catch (_) {}
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kLocationPermissionKey, true);
      return true;
    }
    return false;
  }

  /// Save user live location to BOTH Supabase 'profiles' and 'rides' tables automatically
  static Future<void> saveUserLiveLocationToDatabase({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    final user = client.auth.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final userId = user?.id ?? prefs.getString('locallens_user_id') ?? prefs.getString('user_id');

    if (userId == null || userId.isEmpty) {
      debugPrint('[LocationService] Notice: No logged-in user ID found for saving live location');
      return;
    }

    // 1. Update profiles table (handles missing columns gracefully)
    try {
      await client.from('profiles').upsert({
        'id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('[LocationService] Saved user live location to profiles table ($latitude, $longitude)');
    } catch (e) {
      // Fallback if profiles table is missing latitude/longitude columns
      try {
        await client.from('profiles').upsert({
          'id': userId,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
      debugPrint('[LocationService] Notice: Run SQL migration if profiles table needs latitude/longitude columns: $e');
    }

    // 2. Also update rides table pickup_lat & pickup_lng for any active/searching ride
    try {
      await client.from('rides').update({
        'pickup_lat': latitude,
        'pickup_lng': longitude,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('passenger_id', userId).inFilter('status', ['searching', 'accepted', 'arrived']);
      debugPrint('[LocationService] Updated active ride pickup location in rides table: ($latitude, $longitude)');
    } catch (e) {
      debugPrint('[LocationService] Notice updating rides pickup location: $e');
    }
  }

  static Timer? _liveTrackingTimer;
  static StreamSubscription<Position>? _positionSubscription;
  static StreamController<Position> _positionStreamController = StreamController<Position>.broadcast();
  static Stream<Position> get positionStream => _positionStreamController.stream;

  /// Start periodic & continuous real GPS location tracking and database syncing
  static void startLiveLocationTracking() async {
    _liveTrackingTimer?.cancel();
    await _positionSubscription?.cancel();

    // Recreate the broadcast controller if closed, to prevent stale-stream errors on restart
    if (_positionStreamController.isClosed) {
      _positionStreamController = StreamController<Position>.broadcast();
    }

    // 1. Immediate sync
    _syncCurrentLocation();

    // 2. Try real GPS stream using Geolocator
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (serviceEnabled && (permission == LocationPermission.always || permission == LocationPermission.whileInUse)) {
        _positionSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((Position pos) {
          if (!_positionStreamController.isClosed) {
            _positionStreamController.add(pos);
          }
          saveUserLiveLocationToDatabase(
            latitude: pos.latitude,
            longitude: pos.longitude,
            address: 'Live Location (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})',
          );
        }, onError: (e) {
          debugPrint('[LocationService] GPS Stream notice: $e');
        });
        debugPrint('[LocationService] Real GPS position stream active');
      }
    } catch (e) {
      debugPrint('[LocationService] Geolocator init notice: $e');
    }

    // 3. Fallback 4-second periodic timer
    _liveTrackingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _syncCurrentLocation();
    });
  }

  static Future<void> _syncCurrentLocation() async {
    final resolved = await getCurrentResolvedLocation();
    if (!_positionStreamController.isClosed) {
      _positionStreamController.add(Position(
        latitude: resolved.latitude,
        longitude: resolved.longitude,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ));
    }
    // Only persist to DB if we have a real GPS-resolved location, not the default fallback
    if (resolved.isPermissionGranted) {
      await saveUserLiveLocationToDatabase(
        latitude: resolved.latitude,
        longitude: resolved.longitude,
        address: resolved.displayAddress,
      );
    }
  }

  static void stopLiveLocationTracking() {
    _liveTrackingTimer?.cancel();
    _liveTrackingTimer = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    // Close the stream to release resources; will be recreated on next start
    if (!_positionStreamController.isClosed) {
      _positionStreamController.close();
    }
  }

  /// Resolves current position using real device GPS or fallback
  static Future<UserLocationResult> getCurrentResolvedLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      if (serviceEnabled && (permission == LocationPermission.always || permission == LocationPermission.whileInUse)) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
        return UserLocationResult(
          latitude: pos.latitude,
          longitude: pos.longitude,
          displayAddress: 'Live GPS Location',
          isPermissionGranted: true,
        );
      }
    } catch (e) {
      debugPrint('[LocationService] Real GPS lookup fallback: $e');
    }

    // Fallback to default coordinates - do NOT save to DB, this is fake data
    return const UserLocationResult(
      latitude: 18.9894,
      longitude: 73.1175,
      displayAddress: 'Panvel, Maharashtra',
      isPermissionGranted: false,
    );
  }
}

class _LocationPermissionSheet extends StatelessWidget {
  const _LocationPermissionSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Location Icon
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: LocalLensColors.primaryTealSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: LocalLensColors.primaryTeal,
              size: 38,
            ),
          ),
          const SizedBox(height: 18),

          // Title
          Text(
            'Enable Location Services',
            textAlign: TextAlign.center,
            style: LocalLensTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'LocalLens needs your location to discover hidden local gems, calculate accurate travel times, and provide live step-by-step navigation.',
            textAlign: TextAlign.center,
            style: LocalLensTypography.bodyMedium.copyWith(
              color: LocalLensColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Allow Button
          LocalLensPrimaryButton(
            text: 'Allow While Using App',
            isOrange: true,
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
          const SizedBox(height: 10),

          // Skip Button
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text(
              'Not now (Use default location)',
              style: LocalLensTypography.button.copyWith(
                color: LocalLensColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
