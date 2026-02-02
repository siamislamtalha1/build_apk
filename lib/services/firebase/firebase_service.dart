import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:Bloomee/services/crash_reporter.dart';

/// Firebase initialization service for Android, iOS, and Windows
class FirebaseService {
  static bool _initialized = false;
  static Object? _lastInitError;
  static StackTrace? _lastInitStack;

  static Object? get lastInitError => _lastInitError;
  static StackTrace? get lastInitStack => _lastInitStack;

  static Future<bool> initializeSafe() async {
    if (_initialized) return true;
    try {
      if (kIsWeb) {
        throw UnsupportedError('Web platform is not supported');
      } else if (Platform.isAndroid || Platform.isIOS) {
        await Firebase.initializeApp();
      } else if (Platform.isWindows) {
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
      return true;
    } catch (e, st) {
      _lastInitError = e;
      _lastInitStack = st;
      CrashReporter.record(e, st, source: 'FirebaseService.initializeSafe');
      return false;
    }
  }

  /// Initialize Firebase for the current platform
  static Future<void> initialize() async {
    if (_initialized) return;
    final ok = await initializeSafe();
    if (!ok) {
      throw Exception(
        'Firebase initialization failed: ${_lastInitError ?? 'unknown'}',
      );
    }
  }

  /// Check if Firebase is initialized
  static bool get isInitialized => _initialized;
}
