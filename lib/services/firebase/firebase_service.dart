import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:Bloomee/services/crash_reporter.dart';

/// Firebase initialization service for Android, iOS, and Windows
class FirebaseService {
  static bool _initialized = false;
  static Object? _lastInitError;
  static StackTrace? _lastInitStack;

  static const String _windowsApiKey =
      String.fromEnvironment('FIREBASE_API_KEY_WINDOWS');
  static const String _windowsAppId =
      String.fromEnvironment('FIREBASE_APP_ID_WINDOWS');
  static const String _windowsMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID_WINDOWS');
  static const String _windowsProjectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID_WINDOWS');
  static const String _windowsStorageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET_WINDOWS');

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
        if (_windowsApiKey.trim().isEmpty ||
            _windowsAppId.trim().isEmpty ||
            _windowsMessagingSenderId.trim().isEmpty ||
            _windowsProjectId.trim().isEmpty) {
          throw Exception(
            'Missing Windows Firebase config. Provide these at build time using --dart-define:\n'
            'FIREBASE_API_KEY_WINDOWS, FIREBASE_APP_ID_WINDOWS, FIREBASE_MESSAGING_SENDER_ID_WINDOWS, FIREBASE_PROJECT_ID_WINDOWS\n'
            'Optional: FIREBASE_STORAGE_BUCKET_WINDOWS',
          );
        }

        if (_windowsAppId.contains(':android:')) {
          throw Exception(
            'Windows FirebaseOptions misconfigured: appId looks like an Android appId ($_windowsAppId). '
            'For Windows you must use the Web/Desktop appId from Firebase Console (Project settings -> Your apps -> Web app).',
          );
        }

        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: _windowsApiKey,
            appId: _windowsAppId,
            messagingSenderId: _windowsMessagingSenderId,
            projectId: _windowsProjectId,
            storageBucket:
                _windowsStorageBucket.trim().isEmpty ? null : _windowsStorageBucket,
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
