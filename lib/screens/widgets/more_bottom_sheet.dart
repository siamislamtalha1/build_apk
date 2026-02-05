import 'package:Bloomee/blocs/add_to_playlist/cubit/add_to_playlist_cubit.dart';
import 'package:Bloomee/blocs/downloader/cubit/downloader_cubit.dart';
import 'package:Bloomee/blocs/mediaPlayer/bloomee_player_cubit.dart';
import 'package:Bloomee/model/songModel.dart';
import 'package:Bloomee/routes_and_consts/global_str_consts.dart';
import 'package:Bloomee/screens/widgets/snackbar.dart';
import 'package:Bloomee/screens/widgets/song_tile.dart';
import 'package:Bloomee/services/db/GlobalDB.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:Bloomee/services/db/cubit/bloomee_db_cubit.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:Bloomee/services/import_export_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void showMoreBottomSheet(
  BuildContext context,
  MediaItemModel song, {
  bool showDelete = false,
  bool showSinglePlay = false,
  bool showAddToQueue = true,
  bool showPlayNext = true,
  VoidCallback? onDelete,
}) {
  bool? isDownloaded;
  BloomeeDBService.getDownloadDB(song).then((value) {
    if (value != null) {
      isDownloaded = true;
    } else {
      isDownloaded = false;
    }
  });
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isDark ? scheme.surfaceContainerHighest : scheme.surface,
                scheme.surface,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 1.0],
            ),
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    top: 12, bottom: 8, left: 5, right: 4),
                child: SongCardWidget(
                  song: song,
                  showOptions: false,
                  showCopyBtn: true,
                  showInfoBtn: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10, left: 10),
                child: Opacity(
                  opacity: 0.5,
                  child: Divider(
                    thickness: 2,
                    color: Default_Theme.primaryColor1,
                  ),
                ),
              ),
              (showSinglePlay)
                  ? ListTile(
                      leading: Icon(
                        MingCute.play_circle_fill,
                        color: Default_Theme.primaryColor1,
                        size: 28,
                      ),
                      title: Text(
                        'Play with Mix',
                        style: TextStyle(
                            color: Default_Theme.primaryColor1,
                            fontFamily: "Unageo",
                            fontSize: 17,
                            fontWeight: FontWeight.w400),
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        context
                            .read<BloomeePlayerCubit>()
                            .bloomeePlayer
                            .updateQueue([song], doPlay: true);
                        SnackbarService.showMessage("Playing ${song.title}",
                            duration: const Duration(seconds: 2));
                      },
                    )
                  : const SizedBox.shrink(),
              (showPlayNext)
                  ? ListTile(
                      leading: Icon(
                        MingCute.square_arrow_right_line,
                        color: Default_Theme.primaryColor1,
                        size: 28,
                      ),
                      title: Text(
                        'Play Next',
                        style: TextStyle(
                            color: Default_Theme.primaryColor1,
                            fontFamily: "Unageo",
                            fontSize: 17,
                            fontWeight: FontWeight.w400),
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        context
                            .read<BloomeePlayerCubit>()
                            .bloomeePlayer
                            .addPlayNextItem(song);
                        SnackbarService.showMessage("Added to Next in Queue",
                            duration: const Duration(seconds: 2));
                      },
                    )
                  : const SizedBox.shrink(),
              (showAddToQueue)
                  ? ListTile(
                      leading: Icon(
                        MingCute.playlist_2_line,
                        color: Default_Theme.primaryColor1,
                        size: 28,
                      ),
                      title: Text(
                        'Add to Queue',
                        style: TextStyle(
                            color: Default_Theme.primaryColor1,
                            fontFamily: "Unageo",
                            fontSize: 17,
                            fontWeight: FontWeight.w400),
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        context
                            .read<BloomeePlayerCubit>()
                            .bloomeePlayer
                            .addQueueItem(song);
                        SnackbarService.showMessage("Added to Queue",
                            duration: const Duration(seconds: 2));
                      },
                    )
                  : const SizedBox.shrink(),
              (showAddToQueue)
                  ? ListTile(
                      leading: Icon(
                        Icons.format_list_numbered_rounded,
                        color: Default_Theme.primaryColor1,
                        size: 28,
                      ),
                      title: Text(
                        'Insert into Queue',
                        style: TextStyle(
                            color: Default_Theme.primaryColor1,
                            fontFamily: "Unageo",
                            fontSize: 17,
                            fontWeight: FontWeight.w400),
                      ),
                      onTap: () async {
                        final player =
                            context.read<BloomeePlayerCubit>().bloomeePlayer;
                        final queueLength = player.queue.value.length;
                        final currentIdx = player.audioPlayer.currentIndex ?? 0;
                        int selectedPos =
                            (currentIdx + 2).clamp(1, queueLength + 1);

                        Navigator.pop(sheetContext);

                        final int? chosen = await showDialog<int>(
                          context: context,
                          builder: (dialogContext) {
                            return AlertDialog(
                              backgroundColor: Default_Theme.themeColor,
                              title: const Text(
                                'Insert into Queue',
                                style: Default_Theme.secondoryTextStyleMedium,
                              ),
                              content: StatefulBuilder(
                                builder: (context, setState) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      NumberPicker(
                                        minValue: 1,
                                        maxValue: queueLength + 1,
                                        value: selectedPos,
                                        axis: Axis.horizontal,
                                        onChanged: (val) =>
                                            setState(() => selectedPos = val),
                                        textStyle: TextStyle(
                                            color: Default_Theme.primaryColor1
                                                .withValues(alpha: 0.6)),
                                        selectedTextStyle: TextStyle(
                                            color: Default_Theme.primaryColor1,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Position $selectedPos of ${queueLength + 1}',
                                        style: TextStyle(
                                            color: Default_Theme.primaryColor1
                                                .withValues(alpha: 0.8)),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Default_Theme.accentColor1,
                                    foregroundColor:
                                        Default_Theme.primaryColor2,
                                  ),
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, selectedPos),
                                  child: const Text('Insert'),
                                ),
                              ],
                            );
                          },
                        );

                        if (chosen == null) return;
                        await player.insertQueueItem(chosen - 1, song);
                        SnackbarService.showMessage(
                          'Inserted into queue at position $chosen',
                          duration: const Duration(seconds: 2),
                        );
                      },
                    )
                  : const SizedBox.shrink(),
              ListTile(
                leading: Icon(
                  MingCute.heart_fill,
                  color: Default_Theme.primaryColor1,
                  size: 28,
                ),
                title: Text(
                  'Add to Favorites',
                  style: TextStyle(
                      color: Default_Theme.primaryColor1,
                      fontFamily: "Unageo",
                      fontSize: 17,
                      fontWeight: FontWeight.w400),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.read<BloomeeDBCubit>().addMediaItemToPlaylist(
                      song, MediaPlaylistDB(playlistName: "Liked"));
                  // SnackbarService.showMessage("Added to Favorites",
                  //     duration: const Duration(seconds: 2));
                },
              ),
              ListTile(
                leading: Icon(
                  MingCute.add_circle_fill,
                  color: Default_Theme.primaryColor1,
                  size: 28,
                ),
                title: Text(
                  'Add to Playlist',
                  style: TextStyle(
                      color: Default_Theme.primaryColor1,
                      fontFamily: "Unageo",
                      fontSize: 17,
                      fontWeight: FontWeight.w400),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.read<AddToPlaylistCubit>().setMediaItemModel(song);
                  context.pushNamed(GlobalStrConsts.addToPlaylistScreen);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.share,
                  color: Default_Theme.primaryColor1,
                  size: 28,
                ),
                title: Text(
                  'Share',
                  style: TextStyle(
                    color: Default_Theme.primaryColor1,
                    fontFamily: "Unageo",
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  SnackbarService.showMessage(
                      "Preparing ${song.title} for share.");
                  final tmpPath = await ImportExportService.exportMediaItem(
                      MediaItem2MediaItemDB(song));
                  tmpPath != null ? Share.shareXFiles([XFile(tmpPath)]) : null;
                },
              ),
              (isDownloaded != null && isDownloaded == true)
                  ? ListTile(
                      leading: Icon(
                        Icons.offline_pin_rounded,
                        color: Default_Theme.primaryColor1,
                        size: 28,
                      ),
                      title: Text(
                        'Available Offline',
                        style: TextStyle(
                          color: Default_Theme.primaryColor1,
                          fontFamily: "Unageo",
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        // context.read<DownloaderCubit>().downloadSong(song);
                      },
                    )
                  : ListTile(
                      leading: Icon(
                        MingCute.download_2_fill,
                        color: Default_Theme.primaryColor1,
                        size: 28,
                      ),
                      title: Text(
                        'Download',
                        style: TextStyle(
                          color: Default_Theme.primaryColor1,
                          fontFamily: "Unageo",
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        context.read<DownloaderCubit>().downloadSong(song);
                      },
                    ),
              // : const SizedBox.shrink(),
              ListTile(
                leading: Icon(
                  MingCute.external_link_line,
                  color: Default_Theme.primaryColor1,
                  size: 28,
                ),
                title: Text(
                  'Open original link',
                  style: TextStyle(
                    color: Default_Theme.primaryColor1,
                    fontFamily: "Unageo",
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  launchUrl(Uri.parse(song.extras?['perma_url']));
                },
              ),
              Visibility(
                visible: showDelete,
                child: ListTile(
                  leading: Icon(
                    MingCute.delete_2_fill,
                    color: Default_Theme.primaryColor1,
                    size: 28,
                  ),
                  title: Text(
                    'Delete',
                    style: TextStyle(
                      color: Default_Theme.primaryColor1,
                      fontFamily: "Unageo",
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    if (onDelete != null) onDelete();
                  },
                ),
              ),
            ],
          ),
        );
      });
}
