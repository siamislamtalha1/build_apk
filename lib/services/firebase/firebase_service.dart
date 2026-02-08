import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:Bloomee/services/crash_reporter.dart';

import 'package:Bloomee/firebase_config.dart';

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
        // Fallback to local config if env vars are missing
        String apiKey = _windowsApiKey;
        if (apiKey.isEmpty) apiKey = FirebaseConfig.windowsApiKey;

        String appId = _windowsAppId;
        if (appId.isEmpty) appId = FirebaseConfig.windowsAppId;

        String messagingSenderId = _windowsMessagingSenderId;
        if (messagingSenderId.isEmpty) {
          messagingSenderId = FirebaseConfig.windowsMessagingSenderId;
        }

        String projectId = _windowsProjectId;
        if (projectId.isEmpty) projectId = FirebaseConfig.windowsProjectId;

        String storageBucket = _windowsStorageBucket;
        if (storageBucket.isEmpty) {
          storageBucket = FirebaseConfig.windowsStorageBucket;
        }

        if (apiKey.trim().isEmpty ||
            appId.trim().isEmpty ||
            messagingSenderId.trim().isEmpty ||
            projectId.trim().isEmpty) {
          throw Exception(
            'Missing Windows Firebase config. Provide these at build time using --dart-define or update lib/firebase_config.dart:\n'
            'FIREBASE_API_KEY_WINDOWS, FIREBASE_APP_ID_WINDOWS, FIREBASE_MESSAGING_SENDER_ID_WINDOWS, FIREBASE_PROJECT_ID_WINDOWS',
          );
        }

        if (appId.contains(':android:')) {
          throw Exception(
            'Windows FirebaseOptions misconfigured: appId looks like an Android appId ($appId). '
            'For Windows you must use the Web/Desktop appId from Firebase Console (Project settings -> Your apps -> Web app) and update it in lib/firebase_config.dart.',
          );
        }

        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: apiKey,
            appId: appId,
            messagingSenderId: messagingSenderId,
            projectId: projectId,
            storageBucket: storageBucket.trim().isEmpty ? null : storageBucket,
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
