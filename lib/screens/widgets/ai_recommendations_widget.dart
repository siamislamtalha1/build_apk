import 'package:Bloomee/blocs/mediaPlayer/bloomee_player_cubit.dart';
import 'package:Bloomee/services/ai_service.dart';
import 'package:Bloomee/services/db/GlobalDB.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:Bloomee/utils/media_item_converter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:go_router/go_router.dart';

/// AI-powered recommendations widget for explore screen
class AIRecommendationsWidget extends StatefulWidget {
  const AIRecommendationsWidget({super.key});

  @override
  State<AIRecommendationsWidget> createState() =>
      _AIRecommendationsWidgetState();
}

class _AIRecommendationsWidgetState extends State<AIRecommendationsWidget> {
  final _aiService = AIService();
  List<MediaItemDB> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);

    try {
      // Get liked songs from the "Liked" playlist
      final likedPlaylist =
          await BloomeeDBService.getPlaylistItemsByName("Liked");
      final likedSongs = likedPlaylist ?? <MediaItemDB>[];

      // Get personalized recommendations
      final recommendations = await _aiService.getPersonalizedRecommendations(
        likedSongs: likedSongs,
        limit: 10,
      );

      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Failed to load recommendations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    MingCute.sparkles_fill,
                    color: Default_Theme.accentColor2,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Recommendations',
                    style: Default_Theme.primaryTextStyle.merge(
                      const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Default_Theme.primaryColor1,
                      ),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.push('/AIPlaylist'),
                child: Text(
                  'Create Playlist',
                  style: Default_Theme.secondoryTextStyle.merge(
                    const TextStyle(
                      color: Default_Theme.accentColor2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Recommendations List
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_recommendations.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    MingCute.music_2_line,
                    size: 48,
                    color: Default_Theme.primaryColor2.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No recommendations yet',
                    style: Default_Theme.secondoryTextStyle.merge(
                      const TextStyle(
                        color: Default_Theme.primaryColor2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/AIPlaylist'),
                    child: const Text('Create AI Playlist'),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recommendations.length,
              itemBuilder: (context, index) {
                final song = _recommendations[index];
                return _buildRecommendationCard(song, index);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRecommendationCard(MediaItemDB song, int index) {
    return GestureDetector(
      onTap: () => _playSong(index),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Art
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: song.artURL != null
                    ? DecorationImage(
                        image: NetworkImage(song.artURL!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: Default_Theme.accentColor2.withValues(alpha: 0.2),
              ),
              child: song.artURL == null
                  ? Icon(
                      MingCute.music_2_fill,
                      size: 48,
                      color: Default_Theme.accentColor2,
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            // Song Title
            Text(
              song.title ?? 'Unknown',
              style: Default_Theme.primaryTextStyle.merge(
                const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Default_Theme.primaryColor1,
                ),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Artist
            Text(
              song.artist ?? 'Unknown Artist',
              style: Default_Theme.secondoryTextStyle.merge(
                const TextStyle(
                  fontSize: 12,
                  color: Default_Theme.primaryColor2,
                ),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _playSong(int index) {
    if (_recommendations.isEmpty) return;

    final mediaItems =
        MediaItemConverter.dbListToMediaItemList(_recommendations);
    final playerCubit = context.read<BloomeePlayerCubit>();
    playerCubit.bloomeePlayer.updateQueue(mediaItems, doPlay: true);
    playerCubit.bloomeePlayer.skipToQueueItem(index);
  }
}

/// Daily Mix widget
class DailyMixWidget extends StatefulWidget {
  const DailyMixWidget({super.key});

  @override
  State<DailyMixWidget> createState() => _DailyMixWidgetState();
}

class _DailyMixWidgetState extends State<DailyMixWidget> {
  final _aiService = AIService();
  List<MediaItemDB> _dailyMix = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDailyMix();
  }

  Future<void> _loadDailyMix() async {
    setState(() => _isLoading = true);

    try {
      // Get liked songs from the "Liked" playlist
      final likedPlaylist =
          await BloomeeDBService.getPlaylistItemsByName("Liked");
      final likedSongs = likedPlaylist ?? <MediaItemDB>[];

      // Get daily mix
      final mix = await _aiService.getDailyMix(
        likedSongs: likedSongs,
        limit: 30,
      );

      setState(() {
        _dailyMix = mix;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Failed to load daily mix: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_dailyMix.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: _playDailyMix,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Default_Theme.accentColor2.withValues(alpha: 0.3),
                Default_Theme.accentColor2.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Default_Theme.accentColor2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  MingCute.sparkles_fill,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Mix',
                      style: Default_Theme.primaryTextStyle.merge(
                        const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Default_Theme.primaryColor1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_dailyMix.length} songs curated for you',
                      style: Default_Theme.secondoryTextStyle.merge(
                        const TextStyle(
                          fontSize: 14,
                          color: Default_Theme.primaryColor2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                MingCute.play_circle_fill,
                color: Default_Theme.accentColor2,
                size: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _playDailyMix() {
    if (_dailyMix.isEmpty) return;

    final mediaItems = MediaItemConverter.dbListToMediaItemList(_dailyMix);
    final playerCubit = context.read<BloomeePlayerCubit>();
    playerCubit.bloomeePlayer.updateQueue(mediaItems, doPlay: true);
  }
}
