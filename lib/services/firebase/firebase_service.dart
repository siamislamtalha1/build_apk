import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Firebase initialization service for Android, iOS, and Windows
class FirebaseService {
  static bool _initialized = false;

  /// Initialize Firebase for the current platform
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kIsWeb) {
        // Web configuration (not used in this app)
        throw UnsupportedError('Web platform is not supported');
      } else if (Platform.isAndroid || Platform.isIOS) {
        // Android and iOS use google-services.json and GoogleService-Info.plist
        await Firebase.initializeApp();
      } else if (Platform.isWindows) {
        // Windows configuration
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyBagOn_faUl6cDVdrXL77qWJMkSGAdfI6A',
            appId: '1:612505906312:android:806ef94d1737bffaa1833d',
            messagingSenderId: '612505906312',
            projectId: 'musicly-6bcc1',
            storageBucket: 'musicly-6bcc1.firebasestorage.app',
          ),
        );
      } else {
        throw UnsupportedError(
            'Platform ${Platform.operatingSystem} is not supported');
      }

      _initialized = true;
      print('✅ Firebase initialized successfully');
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      rethrow;
    }
  }

  /// Check if Firebase is initialized
  static bool get isInitialized => _initialized;
}
