// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  final bool autoUpdateNotify;
  final bool autoSlideCharts;
  final String downPath;
  final String downQuality;
  final String ytDownQuality;
  final String strmQuality;
  final String ytStrmQuality;
  final String backupPath;
  final bool autoBackup;
  final String historyClearTime;
  final bool autoGetCountry;
  final bool lFMPicks;
  final bool lastFMScrobble;
  final bool autoSaveLyrics;
  final bool autoPlay;
  final String countryCode;
  final List<bool> sourceEngineSwitches;
  final Map chartMap;
  final String locale;
  final ThemeMode themeMode;
  // Advanced Settings
  final String audioDecoderMode;
  final bool hardwareOffloadEnabled;
  final bool gaplessOffloadEnabled;
  final double playbackSpeed;
  final double playbackPitch;
  final bool skipSilenceEnabled;
  final bool equalizerEnabled;
  final bool normalizationEnabled;
  final int normalizationGainMb;
  final bool tabletUiEnabled;
  final bool persistentQueueEnabled;
  final int maxSavedQueues;
  final bool keepAliveEnabled;
  final bool stopOnTaskClear;
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
    required this.playbackSpeed,
    required this.playbackPitch,
    required this.skipSilenceEnabled,
    required this.equalizerEnabled,
    required this.normalizationEnabled,
    required this.normalizationGainMb,
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
    double? playbackSpeed,
    double? playbackPitch,
    bool? skipSilenceEnabled,
    bool? equalizerEnabled,
    bool? normalizationEnabled,
    int? normalizationGainMb,
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
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      playbackPitch: playbackPitch ?? this.playbackPitch,
      skipSilenceEnabled: skipSilenceEnabled ?? this.skipSilenceEnabled,
      equalizerEnabled: equalizerEnabled ?? this.equalizerEnabled,
      normalizationEnabled: normalizationEnabled ?? this.normalizationEnabled,
      normalizationGainMb: normalizationGainMb ?? this.normalizationGainMb,
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
        playbackSpeed,
        playbackPitch,
        skipSilenceEnabled,
        equalizerEnabled,
        normalizationEnabled,
        normalizationGainMb,
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
          playbackSpeed: 1.0,
          playbackPitch: 1.0,
          skipSilenceEnabled: false,
          equalizerEnabled: false,
          normalizationEnabled: false,
          normalizationGainMb: 0,
          tabletUiEnabled: false,
          persistentQueueEnabled: false,
          maxSavedQueues: 19,
          keepAliveEnabled: false,
          stopOnTaskClear: false,
        );
}
