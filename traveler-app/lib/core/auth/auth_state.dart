import '../../models/user_profile.dart';
import '../../models/user_role.dart';

enum AuthStatus {
  initializing,
  unauthenticated,
  authenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserProfile? user;
  final UserRole? role;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.role,
    this.errorMessage,
  });

  const AuthState.initializing()
      : status = AuthStatus.initializing,
        user = null,
        role = null,
        errorMessage = null;

  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null,
        role = null,
        errorMessage = null;

  AuthState.authenticated({
    required this.user,
    UserRole? role,
  })  : status = AuthStatus.authenticated,
        role = role ?? user?.role ?? UserRole.traveler,
        errorMessage = null;

  const AuthState.error(String message)
      : status = AuthStatus.error,
        user = null,
        role = null,
        errorMessage = message;

  bool get isInitializing => status == AuthStatus.initializing;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get hasError => status == AuthStatus.error;

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? user,
    UserRole? role,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      role: role ?? this.role,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'AuthState(status: $status, role: ${role?.value}, user: ${user?.email}, error: $errorMessage)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.status == status &&
        other.user?.id == user?.id &&
        other.role == role &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(status, user?.id, role, errorMessage);
}
