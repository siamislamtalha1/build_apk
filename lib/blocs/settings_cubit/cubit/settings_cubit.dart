import 'dart:convert';
import 'dart:developer';
import 'package:Bloomee/model/source_engines.dart';
import 'package:Bloomee/routes_and_consts/global_str_consts.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(SettingsInitial()) {
    initSettings();
    autoUpdate();
  }

// Initialize the settings from the database
  void initSettings() {
    BloomeeDBService.getSettingBool(GlobalStrConsts.autoUpdateNotify)
        .then((value) {
      emit(state.copyWith(autoUpdateNotify: value ?? false));
    });

    BloomeeDBService.getSettingBool(GlobalStrConsts.autoSlideCharts)
        .then((value) {
      emit(state.copyWith(autoSlideCharts: value ?? true));
    });

    BloomeeDBService.getSettingStr(GlobalStrConsts.downPathSetting)
        .then((value) async {
      String path;
      if (value != null) {
        path = value;
      } else {
        path = ((await getDownloadsDirectory()) ??
                (await getApplicationDocumentsDirectory()))
            .path;
        setDownPath(path);
        log("Download path set to: $path", name: 'SettingsCubit');
      }
      emit(state.copyWith(downPath: path));
    });

    BloomeeDBService.getSettingStr(GlobalStrConsts.downQuality,
            defaultValue: '320 kbps')
        .then((value) {
      emit(state.copyWith(downQuality: value ?? "320 kbps"));
    });

    BloomeeDBService.getSettingStr(GlobalStrConsts.ytDownQuality).then((value) {
      emit(state.copyWith(ytDownQuality: value ?? "High"));
    });

    BloomeeDBService.getSettingStr(
      GlobalStrConsts.strmQuality,
    ).then((value) {
      emit(state.copyWith(strmQuality: value ?? "96 kbps"));
    });

    BloomeeDBService.getSettingStr(GlobalStrConsts.ytStrmQuality).then((value) {
      if (value == "High" || value == "Low") {
        emit(state.copyWith(ytStrmQuality: value ?? "Low"));
      } else {
        BloomeeDBService.putSettingStr(GlobalStrConsts.ytStrmQuality, "Low");
        emit(state.copyWith(ytStrmQuality: "Low"));
      }
    });

    BloomeeDBService.getSettingStr(GlobalStrConsts.historyClearTime)
        .then((value) {
      emit(state.copyWith(historyClearTime: value ?? "30"));
    });

    BloomeeDBService.getSettingBool(GlobalStrConsts.lFMScrobbleSetting)
        .then((value) {
      emit(state.copyWith(lastFMScrobble: value ?? false));
    });

    BloomeeDBService.getSettingBool(
      GlobalStrConsts.autoPlay,
    ).then((value) {
      emit(state.copyWith(autoPlay: value ?? true));
    });

    BloomeeDBService.getSettingBool(GlobalStrConsts.lFMUIPicks).then((value) {
      emit(state.copyWith(lFMPicks: value ?? false));
    });

    BloomeeDBService.getSettingStr(GlobalStrConsts.backupPath)
        .then((value) async {
      final defaultBackUpDir = await BloomeeDBService.getDbBackupFilePath();

      await BloomeeDBService.putSettingStr(
          GlobalStrConsts.backupPath, defaultBackUpDir);
      emit(state.copyWith(backupPath: defaultBackUpDir));
    });

    BloomeeDBService.getSettingBool(GlobalStrConsts.autoBackup).then((value) {
      emit(state.copyWith(autoBackup: value ?? false));
    });

    BloomeeDBService.getSettingBool(GlobalStrConsts.autoGetCountry)
        .then((value) {
      emit(state.copyWith(autoGetCountry: value ?? false));
    });

    BloomeeDBService.getSettingStr(GlobalStrConsts.countryCode).then((value) {
      emit(state.copyWith(countryCode: value ?? "IN"));
    });

    BloomeeDBService.getSettingStr('app_locale').then((value) {
      emit(state.copyWith(locale: value ?? "en"));
    });

    BloomeeDBService.getSettingBool(GlobalStrConsts.autoSaveLyrics)
        .then((value) {
      emit(state.copyWith(autoSaveLyrics: value ?? false));
    });

    for (var eg in SourceEngine.values) {
      BloomeeDBService.getSettingBool(eg.value).then((value) {
        List<bool> switches = List.from(state.sourceEngineSwitches);
        switches[SourceEngine.values.indexOf(eg)] = value ?? true;
        emit(state.copyWith(sourceEngineSwitches: switches));
        log(switches.toString(), name: 'SettingsCubit');
      });
    }

    Map chartMap = Map.from(state.chartMap);
    BloomeeDBService.getSettingStr(GlobalStrConsts.chartShowMap).then((value) {
      if (value != null) {
        chartMap = jsonDecode(value);
      }
      emit(state.copyWith(chartMap: Map.from(chartMap)));
    });

    // Advanced Settings Init
    BloomeeDBService.getSettingStr(GlobalStrConsts.audioDecoderMode)
        .then((value) {
      emit(state.copyWith(audioDecoderMode: value ?? "system"));
    });
    BloomeeDBService.getSettingBool(GlobalStrConsts.hardwareOffloadEnabled)
        .then((value) {
      emit(state.copyWith(hardwareOffloadEnabled: value ?? false));
    });
    BloomeeDBService.getSettingBool(GlobalStrConsts.gaplessOffloadEnabled)
        .then((value) {
      emit(state.copyWith(gaplessOffloadEnabled: value ?? false));
    });
    BloomeeDBService.getSettingBool(GlobalStrConsts.tabletUiEnabled)
        .then((value) {
      emit(state.copyWith(tabletUiEnabled: value ?? false));
    });
    BloomeeDBService.getSettingBool(GlobalStrConsts.persistentQueueEnabled)
        .then((value) {
      emit(state.copyWith(persistentQueueEnabled: value ?? false));
    });
    BloomeeDBService.getSettingStr(GlobalStrConsts.maxSavedQueues)
        .then((value) {
      emit(state.copyWith(maxSavedQueues: int.tryParse(value ?? "19") ?? 19));
    });
    BloomeeDBService.getSettingBool(GlobalStrConsts.keepAliveEnabled)
        .then((value) {
      emit(state.copyWith(keepAliveEnabled: value ?? false));
    });
    BloomeeDBService.getSettingBool(GlobalStrConsts.stopOnTaskClear)
        .then((value) {
      emit(state.copyWith(stopOnTaskClear: value ?? false));
    });

    // Theme Mode Init
    BloomeeDBService.getSettingStr('theme_mode').then((value) {
      ThemeMode themeMode;
      switch (value) {
        case 'light':
          themeMode = ThemeMode.light;
          break;
        case 'dark':
          themeMode = ThemeMode.dark;
          break;
        case 'system':
          themeMode = ThemeMode.system;
          break;
        default:
          themeMode = ThemeMode.dark;
      }
      emit(state.copyWith(themeMode: themeMode));
    });
  }

  void setChartShow(String title, bool value) {
    Map chartMap = Map.from(state.chartMap);
    chartMap[title] = value;
    BloomeeDBService.putSettingStr(
        GlobalStrConsts.chartShowMap, jsonEncode(chartMap));
    emit(state.copyWith(chartMap: Map.from(chartMap)));
  }

  Future<void> setAutoPlay(bool value) async {
    await BloomeeDBService.putSettingBool(GlobalStrConsts.autoPlay, value);
    emit(state.copyWith(autoPlay: value));
  }

  void autoUpdate() {
    BloomeeDBService.getSettingBool(GlobalStrConsts.autoBackup).then((value) {
      if (value != null || value == true) {
        BloomeeDBService.createBackUp();
      }
    });
  }

  void setCountryCode(String value) {
    BloomeeDBService.putSettingStr(GlobalStrConsts.countryCode, value);
    emit(state.copyWith(countryCode: value));
  }

  void setLocale(String value) {
    BloomeeDBService.putSettingStr('app_locale', value);
    emit(state.copyWith(locale: value));
  }

  void setAutoSaveLyrics(bool value) {
    BloomeeDBService.putSettingBool(GlobalStrConsts.autoSaveLyrics, value);
    emit(state.copyWith(autoSaveLyrics: value));
  }

  void setThemeMode(ThemeMode value) {
    String themeModeStr;
    switch (value) {
      case ThemeMode.light:
        themeModeStr = 'light';
        break;
      case ThemeMode.dark:
        themeModeStr = 'dark';
        break;
      case ThemeMode.system:
        themeModeStr = 'system';
        break;
    }
    BloomeeDBService.putSettingStr('theme_mode', themeModeStr);

    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final brightness = value == ThemeMode.system
        ? platformBrightness
        : value == ThemeMode.dark
            ? Brightness.dark
            : Brightness.light;
    Default_Theme.setBrightness(brightness);

    emit(state.copyWith(themeMode: value));
  }

  void setLastFMScrobble(bool value) {
    BloomeeDBService.putSettingBool(GlobalStrConsts.lFMScrobbleSetting, value);
    emit(state.copyWith(lastFMScrobble: value));
  }

  void setLastFMExpore(bool value) {
    BloomeeDBService.putSettingBool(GlobalStrConsts.lFMUIPicks, value);
    emit(state.copyWith(lFMPicks: value));
  }

  void setAutoGetCountry(bool value) {
    BloomeeDBService.putSettingBool(GlobalStrConsts.autoGetCountry, value);
    emit(state.copyWith(autoGetCountry: value));
  }

  void setAutoUpdateNotify(bool value) {
    BloomeeDBService.putSettingBool(GlobalStrConsts.autoUpdateNotify, value);
    emit(state.copyWith(autoUpdateNotify: value));
  }

  void setAutoSlideCharts(bool value) {
    BloomeeDBService.putSettingBool(GlobalStrConsts.autoSlideCharts, value);
    emit(state.copyWith(autoSlideCharts: value));
  }

  void setDownPath(String value) {
    BloomeeDBService.putSettingStr(GlobalStrConsts.downPathSetting, value);
    emit(state.copyWith(downPath: value));
  }

  void setDownQuality(String value) {
    BloomeeDBService.putSettingStr(GlobalStrConsts.downQuality, value);
    emit(state.copyWith(downQuality: value));
  }

  void setYtDownQuality(String value) {
    BloomeeDBService.putSettingStr(GlobalStrConsts.ytDownQuality, value);
    emit(state.copyWith(ytDownQuality: value));
  }

  void setStrmQuality(String value) {
    BloomeeDBService.putSettingStr(GlobalStrConsts.strmQuality, value);
    emit(state.copyWith(strmQuality: value));
  }

  void setYtStrmQuality(String value) {
    BloomeeDBService.putSettingStr(GlobalStrConsts.ytStrmQuality, value);
    emit(state.copyWith(ytStrmQuality: value));
  }

  void setBackupPath(String value) {
    BloomeeDBService.putSettingStr(GlobalStrConsts.backupPath, value);
    emit(state.copyWith(backupPath: value));
  }

  void setAutoBackup(bool value) {
    BloomeeDBService.putSettingBool(GlobalStrConsts.autoBackup, value);
    emit(state.copyWith(autoBackup: value));
  }

  void setHistoryClearTime(String value) {
    BloomeeDBService.putSettingStr(GlobalStrConsts.historyClearTime, value);
    emit(state.copyWith(historyClearTime: value));
  }

  void setSourceEngineSwitches(int index, bool value) {
    List<bool> switches = List.from(state.sourceEngineSwitches);
    switches[index] = value;
    BloomeeDBService.putSettingBool(SourceEngine.values[index].value, value);
    emit(state.copyWith(sourceEngineSwitches: List.from(switches)));
  }

  Future<void> resetDownPath() async {
    String path;
    path = ((await getDownloadsDirectory()) ??
            (await getApplicationDocumentsDirectory()))
        .path;

    setDownPath(path);
    log("Download path reset to: $path", name: 'SettingsCubit');
  }

  // Setters for Advanced Settings
  void setAudioDecoderMode(String value) {
    BloomeeDBService.putSettingStr(GlobalStrConsts.audioDecoderMode, value);
    emit(state.copyWith(audioDecoderMode: value));
  }

  void setHardwareOffloadEnabled(bool value) {
    BloomeeDBService.putSettingBool(
        GlobalStrConsts.hardwareOffloadEnabled, value);
    emit(state.copyWith(hardwareOffloadEnabled: value));
  }

  void setGaplessOffloadEnabled(bool value) {
    BloomeeDBService.putSettingBool(
        GlobalStrConsts.gaplessOffloadEnabled, value);
    emit(state.copyWith(gaplessOffloadEnabled: value));
  }

  void setTabletUiEnabled(bool value) {
    BloomeeDBService.putSettingBool(GlobalStrConsts.tabletUiEnabled, value);
    emit(state.copyWith(tabletUiEnabled: value));
  }

  void setPersistentQueueEnabled(bool value) {
    BloomeeDBService.putSettingBool(
        GlobalStrConsts.persistentQueueEnabled, value);
    emit(state.copyWith(persistentQueueEnabled: value));
  }

  void setMaxSavedQueues(int value) {
    BloomeeDBService.putSettingStr(
        GlobalStrConsts.maxSavedQueues, value.toString());
    emit(state.copyWith(maxSavedQueues: value));
  }

  void setKeepAliveEnabled(bool value) {
    BloomeeDBService.putSettingBool(GlobalStrConsts.keepAliveEnabled, value);
    emit(state.copyWith(keepAliveEnabled: value));
  }

  void setStopOnTaskClear(bool value) {
    BloomeeDBService.putSettingBool(GlobalStrConsts.stopOnTaskClear, value);
    emit(state.copyWith(stopOnTaskClear: value));
  }
}
