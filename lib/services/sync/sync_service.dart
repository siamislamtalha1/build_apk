import 'dart:async';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:Bloomee/services/db/GlobalDB.dart';
import 'package:Bloomee/services/firebase/auth_service.dart';
import 'package:Bloomee/services/firebase/firestore_service.dart';
import 'package:Bloomee/services/crash_reporter.dart';
import 'package:isar_community/isar.dart';
import 'package:rxdart/rxdart.dart';

enum SyncStatus { idle, syncing, synced, error }

class SyncDetails {
  final SyncStatus status;
  final bool initialSyncInProgress;
  final bool syncingLikedSongs;
  final bool syncingPlaylists;
  final bool syncingHistory;
  final bool syncingSearchHistory;
  final bool syncingPreferences;
  final bool syncingStatistics;

  final int likedSongsCount;
  final int playlistsCount;
  final int playlistItemsCount;
  final int historyCount;
  final int searchHistoryCount;
  final int settingsBoolCount;
  final int settingsStrCount;
  final int statisticsCount;

  final DateTime? lastSuccessfulSyncAt;

  const SyncDetails({
    required this.status,
    required this.initialSyncInProgress,
    required this.syncingLikedSongs,
    required this.syncingPlaylists,
    required this.syncingHistory,
    required this.syncingSearchHistory,
    required this.syncingPreferences,
    required this.syncingStatistics,
    required this.likedSongsCount,
    required this.playlistsCount,
    required this.playlistItemsCount,
    required this.historyCount,
    required this.searchHistoryCount,
    required this.settingsBoolCount,
    required this.settingsStrCount,
    required this.statisticsCount,
    required this.lastSuccessfulSyncAt,
  });

  SyncDetails copyWith({
    SyncStatus? status,
    bool? initialSyncInProgress,
    bool? syncingLikedSongs,
    bool? syncingPlaylists,
    bool? syncingHistory,
    bool? syncingSearchHistory,
    bool? syncingPreferences,
    bool? syncingStatistics,
    int? likedSongsCount,
    int? playlistsCount,
    int? playlistItemsCount,
    int? historyCount,
    int? searchHistoryCount,
    int? settingsBoolCount,
    int? settingsStrCount,
    int? statisticsCount,
    DateTime? lastSuccessfulSyncAt,
  }) {
    return SyncDetails(
      status: status ?? this.status,
      initialSyncInProgress:
          initialSyncInProgress ?? this.initialSyncInProgress,
      syncingLikedSongs: syncingLikedSongs ?? this.syncingLikedSongs,
      syncingPlaylists: syncingPlaylists ?? this.syncingPlaylists,
      syncingHistory: syncingHistory ?? this.syncingHistory,
      syncingSearchHistory: syncingSearchHistory ?? this.syncingSearchHistory,
      syncingPreferences: syncingPreferences ?? this.syncingPreferences,
      syncingStatistics: syncingStatistics ?? this.syncingStatistics,
      likedSongsCount: likedSongsCount ?? this.likedSongsCount,
      playlistsCount: playlistsCount ?? this.playlistsCount,
      playlistItemsCount: playlistItemsCount ?? this.playlistItemsCount,
      historyCount: historyCount ?? this.historyCount,
      searchHistoryCount: searchHistoryCount ?? this.searchHistoryCount,
      settingsBoolCount: settingsBoolCount ?? this.settingsBoolCount,
      settingsStrCount: settingsStrCount ?? this.settingsStrCount,
      statisticsCount: statisticsCount ?? this.statisticsCount,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
    );
  }
}

/// Service to handle synchronization between local Isar DB and Firestore
class SyncService {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription? _authSubscription;
  StreamSubscription? _likedSongsSubscription;
  StreamSubscription? _playlistsSubscription;
  StreamSubscription? _searchHistorySubscription;
  StreamSubscription? _recentlyPlayedSubscription;
  StreamSubscription? _settingsBoolSubscription;
  StreamSubscription? _settingsStrSubscription;
  StreamSubscription? _preferencesSubscription;
  StreamSubscription? _statisticsSubscription;
  StreamSubscription? _localStatisticsSubscription;
  StreamSubscription? _cloudPlaylistsSubscription;
  StreamSubscription? _cloudHistorySubscription;
  StreamSubscription? _cloudSearchHistorySubscription;
  StreamSubscription? _savedCollectionsSubscription;
  StreamSubscription? _queuesSubscription;
  StreamSubscription? _downloadsSubscription;
  StreamSubscription? _lyricsSubscription;
  StreamSubscription? _localSavedCollectionsSubscription;
  StreamSubscription? _localQueuesSubscription;
  StreamSubscription? _localDownloadsSubscription;
  StreamSubscription? _localLyricsSubscription;
  Timer? _periodicBackupTimer;

  bool _suppressLocalPlaylistPush = false;
  bool _suppressLocalHistoryPush = false;
  bool _suppressLocalLikedPush = false;
  bool _suppressLocalPrefsPush = false;
  bool _suppressLocalStatsPush = false;
  bool _suppressLocalSearchPush = false;
  bool _suppressLocalSavedCollectionsPush = false;
  bool _suppressLocalQueuesPush = false;
  bool _suppressLocalDownloadsPush = false;
  bool _suppressLocalLyricsPush = false;

  bool _initialized = false;
  String? _activeUserId;
  Completer<void>? _startSyncCompleter;
  Timer? _localDebounce;

  Future<void> _cloudChangesQueue = Future<void>.value();

  bool _syncingPlaylists = false;
  bool _syncingPrefs = false;
  bool _syncingHistory = false;
  bool _syncingLikedSongs = false;
  bool _syncingStatistics = false;
  bool _syncingSearchHistory = false;
  bool _syncingSavedCollections = false;

  bool _syncingQueues = false;
  bool _syncingDownloads = false;
  bool _syncingLyrics = false;

  bool _initialSyncCompleted = false;

  // Stream controller for sync status
  final BehaviorSubject<SyncStatus> _syncStatusController =
      BehaviorSubject<SyncStatus>.seeded(SyncStatus.idle);

  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  final BehaviorSubject<SyncDetails> _syncDetailsController =
      BehaviorSubject<SyncDetails>.seeded(
    const SyncDetails(
      status: SyncStatus.idle,
      initialSyncInProgress: false,
      syncingLikedSongs: false,
      syncingPlaylists: false,
      syncingHistory: false,
      syncingSearchHistory: false,
      syncingPreferences: false,
      syncingStatistics: false,
      likedSongsCount: 0,
      playlistsCount: 0,
      playlistItemsCount: 0,
      historyCount: 0,
      searchHistoryCount: 0,
      settingsBoolCount: 0,
      settingsStrCount: 0,
      statisticsCount: 0,
      lastSuccessfulSyncAt: null,
    ),
  );

  Stream<SyncDetails> get syncDetails => _syncDetailsController.stream;

  void _safeAddStatus(SyncStatus status) {
    if (!_syncStatusController.isClosed) {
      _syncStatusController.add(status);
    }
  }

  void _safeAddDetails(SyncDetails details) {
    if (!_syncDetailsController.isClosed) {
      _syncDetailsController.add(details);
    }
  }

  Future<void> _enqueueCloudChange(
    String source,
    String userId,
    Future<void> Function() task,
  ) {
    _cloudChangesQueue = _cloudChangesQueue.then((_) async {
      if (_activeUserId != userId) return;
      await task();
    }).catchError((Object e, StackTrace st) {
      CrashReporter.record(e, st, source: source);
    });
    return _cloudChangesQueue;
  }

  // Singleton instance
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  /// Initialize sync service
  void init() {
    if (_initialized) return;
    _initialized = true;
    _authSubscription = _authService.authStateChanges.listen(
      (user) {
        if (user != null && !user.isAnonymous) {
          _startSync(user.uid);
        } else {
          _stopSync();
        }
      },
      onError: (Object e, StackTrace st) {
        CrashReporter.record(e, st, source: 'SyncService.authStateChanges');
        _stopSync();
        _safeAddStatus(SyncStatus.error);
      },
    );
  }

  void dispose() {
    _authSubscription?.cancel();
    _stopSync();
    _syncStatusController.close();
    _syncDetailsController.close();
    _initialized = false;
  }

  /// Start sync for a user
  void _startSync(String userId) async {
    print('🔄 Starting sync for user: $userId');
    if (_activeUserId == userId &&
        (_startSyncCompleter != null || _initialSyncCompleted)) {
      return;
    }

    _stopSync();
    _activeUserId = userId;

    _startSyncCompleter ??= Completer<void>();
    _safeAddStatus(SyncStatus.syncing);
    _safeAddDetails(
      _syncDetailsController.value.copyWith(
        status: SyncStatus.syncing,
        initialSyncInProgress: true,
      ),
    );

    // 1. Initial Pull from Cloud (pessimistic strategy: cloud wins if conflict/empty)
    try {
      // Add a small delay to allow UI to settle and prevent navigation/auth race conditions
      await Future.delayed(const Duration(seconds: 2));
      if (_activeUserId != userId) return; // Check if still active after delay

      await _performInitialSync(userId);
    } catch (e) {
      print('❌ Initial sync failed: $e');
      _safeAddStatus(SyncStatus.error);
    }

    // 2. Listen to Local Changes -> Push to Cloud
    _watchLocalChanges(userId);

    // 3. Listen to Cloud Changes -> Update Local (Realtime)
    _watchCloudChanges(userId);

    _periodicBackupTimer?.cancel();
    _periodicBackupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) {
        if (_activeUserId != userId) return;
        _runFullBackup(userId);
      },
    );

    _startSyncCompleter?.complete();
    _startSyncCompleter = null;
  }

  void _stopSync() {
    print('⏹️ Stopping sync');
    _localDebounce?.cancel();
    _periodicBackupTimer?.cancel();
    _likedSongsSubscription?.cancel();
    _playlistsSubscription?.cancel();
    _searchHistorySubscription?.cancel();
    _recentlyPlayedSubscription?.cancel();
    _settingsBoolSubscription?.cancel();
    _settingsStrSubscription?.cancel();
    _preferencesSubscription?.cancel();
    _statisticsSubscription?.cancel();
    _localStatisticsSubscription?.cancel();
    _cloudPlaylistsSubscription?.cancel();
    _cloudHistorySubscription?.cancel();
    _cloudSearchHistorySubscription?.cancel();
    _savedCollectionsSubscription?.cancel();
    _queuesSubscription?.cancel();
    _downloadsSubscription?.cancel();
    _lyricsSubscription?.cancel();
    _localSavedCollectionsSubscription?.cancel();
    _localQueuesSubscription?.cancel();
    _localDownloadsSubscription?.cancel();
    _localLyricsSubscription?.cancel();

    _suppressLocalPlaylistPush = false;
    _suppressLocalHistoryPush = false;
    _suppressLocalLikedPush = false;
    _suppressLocalPrefsPush = false;
    _suppressLocalStatsPush = false;
    _suppressLocalSearchPush = false;
    _suppressLocalSavedCollectionsPush = false;
    _suppressLocalQueuesPush = false;
    _suppressLocalDownloadsPush = false;
    _suppressLocalLyricsPush = false;

    _activeUserId = null;
    _initialSyncCompleted = false;
    _safeAddStatus(SyncStatus.idle);
    _safeAddDetails(
      _syncDetailsController.value.copyWith(
        status: SyncStatus.idle,
        initialSyncInProgress: false,
        syncingLikedSongs: false,
        syncingPlaylists: false,
        syncingHistory: false,
        syncingSearchHistory: false,
        syncingPreferences: false,
        syncingStatistics: false,
      ),
    );
  }

  Future<void> _performInitialSync(String userId) async {
    print('⬇️ Performing initial sync from cloud...');
    // 1. Sync Liked Songs
    _safeAddDetails(
      _syncDetailsController.value.copyWith(syncingLikedSongs: true),
    );
    final cloudLiked = await _firestoreService.getLikedSongsFromCloud(userId);
    if (cloudLiked.isNotEmpty) {
      _suppressLocalLikedPush = true;
      try {
        await BloomeeDBService.createPlaylist(BloomeeDBService.likedPlaylist);
        for (var item in cloudLiked) {
          try {
            final mediaItem = MediaItemDB.fromMap(item);
            await BloomeeDBService.addMediaItem(
                mediaItem, BloomeeDBService.likedPlaylist);
          } catch (e) {
            print('Error syncing liked item: $e');
          }
        }
      } finally {
        _suppressLocalLikedPush = false;
      }
    }
    _safeAddDetails(
      _syncDetailsController.value.copyWith(
        syncingLikedSongs: false,
        likedSongsCount: cloudLiked.length,
      ),
    );

    // 2. Sync History (Recently Played)
    _safeAddDetails(
      _syncDetailsController.value.copyWith(syncingHistory: true),
    );
    final cloudHistory = await _firestoreService.getHistoryFromCloud(userId);
    if (cloudHistory.isNotEmpty) {
      await BloomeeDBService.createPlaylist(
          BloomeeDBService.recentlyPlayedPlaylist);
      for (var item in cloudHistory) {
        try {
          final mediaItem = MediaItemDB.fromMap(item);
          await BloomeeDBService.putRecentlyPlayed(mediaItem);
        } catch (e) {
          print('Error syncing history item: $e');
        }
      }
    }
    _safeAddDetails(
      _syncDetailsController.value.copyWith(
        syncingHistory: false,
        historyCount: cloudHistory.length,
      ),
    );

    // 3. Sync Preferences/Settings
    _safeAddDetails(
      _syncDetailsController.value.copyWith(syncingPreferences: true),
    );
    final prefs = await _firestoreService.getUserPreferences(userId);
    if (prefs != null) {
      _suppressLocalPrefsPush = true;
      Map<String, dynamic>? b;
      Map<String, dynamic>? s;
      try {
        b = prefs['bool'] as Map<String, dynamic>?;
        if (b != null) {
          for (final entry in b.entries) {
            final v = entry.value;
            if (v is bool) {
              await BloomeeDBService.putSettingBool(entry.key, v);
            }
          }
        }
        s = prefs['str'] as Map<String, dynamic>?;
        if (s != null) {
          for (final entry in s.entries) {
            final v = entry.value;
            if (v is String) {
              await BloomeeDBService.putSettingStr(entry.key, v);
            }
          }
        }
        _safeAddDetails(
          _syncDetailsController.value.copyWith(
            settingsBoolCount: (b?.length ?? 0),
            settingsStrCount: (s?.length ?? 0),
          ),
        );
      } finally {
        _suppressLocalPrefsPush = false;
      }
    }
    _safeAddDetails(
      _syncDetailsController.value.copyWith(syncingPreferences: false),
    );

    // 4. Sync Playlists (including items)
    _safeAddDetails(
      _syncDetailsController.value.copyWith(syncingPlaylists: true),
    );
    final cloudPlaylists =
        await _firestoreService.getPlaylistsFromCloud(userId);
    if (cloudPlaylists.isNotEmpty) {
      _suppressLocalPlaylistPush = true;
      var totalItems = 0;
      try {
        for (final pl in cloudPlaylists) {
          final name = (pl['playlistName'] as String?) ?? '';
          if (name.isEmpty) continue;
          final items =
              await _firestoreService.getPlaylistItemsFromCloud(userId, name);
          totalItems += items.length;
          if (items.isEmpty) {
            await BloomeeDBService.createPlaylist(name);
            continue;
          }
          await BloomeeDBService.createPlaylist(
            name,
            artURL: pl['artURL'] as String?,
            description: pl['description'] as String?,
            permaURL: pl['permaURL'] as String?,
            source: pl['source'] as String?,
            artists: pl['artists'] as String?,
            isAlbum: (pl['isAlbum'] as bool?) ?? false,
          );

          final order = (pl['mediaOrder'] as List?)
                  ?.whereType<String>()
                  .toList(growable: false) ??
              const <String>[];

          final idsInOrder = <int>[];
          final mapById = <String, Map<String, dynamic>>{
            for (final it in items)
              if ((it['mediaID'] ?? it['mediaId'] ?? it['id']) != null)
                (it['mediaID'] ?? it['mediaId'] ?? it['id']).toString(): it,
          };

          final orderedKeys = order.isNotEmpty ? order : mapById.keys.toList();
          for (final mediaId in orderedKeys) {
            final m = mapById[mediaId];
            if (m == null) continue;
            try {
              final dbItem = MediaItemDB.fromMap(m);
              final id = await BloomeeDBService.addMediaItem(dbItem, name);
              if (id != null) idsInOrder.add(id);
            } catch (e) {
              print('Error syncing cloud playlist item to local: $e');
            }
          }
          if (idsInOrder.isNotEmpty) {
            await BloomeeDBService.updatePltItemsRankByName(name, idsInOrder);
          }
        }
      } finally {
        _suppressLocalPlaylistPush = false;
      }
      _safeAddDetails(
        _syncDetailsController.value.copyWith(
          playlistsCount: cloudPlaylists.length,
          playlistItemsCount: totalItems,
        ),
      );
    }
    _safeAddDetails(
      _syncDetailsController.value.copyWith(syncingPlaylists: false),
    );

    // 5. Sync Play Statistics (played)
    _safeAddDetails(
      _syncDetailsController.value.copyWith(syncingStatistics: true),
    );
    final cloudStats = await _firestoreService.getStatisticsFromCloud(userId);
    if (cloudStats.isNotEmpty) {
      _suppressLocalStatsPush = true;
      try {
        final isar = await BloomeeDBService.db;
        await isar.writeTxn(() async {
          for (final stat in cloudStats) {
            try {
              final mediaId = (stat['mediaId'] ?? stat['mediaID'] ?? stat['id'])
                  ?.toString();
              if (mediaId == null || mediaId.isEmpty) continue;
              final playCount = (stat['playCount'] as num?)?.toInt() ?? 0;
              final lastPlayedMs = (stat['lastPlayed'] as num?)?.toInt();
              final lastPlayed = lastPlayedMs != null
                  ? DateTime.fromMillisecondsSinceEpoch(lastPlayedMs)
                  : DateTime.now();
              final ts = (stat['playTimestamps'] as List?)
                      ?.whereType<num>()
                      .map(
                          (e) => DateTime.fromMillisecondsSinceEpoch(e.toInt()))
                      .toList() ??
                  <DateTime>[];

              await isar.playStatisticsDBs.put(
                PlayStatisticsDB(
                  mediaId: mediaId,
                  title: (stat['title'] ?? '').toString(),
                  artist: (stat['artist'] ?? '').toString(),
                  album: (stat['album'] ?? '').toString(),
                  playCount: playCount,
                  lastPlayed: lastPlayed,
                  playTimestamps: ts,
                ),
              );
            } catch (e) {
              print('Error syncing statistics from cloud: $e');
            }
          }
        });
      } finally {
        _suppressLocalStatsPush = false;
      }
    }
    _safeAddDetails(
      _syncDetailsController.value.copyWith(
        syncingStatistics: false,
        statisticsCount: cloudStats.length,
      ),
    );

    // 6. Sync Search History
    _safeAddDetails(
      _syncDetailsController.value.copyWith(syncingSearchHistory: true),
    );
    final cloudSearch =
        await _firestoreService.getSearchHistoryFromCloud(userId);
    if (cloudSearch.isNotEmpty) {
      _suppressLocalSearchPush = true;
      try {
        final isar = await BloomeeDBService.db;
        await isar.writeTxn(() async {
          for (final item in cloudSearch) {
            try {
              final h = SearchHistoryDB.fromMap(item);
              await isar.searchHistoryDBs.put(h);
            } catch (e) {
              print('Error syncing search history item: $e');
            }
          }
        });
      } finally {
        _suppressLocalSearchPush = false;
      }
    }

    _safeAddStatus(SyncStatus.synced);
    _initialSyncCompleted = true;
    _safeAddDetails(
      _syncDetailsController.value.copyWith(
        status: SyncStatus.synced,
        initialSyncInProgress: false,
        syncingSearchHistory: false,
        lastSuccessfulSyncAt: DateTime.now(),
      ),
    );
    print('✅ Initial sync completed');

    // 7. Sync Saved Collections
    final cloudCollections =
        await _firestoreService.getSavedCollectionsFromCloud(userId);
    if (cloudCollections.isNotEmpty) {
      _suppressLocalSavedCollectionsPush = true;
      try {
        final isar = await BloomeeDBService.db;
        await isar.writeTxn(() async {
          for (final item in cloudCollections) {
            try {
              await isar.savedCollectionsDBs
                  .put(SavedCollectionsDB.fromMap(item));
            } catch (e) {
              print('Error syncing saved collection item: $e');
            }
          }
        });
      } catch (e) {
        print('Error syncing saved collections from cloud: $e');
      } finally {
        _suppressLocalSavedCollectionsPush = false;
      }
    }

    // 8. Sync Queues
    final cloudQueues = await _firestoreService.getQueuesFromCloud(userId);
    if (cloudQueues.isNotEmpty) {
      _suppressLocalQueuesPush = true;
      try {
        final isar = await BloomeeDBService.db;
        await isar.writeTxn(() async {
          for (final q in cloudQueues) {
            try {
              final name = (q['queueName'] ?? '').toString();
              if (name.isEmpty) continue;
              final savedAtMs = (q['savedAt'] as num?)?.toInt();
              final savedAt = savedAtMs != null
                  ? DateTime.fromMillisecondsSinceEpoch(savedAtMs)
                  : DateTime.now();
              final mediaItemsJson = (q['mediaItemsJson'] as List?)
                      ?.whereType<String>()
                      .toList() ??
                  <String>[];
              final currentIndex = (q['currentIndex'] as num?)?.toInt() ?? 0;
              final positionMs = (q['positionMs'] as num?)?.toInt() ?? 0;
              await isar.savedQueueDBs.put(
                SavedQueueDB(
                  queueName: name,
                  savedAt: savedAt,
                  mediaItemsJson: mediaItemsJson,
                  currentIndex: currentIndex,
                  positionMs: positionMs,
                ),
              );
            } catch (e) {
              print('Error syncing queue from cloud: $e');
            }
          }
        });
      } catch (e) {
        print('Error syncing queues from cloud: $e');
      } finally {
        _suppressLocalQueuesPush = false;
      }
    }

    // 9. Sync Downloads (Backup)
    final cloudDownloads =
        await _firestoreService.getDownloadsFromCloud(userId);
    if (cloudDownloads.isNotEmpty) {
      try {
        final List<DownloadDB> downloads = [];
        for (final item in cloudDownloads) {
          try {
            downloads.add(DownloadDB.fromMap(item));
          } catch (e) {
            print('Error parsing download item: $e');
          }
        }
        await BloomeeDBService.saveDownloadsBatch(downloads);
      } catch (e) {
        print('Error syncing downloads from cloud: $e');
      }
    }

    // 10. Sync Lyrics (Backup)
    final cloudLyrics = await _firestoreService.getLyricsFromCloud(userId);
    if (cloudLyrics.isNotEmpty) {
      try {
        final List<LyricsDB> lyrics = [];
        for (final item in cloudLyrics) {
          try {
            lyrics.add(LyricsDB.fromMap(item));
          } catch (e) {
            print('Error parsing lyrics item: $e');
          }
        }
        await BloomeeDBService.saveLyricsBatch(lyrics);
      } catch (e) {
        print('Error syncing lyrics from cloud: $e');
      }
    }
  }

  Future<void> _runFullBackup(String userId) async {
    if (_activeUserId != userId) return;
    await _syncPreferencesToCloud(userId);
    await _syncLikedSongsToCloud(userId);
    await _syncHistoryToCloud(userId);
    await _syncSearchHistoryToCloud(userId);
    await _syncStatisticsToCloud(userId);
    await _syncPlaylistsToCloud(userId);
    await _syncSavedCollectionsToCloud(userId);
    await _syncQueuesToCloud(userId);
    await _syncDownloadsToCloud(userId);
    await _syncLyricsToCloud(userId);
  }

  void _watchCloudChanges(String userId) {
    _likedSongsSubscription = _firestoreService.watchLikedSongs(userId).listen(
      (cloudSongs) {
        if (cloudSongs.isEmpty) return;
        _enqueueCloudChange(
          'SyncService.watchLikedSongs',
          userId,
          () async {
            print('☁️ Cloud liked songs changed: ${cloudSongs.length} items');
            _suppressLocalLikedPush = true;
            try {
              await BloomeeDBService.createPlaylist(
                  BloomeeDBService.likedPlaylist);
              for (var item in cloudSongs) {
                try {
                  final mediaItem = MediaItemDB.fromMap(item);
                  await BloomeeDBService.addMediaItem(
                      mediaItem, BloomeeDBService.likedPlaylist);
                } catch (e) {
                  print('Error syncing cloud liked item to local: $e');
                }
              }
            } finally {
              _suppressLocalLikedPush = false;
            }
          },
        );
      },
      onError: (Object e, StackTrace st) {
        CrashReporter.record(e, st, source: 'SyncService.watchLikedSongs');
        _stopSync();
        _safeAddStatus(SyncStatus.error);
      },
    );

    _cloudHistorySubscription = _firestoreService.watchHistory(userId).listen(
      (cloudHistory) {
        if (cloudHistory.isEmpty) return;
        _enqueueCloudChange(
          'SyncService.watchHistory',
          userId,
          () async {
            _suppressLocalHistoryPush = true;
            try {
              await BloomeeDBService.createPlaylist(
                  BloomeeDBService.recentlyPlayedPlaylist);
              for (var item in cloudHistory) {
                try {
                  final mediaItem = MediaItemDB.fromMap(item);
                  await BloomeeDBService.putRecentlyPlayed(mediaItem);
                } catch (e) {
                  print('Error syncing cloud history to local: $e');
                }
              }
            } finally {
              _suppressLocalHistoryPush = false;
            }
          },
        );
      },
      onError: (Object e, StackTrace st) {
        CrashReporter.record(e, st, source: 'SyncService.watchHistory');
        _stopSync();
        _safeAddStatus(SyncStatus.error);
      },
    );

    _cloudSearchHistorySubscription =
        _firestoreService.watchSearchHistory(userId).listen(
      (cloudSearch) {
        if (cloudSearch.isEmpty) return;
        _enqueueCloudChange(
          'SyncService.watchSearchHistory',
          userId,
          () async {
            _suppressLocalSearchPush = true;
            try {
              final isar = await BloomeeDBService.db;
              await isar.writeTxn(() async {
                for (final item in cloudSearch) {
                  try {
                    await isar.searchHistoryDBs
                        .put(SearchHistoryDB.fromMap(item));
                  } catch (e) {
                    print('Error syncing cloud search history to local: $e');
                  }
                }
              });
            } finally {
              _suppressLocalSearchPush = false;
            }
          },
        );
      },
      onError: (Object e, StackTrace st) {
        CrashReporter.record(e, st, source: 'SyncService.watchSearchHistory');
        _stopSync();
        _safeAddStatus(SyncStatus.error);
      },
    );

    _preferencesSubscription =
        _firestoreService.watchUserPreferences(userId).listen(
      (prefs) {
        if (prefs == null) return;
        _enqueueCloudChange(
          'SyncService.watchUserPreferences',
          userId,
          () async {
            _suppressLocalPrefsPush = true;
            try {
              final b = prefs['bool'] as Map<String, dynamic>?;
              if (b != null) {
                for (final entry in b.entries) {
                  final v = entry.value;
                  if (v is bool) {
                    await BloomeeDBService.putSettingBool(entry.key, v);
                  }
                }
              }
              final s = prefs['str'] as Map<String, dynamic>?;
              if (s != null) {
                for (final entry in s.entries) {
                  final v = entry.value;
                  if (v is String) {
                    await BloomeeDBService.putSettingStr(entry.key, v);
                  }
                }
              }
            } finally {
              _suppressLocalPrefsPush = false;
            }
          },
        );
      },
      onError: (Object e, StackTrace st) {
        CrashReporter.record(e, st, source: 'SyncService.watchUserPreferences');
        _stopSync();
        _safeAddStatus(SyncStatus.error);
      },
    );

    _statisticsSubscription = _firestoreService.watchStatistics(userId).listen(
      (cloudStats) {
        if (cloudStats.isEmpty) return;
        _enqueueCloudChange(
          'SyncService.watchStatistics',
          userId,
          () async {
            _suppressLocalStatsPush = true;
            try {
              final isar = await BloomeeDBService.db;
              await isar.writeTxn(() async {
                for (final stat in cloudStats) {
                  try {
                    final mediaId =
                        (stat['mediaId'] ?? stat['mediaID'] ?? stat['id'])
                            ?.toString();
                    if (mediaId == null || mediaId.isEmpty) continue;
                    final playCount = (stat['playCount'] as num?)?.toInt() ?? 0;
                    final lastPlayedMs = (stat['lastPlayed'] as num?)?.toInt();
                    final lastPlayed = lastPlayedMs != null
                        ? DateTime.fromMillisecondsSinceEpoch(lastPlayedMs)
                        : DateTime.now();
                    final ts = (stat['playTimestamps'] as List?)
                            ?.whereType<num>()
                            .map((e) =>
                                DateTime.fromMillisecondsSinceEpoch(e.toInt()))
                            .toList() ??
                        <DateTime>[];

                    await isar.playStatisticsDBs.put(
                      PlayStatisticsDB(
                        mediaId: mediaId,
                        title: (stat['title'] ?? '').toString(),
                        artist: (stat['artist'] ?? '').toString(),
                        album: (stat['album'] ?? '').toString(),
                        playCount: playCount,
                        lastPlayed: lastPlayed,
                        playTimestamps: ts,
                      ),
                    );
                  } catch (e) {
                    print('Error syncing statistics from cloud: $e');
                  }
                }
              });
            } finally {
              _suppressLocalStatsPush = false;
            }
          },
        );
      },
      onError: (Object e, StackTrace st) {
        CrashReporter.record(e, st, source: 'SyncService.watchStatistics');
        _stopSync();
        _safeAddStatus(SyncStatus.error);
      },
    );

    _cloudPlaylistsSubscription =
        _firestoreService.watchPlaylists(userId).listen(
      (_) {
        _enqueueCloudChange(
          'SyncService.watchPlaylists',
          userId,
          () async {
            final cloudPlaylists =
                await _firestoreService.getPlaylistsFromCloud(userId);
            if (cloudPlaylists.isEmpty) return;
            _suppressLocalPlaylistPush = true;
            try {
              for (final pl in cloudPlaylists) {
                final name = (pl['playlistName'] as String?) ?? '';
                if (name.isEmpty) continue;
                final items = await _firestoreService.getPlaylistItemsFromCloud(
                    userId, name);
                if (items.isEmpty) continue;

                await BloomeeDBService.createPlaylist(
                  name,
                  artURL: pl['artURL'] as String?,
                  description: pl['description'] as String?,
                  permaURL: pl['permaURL'] as String?,
                  source: pl['source'] as String?,
                  artists: pl['artists'] as String?,
                  isAlbum: (pl['isAlbum'] as bool?) ?? false,
                );

                final order = (pl['mediaOrder'] as List?)
                        ?.whereType<String>()
                        .toList(growable: false) ??
                    const <String>[];

                final idsInOrder = <int>[];
                final mapById = <String, Map<String, dynamic>>{
                  for (final it in items)
                    if ((it['mediaID'] ?? it['mediaId'] ?? it['id']) != null)
                      (it['mediaID'] ?? it['mediaId'] ?? it['id']).toString():
                          it,
                };

                final orderedKeys =
                    order.isNotEmpty ? order : mapById.keys.toList();
                for (final mediaId in orderedKeys) {
                  final m = mapById[mediaId];
                  if (m == null) continue;
                  try {
                    final dbItem = MediaItemDB.fromMap(m);
                    final id =
                        await BloomeeDBService.addMediaItem(dbItem, name);
                    if (id != null) idsInOrder.add(id);
                  } catch (e) {
                    print('Error syncing cloud playlist item to local: $e');
                  }
                }

                if (idsInOrder.isNotEmpty) {
                  await BloomeeDBService.updatePltItemsRankByName(
                      name, idsInOrder);
                }
              }
            } finally {
              _suppressLocalPlaylistPush = false;
            }
          },
        );
      },
      onError: (Object e, StackTrace st) {
        CrashReporter.record(e, st, source: 'SyncService.watchPlaylists');
        _stopSync();
        _safeAddStatus(SyncStatus.error);
      },
    );

    _savedCollectionsSubscription =
        _firestoreService.watchSavedCollections(userId).listen(
      (items) {
        if (items.isEmpty) return;
        _enqueueCloudChange(
          'SyncService.watchSavedCollections',
          userId,
          () async {
            _suppressLocalSavedCollectionsPush = true;
            try {
              final isar = await BloomeeDBService.db;
              await isar.writeTxn(() async {
                for (final item in items) {
                  try {
                    await isar.savedCollectionsDBs
                        .put(SavedCollectionsDB.fromMap(item));
                  } catch (e) {
                    print('Error syncing saved collection to local: $e');
                  }
                }
              });
            } finally {
              _suppressLocalSavedCollectionsPush = false;
            }
          },
        );
      },
      onError: (Object e, StackTrace st) {
        CrashReporter.record(e, st,
            source: 'SyncService.watchSavedCollections');
      },
    );

    _queuesSubscription = _firestoreService.watchQueues(userId).listen(
      (items) {
        if (items.isEmpty) return;
        _enqueueCloudChange(
          'SyncService.watchQueues',
          userId,
          () async {
            _suppressLocalQueuesPush = true;
            try {
              final isar = await BloomeeDBService.db;
              await isar.writeTxn(() async {
                for (final q in items) {
                  try {
                    final name = (q['queueName'] ?? '').toString();
                    if (name.isEmpty) continue;
                    final savedAtMs = (q['savedAt'] as num?)?.toInt();
                    final savedAt = savedAtMs != null
                        ? DateTime.fromMillisecondsSinceEpoch(savedAtMs)
                        : DateTime.now();
                    final mediaItemsJson = (q['mediaItemsJson'] as List?)
                            ?.whereType<String>()
                            .toList() ??
                        <String>[];
                    final currentIndex =
                        (q['currentIndex'] as num?)?.toInt() ?? 0;
                    final positionMs = (q['positionMs'] as num?)?.toInt() ?? 0;
                    await isar.savedQueueDBs.put(
                      SavedQueueDB(
                        queueName: name,
                        savedAt: savedAt,
                        mediaItemsJson: mediaItemsJson,
                        currentIndex: currentIndex,
                        positionMs: positionMs,
                      ),
                    );
                  } catch (e) {
                    print('Error syncing queue to local: $e');
                  }
                }
              });
            } finally {
              _suppressLocalQueuesPush = false;
            }
          },
        );
      },
      onError: (Object e, StackTrace st) {
        CrashReporter.record(e, st, source: 'SyncService.watchQueues');
      },
    );

    _downloadsSubscription = _firestoreService.watchDownloads(userId).listen(
      (cloudDownloads) {
        if (cloudDownloads.isEmpty) return;
        _enqueueCloudChange(
          'SyncService.watchDownloads',
          userId,
          () async {
            _suppressLocalDownloadsPush = true;
            try {
              final downloads = <DownloadDB>[];
              for (final item in cloudDownloads) {
                try {
                  downloads.add(DownloadDB.fromMap(item));
                } catch (e) {
                  print('Error parsing download item: $e');
                }
              }
              if (downloads.isNotEmpty) {
                await BloomeeDBService.saveDownloadsBatch(downloads);
              }
            } finally {
              _suppressLocalDownloadsPush = false;
            }
          },
        );
      },
      onError: (Object e, StackTrace st) {
        CrashReporter.record(e, st, source: 'SyncService.watchDownloads');
      },
    );

    _lyricsSubscription = _firestoreService.watchLyrics(userId).listen(
      (cloudLyrics) {
        if (cloudLyrics.isEmpty) return;
        _enqueueCloudChange(
          'SyncService.watchLyrics',
          userId,
          () async {
            _suppressLocalLyricsPush = true;
            try {
              final lyrics = <LyricsDB>[];
              for (final item in cloudLyrics) {
                try {
                  lyrics.add(LyricsDB.fromMap(item));
                } catch (e) {
                  print('Error parsing lyrics item: $e');
                }
              }
              if (lyrics.isNotEmpty) {
                await BloomeeDBService.saveLyricsBatch(lyrics);
              }
            } finally {
              _suppressLocalLyricsPush = false;
            }
          },
        );
      },
      onError: (Object e, StackTrace st) {
        CrashReporter.record(e, st, source: 'SyncService.watchLyrics');
      },
    );
  }

  void _watchLocalChanges(String userId) async {
    _playlistsSubscription =
        (await BloomeeDBService.getPlaylistsWatcher()).listen((_) {
      print('💾 Local playlists changed, scheduling sync...');
      if (_suppressLocalPlaylistPush) return;

      _localDebounce?.cancel();
      _localDebounce = Timer(const Duration(milliseconds: 600), () {
        _syncPlaylistsToCloud(userId);
        if (!_suppressLocalHistoryPush) _syncHistoryToCloud(userId);
        if (!_suppressLocalLikedPush) _syncLikedSongsToCloud(userId);
        if (!_suppressLocalSearchPush) _syncSearchHistoryToCloud(userId);
      });
    });

    _searchHistorySubscription =
        (await BloomeeDBService.getSearchHistoryWatcher()).listen((_) {
      if (_suppressLocalSearchPush) return;
      _localDebounce?.cancel();
      _localDebounce = Timer(const Duration(milliseconds: 600), () {
        if (!_suppressLocalSearchPush) _syncSearchHistoryToCloud(userId);
      });
    });

    _recentlyPlayedSubscription =
        (await BloomeeDBService.watchRecentlyPlayed()).listen((_) {
      if (_suppressLocalHistoryPush) return;
      _localDebounce?.cancel();
      _localDebounce = Timer(const Duration(milliseconds: 600), () {
        if (!_suppressLocalHistoryPush) _syncHistoryToCloud(userId);
      });
    });

    final isar = await BloomeeDBService.db;
    _settingsBoolSubscription =
        isar.appSettingsBoolDBs.watchLazy(fireImmediately: true).listen((_) {
      if (_suppressLocalPrefsPush) return;
      _syncPreferencesToCloud(userId);
    });
    _settingsStrSubscription =
        isar.appSettingsStrDBs.watchLazy(fireImmediately: true).listen((_) {
      if (_suppressLocalPrefsPush) return;
      _syncPreferencesToCloud(userId);
    });

    _localStatisticsSubscription =
        isar.playStatisticsDBs.watchLazy(fireImmediately: true).listen((_) {
      if (_suppressLocalStatsPush) return;
      _syncStatisticsToCloud(userId);
    });

    _localSavedCollectionsSubscription =
        isar.savedCollectionsDBs.watchLazy(fireImmediately: true).listen((_) {
      if (_suppressLocalSavedCollectionsPush) return;
      _syncSavedCollectionsToCloud(userId);
    });

    _localQueuesSubscription =
        isar.savedQueueDBs.watchLazy(fireImmediately: true).listen((_) {
      if (_suppressLocalQueuesPush) return;
      _syncQueuesToCloud(userId);
    });

    _localDownloadsSubscription =
        isar.downloadDBs.watchLazy(fireImmediately: true).listen((_) {
      if (_suppressLocalDownloadsPush) return;
      _syncDownloadsToCloud(userId);
    });

    _localLyricsSubscription =
        isar.lyricsDBs.watchLazy(fireImmediately: true).listen((_) {
      if (_suppressLocalLyricsPush) return;
      _syncLyricsToCloud(userId);
    });
  }

  Future<void> _syncSavedCollectionsToCloud(String userId) async {
    if (_syncingSavedCollections) return;
    _syncingSavedCollections = true;
    try {
      final isar = await BloomeeDBService.db;
      final items = await isar.savedCollectionsDBs.where().findAll();
      await _firestoreService.syncSavedCollectionsToCloud(userId, items);
    } catch (e) {
      print('Sync Error (Saved Collections): $e');
    } finally {
      _syncingSavedCollections = false;
    }
  }

  Future<void> _syncQueuesToCloud(String userId) async {
    if (_syncingQueues) return;
    _syncingQueues = true;
    try {
      final isar = await BloomeeDBService.db;
      final queues = await isar.savedQueueDBs.where().findAll();
      await _firestoreService.syncQueuesToCloud(userId, queues);
    } catch (e) {
      print('Sync Error (Queues): $e');
    } finally {
      _syncingQueues = false;
    }
  }

  Future<void> _syncDownloadsToCloud(String userId) async {
    if (_syncingDownloads) return;
    _syncingDownloads = true;
    try {
      final items = await BloomeeDBService.getAllDownloadsDB();
      await _firestoreService.syncDownloadsToCloud(userId, items);
    } catch (e) {
      print('Sync Error (Downloads): $e');
    } finally {
      _syncingDownloads = false;
    }
  }

  Future<void> _syncLyricsToCloud(String userId) async {
    if (_syncingLyrics) return;
    _syncingLyrics = true;
    try {
      final items = await BloomeeDBService.getAllLyricsDB();
      await _firestoreService.syncLyricsToCloud(userId, items);
    } catch (e) {
      print('Sync Error (Lyrics): $e');
    } finally {
      _syncingLyrics = false;
    }
  }

  Future<void> _syncPlaylistsToCloud(String userId) async {
    if (_syncingPlaylists) return;
    _syncingPlaylists = true;

    final playlists = await BloomeeDBService.getAllPlaylistsDB();
    _safeAddDetails(
      _syncDetailsController.value.copyWith(syncingPlaylists: true),
    );

    try {
      await _firestoreService.syncPlaylistsToCloud(userId, playlists);

      var totalItems = 0;
      for (final playlist in playlists) {
        final items = await BloomeeDBService.getPlaylistItems(playlist);
        final info =
            await BloomeeDBService.getPlaylistInfo(playlist.playlistName);
        final rankedIds = await BloomeeDBService.getPlaylistItemsRank(playlist);

        final mapByIsarId = {
          for (final it in items ?? <MediaItemDB>[]) it.id: it
        };
        final ordered = <MediaItemDB>[];
        for (final rid in rankedIds) {
          final it = mapByIsarId[rid];
          if (it != null) ordered.add(it);
        }
        for (final it in items ?? <MediaItemDB>[]) {
          if (!ordered.any((e) => e.id == it.id)) ordered.add(it);
        }
        totalItems += ordered.length;

        final mediaOrder =
            ordered.map((e) => e.mediaID).toList(growable: false);
        await _firestoreService.syncPlaylistToCloud(
          userId,
          playlistName: playlist.playlistName,
          playlistDoc: {
            'lastUpdated': playlist.lastUpdated?.millisecondsSinceEpoch,
            'mediaOrder': mediaOrder,
            'isAlbum': info?.isAlbum,
            'artURL': info?.artURL,
            'description': info?.description,
            'permaURL': info?.permaURL,
            'source': info?.source,
            'artists': info?.artists,
            'infoLastUpdated': info?.lastUpdated.millisecondsSinceEpoch,
          },
          items: ordered,
        );
      }

      _safeAddDetails(
        _syncDetailsController.value.copyWith(
          playlistsCount: playlists.length,
          playlistItemsCount: totalItems,
        ),
      );

      if (_initialSyncCompleted) {
        _safeAddStatus(SyncStatus.synced);
        _safeAddDetails(
          _syncDetailsController.value.copyWith(
            status: SyncStatus.synced,
            lastSuccessfulSyncAt: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      print('Sync Error (Playlists): $e');
      _safeAddStatus(SyncStatus.error);
      _safeAddDetails(
        _syncDetailsController.value.copyWith(status: SyncStatus.error),
      );
    } finally {
      _syncingPlaylists = false;
      _safeAddDetails(
        _syncDetailsController.value.copyWith(syncingPlaylists: false),
      );
    }
  }

  Future<void> _syncHistoryToCloud(String userId) async {
    if (_syncingHistory) return;
    _syncingHistory = true;
    final historyItems = await BloomeeDBService.getRecentlyPlayedDBItems();
    _safeAddDetails(
      _syncDetailsController.value.copyWith(
        syncingHistory: true,
        historyCount: historyItems.length,
      ),
    );

    try {
      await _firestoreService.syncHistoryToCloud(userId, historyItems);
    } catch (e) {
      print('Sync Error (History): $e');
    } finally {
      _syncingHistory = false;
      _safeAddDetails(
        _syncDetailsController.value.copyWith(
          syncingHistory: false,
          status: _initialSyncCompleted ? SyncStatus.synced : SyncStatus.idle,
          lastSuccessfulSyncAt: _initialSyncCompleted ? DateTime.now() : null,
        ),
      );
    }
  }

  Future<void> _syncSearchHistoryToCloud(String userId) async {
    if (_syncingSearchHistory) return;
    _syncingSearchHistory = true;
    try {
      final items = await BloomeeDBService.getAllSearchHistoryDBItems();
      _safeAddDetails(
        _syncDetailsController.value.copyWith(
          syncingSearchHistory: true,
          searchHistoryCount: items.length,
        ),
      );
      await _firestoreService.syncSearchHistoryToCloud(userId, items);
    } catch (e) {
      print('Sync Error (Search History): $e');
    } finally {
      _syncingSearchHistory = false;
      _safeAddDetails(
        _syncDetailsController.value.copyWith(
          syncingSearchHistory: false,
          status: _initialSyncCompleted ? SyncStatus.synced : SyncStatus.idle,
          lastSuccessfulSyncAt: _initialSyncCompleted ? DateTime.now() : null,
        ),
      );
    }
  }

  Future<void> _syncPreferencesToCloud(String userId) async {
    if (_syncingPrefs) return;
    _syncingPrefs = true;
    try {
      final isar = await BloomeeDBService.db;
      final boolSettings = await isar.appSettingsBoolDBs.where().findAll();
      final strSettings = await isar.appSettingsStrDBs.where().findAll();

      _safeAddDetails(
        _syncDetailsController.value.copyWith(
          syncingPreferences: true,
          settingsBoolCount: boolSettings.length,
          settingsStrCount: strSettings.length,
        ),
      );

      final boolMap = <String, bool>{};
      final strMap = <String, String>{};
      for (final s in boolSettings) {
        boolMap[s.settingName] = s.settingValue;
      }
      for (final s in strSettings) {
        strMap[s.settingName] = s.settingValue;
      }

      final prefs = <String, dynamic>{
        'bool': boolMap,
        'str': strMap,
      };

      await _firestoreService.saveUserPreferences(userId, prefs);
    } catch (e) {
      print('Sync Error (Preferences): $e');
    } finally {
      _syncingPrefs = false;
      _safeAddDetails(
        _syncDetailsController.value.copyWith(
          syncingPreferences: false,
          status: _initialSyncCompleted ? SyncStatus.synced : SyncStatus.idle,
          lastSuccessfulSyncAt: _initialSyncCompleted ? DateTime.now() : null,
        ),
      );
    }
  }

  Future<void> _syncLikedSongsToCloud(String userId) async {
    if (_syncingLikedSongs) return;
    _syncingLikedSongs = true;
    final likedItems = await BloomeeDBService.getPlaylistItemsByName(
        BloomeeDBService.likedPlaylist);
    if (likedItems == null) {
      _syncingLikedSongs = false;
      return;
    }

    _safeAddDetails(
      _syncDetailsController.value.copyWith(
        syncingLikedSongs: true,
        likedSongsCount: likedItems.length,
      ),
    );

    try {
      await _firestoreService.syncLikedSongsToCloud(userId, likedItems);
    } catch (e) {
      print('Sync Error (Liked Songs): $e');
    } finally {
      _syncingLikedSongs = false;
      _safeAddDetails(
        _syncDetailsController.value.copyWith(
          syncingLikedSongs: false,
          status: _initialSyncCompleted ? SyncStatus.synced : SyncStatus.idle,
          lastSuccessfulSyncAt: _initialSyncCompleted ? DateTime.now() : null,
        ),
      );
    }
  }

  Future<void> _syncStatisticsToCloud(String userId) async {
    if (_syncingStatistics) return;
    _syncingStatistics = true;
    try {
      final isar = await BloomeeDBService.db;
      final stats = await isar.playStatisticsDBs.where().findAll();
      _safeAddDetails(
        _syncDetailsController.value.copyWith(
          syncingStatistics: true,
          statisticsCount: stats.length,
        ),
      );
      await _firestoreService.syncStatisticsToCloud(userId, stats);
    } catch (e) {
      print('Sync Error (Statistics): $e');
    } finally {
      _syncingStatistics = false;
      _safeAddDetails(
        _syncDetailsController.value.copyWith(
          syncingStatistics: false,
          status: _initialSyncCompleted ? SyncStatus.synced : SyncStatus.idle,
          lastSuccessfulSyncAt: _initialSyncCompleted ? DateTime.now() : null,
        ),
      );
    }
  }
}
