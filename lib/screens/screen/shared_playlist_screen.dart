import 'package:Bloomee/model/MediaPlaylistModel.dart';
import 'package:Bloomee/model/songModel.dart';
import 'package:Bloomee/screens/screen/library_views/cubit/current_playlist_cubit.dart';
import 'package:Bloomee/screens/widgets/snackbar.dart';
import 'package:Bloomee/services/db/GlobalDB.dart';
import 'package:Bloomee/services/firebase/firestore_service.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SharedPlaylistHandler extends StatefulWidget {
  final String shareId;
  const SharedPlaylistHandler({super.key, required this.shareId});

  @override
  State<SharedPlaylistHandler> createState() => _SharedPlaylistHandlerState();
}

class _SharedPlaylistHandlerState extends State<SharedPlaylistHandler> {
  String _status = 'Resolving link...';
  bool _error = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveAndNavigate();
    });
  }

  Future<void> _resolveAndNavigate() async {
    final fs = FirestoreService();
    try {
      setState(() {
        _status = 'Fetching playlist info...';
      });

      // 1. Resolve Share ID to get metadata
      final sharedMetadata = await fs.resolveSharedPlaylist(widget.shareId);
      if (sharedMetadata == null) {
        throw Exception('Playlist not found or link expired');
      }

      final ownerUid = sharedMetadata['ownerUid'] as String?;
      final playlistName = sharedMetadata['playlistName'] as String?;

      if (ownerUid == null || playlistName == null) {
        throw Exception('Invalid playlist data');
      }

      setState(() {
        _status = 'Loading songs...';
      });

      // 2. Fetch Playlist Items
      final header =
          await fs.getPlaylistHeaderFromCloud(ownerUid, playlistName);
      final itemsData =
          await fs.getPlaylistItemsFromCloud(ownerUid, playlistName);

      if (header == null) {
        throw Exception('Playlist header not found');
      }

      // 3. Convert to MediaPlaylist
      final List<MediaItemModel> mediaItems = itemsData.map((data) {
        final itemDB = MediaItemDB.fromMap(data);
        return MediaItemDB2MediaItem(itemDB);
      }).toList();

      final playlist = MediaPlaylist(
        playlistName: playlistName,
        mediaItems: mediaItems,
        artists: header['usernameLower'] != null
            ? "@${header['usernameLower']}"
            : "Unknown User",
        imgUrl: header['imgUrl'], // If available
      );

      if (!mounted) return;

      // 4. Set to Cubit
      await context.read<CurrentPlaylistCubit>().setPlaylist(playlist);

      if (!mounted) return;

      // 5. Navigate to PlaylistView
      // We use push replacement to replace this loading screen
      // But we target the route '/Library/PlaylistView'?
      // Or just '/PlaylistView'?
      // GlobalRoutes defines it as nested in Library: '/Library/PlaylistView'
      context.go('/Library/PlaylistView');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Error: $e';
        _error = true;
      });
      SnackbarService.showMessage('Failed to load shared playlist: $e');

      // Redirect to explore after delay?
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) context.go('/Explore');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Default_Theme.themeColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_error) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
            ] else ...[
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 20),
            ],
            Text(
              _status,
              style: Default_Theme.secondoryTextStyle,
              textAlign: TextAlign.center,
            ),
            if (_error)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: () => context.go('/Explore'),
                  child: const Text('Go Home'),
                ),
              )
          ],
        ),
      ),
    );
  }
}
