import 'package:Bloomee/blocs/lyrics/lyrics_cubit.dart';
import 'package:Bloomee/screens/screen/player_views/lyrics_search.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';

class LyricsMenu extends StatefulWidget {
  final LyricsState state;
  const LyricsMenu({super.key, required this.state});

  @override
  State<LyricsMenu> createState() => _LyricsMenuState();
}

class _LyricsMenuState extends State<LyricsMenu> {
  final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'LyricsMenu');

  @override
  void dispose() {
    _buttonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MenuAnchor(
      childFocusNode: _buttonFocusNode,
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll<Color>(
          scheme.surfaceContainerHighest,
        ),
      ),
      menuChildren: <Widget>[
        MenuItemButton(
          onPressed: () {
            context
                .read<LyricsCubit>()
                .toggleTranslationEnabled(!widget.state.translationEnabled);
          },
          child: Row(
            children: <Widget>[
              Icon(
                widget.state.translationEnabled
                    ? Icons.translate
                    : Icons.translate_outlined,
                color: scheme.onSurface,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                widget.state.translationEnabled
                    ? 'Disable Translation'
                    : 'Translate Lyrics',
                style: TextStyle(color: scheme.onSurface, fontSize: 13),
              ),
            ],
          ),
        ),
        MenuItemButton(
          onPressed: () async {
            final lyricsCubit = context.read<LyricsCubit>();
            final lang = await showDialog<String>(
              context: context,
              builder: (context) {
                String selected = widget.state.translationTargetLang;
                return AlertDialog(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  title: Text(
                    'Translation Language',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  content: StatefulBuilder(
                    builder: (context, setState) {
                      return DropdownButton<String>(
                        value: selected,
                        dropdownColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'bn', child: Text('Bengali')),
                          DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                          DropdownMenuItem(value: 'es', child: Text('Spanish')),
                          DropdownMenuItem(value: 'pt', child: Text('Portuguese')),
                          DropdownMenuItem(value: 'fr', child: Text('French')),
                          DropdownMenuItem(value: 'de', child: Text('German')),
                          DropdownMenuItem(value: 'id', child: Text('Indonesian')),
                          DropdownMenuItem(value: 'ja', child: Text('Japanese')),
                          DropdownMenuItem(value: 'ko', child: Text('Korean')),
                          DropdownMenuItem(value: 'ru', child: Text('Russian')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => selected = v);
                        },
                      );
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(selected),
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );

            if (!mounted) return;

            if (lang != null) {
              await lyricsCubit.setTranslationTargetLang(lang);
            }
          },
          child: Row(
            children: <Widget>[
              Icon(
                Icons.language,
                color: scheme.onSurface,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text('Translation Language',
                  style: TextStyle(color: scheme.onSurface, fontSize: 13)),
            ],
          ),
        ),
        MenuItemButton(
          onPressed: () {
            context.read<LyricsCubit>().translateLyrics(force: true);
          },
          child: Row(
            children: <Widget>[
              Icon(
                Icons.refresh,
                color: scheme.onSurface,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text('Re-translate',
                  style: TextStyle(color: scheme.onSurface, fontSize: 13)),
            ],
          ),
        ),
        MenuItemButton(
          onPressed: () {
            showSearch(
              context: context,
              delegate:
                  LyricsSearchDelegate(mediaID: widget.state.mediaItem.id),
              query:
                  "${widget.state.mediaItem.title} ${widget.state.mediaItem.artist}",
            );
          },
          child: Row(
            children: <Widget>[
              Icon(
                MingCute.search_2_fill,
                color: scheme.onSurface,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text('Search Lyrics',
                  style: TextStyle(color: scheme.onSurface, fontSize: 13)),
            ],
          ),
        ),
        MenuItemButton(
          onPressed: () {
            context
                .read<LyricsCubit>()
                .deleteLyricsFromDB(widget.state.mediaItem);
          },
          child: Row(
            children: <Widget>[
              Icon(
                MingCute.delete_fill,
                color: scheme.onSurface,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text('Reset Lyrics',
                  style: TextStyle(color: scheme.onSurface, fontSize: 13)),
            ],
          ),
        ),
        MenuItemButton(
          onPressed: () {
            context
                .read<LyricsCubit>()
                .setLyricsToDB(widget.state.lyrics, widget.state.mediaItem.id);
          },
          child: Row(
            children: <Widget>[
              Icon(
                MingCute.save_2_fill,
                color: scheme.onSurface,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text('Save Lyrics',
                  style: TextStyle(color: scheme.onSurface, fontSize: 13)),
            ],
          ),
        ),
        // MenuItemButton(
        //   onPressed: () {
        //     showFloatingModalBottomSheet(
        //       context: context,
        //       builder: (context) {
        //         return Container();
        //       },
        //     );
        //   },
        //   child: const Row(
        //     children: <Widget>[
        //       Icon(
        //         MingCute.time_line,
        //         color: Colors.white,
        //         size: 18,
        //       ),
        //       SizedBox(width: 8),
        //       Text('Offset Lyrics',
        //           style: TextStyle(color: Colors.white, fontSize: 13)),
        //     ],
        //   ),
        // ),
      ],
      builder: (_, MenuController controller, Widget? child) {
        return Tooltip(
          message: 'Lyrics Menu',
          child: IconButton(
            focusNode: _buttonFocusNode,
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            icon: const Icon(
              MingCute.edit_2_line,
              size: 20,
            ),
            color: Default_Theme.primaryColor1.withValues(alpha: 0.9),
          ),
        );
      },
    );
  }
}
