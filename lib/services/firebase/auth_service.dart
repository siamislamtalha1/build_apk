import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:desktop_webview_auth/desktop_webview_auth.dart';
import 'package:desktop_webview_auth/google.dart';

/// Authentication service handling email/password, Google Sign-In, and guest mode
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Check if user is anonymous (guest)
  bool get isGuest => _auth.currentUser?.isAnonymous ?? false;

  // ==================== Email/Password Authentication ====================

  /// Sign up with email and password
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
      }

      print('✅ Sign up successful: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e) {
      print('❌ Sign up failed: ${e.message}');
      throw _handleAuthException(e);
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ Sign in successful: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e) {
      print('❌ Sign in failed: ${e.message}');
      throw _handleAuthException(e);
    }
  }

  // ==================== Google Sign-In ====================

  /// Sign in with Google (supports Android, iOS, and Windows)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (Platform.isWindows) {
        return await _signInWithGoogleDesktop();
      } else {
        return await _signInWithGoogleMobile();
      }
    } catch (e) {
      print('❌ Google Sign-In failed: $e');
      rethrow;
    }
  }

  /// Google Sign-In for mobile (Android/iOS)
  Future<UserCredential?> _signInWithGoogleMobile() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

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

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      print('✅ Google Sign-In successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      print('❌ Google Sign-In (mobile) failed: $e');
      rethrow;
    }
  }

  /// Google Sign-In for Windows (using browser-based auth)
  Future<UserCredential?> _signInWithGoogleDesktop() async {
    try {
      // Use desktop_webview_auth for Windows
      final result = await DesktopWebviewAuth.signIn(
        GoogleSignInArgs(
          clientId:
              '612505906312-6fhigd9mi64k7nkqvdh8m68sdqshjopn.apps.googleusercontent.com',
          redirectUri: 'http://localhost',
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
      final userCredential = await _auth.signInWithCredential(credential);
      print(
          '✅ Google Sign-In (Windows) successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      print('❌ Google Sign-In (Windows) failed: $e');
      rethrow;
    }
  }

  // ==================== Anonymous/Guest Authentication ====================

  /// Sign in anonymously (guest mode)
  Future<UserCredential?> signInAsGuest() async {
    try {
      final credential = await _auth.signInAnonymously();
      print('✅ Guest sign-in successful');
      return credential;
    } on FirebaseAuthException catch (e) {
      print('❌ Guest sign-in failed: ${e.message}');
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
        throw Exception('No anonymous user to link');
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      final userCredential = await user.linkWithCredential(credential);
      print('✅ Anonymous account linked with email');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('❌ Linking anonymous account failed: ${e.message}');
      throw _handleAuthException(e);
    }
  }

  // ==================== Password Reset ====================

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('✅ Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      print('❌ Password reset failed: ${e.message}');
      throw _handleAuthException(e);
    }
  }

  // ==================== Sign Out ====================

  /// Sign out from all providers
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Sign out from Firebase
      await _auth.signOut();
      print('✅ Sign out successful');
    } catch (e) {
      print('❌ Sign out failed: $e');
      rethrow;
    }
  }

  // ==================== Account Deletion ====================

  /// Delete current user account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user to delete');
      }

      await user.delete();
      print('✅ Account deleted successfully');
    } on FirebaseAuthException catch (e) {
      print('❌ Account deletion failed: ${e.message}');
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
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
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
