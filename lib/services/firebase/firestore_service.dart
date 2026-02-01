import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Bloomee/services/db/GlobalDB.dart';

/// Firestore service for syncing user data across devices
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String shareUrlPrefix = 'https://bloomee.app/p/';

  /// Get user document reference
  DocumentReference _userDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  DocumentReference _usernameDoc(String usernameLower) {
    return _firestore.collection('usernames').doc(usernameLower);
  }

  DocumentReference _sharedPlaylistDoc(String shareId) {
    return _firestore.collection('sharedPlaylists').doc(shareId);
  }

  static String normalizeUsername(String raw) {
    var u = raw.trim();
    if (u.startsWith('@')) u = u.substring(1);
    return u.trim().toLowerCase();
  }

  static bool isValidUsername(String raw) {
    final u = normalizeUsername(raw);
    if (u.length < 3 || u.length > 20) return false;
    final re = RegExp(r'^[a-z0-9_]+$');
    return re.hasMatch(u);
  }

  String formatUsername(String raw) {
    final u = normalizeUsername(raw);
    return '@$u';
  }

  Future<String?> getUsername(String userId) async {
    final profile = await getUserProfile(userId);
    final username = profile?['username'] as String?;
    return username;
  }

  Stream<Map<String, dynamic>?> watchUserProfile(String userId) {
    return _userDoc(userId).snapshots().map((doc) => doc.data() as Map<String, dynamic>?);
  }

  Future<String> _generateRandomUsername({String? displayName}) async {
    final base = (displayName ?? 'user')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    final prefix = base.isEmpty ? 'user' : base;
    final seed = DateTime.now().millisecondsSinceEpoch;
    final suffix = (seed % 1000000).toString().padLeft(6, '0');
    return '$prefix$suffix';
  }

  Future<String> ensureUsername({
    required String userId,
    String? displayName,
  }) async {
    final current = await getUsername(userId);
    if (current != null && current.trim().isNotEmpty) return current;
    var attempt = await _generateRandomUsername(displayName: displayName);
    var tries = 0;
    while (tries < 6) {
      try {
        return await claimUsername(
          userId: userId,
          desiredUsername: attempt,
        );
      } catch (_) {
        final seed = DateTime.now().microsecondsSinceEpoch;
        attempt = 'user${seed % 100000000}';
        tries++;
      }
    }
    return await claimUsername(
      userId: userId,
      desiredUsername: 'user${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<String> claimUsername({
    required String userId,
    required String desiredUsername,
  }) async {
    if (!isValidUsername(desiredUsername)) {
      throw Exception('Invalid username');
    }
    final desiredLower = normalizeUsername(desiredUsername);

    return _firestore.runTransaction((txn) async {
      final userRef = _userDoc(userId);
      final userSnap = await txn.get(userRef);
      final prevLower = (userSnap.data() as Map<String, dynamic>?)?['usernameLower'] as String?;

      final usernameRef = _usernameDoc(desiredLower);
      final usernameSnap = await txn.get(usernameRef);
      if (usernameSnap.exists) {
        final data = usernameSnap.data() as Map<String, dynamic>?;
        final existingUid = data?['uid'] as String?;
        if (existingUid != userId) {
          throw Exception('Username already taken');
        }
      }

      if (prevLower != null && prevLower.isNotEmpty && prevLower != desiredLower) {
        txn.delete(_usernameDoc(prevLower));
      }

      txn.set(usernameRef, {
        'uid': userId,
        'username': '@$desiredLower',
        'usernameLower': desiredLower,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      txn.set(userRef, {
        'username': '@$desiredLower',
        'usernameLower': desiredLower,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return '@$desiredLower';
    });
  }

  Future<void> releaseUsername(String userId) async {
    try {
      final doc = await _userDoc(userId).get();
      final data = doc.data() as Map<String, dynamic>?;
      final lower = data?['usernameLower'] as String?;
      if (lower != null && lower.isNotEmpty) {
        final batch = _firestore.batch();
        batch.delete(_usernameDoc(lower));
        batch.set(_userDoc(userId), {
          'username': FieldValue.delete(),
          'usernameLower': FieldValue.delete(),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await batch.commit();
      }
    } catch (_) {}
  }

  Future<String?> getUserIdByUsername(String username) async {
    final lower = normalizeUsername(username);
    if (lower.isEmpty) return null;
    final doc = await _usernameDoc(lower).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>?;
    return data?['uid'] as String?;
  }

  Future<void> setPlaylistVisibility({
    required String userId,
    required String playlistName,
    required bool isPublic,
  }) async {
    final playlistRef = _userDoc(userId).collection('playlists').doc(playlistName);
    await playlistRef.set(
      {
        'isPublic': isPublic,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<String> ensurePlaylistShareId({
    required String userId,
    required String playlistName,
  }) async {
    final playlistRef = _userDoc(userId).collection('playlists').doc(playlistName);
    final snap = await playlistRef.get();
    final data = snap.data();
    final existing = data?['shareId'] as String?;
    if (existing != null && existing.trim().isNotEmpty) return existing;

    final shareId = _firestore.collection('_').doc().id;
    await playlistRef.set(
      {
        'shareId': shareId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final userProfile = await getUserProfile(userId);
    final usernameLower = userProfile?['usernameLower'] as String?;
    await _sharedPlaylistDoc(shareId).set(
      {
        'ownerUid': userId,
        'playlistName': playlistName,
        'usernameLower': usernameLower,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return shareId;
  }

  String buildPlaylistShareUrl(String shareId) {
    return '$shareUrlPrefix$shareId';
  }

  String? parseShareId(String input) {
    final s = input.trim();
    if (s.isEmpty) return null;
    if (s.startsWith(shareUrlPrefix)) {
      return s.substring(shareUrlPrefix.length).trim();
    }
    try {
      final uri = Uri.parse(s);
      if (uri.host.isEmpty) return null;
      final seg = uri.pathSegments;
      if (seg.isEmpty) return null;
      if (seg.length >= 2 && seg[0] == 'p') return seg[1];
      return seg.last;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> resolveSharedPlaylist(String shareId) async {
    final doc = await _sharedPlaylistDoc(shareId).get();
    return doc.data() as Map<String, dynamic>?;
  }

  Future<List<Map<String, dynamic>>> getPublicPlaylistsByUserId(String userId) async {
    final snap = await _userDoc(userId)
        .collection('playlists')
        .where('isPublic', isEqualTo: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Future<List<Map<String, dynamic>>> getPublicPlaylistsByUsername(
      String username) async {
    final uid = await getUserIdByUsername(username);
    if (uid == null) return [];
    return getPublicPlaylistsByUserId(uid);
  }

  // ==================== Liked Songs Sync ====================

  /// Sync liked songs to Firestore
  Future<void> syncLikedSongsToCloud(
      String userId, List<MediaItemDB> likedSongs) async {
    try {
      final batch = _firestore.batch();
      final likedSongsRef = _userDoc(userId).collection('likedSongs');

      // Clear existing liked songs
      final existing = await likedSongsRef.get();
      for (var doc in existing.docs) {
        batch.delete(doc.reference);
      }

      // Add current liked songs
      for (var song in likedSongs) {
        final docRef = likedSongsRef.doc(song.mediaID);
        batch.set(docRef, song.toMap());
      }

      await batch.commit();
      print('✅ Synced ${likedSongs.length} liked songs to cloud');
    } catch (e) {
      print('❌ Failed to sync liked songs: $e');
      rethrow;
    }
  }

  /// Get liked songs from Firestore
  Future<List<Map<String, dynamic>>> getLikedSongsFromCloud(
      String userId) async {
    try {
      final snapshot = await _userDoc(userId).collection('likedSongs').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Failed to get liked songs from cloud: $e');
      return [];
    }
  }

  // ==================== Playlists Sync ====================

  /// Sync playlists to Firestore
  Future<void> syncPlaylistsToCloud(
      String userId, List<MediaPlaylistDB> playlists) async {
    try {
      final batch = _firestore.batch();
      final playlistsRef = _userDoc(userId).collection('playlists');

      for (var playlist in playlists) {
        final docRef = playlistsRef.doc(playlist.playlistName);
        batch.set(docRef, {
          'playlistName': playlist.playlistName,
          'lastUpdated': playlist.lastUpdated?.millisecondsSinceEpoch,
          'mediaRanks': playlist.mediaRanks,
          // Cross-device stable ordering is handled by SyncService via syncPlaylistToCloud.
          // Keeping this field here for forward compatibility.
          'mediaOrder': <String>[],
        }, SetOptions(merge: true));
      }

      await batch.commit();
      print('✅ Synced ${playlists.length} playlists to cloud');
    } catch (e) {
      print('❌ Failed to sync playlists: $e');
      rethrow;
    }
  }

  Future<void> syncPlaylistToCloud(
    String userId, {
    required String playlistName,
    required Map<String, dynamic> playlistDoc,
    required List<MediaItemDB> items,
  }) async {
    try {
      final playlistRef = _userDoc(userId).collection('playlists').doc(
            playlistName,
          );

      await playlistRef.set(
        {
          ...playlistDoc,
          'playlistName': playlistName,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final itemsRef = playlistRef.collection('items');
      final existing = await itemsRef.get();
      final batch = _firestore.batch();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }
      for (final song in items) {
        final docRef = itemsRef.doc(song.mediaID);
        batch.set(docRef, song.toMap());
      }
      await batch.commit();
    } catch (e) {
      print('❌ Failed to sync playlist "$playlistName": $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPlaylistItemsFromCloud(
    String userId,
    String playlistName,
  ) async {
    try {
      final snapshot = await _userDoc(userId)
          .collection('playlists')
          .doc(playlistName)
          .collection('items')
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Failed to get playlist items from cloud: $e');
      return [];
    }
  }

  /// Get playlists from Firestore
  Future<List<Map<String, dynamic>>> getPlaylistsFromCloud(
      String userId) async {
    try {
      final snapshot = await _userDoc(userId).collection('playlists').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Failed to get playlists from cloud: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPlaylistHeaderFromCloud(
    String userId,
    String playlistName,
  ) async {
    try {
      final doc = await _userDoc(userId)
          .collection('playlists')
          .doc(playlistName)
          .get();
      return doc.data();
    } catch (e) {
      print('❌ Failed to get playlist header from cloud: $e');
      return null;
    }
  }

  // ==================== Statistics Sync ====================

  /// Sync play statistics to Firestore
  Future<void> syncStatisticsToCloud(
      String userId, List<PlayStatisticsDB> statistics) async {
    try {
      final batch = _firestore.batch();
      final statsRef = _userDoc(userId).collection('statistics');

      for (var stat in statistics) {
        final docRef = statsRef.doc(stat.mediaId);
        batch.set(docRef, {
          'mediaId': stat.mediaId,
          'title': stat.title,
          'artist': stat.artist,
          'album': stat.album,
          'playCount': stat.playCount,
          'lastPlayed': stat.lastPlayed.millisecondsSinceEpoch,
          'playTimestamps':
              stat.playTimestamps.map((t) => t.millisecondsSinceEpoch).toList(),
        });
      }

      await batch.commit();
      print('✅ Synced ${statistics.length} statistics to cloud');
    } catch (e) {
      print('❌ Failed to sync statistics: $e');
      rethrow;
    }
  }

  /// Get statistics from Firestore
  Future<List<Map<String, dynamic>>> getStatisticsFromCloud(
      String userId) async {
    try {
      final snapshot = await _userDoc(userId).collection('statistics').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Failed to get statistics from cloud: $e');
      return [];
    }
  }

  // ==================== History Sync ====================

  /// Sync history (recently played) to Firestore
  Future<void> syncHistoryToCloud(
      String userId, List<MediaItemDB> historyItems) async {
    try {
      final batch = _firestore.batch();
      final historyRef = _userDoc(userId).collection('history');

      // Clear existing history to ensure order and consistency
      // For large history, this might be inefficient, but safe for now.
      final existing = await historyRef.get();
      for (var doc in existing.docs) {
        batch.delete(doc.reference);
      }

      for (var item in historyItems) {
        // Use mediaID as doc ID or auto-gen?
        // Let's use mediaID to prevent duplicates if needed, but history is ordered.
        // Actually, history is a list. Let's just store them with their rank/order if valid.
        // Simple approach: Store them as documents with mediaID.
        final docRef = historyRef.doc(item.mediaID);
        batch.set(docRef, {
          ...item.toMap(),
          'syncedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('✅ Synced ${historyItems.length} history items to cloud');
    } catch (e) {
      print('❌ Failed to sync history: $e');
      rethrow;
    }
  }

  /// Get history from Firestore
  Future<List<Map<String, dynamic>>> getHistoryFromCloud(String userId) async {
    try {
      final snapshot = await _userDoc(userId)
          .collection('history')
          .orderBy('syncedAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Failed to get history from cloud: $e');
      return [];
    }
  }

  // ==================== User Profile ====================

  /// Save user profile to Firestore
  Future<void> saveUserProfile(String userId,
      {String? displayName, String? photoURL, String? email}) async {
    try {
      await _userDoc(userId).set({
        'displayName': displayName,
        'photoURL': photoURL,
        'email': email,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('✅ User profile saved');
    } catch (e) {
      print('❌ Failed to save user profile: $e');
      rethrow;
    }
  }

  /// Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _userDoc(userId).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('❌ Failed to get user profile: $e');
      return null;
    }
  }

  // ==================== Preferences Sync ====================

  /// Save user preferences to Firestore
  Future<void> saveUserPreferences(
      String userId, Map<String, dynamic> preferences) async {
    try {
      await _userDoc(userId).collection('preferences').doc('settings').set(
            preferences,
            SetOptions(merge: true),
          );
      print('✅ User preferences saved');
    } catch (e) {
      print('❌ Failed to save preferences: $e');
      rethrow;
    }
  }

  Future<void> syncUserPreferencesToCloud(
      String userId, Map<String, dynamic> preferences) {
    return saveUserPreferences(userId, preferences);
  }

  /// Get user preferences from Firestore
  Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    try {
      final doc = await _userDoc(userId)
          .collection('preferences')
          .doc('settings')
          .get();
      return doc.data();
    } catch (e) {
      print('❌ Failed to get preferences: $e');
      return null;
    }
  }

  // ==================== Real-time Listeners ====================

  /// Listen to liked songs changes
  Stream<List<Map<String, dynamic>>> watchLikedSongs(String userId) {
    return _userDoc(userId).collection('likedSongs').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  /// Listen to playlists changes
  Stream<List<Map<String, dynamic>>> watchPlaylists(String userId) {
    return _userDoc(userId).collection('playlists').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  /// Listen to history changes
  Stream<List<Map<String, dynamic>>> watchHistory(String userId) {
    return _userDoc(userId)
        .collection('history')
        .orderBy('syncedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  Stream<Map<String, dynamic>?> watchUserPreferences(String userId) {
    return _userDoc(userId)
        .collection('preferences')
        .doc('settings')
        .snapshots()
        .map((doc) => doc.data());
  }

  Stream<List<Map<String, dynamic>>> watchStatistics(String userId) {
    return _userDoc(userId).collection('statistics').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }
}
