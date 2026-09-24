import 'package:flutter/foundation.dart';
import '../models/driver.dart';

/// Abstract auth service for future Supabase integration
abstract class AuthService {
  Future<Driver?> login(String email, String password);
  Future<void> logout();
  Driver? get currentDriver;
  bool get isAuthenticated;
}

/// Mock authentication - replace with SupabaseAuthService later
class MockAuthService extends AuthService {
  Driver? _currentDriver;

  // Mock credentials
  static const String _mockEmail = 'driver@nearbyride.com';
  static const String _mockPassword = '123456';

  @override
  Future<Driver?> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    if (email.trim().toLowerCase() == _mockEmail &&
        password == _mockPassword) {
      _currentDriver = Driver.mock();
      debugPrint('[MockAuth] Login successful for $email');
      return _currentDriver;
    }

    throw AuthException('Invalid email or password');
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentDriver = null;
    debugPrint('[MockAuth] Logged out');
  }

  @override
  Driver? get currentDriver => _currentDriver;

  @override
  bool get isAuthenticated => _currentDriver != null;
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
