import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:Bloomee/services/db/GlobalDB.dart';
import 'package:Bloomee/screens/widgets/snackbar.dart';
import 'package:Bloomee/services/db/cubit/bloomee_db_cubit.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:Bloomee/theme_data/default.dart';

void createPlaylistBottomSheet(BuildContext context) {
  final focusNode = FocusNode();
  showMaterialModalBottomSheet(
    context: context,
    expand: false,
    animationCurve: Curves.easeIn,
    duration: const Duration(milliseconds: 300),
    elevation: 20,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(40), topRight: Radius.circular(40)),
          child: Container(
            height: (MediaQuery.of(context).size.height * 0.45) + 10,
            color: Default_Theme.accentColor2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Spacer(),
                LayoutBuilder(builder: (context, constraints) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.45,
                    width: constraints.maxWidth,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40)),
                      child: Container(
                        color: Default_Theme.themeColor,
                        child: SingleChildScrollView(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16, right: 16, top: 30),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "Create new Playlist 😍",
                                      style: Default_Theme
                                          .secondoryTextStyleMedium
                                          .merge(TextStyle(
                                              color: Default_Theme.accentColor2,
                                              fontSize: 35)),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 10,
                                    right: 10,
                                    top: 10,
                                  ),
                                  child: TextField(
                                    autofocus: true,
                                    textInputAction: TextInputAction.done,
                                    maxLines: 3,
                                    textAlignVertical: TextAlignVertical.center,
                                    textAlign: TextAlign.center,
                                    focusNode: focusNode,
                                    cursorHeight: 60,
                                    showCursor: true,
                                    cursorWidth: 5,
                                    cursorRadius: const Radius.circular(5),
                                    cursorColor: Default_Theme.accentColor2,
                                    style: TextStyle(
                                            fontSize: 45,
                                            color: Default_Theme.accentColor2)
                                        .merge(Default_Theme
                                            .secondoryTextStyleMedium),
                                    decoration: const InputDecoration(
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              style: BorderStyle.none),
                                          // borderRadius: BorderRadius.circular(50)
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide.none,
                                          // borderRadius: BorderRadius.circular(50),
                                        )),
                                    onTapOutside: (event) {
                                      focusNode.unfocus();
                                    },
                                    onSubmitted: (value) {
                                      focusNode.unfocus();

                                      final name = value.trim();
                                      if (name.isEmpty || name.length < 3) {
                                        SnackbarService.showMessage(
                                            'Playlist name must be at least 3 characters');
                                        return;
                                      }

                                      () async {
                                        final exists =
                                            await BloomeeDBService.playlistExists(
                                                name);
                                        if (exists) {
                                          SnackbarService.showMessage(
                                              'A playlist named "$name" already exists');
                                          return;
                                        }

                                        // create (local) playlist
                                        // Keeping existing behavior via BloomeeDBCubit.
                                        // The DB watcher will refresh library UI.
                                        context
                                            .read<BloomeeDBCubit>()
                                            .addNewPlaylistToDB(MediaPlaylistDB(
                                                playlistName: name));
                                        if (context.mounted) context.pop();
                                      }();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    },
  );
}
