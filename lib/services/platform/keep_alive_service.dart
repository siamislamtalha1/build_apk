import 'dart:developer';
import 'dart:io';
import 'package:Bloomee/routes_and_consts/global_str_consts.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';

class KeepAliveService {
  static final KeepAliveService _instance = KeepAliveService._internal();
  factory KeepAliveService() => _instance;
  KeepAliveService._internal();

  /// Check if the user wants the service to remain alive in background/when paused
  Future<bool> shouldKeepAlive() async {
    return await BloomeeDBService.getSettingBool(
            GlobalStrConsts.keepAliveEnabled) ??
        false;
  }

  /// Platform specific start logic (mostly handled by audio_service automatically)
  Future<void> start() async {
    if (Platform.isAndroid) {
      log("KeepAliveService: Foreground service management is handled by AudioHandler",
          name: "PlatformService");
    }
  }
}
