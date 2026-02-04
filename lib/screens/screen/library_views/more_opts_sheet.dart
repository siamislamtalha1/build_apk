import 'dart:io';

import 'package:Bloomee/blocs/library/cubit/library_items_cubit.dart';
import 'package:Bloomee/blocs/mediaPlayer/bloomee_player_cubit.dart';
import 'package:Bloomee/model/MediaPlaylistModel.dart';
import 'package:Bloomee/screens/screen/library_views/playlist_edit_view.dart';
import 'package:Bloomee/screens/widgets/snackbar.dart';
import 'package:Bloomee/services/db/GlobalDB.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:Bloomee/screens/screen/library_views/cubit/current_playlist_cubit.dart';
import 'package:Bloomee/blocs/auth/auth_cubit.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:Bloomee/services/import_export_service.dart';
import 'package:Bloomee/services/firebase/firestore_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

void showPlaylistOptsInrSheet(
    BuildContext context, MediaPlaylist mediaPlaylist) {
  showFloatingModalBottomSheet(
    context: context,
    builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 7, 17, 50),
                    Color.fromARGB(255, 5, 0, 24),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.5]),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  PltOptBtn(
                    title: "Toggle Public/Private",
                    icon: MingCute.lock_line,
                    onPressed: () async {
                      Navigator.pop(context);
                      final auth = context.read<AuthCubit>();
                      final user = auth.currentUser;
                      if (user == null || user.isAnonymous) {
                        SnackbarService.showMessage(
                            'Login required to change visibility');
                        return;
                      }
                      final fs = FirestoreService();
                      try {
                        final header = await fs.getPlaylistHeaderFromCloud(
                            user.uid, mediaPlaylist.playlistName);
                        final cur = header?['isPublic'] == true;
                        await fs.setPlaylistVisibility(
                          userId: user.uid,
                          playlistName: mediaPlaylist.playlistName,
                          isPublic: !cur,
                        );
                        SnackbarService.showMessage(!cur
                            ? 'Playlist is now Public'
                            : 'Playlist is now Private');
                      } catch (e) {
                        SnackbarService.showMessage('Failed: $e');
                      }
                    },
                  ),
                  PltOptBtn(
                    title: "Share Link",
                    icon: MingCute.link_2_line,
                    onPressed: () async {
                      Navigator.pop(context);
                      final auth = context.read<AuthCubit>();
                      final user = auth.currentUser;
                      if (user == null || user.isAnonymous) {
                        SnackbarService.showMessage(
                            'Login required to create share link');
                        return;
                      }
                      final fs = FirestoreService();
                      try {
                        await fs.setPlaylistVisibility(
                          userId: user.uid,
                          playlistName: mediaPlaylist.playlistName,
                          isPublic: true,
                        );
                        final shareId = await fs.ensurePlaylistShareId(
                          userId: user.uid,
                          playlistName: mediaPlaylist.playlistName,
                        );
                        final url = fs.buildPlaylistShareUrl(shareId);
                        await Clipboard.setData(ClipboardData(text: url));
                        SnackbarService.showMessage('Link copied to clipboard');
                      } catch (e) {
                        SnackbarService.showMessage('Failed: $e');
                      }
                    },
                  ),
                  PltOptBtn(
                    title: "Rename Playlist",
                    icon: MingCute.edit_line,
                    onPressed: () async {
                      Navigator.pop(context);
                      final controller = TextEditingController(
                          text: mediaPlaylist.playlistName);
                      final newName = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            backgroundColor: Default_Theme.themeColor,
                            title: const Text('Rename playlist'),
                            content: TextField(
                              controller: controller,
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText: 'New playlist name',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, controller.text),
                                child: const Text('Rename'),
                              ),
                            ],
                          );
                        },
                      );

                      final next = newName?.trim() ?? '';
                      if (next.isEmpty || next.length < 3) {
                        SnackbarService.showMessage(
                            'Playlist name must be at least 3 characters');
                        return;
                      }

                      final ok = await context
                          .read<CurrentPlaylistCubit>()
                          .renamePlaylist(next);
                      if (ok) {
                        SnackbarService.showMessage('Playlist renamed');
                      } else {
                        SnackbarService.showMessage(
                            'Rename failed (name may already exist)');
                      }
                    },
                  ),
                  PltOptBtn(
                    title: "Duplicate Playlist",
                    icon: MingCute.copy_2_line,
                    onPressed: () async {
                      Navigator.pop(context);
                      final suggested =
                          await BloomeeDBService.generateUniquePlaylistName(
                              '${mediaPlaylist.playlistName} Copy');
                      final controller = TextEditingController(text: suggested);
                      final name = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            backgroundColor: Default_Theme.themeColor,
                            title: const Text('Duplicate playlist'),
                            content: TextField(
                              controller: controller,
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText: 'New playlist name',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, controller.text),
                                child: const Text('Duplicate'),
                              ),
                            ],
                          );
                        },
                      );
                      final next = name?.trim() ?? '';
                      if (next.isEmpty || next.length < 3) {
                        SnackbarService.showMessage(
                            'Playlist name must be at least 3 characters');
                        return;
                      }
                      final res = await BloomeeDBService.duplicatePlaylist(
                        mediaPlaylist.playlistName,
                        newPlaylistName: next,
                      );
                      if (res != null) {
                        SnackbarService.showMessage('Playlist duplicated');
                      } else {
                        SnackbarService.showMessage(
                            'Duplicate failed (name may already exist)');
                      }
                    },
                  ),
                  PltOptBtn(
                    title: "Edit Playlist",
                    icon: MingCute.edit_2_line,
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PlaylistEditView()));
                      // context.go(GlobalStrConsts.editPlaylistScreen,
                      //     params: {'playlistName': mediaPlaylist.playlistName});
                    },
                  ),
                  // PltOptBtn(
                  //   title: "Sync Playlist",
                  //   icon: MingCute.refresh_1_line,
                  //   onPressed: () {
                  //     Navigator.pop(context);
                  //     SnackbarService.showMessage(
                  //         "Syncing ${mediaPlaylist.playlistName}");
                  //     // context.go(GlobalStrConsts.syncPlaylistScreen,
                  //     //     params: {'playlistName': mediaPlaylist.playlistName});
                  //   },
                  // ),
                  PltOptBtn(
                    icon: MingCute.share_2_line,
                    title: "Share file",
                    onPressed: () async {
                      Navigator.pop(context);
                      SnackbarService.showMessage(
                          "Preparing ${mediaPlaylist.playlistName} for share");
                      final tmpPath = await ImportExportService.exportPlaylist(
                          mediaPlaylist.playlistName);
                      tmpPath != null
                          ? SharePlus.instance
                              .share(ShareParams(files: [XFile(tmpPath)]))
                          : null;
                    },
                  ),
                  if (!Platform.isAndroid)
                    PltOptBtn(
                      icon: MingCute.file_export_line,
                      title: "Export File",
                      onPressed: () async {
                        Navigator.pop(context);
                        String? path =
                            await FilePicker.platform.getDirectoryPath();
                        if (path == null || path == "/") {
                          path =
                              (await getDownloadsDirectory())?.path.toString();
                        }
                        SnackbarService.showMessage(
                            "Preparing ${mediaPlaylist.playlistName} for export.");
                        final tmpPath =
                            await ImportExportService.exportPlaylist(
                          mediaPlaylist.playlistName,
                          filePath: path,
                        );
                        SnackbarService.showMessage("Exported to: $tmpPath");
                      },
                    ),
                ],
              ),
            ),
          )
        ],
      );
    },
  );
}

void showPlaylistOptsExtSheet(BuildContext context, String playlistName) {
  showFloatingModalBottomSheet(
    context: context,
    builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 7, 17, 50),
                    Color.fromARGB(255, 5, 0, 24),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.5]),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  PltOptBtn(
                    icon: MingCute.play_circle_fill,
                    title: "Play",
                    onPressed: () async {
                      Navigator.pop(context);
                      final list = await context
                          .read<LibraryItemsCubit>()
                          .getPlaylist(playlistName);
                      if (list != null && list.isNotEmpty) {
                        context
                            .read<BloomeePlayerCubit>()
                            .bloomeePlayer
                            .loadPlaylist(
                                MediaPlaylist(
                                    mediaItems: list,
                                    playlistName: playlistName),
                                doPlay: true);
                        SnackbarService.showMessage("Playing $playlistName");
                      }
                    },
                  ),
                  PltOptBtn(
                    title: 'Add Playlist to Queue',
                    icon: MingCute.playlist_2_line,
                    onPressed: () async {
                      Navigator.pop(context);
                      final list = await context
                          .read<LibraryItemsCubit>()
                          .getPlaylist(playlistName);
                      if (list != null && list.isNotEmpty) {
                        context
                            .read<BloomeePlayerCubit>()
                            .bloomeePlayer
                            .addQueueItems(list);
                        SnackbarService.showMessage(
                            "Added $playlistName to Queue");
                      }
                    },
                  ),
                  PltOptBtn(
                    icon: MingCute.share_2_fill,
                    title: "Share Playlist",
                    onPressed: () async {
                      Navigator.pop(context);
                      SnackbarService.showMessage(
                          "Preparing $playlistName for share");
                      final tmpPath = await ImportExportService.exportPlaylist(
                          playlistName);
                      tmpPath != null
                          ? SharePlus.instance
                              .share(ShareParams(files: [XFile(tmpPath)]))
                          : null;
                    },
                  ),
                  if (!Platform.isAndroid)
                    PltOptBtn(
                      icon: MingCute.file_export_line,
                      title: "Export File",
                      onPressed: () async {
                        Navigator.pop(context);
                        String? path =
                            await FilePicker.platform.getDirectoryPath();
                        if (path == null || path == "/") {
                          path =
                              (await getDownloadsDirectory())?.path.toString();
                        }
                        SnackbarService.showMessage(
                            "Preparing $playlistName for export.");
                        final tmpPath =
                            await ImportExportService.exportPlaylist(
                          playlistName,
                          filePath: path,
                        );
                        SnackbarService.showMessage("Exported to: $tmpPath");
                      },
                    ),
                  PltOptBtn(
                    title: 'Delete Playlist',
                    icon: MingCute.delete_2_fill,
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<LibraryItemsCubit>().removePlaylist(
                          MediaPlaylistDB(playlistName: playlistName));
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

class PltOptBtn extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onPressed;
  const PltOptBtn({
    super.key,
    required this.icon,
    required this.title,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Row(
        children: [
          Icon(
            icon,
            color: Default_Theme.primaryColor1,
            size: 25,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: Text(
                title,
                style: TextStyle(
                    color: Default_Theme.primaryColor1,
                    fontFamily: "Unageo",
                    fontSize: 17,
                    fontWeight: FontWeight.w400),
              ),
            ),
          ),
        ],
      ),
      onPressed: onPressed,
      hoverColor: Default_Theme.primaryColor1.withValues(alpha: 0.04),
    );
  }
}

Future<T> showFloatingModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
}) async {
  final result = await showCustomModalBottomSheet(
      context: context,
      builder: builder,
      containerWidget: (_, animation, child) => FloatingModal(
            child: child,
          ),
      expand: false);

  return result;
}

class FloatingModal extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const FloatingModal({super.key, required this.child, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Material(
          color: backgroundColor,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      ),
    );
  }
}
