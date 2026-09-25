import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyFirstLaunch = 'is_first_launch';
  static const String _keyIsLoggedIn = 'is_user_logged_in';
  static const String _keyUserEmail = 'user_cached_email';
  static const String _keyUserName = 'user_cached_name';

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

  /// Checks if user was previously logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsLoggedIn) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Sets login session state
  Future<void> setLoggedIn({required bool loggedIn, String? email, String? name}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, loggedIn);
      if (email != null) await prefs.setString(_keyUserEmail, email);
      if (name != null) await prefs.setString(_keyUserName, name);
      if (!loggedIn) {
        await prefs.remove(_keyUserEmail);
        await prefs.remove(_keyUserName);
      }
    } catch (_) {
      // Gracefully handle storage failure
    }
  }

  /// Gets cached user email
  Future<String?> getCachedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserEmail);
    } catch (_) {
      return null;
    }
  }
}
