import 'package:Bloomee/screens/widgets/snackbar.dart';
import 'package:Bloomee/screens/widgets/sign_board_widget.dart';
import 'package:Bloomee/services/db/GlobalDB.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:Bloomee/services/firebase/firestore_service.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:Bloomee/screens/widgets/glass_widgets.dart';

Future<List<String>?> _pickTargetLocalPlaylists(
  BuildContext context, {
  required String title,
}) async {
  final playlistsDb = await BloomeeDBService.getAllPlaylistsDB();
  final names = playlistsDb
      .map((e) => e.playlistName)
      .where((n) => !BloomeeDBService.standardPlaylists.contains(n))
      .toList();

  final selected = <String>{};
  final createController = TextEditingController();

  final res = await showDialog<List<String>>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx2, setState) {
        return GlassDialog(
          title: Text(title),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: createController,
                  decoration: const InputDecoration(
                    labelText: 'Create new playlist (optional)',
                    hintText: 'New playlist name',
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: names.length,
                    itemBuilder: (c, i) {
                      final name = names[i];
                      final checked = selected.contains(name);
                      return CheckboxListTile(
                        value: checked,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              selected.add(name);
                            } else {
                              selected.remove(name);
                            }
                          });
                        },
                        title: Text(
                          name,
                          style: Default_Theme.secondoryTextStyle.merge(
                            TextStyle(color: Default_Theme.primaryColor1),
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final created = createController.text.trim();
                final all = <String>{...selected};
                if (created.isNotEmpty) {
                  final exists = await BloomeeDBService.playlistExists(created);
                  if (exists) {
                    SnackbarService.showMessage(
                        'Playlist "$created" already exists');
                    return;
                  }
                  await BloomeeDBService.createPlaylist(created);
                  all.add(created);
                }
                if (all.isEmpty) {
                  SnackbarService.showMessage('Select at least one playlist');
                  return;
                }
                if (ctx.mounted) Navigator.pop(ctx, all.toList());
              },
              child: const Text('Save'),
            ),
          ],
        );
      });
    },
  );
  return res;
}

Future<void> _showRemotePlaylistDialog(
  BuildContext context, {
  required FirestoreService fs,
  required Map<String, dynamic> header,
}) async {
  final ownerUid = header['ownerUid'] as String?;
  final playlistName = header['playlistName'] as String?;
  if (ownerUid == null || playlistName == null) return;

  final itemsRaw = await fs.getPlaylistItemsFromCloud(ownerUid, playlistName);
  final items = <MediaItemDB>[];
  for (final m in itemsRaw) {
    try {
      items.add(MediaItemDB.fromMap(m));
    } catch (_) {}
  }

  final selected = <int>{};

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx2, setState) {
        final allSelected = items.isNotEmpty && selected.length == items.length;

        Future<void> saveSelectedToPlaylists() async {
          if (selected.isEmpty) {
            SnackbarService.showMessage('No songs selected');
            return;
          }
          final targets = await _pickTargetLocalPlaylists(
            context,
            title: 'Save songs to',
          );
          if (targets == null || targets.isEmpty) return;

          try {
            for (final name in targets) {
              for (final idx in selected) {
                if (idx < 0 || idx >= items.length) continue;
                await BloomeeDBService.addMediaItem(items[idx], name);
              }
            }
            SnackbarService.showMessage('Saved ${selected.length} songs');
          } catch (e) {
            SnackbarService.showMessage('Save failed: $e');
          }
        }

        Future<void> importAsNewPlaylist() async {
          final suggested = playlistName;
          final nameController = TextEditingController(text: suggested);
          final newName = await showDialog<String>(
            context: ctx,
            builder: (dctx) {
              return GlassDialog(
                title: const Text('Import playlist as'),
                content: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: 'Playlist name'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dctx, nameController.text),
                    child: const Text('Import'),
                  ),
                ],
              );
            },
          );
          final targetName = (newName ?? '').trim();
          if (targetName.isEmpty) return;

          try {
            final exists = await BloomeeDBService.playlistExists(targetName);
            if (exists) {
              SnackbarService.showMessage(
                  'Playlist "$targetName" already exists');
              return;
            }
            await BloomeeDBService.createPlaylist(
              targetName,
              artURL: header['artURL'] as String?,
              description: header['description'] as String?,
              permaURL: header['permaURL'] as String?,
              source: header['source'] as String?,
              artists: header['artists'] as String?,
              isAlbum: header['isAlbum'] == true,
            );
            for (final it in items) {
              await BloomeeDBService.addMediaItem(it, targetName);
            }
            SnackbarService.showMessage('Imported "$targetName"');
            if (context.mounted) Navigator.pop(ctx);
          } catch (e) {
            SnackbarService.showMessage('Import failed: $e');
          }
        }

        return GlassDialog(
          title: Text(playlistName),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: items.isEmpty
                          ? null
                          : () {
                              setState(() {
                                if (allSelected) {
                                  selected.clear();
                                } else {
                                  selected
                                    ..clear()
                                    ..addAll(
                                        List.generate(items.length, (i) => i));
                                }
                              });
                            },
                      child: Text(allSelected ? 'Unselect all' : 'Select all'),
                    ),
                    const Spacer(),
                    Text(
                      '${selected.length}/${items.length}',
                      style: Default_Theme.secondoryTextStyle
                          .merge(const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: items.isEmpty
                      ? const Center(
                          child: SignBoardWidget(
                            message: 'No songs found',
                            icon: MingCute.music_2_line,
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (c, i) {
                            final it = items[i];
                            final checked = selected.contains(i);
                            return CheckboxListTile(
                              value: checked,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    selected.add(i);
                                  } else {
                                    selected.remove(i);
                                  }
                                });
                              },
                              title: Text(
                                it.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Default_Theme.secondoryTextStyle.merge(
                                  TextStyle(color: Default_Theme.primaryColor1),
                                ),
                              ),
                              subtitle: Text(
                                it.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Default_Theme.secondoryTextStyle.merge(
                                  TextStyle(
                                      fontSize: 12,
                                      color: Default_Theme.primaryColor1
                                          .withValues(alpha: 0.7)),
                                ),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: saveSelectedToPlaylists,
              child: const Text('Save selected songs'),
            ),
            ElevatedButton(
              onPressed: importAsNewPlaylist,
              child: const Text('Import playlist'),
            ),
          ],
        );
      });
    },
  );
}

Future<void> showCloudPlaylistImportDialog(BuildContext context) async {
  final fs = FirestoreService();
  final controller = TextEditingController();

  await showDialog(
    context: context,
    builder: (ctx) {
      bool loading = false;
      String? error;
      List<Map<String, dynamic>> results = <Map<String, dynamic>>[];

      Future<void> search() async {
        final input = controller.text.trim();
        if (input.isEmpty) return;
        loading = true;
        error = null;
        results = <Map<String, dynamic>>[];
        (ctx as Element).markNeedsBuild();

        try {
          final shareId = fs.parseShareId(input);
          if (shareId != null) {
            final shared = await fs.resolveSharedPlaylist(shareId);
            if (shared == null) {
              error = 'Invalid link';
            } else {
              final ownerUid = shared['ownerUid'] as String?;
              final playlistName = shared['playlistName'] as String?;
              if (ownerUid == null || playlistName == null) {
                error = 'Invalid link data';
              } else {
                final header =
                    await fs.getPlaylistHeaderFromCloud(ownerUid, playlistName);
                results = [
                  {
                    ...?header,
                    'playlistName': playlistName,
                    'ownerUid': ownerUid,
                  }
                ];
              }
            }
          } else {
            final uid = await fs.getUserIdByUsername(input);
            if (uid == null) {
              error = 'User not found';
            } else {
              final pls = await fs.getPublicPlaylistsByUserId(uid);
              results = pls
                  .map((p) => {
                        ...p,
                        'ownerUid': uid,
                      })
                  .toList();
              if (results.isEmpty) {
                error = 'No public playlists';
              }
            }
          }
        } catch (e) {
          error = e.toString();
        } finally {
          loading = false;
          (ctx).markNeedsBuild();
        }
      }

      Future<void> importPlaylist(Map<String, dynamic> header) async {
        final ownerUid = header['ownerUid'] as String?;
        final playlistName = header['playlistName'] as String?;
        if (ownerUid == null || playlistName == null) return;

        final suggested = playlistName;
        final nameController = TextEditingController(text: suggested);
        final newName = await showDialog<String>(
          context: ctx,
          builder: (dctx) {
            return GlassDialog(
              title: const Text('Import playlist as'),
              content: TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Playlist name'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dctx, nameController.text),
                  child: const Text('Import'),
                ),
              ],
            );
          },
        );
        final targetName = (newName ?? '').trim();
        if (targetName.isEmpty) return;

        try {
          final exists = await BloomeeDBService.playlistExists(targetName);
          if (exists) {
            SnackbarService.showMessage(
                'Playlist "$targetName" already exists');
            return;
          }
          final items = await fs.getPlaylistItemsFromCloud(ownerUid, playlistName);
          await BloomeeDBService.createPlaylist(
            targetName,
            artURL: header['artURL'] as String?,
            description: header['description'] as String?,
            permaURL: header['permaURL'] as String?,
            source: header['source'] as String?,
            artists: header['artists'] as String?,
            isAlbum: header['isAlbum'] == true,
          );
          for (final m in items) {
            try {
              final dbItem = MediaItemDB.fromMap(m);
              await BloomeeDBService.addMediaItem(dbItem, targetName);
            } catch (_) {}
          }
          SnackbarService.showMessage('Imported "$targetName"');
        } catch (e) {
          SnackbarService.showMessage('Import failed: $e');
        }
      }

      return StatefulBuilder(builder: (ctx2, setState) {
        return GlassDialog(
          title: const Text('Import playlist'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: '@username or share link',
                  ),
                  onSubmitted: (_) async {
                    await search();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  )
                else if (error != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                else if (results.isEmpty)
                  const SizedBox.shrink()
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: results.length,
                      itemBuilder: (c, i) {
                        final p = results[i];
                        final name =
                            (p['playlistName'] as String?) ?? 'Playlist';
                        final desc = (p['description'] as String?) ?? '';
                        return ListTile(
                          onTap: () async {
                            await _showRemotePlaylistDialog(
                              context,
                              fs: fs,
                              header: p,
                            );
                          },
                          title: Text(name,
                              style: Default_Theme.secondoryTextStyleMedium.merge(
                                  TextStyle(color: Default_Theme.primaryColor1))),
                          subtitle: desc.isEmpty
                              ? null
                              : Text(desc,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Default_Theme.secondoryTextStyle
                                      .merge(const TextStyle(fontSize: 12))),
                          trailing: IconButton(
                            icon: Icon(MingCute.download_2_line,
                                color: Default_Theme.accentColor2),
                            onPressed: () async {
                              await importPlaylist(p);
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                await search();
                setState(() {});
              },
              child: const Text('Search'),
            ),
          ],
        );
      });
    },
  );
}
