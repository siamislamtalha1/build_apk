import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Bloomee/services/firebase/auth_service.dart';

part 'auth_state.dart';

/// Authentication state management cubit
class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;

  AuthCubit({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(AuthInitial()) {
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        emit(Authenticated(user: user));
      } else {
        emit(Unauthenticated());
      }
    });
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      emit(AuthLoading());
      await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      // State will be updated by authStateChanges listener
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      emit(AuthLoading());
      await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      // State will be updated by authStateChanges listener
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      emit(AuthLoading());
      final result = await _authService.signInWithGoogle();
      if (result == null) {
        // User canceled
        emit(Unauthenticated());
      }
      // State will be updated by authStateChanges listener
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Sign in as guest (anonymous)
  Future<void> signInAsGuest() async {
    try {
      emit(AuthLoading());
      await _authService.signInAsGuest();
      // State will be updated by authStateChanges listener
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      emit(AuthLoading());
      await _authService.signOut();
      // State will be updated by authStateChanges listener
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      emit(AuthLoading());
      await _authService.deleteAccount();
      // State will be updated by authStateChanges listener
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Get current user
  User? get currentUser => _authService.currentUser;

  /// Check if user is guest
  bool get isGuest => _authService.isGuest;
}
