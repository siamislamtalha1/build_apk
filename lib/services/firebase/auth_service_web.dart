import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:Bloomee/services/firebase/firebase_service.dart';
import 'package:Bloomee/services/firebase/firestore_service.dart';

/// Authentication service handling email/password, Google Sign-In, and guest mode
class AuthService {
  static bool _didSetWebPersistence = false;

  FirebaseAuth get _auth {
    final auth = FirebaseAuth.instance;
    // setPersistence is only supported on web.
    if (kIsWeb && !_didSetWebPersistence) {
      _didSetWebPersistence = true;
      try {
        auth.setPersistence(Persistence.LOCAL);
      } catch (_) {
        // ignore
      }
    }
    return auth;
  }

  static const String _googleServerClientId =
      String.fromEnvironment('GOOGLE_OAUTH_SERVER_CLIENT_ID');

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        _googleServerClientId.trim().isEmpty ? null : _googleServerClientId,
  );

  User? get currentUser {
    if (!FirebaseService.isInitialized) return null;
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

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

  bool get isLoggedIn => currentUser != null;

  bool get isGuest => currentUser?.isAnonymous ?? false;

  Future<void> _initializeUserProfile(
    User user, {
    String? desiredUsername,
  }) async {
    if (user.isAnonymous) return;

    try {
      final firestoreService = FirestoreService();

      if (user.displayName != null ||
          user.photoURL != null ||
          user.email != null) {
        await firestoreService.saveUserProfile(
          user.uid,
          displayName: user.displayName,
          photoURL: user.photoURL,
          email: user.email,
        );
      }

      final desired = (desiredUsername ?? '').trim();
      if (desired.isNotEmpty) {
        await firestoreService.claimUsername(
          userId: user.uid,
          desiredUsername: desired,
        );
      } else {
        await firestoreService.ensureUsername(
          userId: user.uid,
          displayName: user.displayName,
        );
      }

      debugPrint('✅ User profile initialized for ${user.email ?? user.uid}');
    } catch (e) {
      debugPrint('⚠️ Error initializing user profile: $e');
    }
  }

  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
    String? desiredUsername,
  }) async {
    try {
      if (!FirebaseService.isInitialized) {
        throw Exception('Firebase is not initialized');
      }
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
      }

      if (credential.user != null) {
        _initializeUserProfile(
          credential.user!,
          desiredUsername: desiredUsername,
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      final initErr = FirebaseService.lastInitError;
      if (initErr != null) {
        throw Exception('Auth failed. Firebase init error: $initErr');
      }
      rethrow;
    }
  }

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
      if (credential.user != null) {
        _initializeUserProfile(credential.user!);
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (!FirebaseService.isInitialized) {
        throw Exception('Firebase is not initialized');
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception(
          'Google Sign-In failed to return an idToken. Ensure Google Sign-In is enabled in Firebase Auth and your Web OAuth client is configured.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

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

      if (userCredential.user != null) {
        _initializeUserProfile(userCredential.user!);
      }
      return userCredential;
    } catch (e) {
      debugPrint('❌ Google Sign-In (web) failed: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInAsGuest() async {
    try {
      if (!FirebaseService.isInitialized) {
        throw Exception('Firebase is not initialized');
      }
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> linkAnonymousWithEmail({
    required String email,
    required String password,
    String? desiredUsername,
  }) async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) {
      try {
        return await signUpWithEmail(
          email: email,
          password: password,
          desiredUsername: desiredUsername,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          return await signInWithEmail(email: email, password: password);
        }
        rethrow;
      }
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      final linked = await user.linkWithCredential(credential);
      if (linked.user != null) {
        _initializeUserProfile(
          linked.user!,
          desiredUsername: desiredUsername,
        );
      }
      return linked;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use' ||
          e.code == 'credential-already-in-use') {
        final signedIn = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (signedIn.user != null) {
          _initializeUserProfile(
            signedIn.user!,
            desiredUsername: desiredUsername,
          );
        }
        return signedIn;
      }
      throw _handleAuthException(e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      if (!FirebaseService.isInitialized) {
        throw Exception('Firebase is not initialized');
      }
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    if (!FirebaseService.isInitialized) return;
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    if (!FirebaseService.isInitialized) {
      throw Exception('Firebase is not initialized');
    }
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user to delete');
    }
    await user.delete();
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    final message = switch (e.code) {
      'weak-password' =>
        'The password is too weak. Please use a stronger password.',
      'email-already-in-use' => 'An account already exists with this email.',
      'account-exists-with-different-credential' =>
        'An account already exists with the same email but a different sign-in method. Try signing in using the original method, then link Google from your account.',
      'invalid-email' => 'The email address is invalid.',
      'user-not-found' => 'No account found with this email.',
      'wrong-password' => 'Incorrect password. Please try again.',
      'credential-already-in-use' =>
        'This Google account is already linked to another user. Please sign in directly with Google.',
      'invalid-credential' =>
        'Invalid credentials. If this is Google Sign-In, check your Firebase project configuration and OAuth client IDs.',
      'user-disabled' => 'This account has been disabled.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'operation-not-allowed' => 'This sign-in method is not enabled.',
      'requires-recent-login' => 'Please sign in again to perform this action.',
      _ => e.message ?? 'An error occurred. Please try again.',
    };

    return Exception(message);
  }
}
