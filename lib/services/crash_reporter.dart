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
      Directory dir;
      try {
        dir = await getApplicationSupportDirectory();
      } catch (_) {
        dir = await getTemporaryDirectory();
      }

      final file = File(p.join(dir.path, 'last_crash.txt'));
      await file.writeAsString(text, flush: true);
      lastCrashFilePath = file.path;
    } catch (e) {
      debugPrint('CrashReporter persist failed: $e');
    }
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
