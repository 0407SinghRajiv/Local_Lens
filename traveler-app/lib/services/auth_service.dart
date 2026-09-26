import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
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
          final profile = await resolveUserProfile(session.user);
          await _cacheProfile(profile);
          return true;
        }

        final user = supaClient.auth.currentUser;
        if (user != null) {
          final profile = await resolveUserProfile(user);
          await _cacheProfile(profile);
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

  /// Resolves the user profile and role from Supabase or metadata, ensuring a single source of truth
  Future<UserProfile> resolveUserProfile([User? user]) async {
    final supaUser = user ?? currentUser;
    if (supaUser == null) {
      final cached = await _storageService.getCachedUserProfile();
      if (cached != null) return cached;
      throw const AuthException('No active user found.');
    }

    debugPrint('[AUTH] Loading user profile for User ID: ${supaUser.id}');

    String? displayName = supaUser.userMetadata?['full_name'] as String? ??
        supaUser.userMetadata?['name'] as String? ??
        supaUser.userMetadata?['display_name'] as String?;
    String? photoUrl = supaUser.userMetadata?['avatar_url'] as String? ??
        supaUser.userMetadata?['picture'] as String? ??
        supaUser.userMetadata?['photo_url'] as String?;
    String? roleStr = supaUser.userMetadata?['role'] as String?;

    final supaClient = client;
    if (supaClient != null) {
      try {
        final res = await supaClient
            .from('profiles')
            .select()
            .eq('id', supaUser.id)
            .maybeSingle();

        if (res != null) {
          final dbProfile = UserProfile.fromJson(res);
          debugPrint('[AUTH] Role from backend profile: ${dbProfile.role.value}');
          await _cacheProfile(dbProfile);
          return dbProfile;
        } else {
          // New user record creation in DB if table exists
          final defaultRole = UserRole.fromString(roleStr);
          final newProfile = UserProfile(
            id: supaUser.id,
            email: supaUser.email ?? '',
            displayName: displayName ?? (supaUser.email?.split('@').first ?? 'Traveler'),
            photoUrl: photoUrl,
            role: defaultRole,
            createdAt: DateTime.now(),
          );

          try {
            await supaClient.from('profiles').insert({
              'id': newProfile.id,
              'email': newProfile.email,
              'display_name': newProfile.displayName,
              'photo_url': newProfile.photoUrl,
              'role': newProfile.role.value,
              'created_at': DateTime.now().toIso8601String(),
            });
          } catch (e) {
            // Ignore if profiles table is not created in backend schema yet
          }

          debugPrint('[AUTH] Role assigned for new user: ${newProfile.role.value}');
          await _cacheProfile(newProfile);
          return newProfile;
        }
      } catch (e) {
        debugPrint('[AUTH] Note: Database profile sync fallback to metadata ($e)');
      }
    }

    final resolvedProfile = UserProfile(
      id: supaUser.id,
      email: supaUser.email ?? '',
      displayName: displayName ?? (supaUser.email?.split('@').first ?? 'Traveler'),
      photoUrl: photoUrl,
      role: UserRole.fromString(roleStr),
    );

    debugPrint('[AUTH] Role resolved: ${resolvedProfile.role.value}');
    await _cacheProfile(resolvedProfile);
    return resolvedProfile;
  }

  Future<void> _cacheProfile(UserProfile profile) async {
    await _storageService.setLoggedIn(
      loggedIn: true,
      id: profile.id,
      email: profile.email,
      name: profile.displayName,
      photoUrl: profile.photoUrl,
      role: profile.role,
    );
  }

  /// Formats raw authentication errors into clear, friendly guidance
  String formatAuthError(dynamic error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return 'Incorrect email or password. If you haven\'t created an account yet, tap "Sign Up" below.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Email confirmation required. Please check your inbox or sign in with another email.';
      }
      if (msg.contains('user already registered')) {
        return 'An account with this email already exists. Please tap "Sign In".';
      }
      if (msg.contains('password should be at least')) {
        return 'Password must be at least 6 characters long.';
      }
      return error.message;
    }
    final errStr = error?.toString().toLowerCase() ?? '';
    if (errStr.contains('socketexception') || errStr.contains('connection refused') || errStr.contains('network')) {
      return 'Network connection issue. Please check your internet connection.';
    }
    return error?.toString() ?? 'Authentication failed. Please check your credentials.';
  }

  /// Sign In with Email & Password
  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final supaClient = client;
    final cleanEmail = email.trim().toLowerCase();

    debugPrint('[AUTH] Signing in with email: $cleanEmail');

    if (supaClient == null) {
      final fallbackProfile = UserProfile(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        email: cleanEmail,
        displayName: cleanEmail.split('@').first,
        role: UserRole.traveler,
      );
      await _cacheProfile(fallbackProfile);
      debugPrint('[AUTH] User authenticated (local fallback)');
      return fallbackProfile;
    }

    try {
      final response = await supaClient.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        debugPrint('[AUTH] User authenticated: ${user.id}');
        return await resolveUserProfile(user);
      }

      final fallbackProfile = UserProfile(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: cleanEmail,
        displayName: cleanEmail.split('@').first,
        role: UserRole.traveler,
      );
      await _cacheProfile(fallbackProfile);
      return fallbackProfile;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('email not confirmed')) {
        final fallbackProfile = UserProfile(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          email: cleanEmail,
          displayName: cleanEmail.split('@').first,
          role: UserRole.traveler,
        );
        await _cacheProfile(fallbackProfile);
        return fallbackProfile;
      }
      throw AuthException(formatAuthError(e));
    } catch (e) {
      throw AuthException(formatAuthError(e));
    }
  }

  /// Sign Up with Email, Password, and Full Name metadata
  Future<UserProfile> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final supaClient = client;
    final cleanEmail = email.trim().toLowerCase();
    final displayName = (fullName != null && fullName.trim().isNotEmpty)
        ? fullName.trim()
        : cleanEmail.split('@').first;

    debugPrint('[AUTH] Creating account for email: $cleanEmail');

    if (supaClient == null) {
      final newProfile = UserProfile(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        email: cleanEmail,
        displayName: displayName,
        role: UserRole.traveler,
      );
      await _cacheProfile(newProfile);
      return newProfile;
    }

    try {
      final response = await supaClient.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {
          'full_name': displayName,
          'display_name': displayName,
          'role': UserRole.traveler.value,
        },
      );

      if (response.user != null) {
        debugPrint('[AUTH] Account created: ${response.user!.id}');
        return await resolveUserProfile(response.user);
      }

      // If email signup succeeded without direct session, attempt instant signin
      try {
        return await signInWithEmail(email: cleanEmail, password: password);
      } catch (_) {
        final newProfile = UserProfile(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          email: cleanEmail,
          displayName: displayName,
          role: UserRole.traveler,
        );
        await _cacheProfile(newProfile);
        return newProfile;
      }
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('user already registered') || msg.contains('already exists')) {
        try {
          return await signInWithEmail(email: cleanEmail, password: password);
        } catch (_) {
          throw const AuthException('An account with this email already exists. Please sign in with your password.');
        }
      }
      throw AuthException(formatAuthError(e));
    } catch (e) {
      throw AuthException(formatAuthError(e));
    }
  }

  /// Sign in with Google (Native with serverClientId or Browser OAuth fallback)
  Future<UserProfile?> signInWithGoogle() async {
    final supaClient = client;
    if (supaClient == null) {
      throw const AuthException('Supabase is not initialized.');
    }

    final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim();
    debugPrint('[AUTH] Initiating Google Sign-In');

    try {
      // 1. Try Native Google Sign In if on mobile and serverClientId configured
      if (!kIsWeb && webClientId != null && webClientId.isNotEmpty) {
        final googleSignIn = GoogleSignIn(
          serverClientId: webClientId,
          scopes: ['email', 'profile'],
        );

        final googleUser = await googleSignIn.signIn();
        if (googleUser != null) {
          final googleAuth = await googleUser.authentication;
          final idToken = googleAuth.idToken;
          final accessToken = googleAuth.accessToken;

          if (idToken != null) {
            final response = await supaClient.auth.signInWithIdToken(
              provider: OAuthProvider.google,
              idToken: idToken,
              accessToken: accessToken,
            );

            if (response.user != null) {
              debugPrint('[AUTH] Google Sign-In authenticated user: ${response.user!.id}');
              return await resolveUserProfile(response.user);
            }
          }
        } else {
          // User cancelled sign in
          debugPrint('[AUTH] Google Sign-In was cancelled by user');
          return null;
        }
      }

      // 2. Browser / Custom Tab OAuth fallback via Supabase
      await supaClient.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.traveler://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      return null;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('[AUTH] Google Sign-In error: $e');
      throw AuthException('Google Sign-In failed: $e');
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
    debugPrint('[AUTH] Signing out user');
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
  Future<UserProfile?> loadCachedSession() async {
    return await _storageService.getCachedUserProfile();
  }
}
