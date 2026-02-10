import 'dart:io' as io;

class PlatformInfo {
  static bool get isAndroid => io.Platform.isAndroid;
  static bool get isIOS => io.Platform.isIOS;
  static bool get isWindows => io.Platform.isWindows;
  static String get operatingSystem => io.Platform.operatingSystem;
}
