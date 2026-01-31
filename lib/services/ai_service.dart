import 'package:Bloomee/repository/Youtube/youtube_api.dart';
import 'package:Bloomee/repository/Youtube/yt_music_api.dart';
import 'package:Bloomee/services/db/GlobalDB.dart';

/// AI-powered music recommendation and playlist generation service
/// Uses YouTube Music API for free recommendations (no API keys required)
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  /// Convert YouTube API Map results to MediaItemDB list
  List<MediaItemDB> _convertToMediaItems(List<Map> results) {
    final mediaItems = <MediaItemDB>[];

    for (var result in results) {
      if (result['title'] == 'Videos' && result['items'] != null) {
        final items = result['items'] as List;
        for (var item in items) {
          try {
            mediaItems.add(MediaItemDB.fromMap(item as Map<String, dynamic>));
          } catch (e) {
            print('Failed to convert item: $e');
          }
        }
      }
    }

    return mediaItems;
  }

  /// Generate AI-powered playlist based on mood
  /// Moods: happy, sad, energetic, calm, romantic, party, workout, focus
  Future<List<MediaItemDB>> generateMoodPlaylist({
    required String mood,
    int limit = 20,
  }) async {
    try {
      // Map moods to search queries
      final moodQueries = {
        'happy': 'happy upbeat songs',
        'sad': 'sad emotional songs',
        'energetic': 'energetic workout songs',
        'calm': 'calm relaxing music',
        'romantic': 'romantic love songs',
        'party': 'party dance songs',
        'workout': 'workout gym music',
        'focus': 'focus study music',
      };

      final query = moodQueries[mood.toLowerCase()] ?? 'popular music';
      final results = await YouTubeServices().fetchSearchResults(query);
      final mediaItems = _convertToMediaItems(results);

      // Return limited results
      return mediaItems.take(limit).toList();
    } catch (e) {
      print('❌ Failed to generate mood playlist: $e');
      return [];
    }
  }

  /// Generate AI-powered playlist based on a seed song
  /// Creates a radio station from the given song
  Future<List<MediaItemDB>> generateRadioFromSong({
    required MediaItemDB seedSong,
    int limit = 20,
  }) async {
    try {
      // Use YouTube Music's radio feature
      final radioResults = await YtMusicService().getWatchPlaylist(
        videoId: seedSong.mediaID ?? '',
      );

      final mediaItems = _convertToMediaItems(radioResults);

      // Return limited results
      return mediaItems.take(limit).toList();
    } catch (e) {
      print('❌ Failed to generate radio playlist: $e');
      return [];
    }
  }

  /// Generate AI-powered playlist based on an artist
  Future<List<MediaItemDB>> generateArtistRadio({
    required String artistName,
    int limit = 20,
  }) async {
    try {
      // Search for artist and get their top songs
      final results =
          await YouTubeServices().fetchSearchResults('$artistName songs');
      final mediaItems = _convertToMediaItems(results);

      // Return limited results
      return mediaItems.take(limit).toList();
    } catch (e) {
      print('❌ Failed to generate artist radio: $e');
      return [];
    }
  }

  /// Generate AI-powered playlist based on genre
  Future<List<MediaItemDB>> generateGenrePlaylist({
    required String genre,
    int limit = 20,
  }) async {
    try {
      final results =
          await YouTubeServices().fetchSearchResults('$genre music');
      final mediaItems = _convertToMediaItems(results);

      // Return limited results
      return mediaItems.take(limit).toList();
    } catch (e) {
      print('❌ Failed to generate genre playlist: $e');
      return [];
    }
  }

  /// Get AI-powered recommendations based on user's listening history
  Future<List<MediaItemDB>> getPersonalizedRecommendations({
    required List<MediaItemDB> likedSongs,
    int limit = 20,
  }) async {
    try {
      if (likedSongs.isEmpty) {
        // Return trending songs if no history
        return await getTrendingSongs(limit: limit);
      }

      // Get a random liked song as seed
      final seedSong =
          likedSongs[DateTime.now().millisecond % likedSongs.length];

      // Generate radio from seed song
      return await generateRadioFromSong(seedSong: seedSong, limit: limit);
    } catch (e) {
      print('❌ Failed to get personalized recommendations: $e');
      return [];
    }
  }

  /// Get trending songs (popular music)
  Future<List<MediaItemDB>> getTrendingSongs({int limit = 20}) async {
    try {
      final results =
          await YouTubeServices().fetchSearchResults('trending songs 2026');
      final mediaItems = _convertToMediaItems(results);

      // Return limited results
      return mediaItems.take(limit).toList();
    } catch (e) {
      print('❌ Failed to get trending songs: $e');
      return [];
    }
  }

  /// Get AI-powered mix based on multiple songs
  Future<List<MediaItemDB>> generateMixFromSongs({
    required List<MediaItemDB> seedSongs,
    int limit = 20,
  }) async {
    try {
      if (seedSongs.isEmpty) {
        return await getTrendingSongs(limit: limit);
      }

      // Use first song as seed
      final seedSong = seedSongs.first;
      return await generateRadioFromSong(seedSong: seedSong, limit: limit);
    } catch (e) {
      print('❌ Failed to generate mix: $e');
      return [];
    }
  }

  /// Get similar songs to a given song
  Future<List<MediaItemDB>> getSimilarSongs({
    required MediaItemDB song,
    int limit = 20,
  }) async {
    try {
      // Search for similar songs
      final query = '${song.artist} ${song.title} similar songs';
      final results = await YouTubeServices().fetchSearchResults(query);
      final mediaItems = _convertToMediaItems(results);

      // Return limited results
      return mediaItems.take(limit).toList();
    } catch (e) {
      print('❌ Failed to get similar songs: $e');
      return [];
    }
  }

  /// Get AI-powered daily mix
  Future<List<MediaItemDB>> getDailyMix({
    required List<MediaItemDB> likedSongs,
    int limit = 30,
  }) async {
    try {
      if (likedSongs.isEmpty) {
        return await getTrendingSongs(limit: limit);
      }

      // Get recommendations based on liked songs
      return await getPersonalizedRecommendations(
        likedSongs: likedSongs,
        limit: limit,
      );
    } catch (e) {
      print('❌ Failed to get daily mix: $e');
      return [];
    }
  }

  /// Get AI-powered discover weekly
  Future<List<MediaItemDB>> getDiscoverWeekly({
    required List<MediaItemDB> likedSongs,
    int limit = 30,
  }) async {
    try {
      if (likedSongs.isEmpty) {
        // Return new releases if no history
        final results =
            await YouTubeServices().fetchSearchResults('new music 2026');
        return _convertToMediaItems(results).take(limit).toList();
      }

      // Get diverse recommendations
      final recommendations = <MediaItemDB>[];

      // Get recommendations from different liked songs
      for (var i = 0; i < 3 && i < likedSongs.length; i++) {
        final radio = await generateRadioFromSong(
          seedSong: likedSongs[i],
          limit: 10,
        );
        recommendations.addAll(radio);
      }

      // Remove duplicates and return
      final uniqueSongs = <String, MediaItemDB>{};
      for (var song in recommendations) {
        uniqueSongs[song.mediaID] = song;
            }

      return uniqueSongs.values.take(limit).toList();
    } catch (e) {
      print('❌ Failed to get discover weekly: $e');
      return [];
    }
  }
}
