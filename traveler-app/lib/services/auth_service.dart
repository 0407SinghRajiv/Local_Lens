import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'storage_service.dart';

class AuthService {
  final SupabaseClient? _injectedClient;
  final StorageService _storageService;

  AuthService({SupabaseClient? client, StorageService? storageService})
      : _injectedClient = client,
        _storageService = storageService ?? StorageService();

  SupabaseClient? get client => _injectedClient ?? SupabaseConfig.client;

  /// Returns current Supabase user if logged in
  User? get currentUser {
    try {
      return client?.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Returns current session
  Session? get currentSession {
    try {
      return client?.auth.currentSession;
    } catch (_) {
      return null;
    }
  }

  /// Checks whether an authenticated session exists with double verification
  Future<bool> checkAuthToken() async {
    try {
      final supaClient = client;
      if (supaClient != null) {
        final session = supaClient.auth.currentSession;
        if (session != null && !session.isExpired) {
          await _storageService.setLoggedIn(
            loggedIn: true,
            email: session.user.email,
            name: session.user.userMetadata?['full_name'] as String?,
          );
          return true;
        }

        final user = supaClient.auth.currentUser;
        if (user != null) {
          await _storageService.setLoggedIn(
            loggedIn: true,
            email: user.email,
            name: user.userMetadata?['full_name'] as String?,
          );
          return true;
        }
      }

      // Check persistent storage fallback
      final storedLoggedIn = await _storageService.isLoggedIn();
      return storedLoggedIn;
    } catch (_) {
      return false;
    }
  }

  /// Stream of authentication state changes
  Stream<AuthState>? get authStateChanges => client?.auth.onAuthStateChange;

  /// Sign In with Email & Password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final supaClient = client;
    if (supaClient == null) {
      throw const AuthException(
        'Supabase is not configured. Please add your SUPABASE_URL and SUPABASE_ANON_KEY to .env',
      );
    }

    try {
      final response = await supaClient.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        await _storageService.setLoggedIn(
          loggedIn: true,
          email: response.user?.email,
          name: response.user?.userMetadata?['full_name'] as String?,
        );
      }

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
    final supaClient = client;
    if (supaClient == null) {
      throw const AuthException(
        'Supabase is not configured. Please add your SUPABASE_URL and SUPABASE_ANON_KEY to .env',
      );
    }

    try {
      final response = await supaClient.auth.signUp(
        email: email.trim(),
        password: password,
        data: fullName != null && fullName.isNotEmpty
            ? {'full_name': fullName.trim(), 'display_name': fullName.trim()}
            : null,
      );

      // If user or session is created, persist state
      if (response.user != null) {
        await _storageService.setLoggedIn(
          loggedIn: true,
          email: response.user?.email,
          name: fullName ?? response.user?.userMetadata?['full_name'] as String?,
        );
      }

      return response;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// Sign in with Google (Native Google Sign-In with OAuth fallback)
  Future<AuthResponse?> signInWithGoogle() async {
    final supaClient = client;
    if (supaClient == null) {
      throw const AuthException('Supabase is not initialized.');
    }

    try {
      if (kIsWeb) {
        await supaClient.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? null : 'io.supabase.traveler://login-callback/',
        );
        return null;
      }

      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled Google Sign In picker
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw const AuthException('Google Sign In failed: No ID Token found.');
      }

      final response = await supaClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        await _storageService.setLoggedIn(
          loggedIn: true,
          email: response.user?.email,
          name: response.user?.userMetadata?['full_name'] as String? ?? googleUser.displayName,
        );
      }

      return response;
    } on AuthException {
      rethrow;
    } catch (e) {
      // If native GoogleSignIn fails, attempt Supabase browser OAuth fallback
      try {
        await supaClient.auth.signInWithOAuth(
          OAuthProvider.google,
        );
        return null;
      } catch (fallbackError) {
        throw AuthException('Google Sign-In failed: $e');
      }
    }
  }

  /// Send password reset link to email
  Future<void> resetPasswordForEmail(String email) async {
    final supaClient = client;
    if (supaClient == null) {
      throw const AuthException(
        'Supabase is not configured. Please add your SUPABASE_URL and SUPABASE_ANON_KEY to .env',
      );
    }

    try {
      await supaClient.auth.resetPasswordForEmail(email.trim());
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      final supaClient = client;
      if (supaClient != null) {
        await supaClient.auth.signOut();
      }
      await _storageService.setLoggedIn(loggedIn: false);
      try {
        final googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
      } catch (_) {}
    } catch (_) {
      await _storageService.setLoggedIn(loggedIn: false);
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
