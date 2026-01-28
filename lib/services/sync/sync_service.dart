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
    // _watchCloudChanges(userId); // Optional: can be resource intensive, simpler to just pull on start

    // Assume initial sync done or running
    // Ideally await _performInitialSync, but _startSync is void here.
    // Changing _startSync to async void is fine for fire-and-forget but better to handle state.
  }

  void _stopSync() {
    print('⏹️ Stopping sync');
    _likedSongsSubscription?.cancel();
    _playlistsSubscription?.cancel();
    _syncStatusController.add(SyncStatus.idle);
  }

  Future<void> _performInitialSync(String userId) async {
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
  }

  void _watchLocalChanges(String userId) async {
    // Watch Playlists (triggers on any playlist change, including Liked and Recently Played)
    _playlistsSubscription =
        (await BloomeeDBService.getPlaylistsWatcher()).listen((_) {
      _syncPlaylistsToCloud(userId);
      _syncHistoryToCloud(userId);
      _syncLikedSongsToCloud(userId);
    });
  }

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
