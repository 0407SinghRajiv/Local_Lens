import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services_provider.dart';

final authStateProvider = StreamProvider<AuthState?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges ?? const Stream.empty();
});

final currentUserProvider = Provider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  // Re-read when auth state stream changes
  ref.watch(authStateProvider);
  return authService.currentUser;
});

class AuthController extends StateNotifier<AsyncValue<User?>> {
  final Ref _ref;

  AuthController(this._ref) : super(const AsyncValue.data(null)) {
    _init();
  }

  void _init() {
    final user = _ref.read(authServiceProvider).currentUser;
    state = AsyncValue.data(user);
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
      state = AsyncValue.data(response.user);
      return true;
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
