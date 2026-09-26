import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services_provider.dart';

final authStateProvider = StreamProvider<AuthState?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges ?? const Stream.empty();
});

final currentUserProvider = Provider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  ref.watch(authStateProvider);
  return authService.currentUser;
});

class AuthController extends StateNotifier<AsyncValue<User?>> {
  final Ref _ref;
  StreamSubscription<AuthState>? _authSubscription;

  AuthController(this._ref) : super(const AsyncValue.data(null)) {
    _init();
  }

  void _init() {
    final authService = _ref.read(authServiceProvider);
    final user = authService.currentUser;
    state = AsyncValue.data(user);

    // Listen to live Supabase auth stream changes
    final stream = authService.authStateChanges;
    if (stream != null) {
      _authSubscription = stream.listen((authState) {
        state = AsyncValue.data(authState.session?.user ?? authService.currentUser);
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
    state = const AsyncValue.loading();
    try {
      final authService = _ref.read(authServiceProvider);
      final response = await authService.signInWithEmail(
        email: email,
        password: password,
      );
      state = AsyncValue.data(response.user);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final authService = _ref.read(authServiceProvider);
      final response = await authService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );

      // If Supabase created user but session is null, attempt immediate sign-in
      if (response.session == null) {
        try {
          final loginResponse = await authService.signInWithEmail(
            email: email,
            password: password,
          );
          state = AsyncValue.data(loginResponse.user);
          return true;
        } catch (_) {
          // Fallback to registered user instance
        }
      }

      state = AsyncValue.data(response.user);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final authService = _ref.read(authServiceProvider);
      final response = await authService.signInWithGoogle();
      if (response != null) {
        state = AsyncValue.data(response.user);
        return true;
      }
      state = AsyncValue.data(authService.currentUser);
      return authService.currentUser != null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      final authService = _ref.read(authServiceProvider);
      await authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      final authService = _ref.read(authServiceProvider);
      await authService.resetPasswordForEmail(email);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
  return AuthController(ref);
});
