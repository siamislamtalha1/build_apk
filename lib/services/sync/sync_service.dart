import 'dart:async';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:Bloomee/services/db/GlobalDB.dart';
import 'package:Bloomee/services/firebase/auth_service.dart';
import 'package:Bloomee/services/firebase/firestore_service.dart';
import 'package:isar_community/isar.dart';
import 'package:rxdart/rxdart.dart';

enum SyncStatus { idle, syncing, synced, error }

/// Service to handle synchronization between local Isar DB and Firestore
class SyncService {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription? _authSubscription;
  StreamSubscription? _likedSongsSubscription;
  StreamSubscription? _playlistsSubscription;
  StreamSubscription? _settingsBoolSubscription;
  StreamSubscription? _settingsStrSubscription;
  StreamSubscription? _preferencesSubscription;
  StreamSubscription? _statisticsSubscription;
  StreamSubscription? _localStatisticsSubscription;
  StreamSubscription? _cloudPlaylistsSubscription;
  StreamSubscription? _cloudHistorySubscription;

  bool _suppressLocalPlaylistPush = false;
  bool _suppressLocalHistoryPush = false;
  bool _suppressLocalLikedPush = false;
  bool _suppressLocalPrefsPush = false;
  bool _suppressLocalStatsPush = false;

  // Stream controller for sync status
  final BehaviorSubject<SyncStatus> _syncStatusController =
      BehaviorSubject<SyncStatus>.seeded(SyncStatus.idle);

  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  // Singleton instance
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  /// Initialize sync service
  void init() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (user != null && !user.isAnonymous) {
        _startSync(user.uid);
      } else {
        _stopSync();
      }
    });
  }

  /// Start sync for a user
  void _startSync(String userId) async {
    print('🔄 Starting sync for user: $userId');
    _syncStatusController.add(SyncStatus.syncing);

    // 1. Initial Pull from Cloud (pessimistic strategy: cloud wins if conflict/empty)
    _performInitialSync(userId);

    // 2. Listen to Local Changes -> Push to Cloud
    _watchLocalChanges(userId);

    // 3. Listen to Cloud Changes -> Update Local (Realtime)
    _watchCloudChanges(userId);
  }

  void _stopSync() {
    print('⏹️ Stopping sync');
    _likedSongsSubscription?.cancel();
    _playlistsSubscription?.cancel();
    _settingsBoolSubscription?.cancel();
    _settingsStrSubscription?.cancel();
    _preferencesSubscription?.cancel();
    _statisticsSubscription?.cancel();
    _localStatisticsSubscription?.cancel();
    _cloudPlaylistsSubscription?.cancel();
    _cloudHistorySubscription?.cancel();
    _syncStatusController.add(SyncStatus.idle);
  }

  Future<void> _performInitialSync(String userId) async {
    print('⬇️ Performing initial sync from cloud...');
    // 1. Sync Liked Songs
    final cloudLiked = await _firestoreService.getLikedSongsFromCloud(userId);
    if (cloudLiked.isNotEmpty) {
      _suppressLocalLikedPush = true;
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
    }

    // 2. Sync History (Recently Played)
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

    // 3. Sync Preferences/Settings
    final prefs = await _firestoreService.getUserPreferences(userId);
    if (prefs != null) {
      _suppressLocalPrefsPush = true;
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
      _suppressLocalPrefsPush = false;
    }

    // 4. Sync Playlists (including items)
    final cloudPlaylists = await _firestoreService.getPlaylistsFromCloud(userId);
    if (cloudPlaylists.isNotEmpty) {
      _suppressLocalPlaylistPush = true;
      for (final pl in cloudPlaylists) {
        final name = (pl['playlistName'] as String?) ?? '';
        if (name.isEmpty) continue;
        final items = await _firestoreService.getPlaylistItemsFromCloud(userId, name);
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
      _suppressLocalPlaylistPush = false;
    }

    // 5. Sync Play Statistics (played)
    final cloudStats = await _firestoreService.getStatisticsFromCloud(userId);
    if (cloudStats.isNotEmpty) {
      _suppressLocalStatsPush = true;
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
                    .map((e) => DateTime.fromMillisecondsSinceEpoch(e.toInt()))
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
      _suppressLocalStatsPush = false;
    }

    _syncStatusController.add(SyncStatus.synced);
    print('✅ Initial sync completed');
  }

  void _watchCloudChanges(String userId) {
    // Watch Liked Songs from Cloud
    _likedSongsSubscription =
        _firestoreService.watchLikedSongs(userId).listen((cloudSongs) async {
      if (cloudSongs.isEmpty) return;
      print('☁️ Cloud liked songs changed: ${cloudSongs.length} items');

      // Update Local DB
      // Note: This might trigger _watchLocalChanges -> _syncLikeSongsToCloud
      // Loop prevention: _syncLikedSongsToCloud compares content or we rely on Idempotency
      // Ideally, we shout check if local == cloud before writing.
      // For now, simpler implementation:

      await BloomeeDBService.createPlaylist(BloomeeDBService.likedPlaylist);
      // We might want to merge or replace. Cloud is "truth" here for simplicity?
      // Or merge? Let's just add missing ones for now to be safe against deletion loops.

      for (var item in cloudSongs) {
        try {
          final mediaItem = MediaItemDB.fromMap(item);
          // Add if not exists or update.
          // BloomeeDBService.addMediaItem checks for existence?
          // Usually yes, or use put.
          await BloomeeDBService.addMediaItem(
              mediaItem, BloomeeDBService.likedPlaylist);
        } catch (e) {
          print('Error syncing cloud liked item to local: $e');
        }
      }
      _suppressLocalLikedPush = false;
    });

    // Watch History from Cloud
    // Note: History stream might be frequent.
    _cloudHistorySubscription =
        _firestoreService.watchHistory(userId).listen((cloudHistory) async {
      if (cloudHistory.isEmpty) return;
      // Similar logic for history
      _suppressLocalHistoryPush = true;
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
      _suppressLocalHistoryPush = false;
    });

    _preferencesSubscription =
        _firestoreService.watchUserPreferences(userId).listen((prefs) async {
      if (prefs == null) return;
      _suppressLocalPrefsPush = true;
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
      _suppressLocalPrefsPush = false;
    });

    _statisticsSubscription =
        _firestoreService.watchStatistics(userId).listen((cloudStats) async {
      if (cloudStats.isEmpty) return;
      _suppressLocalStatsPush = true;
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
                    .map((e) => DateTime.fromMillisecondsSinceEpoch(e.toInt()))
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
      _suppressLocalStatsPush = false;
    });

    _cloudPlaylistsSubscription =
        _firestoreService.watchPlaylists(userId).listen((_) async {
      // Pull playlist headers changed; items are stored in subcollections.
      // We'll refresh by pulling each playlist's items and applying to local.
      final cloudPlaylists = await _firestoreService.getPlaylistsFromCloud(userId);
      if (cloudPlaylists.isEmpty) return;

      _suppressLocalPlaylistPush = true;
      for (final pl in cloudPlaylists) {
        final name = (pl['playlistName'] as String?) ?? '';
        if (name.isEmpty) continue;
        final items = await _firestoreService.getPlaylistItemsFromCloud(userId, name);
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
      _suppressLocalPlaylistPush = false;
    });
  }

  void _watchLocalChanges(String userId) async {
    // Watch Playlists (triggers on any playlist change, including Liked and Recently Played)
    _playlistsSubscription =
        (await BloomeeDBService.getPlaylistsWatcher()).listen((_) {
      print('💾 Local playlists changed, scheduling sync...');
      // Simple debounce or just fire
      if (_suppressLocalPlaylistPush) return;
      _syncPlaylistsToCloud(userId);
      if (!_suppressLocalHistoryPush) _syncHistoryToCloud(userId);
      if (!_suppressLocalLikedPush) _syncLikedSongsToCloud(userId);
    });

    // Watch settings changes -> push to cloud preferences
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
  }

  // ... (Rest of existing sync methods)

  Future<void> _syncPlaylistsToCloud(String userId) async {
    final playlists = await BloomeeDBService.getAllPlaylistsDB();
    _syncStatusController.add(SyncStatus.syncing);
    try {
      // First sync playlist headers
      await _firestoreService.syncPlaylistsToCloud(userId, playlists);

      // Then sync each playlist items + order
      for (final playlist in playlists) {
        final items = await BloomeeDBService.getPlaylistItems(playlist);
        final info = await BloomeeDBService.getPlaylistInfo(playlist.playlistName);

        // Try to construct a stable cross-device order based on mediaID
        final rankedIds = await BloomeeDBService.getPlaylistItemsRank(playlist);
        final mapByIsarId = {for (final it in items ?? <MediaItemDB>[]) it.id: it};
        final ordered = <MediaItemDB>[];
        for (final rid in rankedIds) {
          final it = mapByIsarId[rid];
          if (it != null) ordered.add(it);
        }
        for (final it in items ?? <MediaItemDB>[]) {
          if (!ordered.any((e) => e.id == it.id)) ordered.add(it);
        }

        final mediaOrder = ordered.map((e) => e.mediaID).toList(growable: false);

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
      _syncStatusController.add(SyncStatus.synced);
    } catch (e) {
      print('Sync Error (Playlists): $e');
      _syncStatusController.add(SyncStatus.error);
    }
  }

  Future<void> _syncHistoryToCloud(String userId) async {
    final historyItems = await BloomeeDBService.getRecentlyPlayedDBItems();

    try {
      await _firestoreService.syncHistoryToCloud(userId, historyItems);
    } catch (e) {
      print('Sync Error (History): $e');
    }
  }

  Future<void> _syncPreferencesToCloud(String userId) async {
    try {
      final isar = await BloomeeDBService.db;
      final boolSettings = await isar.appSettingsBoolDBs.where().findAll();
      final strSettings = await isar.appSettingsStrDBs.where().findAll();

      final prefs = <String, dynamic>{
        'bool': {for (final s in boolSettings) s.settingName: s.settingValue},
        'str': {for (final s in strSettings) s.settingName: s.settingValue},
      };

      await _firestoreService.saveUserPreferences(userId, prefs);
    } catch (e) {
      print('Sync Error (Preferences): $e');
    }
  }

  Future<void> _syncLikedSongsToCloud(String userId) async {
    final likedItems = await BloomeeDBService.getPlaylistItemsByName(
        BloomeeDBService.likedPlaylist);
    if (likedItems == null) return;

    try {
      await _firestoreService.syncLikedSongsToCloud(userId, likedItems);
    } catch (e) {
      print('Sync Error (Liked Songs): $e');
    }
  }

  Future<void> _syncStatisticsToCloud(String userId) async {
    try {
      final isar = await BloomeeDBService.db;
      final stats = await isar.playStatisticsDBs.where().findAll();
      await _firestoreService.syncStatisticsToCloud(userId, stats);
    } catch (e) {
      print('Sync Error (Statistics): $e');
    }
  }
}
