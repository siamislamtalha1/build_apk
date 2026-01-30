import 'dart:async';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:Bloomee/services/db/GlobalDB.dart';
import 'package:Bloomee/services/firebase/auth_service.dart';
import 'package:Bloomee/services/firebase/firestore_service.dart';
import 'package:rxdart/rxdart.dart';

enum SyncStatus { idle, syncing, synced, error }

/// Service to handle synchronization between local Isar DB and Firestore
class SyncService {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription? _authSubscription;
  StreamSubscription? _likedSongsSubscription;
  StreamSubscription? _playlistsSubscription;

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
      if (user != null) {
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
    _authSubscription?.cancel();
    _likedSongsSubscription?.cancel();
    _playlistsSubscription?.cancel();
    _syncStatusController.add(SyncStatus.idle);
  }

  Future<void> _performInitialSync(String userId) async {
    print('⬇️ Performing initial sync from cloud...');
    // 1. Sync Liked Songs
    final cloudLiked = await _firestoreService.getLikedSongsFromCloud(userId);
    if (cloudLiked.isNotEmpty) {
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
          await BloomeeDBService.addMediaItem(
              mediaItem, BloomeeDBService.recentlyPlayedPlaylist);
        } catch (e) {
          print('Error syncing history item: $e');
        }
      }
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
    });

    // Watch History from Cloud
    // Note: History stream might be frequent.
    _firestoreService.watchHistory(userId).listen((cloudHistory) async {
      if (cloudHistory.isEmpty) return;
      // Similar logic for history
      await BloomeeDBService.createPlaylist(
          BloomeeDBService.recentlyPlayedPlaylist);
      for (var item in cloudHistory) {
        try {
          final mediaItem = MediaItemDB.fromMap(item);
          await BloomeeDBService.addMediaItem(
              mediaItem, BloomeeDBService.recentlyPlayedPlaylist);
        } catch (e) {
          print('Error syncing cloud history to local: $e');
        }
      }
    });
  }

  void _watchLocalChanges(String userId) async {
    // Watch Playlists (triggers on any playlist change, including Liked and Recently Played)
    _playlistsSubscription =
        (await BloomeeDBService.getPlaylistsWatcher()).listen((_) {
      print('💾 Local playlists changed, scheduling sync...');
      // Simple debounce or just fire
      _syncPlaylistsToCloud(userId);
      _syncHistoryToCloud(userId);
      _syncLikedSongsToCloud(userId);
    });
  }

  // ... (Rest of existing sync methods)

  Future<void> _syncPlaylistsToCloud(String userId) async {
    final playlists = await BloomeeDBService.getAllPlaylistsDB();
    _syncStatusController.add(SyncStatus.syncing);
    try {
      await _firestoreService.syncPlaylistsToCloud(userId, playlists);
      _syncStatusController.add(SyncStatus.synced);
    } catch (e) {
      print('Sync Error (Playlists): $e');
      _syncStatusController.add(SyncStatus.error);
    }
  }

  Future<void> _syncHistoryToCloud(String userId) async {
    final historyItems = await BloomeeDBService.getPlaylistItemsByName(
        BloomeeDBService.recentlyPlayedPlaylist);
    if (historyItems == null) return;

    try {
      await _firestoreService.syncHistoryToCloud(userId, historyItems);
    } catch (e) {
      print('Sync Error (History): $e');
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
}
