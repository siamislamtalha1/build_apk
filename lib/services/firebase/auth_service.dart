import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:desktop_webview_auth/desktop_webview_auth.dart';
import 'package:desktop_webview_auth/google.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:Bloomee/services/firebase/firebase_service.dart';

/// Authentication service handling email/password, Google Sign-In, and guest mode
class AuthService {
  FirebaseAuth get _auth {
    return FirebaseAuth.instance;
  }

  static const String _googleServerClientId =
      String.fromEnvironment('GOOGLE_OAUTH_SERVER_CLIENT_ID');
  static const String _windowsGoogleOAuthClientId =
      String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID_WINDOWS');
  static const String _windowsGoogleOAuthRedirectUri = String.fromEnvironment(
      'GOOGLE_OAUTH_REDIRECT_URI_WINDOWS',
      defaultValue: 'http://localhost');

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        _googleServerClientId.trim().isEmpty ? null : _googleServerClientId,
  );

  /// Get current user
  User? get currentUser {
    if (!FirebaseService.isInitialized) return null;
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Stream of auth state changes
  Stream<User?> get authStateChanges {
    if (!FirebaseService.isInitialized) {
      return Stream<User?>.value(null);
    }
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return Stream<User?>.value(null);
    }
  }

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Check if user is anonymous (guest)
  bool get isGuest => currentUser?.isAnonymous ?? false;

  // ==================== Email/Password Authentication ====================

  /// Sign up with email and password
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      if (!FirebaseService.isInitialized) {
        throw Exception('Firebase is not initialized');
      }
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
      }

      debugPrint('✅ Sign up successful: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Sign up failed: ${e.message}');
      throw _handleAuthException(e);
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      if (!FirebaseService.isInitialized) {
        throw Exception('Firebase is not initialized');
      }
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ Sign in successful: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Sign in failed: ${e.message}');
      throw _handleAuthException(e);
    }
  }

  // ==================== Google Sign-In ====================

  /// Sign in with Google (supports Android, iOS, and Windows)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (!FirebaseService.isInitialized) {
        throw Exception('Firebase is not initialized');
      }
      if (Platform.isWindows) {
        return await _signInWithGoogleDesktop();
      } else {
        return await _signInWithGoogleMobile();
      }
    } catch (e) {
      debugPrint('❌ Google Sign-In failed: $e');
      rethrow;
    }
  }

  /// Google Sign-In for mobile (Android/iOS)
  Future<UserCredential?> _signInWithGoogleMobile() async {
    try {
      // Trigger the authentication flow
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signIn();
      } on PlatformException catch (e) {
        final msg = (e.message ?? '').toLowerCase();
        if (e.code == 'sign_in_failed' && msg.contains('invalid_client')) {
          final fallback = GoogleSignIn(scopes: ['email', 'profile']);
          googleUser = await fallback.signIn();
        } else if (e.code == 'sign_in_failed' && msg.contains('10')) {
          throw Exception(
            'Google Sign-In failed (Android error 10). This is almost always caused by missing/incorrect SHA-1/SHA-256 in Firebase for your Android app. Add your debug + release SHA fingerprints in Firebase Console, then re-download google-services.json and reinstall the app.',
          );
        } else {
          rethrow;
        }
      }

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (googleAuth.idToken == null) {
        throw Exception(
          'Google Sign-In failed to return an idToken. Ensure Google Sign-In is enabled in Firebase Auth and your Android SHA-1/SHA-256 fingerprints are configured.',
        );
      }

      // Sign in to Firebase with the Google credential
      final currentUser = _auth.currentUser;
      UserCredential userCredential;
      if (currentUser != null && currentUser.isAnonymous) {
        try {
          userCredential = await currentUser.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            userCredential = await _auth.signInWithCredential(credential);
          } else {
            throw _handleAuthException(e);
          }
        }
      } else {
        userCredential = await _auth.signInWithCredential(credential);
      }
      debugPrint('✅ Google Sign-In successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('❌ Google Sign-In (mobile) failed: $e');
      rethrow;
    }
  }

  /// Google Sign-In for Windows (using browser-based auth)
  Future<UserCredential?> _signInWithGoogleDesktop() async {
    try {
      if (_windowsGoogleOAuthClientId.trim().isEmpty) {
        throw Exception(
          'Missing Windows OAuth clientId. Build/run with --dart-define=GOOGLE_OAUTH_CLIENT_ID_WINDOWS=YOUR_DESKTOP_OAUTH_CLIENT_ID',
        );
      }
      // Use desktop_webview_auth for Windows
      final result = await DesktopWebviewAuth.signIn(
        GoogleSignInArgs(
          clientId: _windowsGoogleOAuthClientId,
          redirectUri: _windowsGoogleOAuthRedirectUri,
          scope: 'email profile',
        ),
      );

      if (result == null) {
        return null;
      }

      // Extract tokens from result
      final accessToken = result.accessToken;
      final idToken = result.idToken;

      // Create credential from the tokens
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      // Sign in to Firebase
      final currentUser = _auth.currentUser;
      UserCredential userCredential;
      if (currentUser != null && currentUser.isAnonymous) {
        try {
          userCredential = await currentUser.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            userCredential = await _auth.signInWithCredential(credential);
          } else {
            throw _handleAuthException(e);
          }
        }
      } else {
        userCredential = await _auth.signInWithCredential(credential);
      }
      debugPrint(
          '✅ Google Sign-In (Windows) successful: ${userCredential.user?.email}');
      return userCredential;
    } on PlatformException catch (e) {
      final msg = (e.message ?? '').toLowerCase();
      if (msg.contains('invalid_client')) {
        throw Exception(
          'Google Sign-In (Windows) failed: invalid_client. Ensure you are using a Desktop OAuth Client ID (not Android/Web), and that your redirect URI matches exactly. Current redirectUri: $_windowsGoogleOAuthRedirectUri',
        );
      }
      throw Exception(
        'Google Sign-In (Windows) failed: ${e.code}${e.message == null ? '' : ' - ${e.message}'}',
      );
    } catch (e) {
      debugPrint('❌ Google Sign-In (Windows) failed: $e');
      rethrow;
    }
  }

  // ==================== Anonymous/Guest Authentication ====================

  /// Sign in anonymously (guest mode)
  Future<UserCredential?> signInAsGuest() async {
    try {
      if (!FirebaseService.isInitialized) {
        throw Exception('Firebase is not initialized');
      }
      final credential = await _auth.signInAnonymously();
      debugPrint('✅ Guest sign-in successful');
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Guest sign-in failed: ${e.message}');
      throw _handleAuthException(e);
    }
  }

  /// Convert anonymous account to permanent account with email/password
  Future<UserCredential?> linkAnonymousWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || !user.isAnonymous) {
        // If not anonymous, just try to sign up/in normally
        // This handles edge cases where state might be desynced
        try {
          return await signUpWithEmail(email: email, password: password);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            return await signInWithEmail(email: email, password: password);
          }
          rethrow;
        }
      }

      // Windows/Desktop often has issues with linkWithCredential crashing the native plugin.
      // Since our Isar DB is user-agnostic (global on device), we don't strictly *need* to link
      // the Firebase accounts to preserve local data. The local data will simply be pushed
      // to the new account by SyncService.
      // So on Windows, we prefer stability: Create New Account instead of Link.
      if (Platform.isWindows) {
        try {
          // Try to create new account. This will sign out the anonymous user and sign in the new one.
          final credential = await _auth.createUserWithEmailAndPassword(
              email: email, password: password);
          debugPrint(
              '✅ (Windows) Created new account instead of linking: ${credential.user?.email}');
          return credential;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            // If email exists, just sign in.
            final credential = await _auth.signInWithEmailAndPassword(
                email: email, password: password);
            debugPrint(
                '✅ (Windows) Signed into existing account: ${credential.user?.email}');
            return credential;
          }
          rethrow;
        }
      }

      // For Mobile/Web, proceed with standard linking
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      final userCredential = await user.linkWithCredential(credential);
      debugPrint('✅ Anonymous account linked with email');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use' ||
          e.code == 'credential-already-in-use') {
        // If the email already has an account, linking the anonymous user will fail.
        // In that case, sign in to that account instead.
        try {
          final signedIn = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          debugPrint('✅ Existing account found; signed in with email/password');
          return signedIn;
        } on FirebaseAuthException catch (signInError) {
          debugPrint(
              '❌ Sign-in after link failure failed: ${signInError.message}');
          throw _handleAuthException(signInError);
        }
      }
      debugPrint('❌ Linking anonymous account failed: ${e.message}');
      throw _handleAuthException(e);
    }
  }

  // ==================== Password Reset ====================

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      if (!FirebaseService.isInitialized) {
        throw Exception('Firebase is not initialized');
      }
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('✅ Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Password reset failed: ${e.message}');
      throw _handleAuthException(e);
    }
  }

  // ==================== Sign Out ====================

  /// Sign out from all providers
  Future<void> signOut() async {
    try {
      if (!FirebaseService.isInitialized) {
        return;
      }
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Sign out from Firebase
      await _auth.signOut();
      debugPrint('✅ Sign out successful');
    } catch (e) {
      debugPrint('❌ Sign out failed: $e');
      rethrow;
    }
  }

  // ==================== Account Deletion ====================

  /// Delete current user account
  Future<void> deleteAccount() async {
    try {
      if (!FirebaseService.isInitialized) {
        throw Exception('Firebase is not initialized');
      }
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user to delete');
      }

      await user.delete();
      debugPrint('✅ Account deleted successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Account deletion failed: ${e.message}');
      throw _handleAuthException(e);
    }
  }

  // ==================== Error Handling ====================

  /// Handle Firebase Auth exceptions and return user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but a different sign-in method. Try signing in using the original method, then link Google from your account.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'credential-already-in-use':
        return 'This Google account is already linked to another user. Please sign in directly with Google.';
      case 'invalid-credential':
        return 'Invalid credentials. If this is Google Sign-In, check your Firebase project configuration and OAuth client IDs.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'requires-recent-login':
        return 'Please sign in again to perform this action.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}
