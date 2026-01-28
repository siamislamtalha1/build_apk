import 'package:Bloomee/routes_and_consts/global_str_consts.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'dart:developer';
import 'dart:io';

class HardwareOffloadService {
  static final HardwareOffloadService _instance =
      HardwareOffloadService._internal();
  factory HardwareOffloadService() => _instance;
  HardwareOffloadService._internal();

  bool _isOffloadEnabled = false;
  bool _isGaplessOffloadEnabled = false;

  bool get isOffloadEnabled => _isOffloadEnabled;
  bool get isGaplessOffloadEnabled => _isGaplessOffloadEnabled;

  Future<void> init() async {
    _isOffloadEnabled = await BloomeeDBService.getSettingBool(
            GlobalStrConsts.hardwareOffloadEnabled) ??
        false;
    _isGaplessOffloadEnabled = await BloomeeDBService.getSettingBool(
            GlobalStrConsts.gaplessOffloadEnabled) ??
        false;

    // Auto-disable offload on unsupported platforms if needed, currently treating as preference
    if (!Platform.isAndroid && _isOffloadEnabled) {
      log("Hardware offload enabled but purely effective on Android usually",
          name: "HardwareOffloadService");
    }
  }

  Future<void> setOffloadEnabled(bool enabled) async {
    _isOffloadEnabled = enabled;
    await BloomeeDBService.putSettingBool(
        GlobalStrConsts.hardwareOffloadEnabled, enabled);
  }

  Future<void> setGaplessOffloadEnabled(bool enabled) async {
    _isGaplessOffloadEnabled = enabled;
    await BloomeeDBService.putSettingBool(
        GlobalStrConsts.gaplessOffloadEnabled, enabled);
  }
}
