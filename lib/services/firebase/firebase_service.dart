import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:Bloomee/services/crash_reporter.dart';
import 'package:Bloomee/services/platform/platform_info.dart';

/// Firebase initialization service for Android, iOS, and Windows
class FirebaseService {
  static bool _initialized = false;
  static Object? _lastInitError;
  static StackTrace? _lastInitStack;

  static const String _webApiKey = String.fromEnvironment('FIREBASE_API_KEY_WEB');
  static const String _webAppId = String.fromEnvironment('FIREBASE_APP_ID_WEB');
  static const String _webMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID_WEB');
  static const String _webProjectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID_WEB');
  static const String _webAuthDomain =
      String.fromEnvironment('FIREBASE_AUTH_DOMAIN_WEB');
  static const String _webStorageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET_WEB');

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
        const apiKey = _webApiKey;
        const appId = _webAppId;
        const messagingSenderId = _webMessagingSenderId;
        const projectId = _webProjectId;
        const authDomain = _webAuthDomain;
        const storageBucket = _webStorageBucket;

        if (apiKey.trim().isEmpty ||
            appId.trim().isEmpty ||
            messagingSenderId.trim().isEmpty ||
            projectId.trim().isEmpty ||
            authDomain.trim().isEmpty) {
          throw Exception(
            'Missing Web Firebase config. Provide these at build time using --dart-define:\n'
            'FIREBASE_API_KEY_WEB, FIREBASE_APP_ID_WEB, FIREBASE_MESSAGING_SENDER_ID_WEB, FIREBASE_PROJECT_ID_WEB, FIREBASE_AUTH_DOMAIN_WEB\n'
            'Optional: FIREBASE_STORAGE_BUCKET_WEB',
          );
        }

        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: apiKey,
            appId: appId,
            messagingSenderId: messagingSenderId,
            projectId: projectId,
            authDomain: authDomain,
            storageBucket: storageBucket.trim().isEmpty ? null : storageBucket,
          ),
        );
      } else if (PlatformInfo.isAndroid || PlatformInfo.isIOS) {
        // Android/iOS must use native config only (google-services.json / GoogleService-Info.plist)
        await Firebase.initializeApp();
      } else if (PlatformInfo.isWindows) {
        const apiKey = _windowsApiKey;
        const appId = _windowsAppId;
        const messagingSenderId = _windowsMessagingSenderId;
        const projectId = _windowsProjectId;
        const storageBucket = _windowsStorageBucket;

        if (apiKey.trim().isEmpty ||
            appId.trim().isEmpty ||
            messagingSenderId.trim().isEmpty ||
            projectId.trim().isEmpty) {
          throw Exception(
            'Missing Windows Firebase config. Provide these at build time using --dart-define:\n'
            'FIREBASE_API_KEY_WINDOWS, FIREBASE_APP_ID_WINDOWS, FIREBASE_MESSAGING_SENDER_ID_WINDOWS, FIREBASE_PROJECT_ID_WINDOWS\n'
            'Optional: FIREBASE_STORAGE_BUCKET_WINDOWS',
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
            'Platform ${PlatformInfo.operatingSystem} is not supported');
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
