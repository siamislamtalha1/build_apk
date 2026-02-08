import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Bloomee/services/firebase/auth_service.dart';
import 'package:Bloomee/services/firebase/firestore_service.dart';
import 'package:Bloomee/services/crash_reporter.dart';

part 'auth_state.dart';

/// Authentication state management cubit
class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  StreamSubscription<User?>? _authSubscription;
  int _opToken = 0;

  AuthCubit({AuthService? authService})
      : _authService = authService ?? AuthService(),
        _firestoreService = FirestoreService(),
        super(AuthInitial()) {
    // Listen to auth state changes
    _authSubscription = _authService.authStateChanges.listen(
      (user) {
        if (isClosed) return;
        if (user != null) {
          emit(Authenticated(user: user));
          // Profile saving and username allocation is handled by SyncService
          // to avoid race conditions and database transaction conflicts
        } else {
          emit(Unauthenticated());
        }
      },
      onError: (Object e, StackTrace st) {
        CrashReporter.record(e, st, source: 'AuthCubit.authStateChanges');
        if (isClosed) return;
        emit(AuthError(message: _messageFromError(e)));
      },
    );
  }

  void _armLoadingTimeout(String opName, int token,
      {Duration timeout = const Duration(seconds: 12)}) {
    unawaited(
      Future.delayed(timeout).then((_) {
        if (isClosed) return;
        if (token != _opToken) return;
        if (state is AuthLoading) {
          emit(AuthError(message: '$opName timed out. Please try again.'));
        }
      }),
    );
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
    String? desiredUsername,
  }) async {
    try {
      if (isClosed) return;
      _opToken++;
      final token = _opToken;
      emit(AuthLoading());
      _armLoadingTimeout('Sign up', token);
      final current = _authService.currentUser;
      final cred = (current != null && current.isAnonymous)
          ? await _authService.linkAnonymousWithEmail(
              email: email,
              password: password,
            )
          : await _authService.signUpWithEmail(
              email: email,
              password: password,
              displayName: displayName,
            );

      if (displayName != null && displayName.trim().isNotEmpty) {
        try {
          await cred?.user?.updateDisplayName(displayName.trim());
        } catch (e, st) {
          CrashReporter.record(
            e,
            st,
            source: 'AuthCubit.signUpWithEmail failed to update display name',
          );
          if (isClosed) return;
          emit(AuthError(message: _messageFromError(e)));
        }
      }
      // Profile saving and username allocation is now handled by the authStateChanges listener
      // to avoid double writes and race conditions.
      // State will be updated by authStateChanges listener
    } catch (e, st) {
      CrashReporter.record(e, st, source: 'AuthCubit.signUpWithEmail failed');
      if (isClosed) return;
      emit(AuthError(message: _messageFromError(e)));
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      if (isClosed) return;
      _opToken++;
      final token = _opToken;
      emit(AuthLoading());
      _armLoadingTimeout('Login', token);
      final cred = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      final user = cred?.user;
      if (user != null && !user.isAnonymous) {
        if (!Platform.isWindows) {
          try {
            await _firestoreService.saveUserProfile(
              user.uid,
              displayName: user.displayName,
              photoURL: user.photoURL,
              email: user.email,
            );
            await _firestoreService.ensureUsername(
              userId: user.uid,
              displayName: user.displayName,
            );
          } catch (e, st) {
            CrashReporter.record(
              e,
              st,
              source: 'AuthCubit.signInWithEmail failed to save user profile',
            );
            if (isClosed) return;
            emit(AuthError(message: _messageFromError(e)));
          }
        }
      }
      // State will be updated by authStateChanges listener
    } catch (e, st) {
      CrashReporter.record(e, st, source: 'AuthCubit.signInWithEmail failed');
      if (isClosed) return;
      emit(AuthError(message: _messageFromError(e)));
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      if (isClosed) return;
      _opToken++;
      final token = _opToken;
      emit(AuthLoading());
      _armLoadingTimeout('Google sign-in', token);
      final result = await _authService.signInWithGoogle();
      if (result == null) {
        // User canceled
        emit(Unauthenticated());
      }
      // Profile saving and username checked in authStateChanges listener
      // State will be updated by authStateChanges listener
    } catch (e, st) {
      CrashReporter.record(e, st, source: 'AuthCubit.signInWithGoogle failed');
      if (isClosed) return;
      emit(AuthError(message: _messageFromError(e)));
    }
  }

  /// Sign in as guest (anonymous)
  Future<void> signInAsGuest() async {
    try {
      if (isClosed) return;
      _opToken++;
      final token = _opToken;
      emit(AuthLoading());
      _armLoadingTimeout('Guest sign-in', token);
      await _authService.signInAsGuest();
      // State will be updated by authStateChanges listener
    } catch (e, st) {
      CrashReporter.record(e, st, source: 'AuthCubit.signInAsGuest failed');
      if (isClosed) return;
      emit(AuthError(message: _messageFromError(e)));
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      if (isClosed) return;
      _opToken++;
      final token = _opToken;
      emit(AuthLoading());
      _armLoadingTimeout('Sign out', token);
      await _authService.signOut();
      // State will be updated by authStateChanges listener
    } catch (e, st) {
      CrashReporter.record(e, st, source: 'AuthCubit.signOut failed');
      if (isClosed) return;
      emit(AuthError(message: _messageFromError(e)));
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      if (isClosed) return;
      _opToken++;
      final token = _opToken;
      emit(AuthLoading());
      _armLoadingTimeout('Password reset', token);
      await _authService.sendPasswordResetEmail(email);
      if (isClosed) return;
      emit(AuthPasswordResetEmailSent(email: email));
    } catch (e, st) {
      CrashReporter.record(
        e,
        st,
        source: 'AuthCubit.sendPasswordResetEmail failed',
      );
      if (isClosed) return;
      emit(AuthError(message: _messageFromError(e)));
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      if (isClosed) return;
      _opToken++;
      final token = _opToken;
      emit(AuthLoading());
      _armLoadingTimeout('Delete account', token);
      final user = _authService.currentUser;
      final uid = user?.uid;
      if (uid != null && !(user?.isAnonymous ?? true)) {
        try {
          await _firestoreService.releaseUsername(uid);
        } catch (e, st) {
          CrashReporter.record(
            e,
            st,
            source: 'AuthCubit.deleteAccount failed to release username',
          );
          if (isClosed) return;
          emit(AuthError(message: _messageFromError(e)));
        }
      }

      await _authService.deleteAccount();
      // State will be updated by authStateChanges listener
    } catch (e, st) {
      CrashReporter.record(e, st, source: 'AuthCubit.deleteAccount failed');
      if (isClosed) return;
      emit(AuthError(message: _messageFromError(e)));
    }
  }

  Future<void> updateUsername(String desiredUsername) async {
    final user = _authService.currentUser;
    if (user == null || user.isAnonymous) {
      throw Exception('Not logged in');
    }
    try {
      await _firestoreService.claimUsername(
        userId: user.uid,
        desiredUsername: desiredUsername,
      );
    } catch (e, st) {
      CrashReporter.record(e, st, source: 'AuthCubit.updateUsername failed');
      if (isClosed) return;
      emit(AuthError(message: _messageFromError(e)));
    }
  }

  String _messageFromError(Object e) {
    if (e is Exception) {
      return e.toString().replaceFirst('Exception: ', '');
    }
    return e.toString();
  }

  /// Get current user
  User? get currentUser => _authService.currentUser;

  /// Check if user is guest
  bool get isGuest => _authService.isGuest;

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
