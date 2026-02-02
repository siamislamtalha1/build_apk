import 'package:Bloomee/blocs/mediaPlayer/bloomee_player_cubit.dart';
import 'package:Bloomee/services/ai_service.dart';
import 'package:Bloomee/services/db/GlobalDB.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:Bloomee/utils/load_Image.dart';
import 'package:Bloomee/utils/media_item_converter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';

/// Discover Weekly screen - AI-powered weekly music discovery
class DiscoverWeeklyScreen extends StatefulWidget {
  const DiscoverWeeklyScreen({super.key});

  @override
  State<DiscoverWeeklyScreen> createState() => _DiscoverWeeklyScreenState();
}

class _DiscoverWeeklyScreenState extends State<DiscoverWeeklyScreen> {
  final _aiService = AIService();
  List<MediaItemDB> _discoverWeekly = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiscoverWeekly();
  }

  Future<void> _loadDiscoverWeekly() async {
    setState(() => _isLoading = true);

    try {
      // Get liked songs from the "Liked" playlist
      final likedPlaylist =
          await BloomeeDBService.getPlaylistItemsByName("Liked");
      final likedSongs = likedPlaylist ?? <MediaItemDB>[];

      // Get discover weekly
      final songs = await _aiService.getDiscoverWeekly(
        likedSongs: likedSongs,
        limit: 30,
      );

      setState(() {
        _discoverWeekly = songs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Failed to load discover weekly: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Default_Theme.themeColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Default_Theme.themeColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Default_Theme.accentColor2.withValues(alpha: 0.4),
                      Default_Theme.themeColor,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Default_Theme.accentColor2,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        MingCute.sparkles_fill,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Discover Weekly',
                      style: Default_Theme.primaryTextStyle.merge(
                        TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Default_Theme.primaryColor1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your personalized weekly playlist',
                      style: Default_Theme.secondoryTextStyle.merge(
                        TextStyle(
                          fontSize: 14,
                          color: Default_Theme.primaryColor2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_discoverWeekly.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      MingCute.music_2_line,
                      size: 64,
                      color: Default_Theme.primaryColor2.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No songs available',
                      style: Default_Theme.primaryTextStyle.merge(
                        TextStyle(
                          fontSize: 18,
                          color: Default_Theme.primaryColor2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Like some songs to get personalized recommendations',
                      textAlign: TextAlign.center,
                      style: Default_Theme.secondoryTextStyle.merge(
                        TextStyle(
                          fontSize: 14,
                          color: Default_Theme.primaryColor2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Play All Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _playAll,
                        icon: const Icon(MingCute.play_fill),
                        label: Text(
                          'Play All (${_discoverWeekly.length} songs)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Default_Theme.accentColor2,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Song List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _discoverWeekly.length,
                      itemBuilder: (context, index) {
                        final song = _discoverWeekly[index];
                        return _buildSongTile(song, index);
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSongTile(MediaItemDB song, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Default_Theme.primaryColor1.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: safeImageProvider(song.artURL),
              fit: BoxFit.cover,
            ),
            color: Default_Theme.accentColor2.withValues(alpha: 0.2),
          ),
          child: null,
        ),
        title: Text(
          song.title ?? 'Unknown',
          style: Default_Theme.primaryTextStyle.merge(
            TextStyle(
              fontSize: 14,
              color: Default_Theme.primaryColor1,
            ),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          song.artist ?? 'Unknown Artist',
          style: Default_Theme.secondoryTextStyle.merge(
            TextStyle(
              fontSize: 12,
              color: Default_Theme.primaryColor2,
            ),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#${index + 1}',
              style: Default_Theme.secondoryTextStyle.merge(
                TextStyle(
                  fontSize: 12,
                  color: Default_Theme.primaryColor2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(MingCute.play_fill),
              color: Default_Theme.accentColor2,
              onPressed: () => _playSong(index),
            ),
          ],
        ),
      ),
    );
  }

  void _playAll() {
    if (_discoverWeekly.isEmpty) return;

    final mediaItems =
        MediaItemConverter.dbListToMediaItemList(_discoverWeekly);
    final playerCubit = context.read<BloomeePlayerCubit>();
    playerCubit.bloomeePlayer.updateQueue(mediaItems, doPlay: true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing ${_discoverWeekly.length} songs'),
        backgroundColor: Default_Theme.accentColor2,
      ),
    );
  }

  void _playSong(int index) {
    if (_discoverWeekly.isEmpty) return;

    final mediaItems =
        MediaItemConverter.dbListToMediaItemList(_discoverWeekly);
    final playerCubit = context.read<BloomeePlayerCubit>();
    playerCubit.bloomeePlayer.updateQueue(mediaItems, doPlay: true);
    playerCubit.bloomeePlayer.skipToQueueItem(index);
  }
}
