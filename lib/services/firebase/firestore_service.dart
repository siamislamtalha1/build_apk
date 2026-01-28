import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Bloomee/services/db/GlobalDB.dart';

/// Firestore service for syncing user data across devices
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user document reference
  DocumentReference _userDoc(String userId) {
    return _firestore.collection('users').doc(userId);
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
        });
      }

      await batch.commit();
      print('✅ Synced ${playlists.length} playlists to cloud');
    } catch (e) {
      print('❌ Failed to sync playlists: $e');
      rethrow;
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
}
