// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  bool autoUpdateNotify;
  bool autoSlideCharts;
  String downPath;
  String downQuality;
  String ytDownQuality;
  String strmQuality;
  String ytStrmQuality;
  String backupPath;
  bool autoBackup;
  String historyClearTime;
  bool autoGetCountry;
  bool lFMPicks;
  bool lastFMScrobble;
  bool autoSaveLyrics;
  bool autoPlay;
  String countryCode;
  List<bool> sourceEngineSwitches;
  Map chartMap;
  String locale;
  ThemeMode themeMode;
  // Advanced Settings
  String audioDecoderMode;
  bool hardwareOffloadEnabled;
  bool gaplessOffloadEnabled;
  bool tabletUiEnabled;
  bool persistentQueueEnabled;
  int maxSavedQueues;
  bool keepAliveEnabled;
  bool stopOnTaskClear;
  SettingsState({
    required this.autoUpdateNotify,
    required this.autoSlideCharts,
    required this.downPath,
    required this.downQuality,
    required this.ytDownQuality,
    required this.strmQuality,
    required this.ytStrmQuality,
    required this.backupPath,
    required this.autoBackup,
    required this.historyClearTime,
    required this.autoGetCountry,
    required this.countryCode,
    required this.autoSaveLyrics,
    required this.lFMPicks,
    required this.lastFMScrobble,
    required this.sourceEngineSwitches,
    required this.chartMap,
    required this.locale,
    required this.autoPlay,
    required this.themeMode,
    required this.audioDecoderMode,
    required this.hardwareOffloadEnabled,
    required this.gaplessOffloadEnabled,
    required this.tabletUiEnabled,
    required this.persistentQueueEnabled,
    required this.maxSavedQueues,
    required this.keepAliveEnabled,
    required this.stopOnTaskClear,
  });

  SettingsState copyWith({
    bool? autoUpdateNotify,
    bool? autoSlideCharts,
    String? downPath,
    String? downQuality,
    String? ytDownQuality,
    String? strmQuality,
    String? ytStrmQuality,
    String? backupPath,
    bool? autoBackup,
    String? historyClearTime,
    bool? autoGetCountry,
    String? countryCode,
    bool? lFMPicks,
    bool? lastFMScrobble,
    List<bool>? sourceEngineSwitches,
    Map? chartMap,
    String? locale,
    bool? autoSaveLyrics,
    bool? autoPlay,
    ThemeMode? themeMode,
    String? audioDecoderMode,
    bool? hardwareOffloadEnabled,
    bool? gaplessOffloadEnabled,
    bool? tabletUiEnabled,
    bool? persistentQueueEnabled,
    int? maxSavedQueues,
    bool? keepAliveEnabled,
    bool? stopOnTaskClear,
  }) {
    return SettingsState(
      autoUpdateNotify: autoUpdateNotify ?? this.autoUpdateNotify,
      autoSlideCharts: autoSlideCharts ?? this.autoSlideCharts,
      downPath: downPath ?? this.downPath,
      downQuality: downQuality ?? this.downQuality,
      ytDownQuality: ytDownQuality ?? this.ytDownQuality,
      strmQuality: strmQuality ?? this.strmQuality,
      ytStrmQuality: ytStrmQuality ?? this.ytStrmQuality,
      backupPath: backupPath ?? this.backupPath,
      autoBackup: autoBackup ?? this.autoBackup,
      historyClearTime: historyClearTime ?? this.historyClearTime,
      autoGetCountry: autoGetCountry ?? this.autoGetCountry,
      countryCode: countryCode ?? this.countryCode,
      lFMPicks: lFMPicks ?? this.lFMPicks,
      lastFMScrobble: lastFMScrobble ?? this.lastFMScrobble,
      sourceEngineSwitches:
          List.from(sourceEngineSwitches ?? this.sourceEngineSwitches),
      chartMap: Map.from(chartMap ?? this.chartMap),
      locale: locale ?? this.locale,
      autoSaveLyrics: autoSaveLyrics ?? this.autoSaveLyrics,
      autoPlay: autoPlay ?? this.autoPlay,
      themeMode: themeMode ?? this.themeMode,
      audioDecoderMode: audioDecoderMode ?? this.audioDecoderMode,
      hardwareOffloadEnabled:
          hardwareOffloadEnabled ?? this.hardwareOffloadEnabled,
      gaplessOffloadEnabled:
          gaplessOffloadEnabled ?? this.gaplessOffloadEnabled,
      tabletUiEnabled: tabletUiEnabled ?? this.tabletUiEnabled,
      persistentQueueEnabled:
          persistentQueueEnabled ?? this.persistentQueueEnabled,
      maxSavedQueues: maxSavedQueues ?? this.maxSavedQueues,
      keepAliveEnabled: keepAliveEnabled ?? this.keepAliveEnabled,
      stopOnTaskClear: stopOnTaskClear ?? this.stopOnTaskClear,
    );
  }

  @override
  List<Object?> get props => [
        autoUpdateNotify,
        autoSlideCharts,
        downPath,
        downQuality,
        ytDownQuality,
        strmQuality,
        ytStrmQuality,
        backupPath,
        autoBackup,
        historyClearTime,
        autoGetCountry,
        countryCode,
        sourceEngineSwitches,
        chartMap,
        locale,
        lFMPicks,
        lastFMScrobble,
        autoSaveLyrics,
        autoPlay,
        themeMode,
        audioDecoderMode,
        hardwareOffloadEnabled,
        gaplessOffloadEnabled,
        tabletUiEnabled,
        persistentQueueEnabled,
        maxSavedQueues,
        keepAliveEnabled,
        stopOnTaskClear,
      ];
}

class SettingsInitial extends SettingsState {
  SettingsInitial()
      : super(
          autoUpdateNotify: false,
          autoSlideCharts: true,
          downPath: "",
          downQuality: "320 kbps",
          ytDownQuality: "High",
          strmQuality: "96 kbps",
          ytStrmQuality: "Low",
          backupPath: "",
          autoBackup: true,
          historyClearTime: "30",
          autoGetCountry: true,
          countryCode: "IN",
          sourceEngineSwitches: SourceEngine.values.map((e) => true).toList(),
          chartMap: {},
          locale: 'en',
          lFMPicks: false,
          lastFMScrobble: true,
          autoSaveLyrics: false,
          autoPlay: true,
          themeMode: ThemeMode.system,
          // New advanced settings
          audioDecoderMode: "system",
          hardwareOffloadEnabled: false,
          gaplessOffloadEnabled: false,
          tabletUiEnabled: false,
          persistentQueueEnabled: false,
          maxSavedQueues: 19,
          keepAliveEnabled: false,
          stopOnTaskClear: false,
        );
}
