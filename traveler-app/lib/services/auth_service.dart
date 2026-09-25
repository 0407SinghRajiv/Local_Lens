import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService {
  final SupabaseClient? _client;

  AuthService({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  /// Returns current Supabase user if logged in
  User? get currentUser {
    try {
      return _client?.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Returns current session
  Session? get currentSession {
    try {
      return _client?.auth.currentSession;
    } catch (_) {
      return null;
    }
  }

  /// Checks whether an authenticated session exists
  Future<bool> checkAuthToken() async {
    try {
      if (_client != null) {
        final session = _client.auth.currentSession;
        if (session != null && !session.isExpired) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Stream of authentication state changes
  Stream<AuthState>? get authStateChanges => _client?.auth.onAuthStateChange;

  /// Sign In with Email & Password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final client = _client ?? SupabaseConfig.client;
    if (client == null) {
      throw const AuthException(
        'Supabase is not configured. Please add your SUPABASE_URL and SUPABASE_ANON_KEY to .env',
      );
    }

    try {
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// Sign Up with Email, Password, and Full Name metadata
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final client = _client ?? SupabaseConfig.client;
    if (client == null) {
      throw const AuthException(
        'Supabase is not configured. Please add your SUPABASE_URL and SUPABASE_ANON_KEY to .env',
      );
    }

    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: fullName != null && fullName.isNotEmpty
            ? {'full_name': fullName.trim(), 'display_name': fullName.trim()}
            : null,
      );
      return response;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// Send password reset link to email
  Future<void> resetPasswordForEmail(String email) async {
    final client = _client ?? SupabaseConfig.client;
    if (client == null) {
      throw const AuthException(
        'Supabase is not configured. Please add your SUPABASE_URL and SUPABASE_ANON_KEY to .env',
      );
    }

    try {
      await client.auth.resetPasswordForEmail(email.trim());
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      final client = _client ?? SupabaseConfig.client;
      if (client != null) {
        await client.auth.signOut();
      }
    } catch (_) {
      // Gracefully handle sign out errors
    }
  }

  /// Loads cached session profile data
  Future<Map<String, dynamic>?> loadCachedSession() async {
    try {
      final user = currentUser;
      if (user != null) {
        return {
          'id': user.id,
          'email': user.email,
          'metadata': user.userMetadata,
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
