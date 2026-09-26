import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../core/auth/auth_state.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import 'services_provider.dart';

class AuthNotifier extends ChangeNotifier {
  final Ref _ref;
  AuthState _state = const AuthState.initializing();
  StreamSubscription<supa.AuthState>? _authSubscription;

  AuthNotifier(this._ref) {
    _init();
  }

  AuthState get state => _state;

  void _updateState(AuthState newState) {
    if (_state != newState) {
      _state = newState;
      debugPrint('[AUTH] State updated: ${_state.status} | Role: ${_state.role?.value} | User: ${_state.user?.email}');
      notifyListeners();
    }
  }

  Future<void> _init() async {
    debugPrint('[AUTH] Initializing AuthNotifier...');
    final authService = _ref.read(authServiceProvider);

    try {
      final hasSession = await authService.checkAuthToken();
      if (hasSession) {
        final profile = await authService.resolveUserProfile();
        _updateState(AuthState.authenticated(user: profile, role: profile.role));
      } else {
        _updateState(const AuthState.unauthenticated());
      }
    } catch (e) {
      debugPrint('[AUTH] Initialization error ($e), fallback to unauthenticated');
      _updateState(const AuthState.unauthenticated());
    }

    // Listen to live Supabase auth stream changes
    final stream = authService.authStateChanges;
    if (stream != null) {
      _authSubscription = stream.listen((supaAuthState) async {
        final session = supaAuthState.session;
        if (session != null) {
          try {
            final profile = await authService.resolveUserProfile(session.user);
            _updateState(AuthState.authenticated(user: profile, role: profile.role));
          } catch (_) {
            final fallback = UserProfile(
              id: session.user.id,
              email: session.user.email ?? '',
              displayName: session.user.email?.split('@').first ?? 'Traveler',
              role: UserRole.traveler,
            );
            _updateState(AuthState.authenticated(user: fallback, role: fallback.role));
          }
        } else if (supaAuthState.event == supa.AuthChangeEvent.signedOut) {
          _updateState(const AuthState.unauthenticated());
        }
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final authService = _ref.read(authServiceProvider);
      final profile = await authService.signInWithEmail(
        email: email,
        password: password,
      );
      _updateState(AuthState.authenticated(user: profile, role: profile.role));
      return true;
    } catch (e) {
      final authService = _ref.read(authServiceProvider);
      final formattedMsg = authService.formatAuthError(e);
      _updateState(AuthState.error(formattedMsg));
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final authService = _ref.read(authServiceProvider);
      final profile = await authService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );
      _updateState(AuthState.authenticated(user: profile, role: profile.role));
      return true;
    } catch (e) {
      final authService = _ref.read(authServiceProvider);
      final formattedMsg = authService.formatAuthError(e);
      _updateState(AuthState.error(formattedMsg));
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final authService = _ref.read(authServiceProvider);
      final profile = await authService.signInWithGoogle();
      if (profile != null) {
        _updateState(AuthState.authenticated(user: profile, role: profile.role));
        return true;
      }
      // Check if session became active via browser OAuth
      final current = authService.currentUser;
      if (current != null) {
        final resolved = await authService.resolveUserProfile(current);
        _updateState(AuthState.authenticated(user: resolved, role: resolved.role));
        return true;
      }
      return false;
    } catch (e) {
      final authService = _ref.read(authServiceProvider);
      final formattedMsg = authService.formatAuthError(e);
      _updateState(AuthState.error(formattedMsg));
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      final authService = _ref.read(authServiceProvider);
      await authService.signOut();
      _updateState(const AuthState.unauthenticated());
    } catch (e) {
      _updateState(const AuthState.unauthenticated());
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      final authService = _ref.read(authServiceProvider);
      await authService.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      final authService = _ref.read(authServiceProvider);
      _updateState(AuthState.error(authService.formatAuthError(e)));
      return false;
    }
  }
}

/// Central Auth Notifier provider supporting GoRouter refreshListenable
final authNotifierProvider = ChangeNotifierProvider<AuthNotifier>((ref) {
  return AuthNotifier(ref);
});

/// Exposes the current AuthState snapshot
final authStateProvider = Provider<AuthState>((ref) {
  final notifier = ref.watch(authNotifierProvider);
  return notifier.state;
});

/// Exposes the current UserProfile
final currentUserProfileProvider = Provider<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user;
});

/// Exposes the current UserRole
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.role;
});

/// Backwards compatibility provider for User
final currentUserProvider = Provider<supa.User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  ref.watch(authStateProvider);
  return authService.currentUser;
});
