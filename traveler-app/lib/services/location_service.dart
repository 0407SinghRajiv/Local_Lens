import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../widgets/common/locallens_components.dart';

class LocationService {
  static const String _kLocationPermissionKey = 'locallens_location_permission_granted';

  /// Check if location permission is granted in app preferences
  static Future<bool> isLocationPermissionGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLocationPermissionKey) ?? false;
  }

  /// Request location permission via bottom sheet
  static Future<bool> requestLocationPermission(BuildContext context) async {
    final isGranted = await isLocationPermissionGranted();
    if (isGranted) return true;
    if (!context.mounted) return false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _LocationPermissionSheet(),
    );

    if (result == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kLocationPermissionKey, true);
      return true;
    }
    return false;
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
            decoration: BoxDecoration(
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
