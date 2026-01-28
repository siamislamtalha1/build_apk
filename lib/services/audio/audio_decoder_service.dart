import 'package:Bloomee/routes_and_consts/global_str_consts.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'dart:developer';

enum DecoderMode {
  system,
  ffmpeg,
  hybrid,
}

class AudioDecoderService {
  static final AudioDecoderService _instance = AudioDecoderService._internal();
  factory AudioDecoderService() => _instance;
  AudioDecoderService._internal();

  DecoderMode _currentMode = DecoderMode.system;

  DecoderMode get currentMode => _currentMode;

  Future<void> init() async {
    final modeStr = await BloomeeDBService.getSettingStr(
            GlobalStrConsts.audioDecoderMode) ??
        "system";
    _currentMode = _parseMode(modeStr);
    log("Audio Decoder initialized to: ${_currentMode.name}",
        name: "AudioDecoderService");
  }

  DecoderMode _parseMode(String mode) {
    switch (mode.toLowerCase()) {
      case "ffmpeg":
        return DecoderMode.ffmpeg;
      case "hybrid":
        return DecoderMode.hybrid;
      default:
        return DecoderMode.system;
    }
  }

  Future<void> setDecoderMode(String mode) async {
    _currentMode = _parseMode(mode);
    await BloomeeDBService.putSettingStr(
        GlobalStrConsts.audioDecoderMode, mode);
    log("Audio Decoder changed to: ${_currentMode.name}",
        name: "AudioDecoderService");
  }

  // Helper method to determine if we should try FFmpeg for a given source
  // This is a placeholder since we don't have the actual ffmpeg implementation yet
  bool shouldUseFFmpeg(String uri) {
    if (_currentMode == DecoderMode.system) return false;
    if (_currentMode == DecoderMode.ffmpeg) return true;

    // Hybrid: use FFmpeg for specific containers that might fail on system
    // This logic can be expanded
    if (uri.endsWith(".flac") ||
        uri.endsWith(".mkv") ||
        uri.endsWith(".opus")) {
      return true;
    }
    return false;
  }
}
