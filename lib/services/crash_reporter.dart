import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CrashReporter {
  static String? lastCrashText;
  static String? lastCrashFilePath;
  static bool _handling = false;

  static String? lastStageText;
  static String? lastStageFilePath;
  static const String _windowsStageFileName = 'Musicly_boot_stage.txt';

  static void writeStartupProbe() {
    if (!Platform.isWindows) return;
    try {
      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final text = 'Musicly startup probe: $ts\n';
      final file = _tryWriteWindowsSync(text, prefix: 'Musicly_startup_');
      if (file != null) {
        lastCrashFilePath = file.path;
      }
    } catch (_) {
      // ignore
    }
  }

  static void markStage(String stage) {
    try {
      final now = DateTime.now().toIso8601String();
      final text = 'time: $now\nstage: $stage\n';
      lastStageText = text;

      if (Platform.isWindows) {
        final file = _tryWriteWindowsSyncFixed(_windowsStageFileName, text);
        if (file != null) {
          lastStageFilePath = file.path;
        }
      }

      unawaited(_persistStage(text));
    } catch (_) {
      // ignore
    }
  }

  static void record(
    Object error,
    StackTrace? stack, {
    String source = 'unknown',
  }) {
    if (_handling) return;
    _handling = true;

    final text = _format(error, stack, source: source);
    lastCrashText = text;

    if (Platform.isWindows) {
      try {
        final file = _tryWriteWindowsSync(text, prefix: 'Musicly_crash_');
        if (file != null) {
          lastCrashFilePath = file.path;
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

  static Future<void> _persistStage(String text) async {
    try {
      Directory dir;
      try {
        dir = await getApplicationSupportDirectory();
      } catch (_) {
        dir = await getTemporaryDirectory();
      }

      final file = File(p.join(dir.path, 'boot_stage.txt'));
      await file.writeAsString(text, flush: true);
    } catch (_) {
      // ignore
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

  static File? _tryWriteWindowsSyncFixed(String fileName, String text) {
    final candidates = <Directory>[];

    final desktop = _tryGetWindowsDesktopDirectory();
    if (desktop != null) candidates.add(desktop);

    try {
      final exeDir = Directory(p.dirname(Platform.resolvedExecutable));
      candidates.add(exeDir);
    } catch (_) {
      // ignore
    }

    try {
      candidates.add(Directory.current);
    } catch (_) {
      // ignore
    }

    try {
      candidates.add(Directory.systemTemp);
    } catch (_) {
      // ignore
    }

    for (final dir in candidates) {
      try {
        if (!dir.existsSync()) continue;
        final file = File(p.join(dir.path, fileName));
        file.writeAsStringSync(text, flush: true);
        return file;
      } catch (_) {
        // ignore
      }
    }

    return null;
  }

  static String? readWindowsStageSync() {
    if (!Platform.isWindows) return null;
    try {
      final candidates = <Directory>[];

      final desktop = _tryGetWindowsDesktopDirectory();
      if (desktop != null) candidates.add(desktop);

      try {
        candidates.add(Directory(p.dirname(Platform.resolvedExecutable)));
      } catch (_) {
        // ignore
      }

      try {
        candidates.add(Directory.current);
      } catch (_) {
        // ignore
      }

      try {
        candidates.add(Directory.systemTemp);
      } catch (_) {
        // ignore
      }

      for (final dir in candidates) {
        try {
          final file = File(p.join(dir.path, _windowsStageFileName));
          if (file.existsSync()) {
            return file.readAsStringSync();
          }
        } catch (_) {
          // ignore
        }
      }
    } catch (_) {
      // ignore
    }
    return null;
  }

  static File? _tryWriteWindowsSync(String text, {required String prefix}) {
    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final fileName = '$prefix$ts.txt';

    final candidates = <Directory>[];

    final desktop = _tryGetWindowsDesktopDirectory();
    if (desktop != null) candidates.add(desktop);

    try {
      final exeDir = Directory(p.dirname(Platform.resolvedExecutable));
      candidates.add(exeDir);
    } catch (_) {
      // ignore
    }

    try {
      candidates.add(Directory.current);
    } catch (_) {
      // ignore
    }

    try {
      candidates.add(Directory.systemTemp);
    } catch (_) {
      // ignore
    }

    for (final dir in candidates) {
      try {
        if (!dir.existsSync()) continue;
        final file = File(p.join(dir.path, fileName));
        file.writeAsStringSync(text, flush: true);
        return file;
      } catch (_) {
        // ignore
      }
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
