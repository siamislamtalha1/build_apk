import 'dart:async';
import 'dart:isolate';
import 'dart:io' as io;
import 'package:Bloomee/blocs/downloader/cubit/downloader_cubit.dart';
import 'package:Bloomee/blocs/global_events/global_events_cubit.dart';
import 'package:Bloomee/blocs/internet_connectivity/cubit/connectivity_cubit.dart';
import 'package:Bloomee/blocs/lastdotfm/lastdotfm_cubit.dart';
import 'package:Bloomee/blocs/lyrics/lyrics_cubit.dart';
import 'package:Bloomee/blocs/mini_player/mini_player_bloc.dart';
import 'package:Bloomee/blocs/player_overlay/player_overlay_cubit.dart';
import 'package:Bloomee/blocs/search_suggestions/search_suggestion_bloc.dart';
import 'package:Bloomee/blocs/settings_cubit/cubit/settings_cubit.dart';
import 'package:Bloomee/blocs/timer/timer_bloc.dart';
import 'package:Bloomee/blocs/notification/notification_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:Bloomee/repository/Youtube/youtube_api.dart';
import 'package:Bloomee/screens/widgets/global_event_listener.dart';
import 'package:Bloomee/screens/widgets/shortcut_indicator_overlay.dart';
import 'package:Bloomee/screens/widgets/snackbar.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:Bloomee/services/keyboard_shortcuts_service.dart';
import 'package:Bloomee/services/shortcut_indicator_service.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:Bloomee/services/import_export_service.dart';
import 'package:Bloomee/utils/external_list_importer.dart';
import 'package:Bloomee/utils/ticker.dart';
import 'package:Bloomee/utils/url_checker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Bloomee/blocs/add_to_playlist/cubit/add_to_playlist_cubit.dart';
import 'package:Bloomee/blocs/library/cubit/library_items_cubit.dart';
import 'package:Bloomee/blocs/search/fetch_search_results.dart';
import 'package:Bloomee/routes_and_consts/routes.dart';
import 'package:Bloomee/screens/screen/library_views/cubit/current_playlist_cubit.dart';
import 'package:Bloomee/screens/screen/library_views/cubit/import_playlist_cubit.dart';
import 'package:Bloomee/services/db/cubit/bloomee_db_cubit.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_handler/share_handler.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'blocs/mediaPlayer/bloomee_player_cubit.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:Bloomee/services/discord_service.dart';
import 'package:Bloomee/services/firebase/firebase_service.dart';
import 'package:Bloomee/services/sync/sync_service.dart';
import 'package:Bloomee/blocs/auth/auth_cubit.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:Bloomee/l10n/app_localizations.dart';
import 'package:Bloomee/services/crash_reporter.dart';
import 'package:Bloomee/services/trace_logger.dart';

void processIncomingIntent(SharedMedia sharedMedia) {
  // Check if there's text content that might be a URL
  if (sharedMedia.content != null && isUrl(sharedMedia.content!)) {
    final urlType = getUrlType(sharedMedia.content!);
    switch (urlType) {
      case UrlType.spotifyTrack:
        ExternalMediaImporter.sfyMediaImporter(sharedMedia.content!).then((
          value,
        ) async {
          if (value != null) {
            await bloomeePlayerCubit.bloomeePlayer.addQueueItem(value);
          }
        });
        break;
      case UrlType.spotifyPlaylist:
        SnackbarService.showMessage("Import Spotify Playlist from library!");
        break;
      case UrlType.youtubePlaylist:
        SnackbarService.showMessage("Import Youtube Playlist from library!");
        break;
      case UrlType.spotifyAlbum:
        SnackbarService.showMessage("Import Spotify Album from library!");
        break;
      case UrlType.youtubeVideo:
        ExternalMediaImporter.ytMediaImporter(sharedMedia.content!).then((
          value,
        ) async {
          if (value != null) {
            await bloomeePlayerCubit.bloomeePlayer.updateQueue([
              value,
            ], doPlay: true);
          }
        });
        break;
      case UrlType.other:
        // Handle as file if it's a file URL
        if (sharedMedia.attachments != null &&
            sharedMedia.attachments!.isNotEmpty) {
          final attachment = sharedMedia.attachments!.first;
          SnackbarService.showMessage("Processing File...");
          importItems(attachment!.path);
        }
    }
  } else if (sharedMedia.attachments != null &&
      sharedMedia.attachments!.isNotEmpty) {
    // Handle attachments
    // todo: handle multiple attachments
  }
}

Future<void> importItems(String path) async {
  bool res = await ImportExportService.importMediaItem(path);
  if (res) {
    SnackbarService.showMessage("Media Item Imported");
  } else {
    res = await ImportExportService.importPlaylist(path);
    if (res) {
      SnackbarService.showMessage("Playlist Imported");
    } else {
      SnackbarService.showMessage("Invalid File Format");
    }
  }
}

Future<void> setHighRefreshRate() async {
  if (io.Platform.isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (e, st) {
      debugPrint('setHighRefreshRate failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }
}

late BloomeePlayerCubit bloomeePlayerCubit;
void setupPlayerCubit() {
  bloomeePlayerCubit = BloomeePlayerCubit();
}

RawReceivePort? _isolateErrorPort;

Future<void> initServices() async {
  String appDocPath = (await getApplicationDocumentsDirectory()).path;
  String appSuppPath = (await getApplicationSupportDirectory()).path;
  BloomeeDBService(appDocPath: appDocPath, appSuppPath: appSuppPath);
  YouTubeServices(appDocPath: appDocPath, appSuppPath: appSuppPath);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GestureBinding.instance.resamplingEnabled = true;

  CrashReporter.markStage('main:entered');
  CrashReporter.writeStartupProbe();
  CrashReporter.markStage('main:after_startup_probe');

  ErrorWidget.builder = (FlutterErrorDetails details) {
    CrashReporter.record(
      details.exception,
      details.stack,
      source: 'ErrorWidget.builder',
    );
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: SelectableText(
              CrashReporter.lastCrashText ?? details.toString(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  };

  CrashReporter.markStage('main:after_error_widget_builder');

  _isolateErrorPort = RawReceivePort((dynamic pair) {
    try {
      final list = pair as List<dynamic>;
      final error = list.isNotEmpty ? list[0] : 'Unknown isolate error';
      StackTrace? st;
      if (list.length > 1 && list[1] != null) {
        st = StackTrace.fromString(list[1].toString());
      }
      CrashReporter.record(error, st, source: 'Isolate.errorListener');
    } catch (e, st) {
      CrashReporter.record(e, st, source: 'Isolate.errorListener.parse');
    }
  });
  Isolate.current.addErrorListener(_isolateErrorPort!.sendPort);

  CrashReporter.markStage('main:after_isolate_error_listener');

  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
    CrashReporter.record(
      details.exception,
      details.stack,
      source: 'FlutterError.onError',
    );
  };

  CrashReporter.markStage('main:after_flutter_error_on_error');

  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    debugPrint('Uncaught platformDispatcher error: $error');
    debugPrintStack(stackTrace: stack);
    CrashReporter.record(error, stack, source: 'platformDispatcher.onError');
    return true;
  };

  CrashReporter.markStage('main:after_platform_dispatcher_on_error');

  runZonedGuarded(
    () async {
      try {
        CrashReporter.markStage('main:runZonedGuarded:entered');
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        CrashReporter.markStage('main:after_set_ui_mode');
        runApp(const _BootstrapApp());
        CrashReporter.markStage('main:after_runApp');
      } catch (e, st) {
        debugPrint('Fatal error during app bootstrap: $e');
        debugPrintStack(stackTrace: st);
        CrashReporter.record(e, st, source: 'main.bootstrap');
        runApp(CrashReportScreen(error: e.toString()));
      }
    },
    (error, stack) {
      debugPrint('Uncaught zoned error: $error');
      debugPrintStack(stackTrace: stack);
      CrashReporter.record(error, stack, source: 'runZonedGuarded');
      runApp(CrashReportScreen(error: error.toString()));
    },
  );
}

class _BootstrapData {
  final AuthCubit authCubit;
  final GlobalEventsCubit globalEventsCubit;
  const _BootstrapData({
    required this.authCubit,
    required this.globalEventsCubit,
  });
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  late final Future<_BootstrapData> _bootstrapFuture = _bootstrap();

  Future<_BootstrapData> _bootstrap() async {
    CrashReporter.markStage('_bootstrap:entered');

    if (io.Platform.isLinux) {
      try {
        CrashReporter.markStage('_bootstrap:before_just_audio_media_kit');
        JustAudioMediaKit.ensureInitialized(linux: true, windows: false);
        CrashReporter.markStage('_bootstrap:after_just_audio_media_kit');
      } catch (e, st) {
        debugPrint('JustAudioMediaKit init failed: $e');
        debugPrintStack(stackTrace: st);
      }
    }

    CrashReporter.markStage('_bootstrap:before_init_services');
    await TraceLogger.init();
    TraceLogger.log('Bootstrap: Init services started');
    try {
      await initServices();
    } catch (e, st) {
      CrashReporter.record(e, st, source: 'initServices');
    }
    TraceLogger.log('Bootstrap: Init services completed');
    CrashReporter.markStage('_bootstrap:after_init_services');

    CrashReporter.markStage('_bootstrap:before_firebase_init');
    final firebaseOk = await FirebaseService.initializeSafe();
    CrashReporter.markStage(
      '_bootstrap:after_firebase_init:${firebaseOk ? 'ok' : 'failed'}',
    );

    final authCubit = AuthCubit();
    final globalEventsCubit = GlobalEventsCubit();

    CrashReporter.markStage('_bootstrap:after_create_auth_global_events');

    if (firebaseOk) {
      try {
        CrashReporter.markStage('_bootstrap:before_sync_service_init');
        if (!io.Platform.isWindows) {
          SyncService().init();
        }
        CrashReporter.markStage('_bootstrap:after_sync_service_init');
      } catch (e, st) {
        debugPrint('SyncService init failed: $e');
        debugPrintStack(stackTrace: st);
      }
    } else {
      CrashReporter.record(
        FirebaseService.lastInitError ?? 'Firebase init failed',
        FirebaseService.lastInitStack,
        source: 'FirebaseService.initializeSafe',
      );
    }

    CrashReporter.markStage('_bootstrap:before_set_high_refresh_rate');
    await setHighRefreshRate();
    CrashReporter.markStage('_bootstrap:after_set_high_refresh_rate');

    CrashReporter.markStage('_bootstrap:before_setup_player_cubit');
    setupPlayerCubit();
    CrashReporter.markStage('_bootstrap:after_setup_player_cubit');

    TraceLogger.log('Bootstrap: Before Discord init');
    CrashReporter.markStage('_bootstrap:before_discord_init');
    if (!io.Platform.isWindows) {
      DiscordService.initialize();
    }
    CrashReporter.markStage('_bootstrap:after_discord_init');
    TraceLogger.log('Bootstrap: After Discord init');

    CrashReporter.markStage('_bootstrap:completed');
    TraceLogger.log('Bootstrap: Completed');
    return _BootstrapData(
      authCubit: authCubit,
      globalEventsCubit: globalEventsCubit,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootstrapData>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final err = snapshot.error ?? 'Unknown bootstrap error';
          CrashReporter.record(err, StackTrace.current, source: 'bootstrap');
          return CrashReportScreen(error: err.toString());
        }
        if (!snapshot.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Default_Theme.themeColor,
              body: Center(
                child: SizedBox(
                  height: 48,
                  width: 48,
                  child: CircularProgressIndicator(
                    color: Default_Theme.accentColor2,
                  ),
                ),
              ),
            ),
          );
        }

        final data = snapshot.data!;
        return MyApp(
          authCubit: data.authCubit,
          globalEventsCubit: data.globalEventsCubit,
        );
      },
    );
  }
}

class CrashReportScreen extends StatelessWidget {
  final String error;
  const CrashReportScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    final txt = CrashReporter.lastCrashText ?? error;
    final path = CrashReporter.lastCrashFilePath;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'App crashed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (path != null) ...[
                  SelectableText('Saved to: $path'),
                  const SizedBox(height: 8),
                ],
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(child: SelectableText(txt)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final AuthCubit authCubit;
  final GlobalEventsCubit globalEventsCubit;

  const MyApp({
    super.key,
    required this.authCubit,
    required this.globalEventsCubit,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Initialize the player
  // This widget is the root of your application.
  StreamSubscription? _intentSub;
  SharedMedia? sharedMedia;
  late final GoRouter _router;
  VoidCallback? _previousPlatformBrightnessHandler;

  @override
  void initState() {
    super.initState();
    TraceLogger.log('MyApp: initState started');
    _router = GlobalRoutes.getRouter(widget.authCubit);

    _previousPlatformBrightnessHandler =
        WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged;
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        () {
      _previousPlatformBrightnessHandler?.call();
      if (!mounted) return;
      setState(() {});
    };

    if (io.Platform.isAndroid) {
      initPlatformState().catchError((e, st) {
        debugPrint('initPlatformState failed: $e');
        debugPrintStack(stackTrace: st);
      });
    } else {
      TraceLogger.log('MyApp: initState completed (non-Android)');
    }

    // Check for Weekly Popup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWeeklyPopup();
    });
  }

  Future<void> _checkWeeklyPopup() async {
    // Logic:
    // If Guest -> Check Install Date.
    // If > 7 days since install AND > 7 days since last popup -> Show Popup.

    if (!widget.authCubit.isGuest && widget.authCubit.currentUser != null) {
      return; // Already logged in as user
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      const installDateKey = 'install_date';
      const lastPopupKey = 'weekly_login_popup_last_shown';

      String? installDateStr = prefs.getString(installDateKey);

      if (installDateStr == null) {
        // First run or data cleared
        await prefs.setString(installDateKey, now.toIso8601String());
        return;
      }

      final installDate = DateTime.parse(installDateStr);
      final daysSinceInstall = now.difference(installDate).inDays;

      if (daysSinceInstall < 7) return; // Not a week yet

      String? lastPopupStr = prefs.getString(lastPopupKey);
      DateTime lastPopupDate = DateTime.fromMillisecondsSinceEpoch(0);
      if (lastPopupStr != null) {
        lastPopupDate = DateTime.parse(lastPopupStr);
      }

      final daysSinceLastPopup = now.difference(lastPopupDate).inDays;

      if (daysSinceLastPopup >= 7) {
        // Show Popup
        await prefs.setString(lastPopupKey, now.toIso8601String());

        widget.globalEventsCubit.showAlertDialog(
          "Personalize Your Experience",
          "By logging in, we can personalize music to your taste and sync everything across multiple devices.",
        );
      }
    } catch (e) {
      debugPrint("Error checking weekly popup: $e");
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    try {
      final handler = ShareHandlerPlatform.instance;
      sharedMedia = await handler.getInitialSharedMedia();

      _intentSub = handler.sharedMediaStream.listen((SharedMedia media) {
        if (!mounted) return;
        setState(() {
          sharedMedia = media;
        });
        if (sharedMedia != null) {
          processIncomingIntent(sharedMedia!);
        }
      });
      if (!mounted) return;

      setState(() {
        // If there's initial shared media, process it
        if (sharedMedia != null) {
          processIncomingIntent(sharedMedia!);
        }
      });
    } catch (e, st) {
      debugPrint('initPlatformState exception: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    SyncService().dispose();
    bloomeePlayerCubit.close();
    // Do not close authCubit or globalEventsCubit if they are meant to persist or be closed elsewhere.

    if (io.Platform.isWindows || io.Platform.isLinux || io.Platform.isMacOS) {
      DiscordService.clearPresence();
    }

    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        _previousPlatformBrightnessHandler;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => bloomeePlayerCubit, lazy: false),
        BlocProvider(
          create: (context) => MiniPlayerBloc(playerCubit: bloomeePlayerCubit),
          lazy: true,
        ),
        BlocProvider(create: (context) => BloomeeDBCubit(), lazy: true),
        BlocProvider(create: (context) => SettingsCubit(), lazy: false),
        BlocProvider(create: (context) => NotificationCubit(), lazy: false),
        BlocProvider.value(value: widget.authCubit),
        BlocProvider.value(value: widget.globalEventsCubit),
        BlocProvider(
          create: (context) => TimerBloc(
            ticker: const Ticker(),
            bloomeePlayer: bloomeePlayerCubit,
          ),
        ),
        BlocProvider(create: (context) => ConnectivityCubit(), lazy: false),
        BlocProvider(
          create: (context) => CurrentPlaylistCubit(
            bloomeeDBCubit: context.read<BloomeeDBCubit>(),
          ),
          lazy: false,
        ),
        BlocProvider(
          create: (context) =>
              LibraryItemsCubit(bloomeeDBCubit: context.read<BloomeeDBCubit>()),
        ),
        BlocProvider(create: (context) => AddToPlaylistCubit(), lazy: false),
        BlocProvider(create: (context) => ImportPlaylistCubit()),
        BlocProvider(create: (context) => FetchSearchResultsCubit()),
        BlocProvider(create: (context) => SearchSuggestionBloc()),
        BlocProvider(create: (context) => LyricsCubit(bloomeePlayerCubit)),
        BlocProvider(
          create: (context) => LastdotfmCubit(playerCubit: bloomeePlayerCubit),
          lazy: false,
        ),
        BlocProvider(
          create: (context) => DownloaderCubit(
            connectivityCubit: context.read<ConnectivityCubit>(),
            libraryItemsCubit: context.read<LibraryItemsCubit>(),
          ),
          lazy: false,
        ),
        BlocProvider(create: (context) => PlayerOverlayCubit(), lazy: false),
        BlocProvider(
          create: (context) => ShortcutIndicatorCubit(),
          lazy: false,
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          final platformBrightness =
              WidgetsBinding.instance.platformDispatcher.platformBrightness;
          final brightness = settingsState.themeMode == ThemeMode.system
              ? platformBrightness
              : settingsState.themeMode == ThemeMode.dark
                  ? Brightness.dark
                  : Brightness.light;
          Default_Theme.setBrightness(brightness);
          return BlocBuilder<BloomeePlayerCubit, BloomeePlayerState>(
            builder: (context, state) {
              if (state is BloomeePlayerInitial) {
                return const Center(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(),
                  ),
                );
              } else {
                return KeyboardShortcutsHandler(
                  child: ShortcutIndicatorOverlay(
                    child: MaterialApp.router(
                      localizationsDelegates: const [
                        AppLocalizations.delegate,
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                      ],
                      supportedLocales: AppLocalizations.supportedLocales,
                      builder: (context, child) {
                        final brightness = Theme.of(context).brightness;
                        final isDark = brightness == Brightness.dark;
                        Default_Theme.setBrightness(brightness);
                        return AnnotatedRegion<SystemUiOverlayStyle>(
                          value: SystemUiOverlayStyle(
                            statusBarColor: Colors
                                .transparent, // Also make status bar transparent
                            statusBarIconBrightness:
                                isDark ? Brightness.light : Brightness.dark,
                            statusBarBrightness:
                                isDark ? Brightness.dark : Brightness.light,
                            systemNavigationBarColor: Colors
                                .transparent, // FIX: Transparent for edge-to-edge
                            systemNavigationBarIconBrightness:
                                isDark ? Brightness.light : Brightness.dark,
                          ),
                          child: ResponsiveBreakpoints.builder(
                            breakpoints: [
                              const Breakpoint(
                                start: 0,
                                end: 450,
                                name: MOBILE,
                              ),
                              const Breakpoint(
                                start: 451,
                                end: 800,
                                name: TABLET,
                              ),
                              const Breakpoint(
                                start: 801,
                                end: 1920,
                                name: DESKTOP,
                              ),
                              const Breakpoint(
                                start: 1921,
                                end: double.infinity,
                                name: '4K',
                              ),
                            ],
                            child: GlobalEventListener(
                              navigatorKey: GlobalRoutes.globalRouterKey,
                              child: child!,
                            ),
                          ),
                        );
                      },
                      scaffoldMessengerKey: SnackbarService.messengerKey,
                      routerConfig: _router,
                      // Theming connection
                      themeMode: settingsState.themeMode,
                      theme: Default_Theme().lightThemeData,
                      darkTheme: Default_Theme().defaultThemeData,
                      scrollBehavior: CustomScrollBehavior(),
                      debugShowCheckedModeBanner: false,
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}

class CustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        // etc.
      };
}
