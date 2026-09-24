import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyFirstLaunch = 'is_first_launch';

  /// Checks if this is the first time the app is launched.
  Future<bool> isFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyFirstLaunch) ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Sets the first launch flag to false once onboarding is completed/viewed.
  Future<void> setFirstLaunchCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyFirstLaunch, false);
    } catch (_) {
      // Gracefully handle storage failure
    }
  }
}
