import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CrashReporter {
  static String? lastCrashText;
  static String? lastCrashFilePath;
  static bool _handling = false;

  static void record(
    Object error,
    StackTrace? stack, {
    String source = 'unknown',
  }) {
    if (_handling) return;
    _handling = true;

    final text = _format(error, stack, source: source);
    lastCrashText = text;

    // Best-effort, immediate write on Windows so the file exists even if the
    // process terminates quickly.
    if (Platform.isWindows) {
      try {
        final desktop = _tryGetWindowsDesktopDirectory();
        if (desktop != null) {
          final ts = DateTime.now()
              .toIso8601String()
              .replaceAll(':', '-')
              .replaceAll('.', '-');
          final desktopFile = File(p.join(desktop.path, 'Musicly_crash_$ts.txt'));
          desktopFile.writeAsStringSync(text, flush: true);
          lastCrashFilePath = desktopFile.path;
        }
      } catch (_) {
        // ignore
      }
    }

    unawaited(_persist(text));

    scheduleMicrotask(() {
      _handling = false;
    });
  }

  static String _format(
    Object error,
    StackTrace? stack, {
    required String source,
  }) {
    final now = DateTime.now().toIso8601String();
    final st = stack?.toString() ?? 'No StackTrace';
    return '=== Musicly Crash Report ===\n'
        'time: $now\n'
        'source: $source\n'
        'error: $error\n'
        '\n'
        'stacktrace:\n'
        '$st\n';
  }

  static Future<void> _persist(String text) async {
    try {
      // 1) Always write to app-support (or temp) so it exists on every platform.
      Directory dir;
      try {
        dir = await getApplicationSupportDirectory();
      } catch (_) {
        dir = await getTemporaryDirectory();
      }

      final file = File(p.join(dir.path, 'last_crash.txt'));
      await file.writeAsString(text, flush: true);
      lastCrashFilePath = file.path;

      // 2) Best-effort: also write to Desktop on Windows.
      if (Platform.isWindows) {
        final desktop = _tryGetWindowsDesktopDirectory();
        if (desktop != null) {
          final ts = DateTime.now()
              .toIso8601String()
              .replaceAll(':', '-')
              .replaceAll('.', '-');
          final desktopFile = File(p.join(desktop.path, 'Musicly_crash_$ts.txt'));
          await desktopFile.writeAsString(text, flush: true);
          // Prefer the desktop path so the crash screen shows it.
          lastCrashFilePath = desktopFile.path;
        }
      }
    } catch (e) {
      debugPrint('CrashReporter persist failed: $e');
    }
  }

  static Directory? _tryGetWindowsDesktopDirectory() {
    try {
      final oneDrive = Platform.environment['OneDrive'];
      if (oneDrive != null && oneDrive.isNotEmpty) {
        final d = Directory(p.join(oneDrive, 'Desktop'));
        if (d.existsSync()) return d;
      }

      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.isNotEmpty) {
        final d = Directory(p.join(userProfile, 'Desktop'));
        if (d.existsSync()) return d;
      }

      final homeDrive = Platform.environment['HOMEDRIVE'];
      final homePath = Platform.environment['HOMEPATH'];
      if ((homeDrive ?? '').isNotEmpty && (homePath ?? '').isNotEmpty) {
        final d = Directory(p.join('$homeDrive$homePath', 'Desktop'));
        if (d.existsSync()) return d;
      }
    } catch (_) {
      // ignore
    }
    return null;
  }

  static Future<String?> loadLastCrashFromDisk() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File(p.join(dir.path, 'last_crash.txt'));
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }
}
