import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

    // Gather comprehensive diagnostic info
    final diagnostics = _gatherDiagnostics();

    return '=== Musicly Crash Report ===\n'
        'time: $now\n'
        'source: $source\n'
        'error: $error\n'
        '\n'
        '$diagnostics'
        '\n'
        'stacktrace:\n'
        '$st\n';
  }

  static String _gatherDiagnostics() {
    final buffer = StringBuffer();

    // Platform information
    buffer.writeln('=== Platform Info ===');
    buffer.writeln('OS: ${Platform.operatingSystem}');
    buffer.writeln('OS Version: ${Platform.operatingSystemVersion}');
    buffer.writeln('Locale: ${Platform.localeName}');
    buffer.writeln('Number of Processors: ${Platform.numberOfProcessors}');
    buffer.writeln('Executable: ${Platform.resolvedExecutable}');
    buffer.writeln();

    // Memory information
    buffer.writeln('=== Memory Info ===');
    try {
      final info = ProcessInfo.currentRss;
      buffer.writeln(
          'Current RSS: ${(info / 1024 / 1024).toStringAsFixed(2)} MB');
      final maxRss = ProcessInfo.maxRss;
      buffer
          .writeln('Max RSS: ${(maxRss / 1024 / 1024).toStringAsFixed(2)} MB');
    } catch (e) {
      buffer.writeln('Memory info unavailable: $e');
    }
    buffer.writeln();

    // Flutter/Dart information
    buffer.writeln('=== Flutter/Dart Info ===');
    buffer.writeln('Dart Version: ${Platform.version}');
    buffer.writeln('Debug Mode: $kDebugMode');
    buffer.writeln('Profile Mode: $kProfileMode');
    buffer.writeln('Release Mode: $kReleaseMode');
    buffer.writeln();

    // Environment variables (selective)
    buffer.writeln('=== Environment ===');
    if (Platform.isWindows) {
      buffer.writeln('USERPROFILE: ${Platform.environment['USERPROFILE']}');
      buffer.writeln('COMPUTERNAME: ${Platform.environment['COMPUTERNAME']}');
      buffer.writeln(
          'PROCESSOR_ARCHITECTURE: ${Platform.environment['PROCESSOR_ARCHITECTURE']}');
    }
    buffer.writeln();

    return buffer.toString();
  }

  /// Enhanced record method with async device info gathering
  static Future<void> recordWithDeviceInfo(
    Object error,
    StackTrace? stack, {
    String source = 'unknown',
  }) async {
    if (_handling) return;
    _handling = true;

    String deviceInfo = '';
    try {
      deviceInfo = await _getDeviceInfo();
    } catch (e) {
      deviceInfo = 'Device info unavailable: $e\n';
    }

    String appInfo = '';
    try {
      appInfo = await _getAppInfo();
    } catch (e) {
      appInfo = 'App info unavailable: $e\n';
    }

    final text = _formatEnhanced(error, stack,
        source: source, deviceInfo: deviceInfo, appInfo: appInfo);
    lastCrashText = text;

    if (Platform.isWindows) {
      try {
        final file =
            _tryWriteWindowsSync(text, prefix: 'Musicly_crash_detailed_');
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

  static Future<String> _getDeviceInfo() async {
    final buffer = StringBuffer();
    buffer.writeln('=== Device Info ===');

    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        buffer.writeln('Computer Name: ${info.computerName}');
        buffer.writeln('Number of Cores: ${info.numberOfCores}');
        buffer.writeln('System Memory: ${info.systemMemoryInMegabytes} MB');
        buffer.writeln('Product Name: ${info.productName}');
        buffer.writeln('Display Version: ${info.displayVersion}');
        buffer.writeln('Build Number: ${info.buildNumber}');
        buffer.writeln('Platform ID: ${info.platformId}');
      } else if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        buffer.writeln('Brand: ${info.brand}');
        buffer.writeln('Model: ${info.model}');
        buffer.writeln('Device: ${info.device}');
        buffer.writeln('Android Version: ${info.version.release}');
        buffer.writeln('SDK: ${info.version.sdkInt}');
        buffer.writeln('Manufacturer: ${info.manufacturer}');
        buffer.writeln('Product: ${info.product}');
        buffer.writeln('Hardware: ${info.hardware}');
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        buffer.writeln('Name: ${info.name}');
        buffer.writeln('Model: ${info.model}');
        buffer.writeln('System Name: ${info.systemName}');
        buffer.writeln('System Version: ${info.systemVersion}');
        buffer.writeln('Machine: ${info.utsname.machine}');
      }
    } catch (e) {
      buffer.writeln('Error getting device info: $e');
    }

    buffer.writeln();
    return buffer.toString();
  }

  static Future<String> _getAppInfo() async {
    final buffer = StringBuffer();
    buffer.writeln('=== App Info ===');

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      buffer.writeln('App Name: ${packageInfo.appName}');
      buffer.writeln('Package Name: ${packageInfo.packageName}');
      buffer.writeln('Version: ${packageInfo.version}');
      buffer.writeln('Build Number: ${packageInfo.buildNumber}');
      buffer.writeln('Build Signature: ${packageInfo.buildSignature}');
    } catch (e) {
      buffer.writeln('Error getting app info: $e');
    }

    buffer.writeln();
    return buffer.toString();
  }

  static String _formatEnhanced(
    Object error,
    StackTrace? stack, {
    required String source,
    required String deviceInfo,
    required String appInfo,
  }) {
    final now = DateTime.now().toIso8601String();
    final st = stack?.toString() ?? 'No StackTrace';
    final diagnostics = _gatherDiagnostics();

    return '=== Musicly Crash Report (Enhanced) ===\n'
        'time: $now\n'
        'source: $source\n'
        'error: $error\n'
        '\n'
        '$appInfo'
        '$deviceInfo'
        '$diagnostics'
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
          final desktopFile =
              File(p.join(desktop.path, 'Musicly_crash_$ts.txt'));
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
