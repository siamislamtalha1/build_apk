part of 'auth_cubit.dart';

/// Base authentication state
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state - checking authentication
class AuthInitial extends AuthState {}

/// Loading state - performing authentication operation
class AuthLoading extends AuthState {}

/// Authenticated state - user is logged in
class Authenticated extends AuthState {
  final User user;

  const Authenticated({required this.user});

  @override
  List<Object?> get props => [user.uid];
}

/// Unauthenticated state - no user logged in
class Unauthenticated extends AuthState {}

/// Error state - authentication error occurred
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
