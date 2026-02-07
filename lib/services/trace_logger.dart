import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class TraceLogger {
  static File? _logFile;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      // Try to find a writable path that definitely exists
      Directory? dir;
      if (Platform.isWindows) {
        dir = await getApplicationDocumentsDirectory();
      } else {
        dir = await getApplicationSupportDirectory();
      }

      _logFile = File(p.join(dir.path, 'Musicly_Trace.log'));
      final timestamp = DateTime.now().toIso8601String();
      await _logFile!.writeAsString(
        '=== Trace Log Started $timestamp ===\n',
        mode: FileMode.write,
        flush: true,
      );
      _initialized = true;
      log('TraceLogger initialized at ${_logFile!.path}');
    } catch (e) {
      print('Failed to initialize TraceLogger: $e');
    }
  }

  static void log(String message) {
    print('[Trace] $message');
    if (_logFile != null) {
      try {
        final timestamp = DateTime.now().toIso8601String();
        _logFile!.writeAsStringSync(
          '[$timestamp] $message\n',
          mode: FileMode.append,
          flush: true,
        );
      } catch (_) {
        // Ignored
      }
    }
  }
}
