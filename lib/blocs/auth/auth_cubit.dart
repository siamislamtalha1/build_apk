import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Bloomee/services/firebase/auth_service.dart';
import 'package:Bloomee/services/firebase/firestore_service.dart';

part 'auth_state.dart';

/// Authentication state management cubit
class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  AuthCubit({AuthService? authService})
      : _authService = authService ?? AuthService(),
        _firestoreService = FirestoreService(),
        super(AuthInitial()) {
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        emit(Authenticated(user: user));
        if (!user.isAnonymous) {
          () async {
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
            } catch (_) {}
          }();
        }
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
    String? desiredUsername,
  }) async {
    try {
      emit(AuthLoading());
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
        } catch (_) {}
      }
      final user = cred?.user;
      if (user != null && !user.isAnonymous) {
        await _firestoreService.saveUserProfile(
          user.uid,
          displayName: user.displayName,
          photoURL: user.photoURL,
          email: user.email,
        );
        if (desiredUsername != null && desiredUsername.trim().isNotEmpty) {
          await _firestoreService.claimUsername(
            userId: user.uid,
            desiredUsername: desiredUsername,
          );
        } else {
          await _firestoreService.ensureUsername(
            userId: user.uid,
            displayName: user.displayName,
          );
        }
      }
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
      final cred = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      final user = cred?.user;
      if (user != null && !user.isAnonymous) {
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
      }
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
      final user = result?.user;
      if (user != null && !user.isAnonymous) {
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
      final user = _authService.currentUser;
      final uid = user?.uid;
      if (uid != null && !(user?.isAnonymous ?? true)) {
        await _firestoreService.releaseUsername(uid);
      }

      await _authService.deleteAccount();
      // State will be updated by authStateChanges listener
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> updateUsername(String desiredUsername) async {
    final user = _authService.currentUser;
    if (user == null || user.isAnonymous) {
      throw Exception('Not logged in');
    }
    await _firestoreService.claimUsername(
      userId: user.uid,
      desiredUsername: desiredUsername,
    );
  }

  /// Get current user
  User? get currentUser => _authService.currentUser;

  /// Check if user is guest
  bool get isGuest => _authService.isGuest;
}
