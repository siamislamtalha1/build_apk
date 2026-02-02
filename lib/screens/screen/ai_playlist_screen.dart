import 'package:Bloomee/blocs/mediaPlayer/bloomee_player_cubit.dart';
import 'package:Bloomee/services/ai_service.dart';
import 'package:Bloomee/services/db/GlobalDB.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:Bloomee/utils/load_Image.dart';
import 'package:Bloomee/utils/media_item_converter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';

/// AI-powered playlist creation screen
class AIPlaylistScreen extends StatefulWidget {
  const AIPlaylistScreen({super.key});

  @override
  State<AIPlaylistScreen> createState() => _AIPlaylistScreenState();
}

class _AIPlaylistScreenState extends State<AIPlaylistScreen> {
  final _aiService = AIService();
  bool _isLoading = false;
  List<MediaItemDB> _generatedSongs = [];
  String _selectedMood = 'happy';

  final _moods = [
    {'name': 'Happy', 'value': 'happy', 'icon': MingCute.emoji_line},
    {'name': 'Sad', 'value': 'sad', 'icon': MingCute.sad_line},
    {
      'name': 'Energetic',
      'value': 'energetic',
      'icon': MingCute.lightning_line
    },
    {'name': 'Calm', 'value': 'calm', 'icon': MingCute.leaf_line},
    {'name': 'Romantic', 'value': 'romantic', 'icon': MingCute.heart_fill},
    {'name': 'Party', 'value': 'party', 'icon': MingCute.celebrate_line},
    {'name': 'Workout', 'value': 'workout', 'icon': MingCute.fire_line},
    {'name': 'Focus', 'value': 'focus', 'icon': MingCute.brain_line},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Default_Theme.themeColor,
      appBar: AppBar(
        backgroundColor: Default_Theme.themeColor,
        elevation: 0,
        title: Text(
          'AI Playlist Generator',
          style: Default_Theme.primaryTextStyle.merge(
            TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Default_Theme.primaryColor1,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(MingCute.arrow_left_line),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
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
                  Icon(
                    MingCute.sparkles_fill,
                    size: 40,
                    color: Default_Theme.accentColor2,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI-Powered Playlists',
                          style: Default_Theme.primaryTextStyle.merge(
                            TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Default_Theme.primaryColor1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Let AI create the perfect playlist for your mood',
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
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Mood Selection
            Text(
              'Select Your Mood',
              style: Default_Theme.primaryTextStyle.merge(
                TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Default_Theme.primaryColor1,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Mood Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _moods.length,
              itemBuilder: (context, index) {
                final mood = _moods[index];
                final isSelected = _selectedMood == mood['value'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMood = mood['value'] as String;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Default_Theme.accentColor2.withValues(alpha: 0.2)
                          : Default_Theme.primaryColor1.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Default_Theme.accentColor2
                            : Default_Theme.primaryColor1
                                .withValues(alpha: 0.1),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          mood['icon'] as IconData,
                          size: 32,
                          color: isSelected
                              ? Default_Theme.accentColor2
                              : Default_Theme.primaryColor2,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mood['name'] as String,
                          style: Default_Theme.secondoryTextStyle.merge(
                            TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Default_Theme.accentColor2
                                  : Default_Theme.primaryColor2,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Generate Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generatePlaylist,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(MingCute.sparkles_fill),
                label: Text(
                  _isLoading ? 'Generating...' : 'Generate Playlist',
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

            // Generated Playlist
            if (_generatedSongs.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Generated Playlist',
                    style: Default_Theme.primaryTextStyle.merge(
                      TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Default_Theme.primaryColor1,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _playAll,
                    icon: const Icon(MingCute.play_fill, size: 18),
                    label: const Text('Play All'),
                    style: TextButton.styleFrom(
                      foregroundColor: Default_Theme.accentColor2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Song List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _generatedSongs.length,
                itemBuilder: (context, index) {
                  final song = _generatedSongs[index];
                  return _buildSongTile(song, index);
                },
              ),
            ],
          ],
        ),
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
        trailing: IconButton(
          icon: const Icon(MingCute.play_fill),
          color: Default_Theme.accentColor2,
          onPressed: () => _playSong(index),
        ),
      ),
    );
  }

  Future<void> _generatePlaylist() async {
    setState(() {
      _isLoading = true;
      _generatedSongs = [];
    });

    try {
      final songs = await _aiService.generateMoodPlaylist(
        mood: _selectedMood,
        limit: 20,
      );

      setState(() {
        _generatedSongs = songs;
        _isLoading = false;
      });

      if (songs.isEmpty) {
        _showMessage('Failed to generate playlist. Please try again.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Error generating playlist: $e');
    }
  }

  void _playAll() {
    if (_generatedSongs.isEmpty) return;

    final mediaItems =
        MediaItemConverter.dbListToMediaItemList(_generatedSongs);
    final playerCubit = context.read<BloomeePlayerCubit>();
    playerCubit.bloomeePlayer.updateQueue(mediaItems, doPlay: true);

    _showMessage('Playing ${_generatedSongs.length} songs');
  }

  void _playSong(int index) {
    if (_generatedSongs.isEmpty) return;

    final mediaItems =
        MediaItemConverter.dbListToMediaItemList(_generatedSongs);
    final playerCubit = context.read<BloomeePlayerCubit>();
    // First update the queue
    playerCubit.bloomeePlayer.updateQueue(mediaItems, doPlay: true);
    // Then skip to the desired index
    playerCubit.bloomeePlayer.skipToQueueItem(index);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Default_Theme.accentColor2,
      ),
    );
  }
}
