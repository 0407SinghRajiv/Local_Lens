import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';

class StorageService {
  static const String _keyFirstLaunch = 'is_first_launch';
  static const String _keyIsLoggedIn = 'is_user_logged_in';
  static const String _keyUserId = 'user_cached_id';
  static const String _keyUserEmail = 'user_cached_email';
  static const String _keyUserName = 'user_cached_name';
  static const String _keyUserPhoto = 'user_cached_photo';
  static const String _keyUserRole = 'user_cached_role';

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

  /// Sets login session state with complete profile metadata
  Future<void> setLoggedIn({
    required bool loggedIn,
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    UserRole? role,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, loggedIn);
      if (id != null) await prefs.setString(_keyUserId, id);
      if (email != null) await prefs.setString(_keyUserEmail, email);
      if (name != null) await prefs.setString(_keyUserName, name);
      if (photoUrl != null) await prefs.setString(_keyUserPhoto, photoUrl);
      if (role != null) await prefs.setString(_keyUserRole, role.value);

      if (!loggedIn) {
        await prefs.remove(_keyUserId);
        await prefs.remove(_keyUserEmail);
        await prefs.remove(_keyUserName);
        await prefs.remove(_keyUserPhoto);
        await prefs.remove(_keyUserRole);
      }
    } catch (_) {
      // Gracefully handle storage failure
    }
  }

  /// Gets cached user profile
  Future<UserProfile?> getCachedUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      if (!isLoggedIn) return null;

      final id = prefs.getString(_keyUserId) ?? 'cached_user';
      final email = prefs.getString(_keyUserEmail) ?? '';
      final name = prefs.getString(_keyUserName) ?? (email.isNotEmpty ? email.split('@').first : 'Traveler');
      final photo = prefs.getString(_keyUserPhoto);
      final roleStr = prefs.getString(_keyUserRole);

      return UserProfile(
        id: id,
        email: email,
        displayName: name,
        photoUrl: photo,
        role: UserRole.fromString(roleStr),
      );
    } catch (_) {
      return null;
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

  /// Gets cached user role
  Future<UserRole> getCachedRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roleStr = prefs.getString(_keyUserRole);
      return UserRole.fromString(roleStr);
    } catch (_) {
      return UserRole.traveler;
    }
  }
}
