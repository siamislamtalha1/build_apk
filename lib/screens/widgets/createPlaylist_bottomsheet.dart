import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:Bloomee/services/db/GlobalDB.dart';
import 'package:Bloomee/blocs/auth/auth_cubit.dart';
import 'package:Bloomee/services/firebase/firestore_service.dart';
import 'package:Bloomee/screens/widgets/snackbar.dart';
import 'package:Bloomee/services/db/cubit/bloomee_db_cubit.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:Bloomee/theme_data/default.dart';

void createPlaylistBottomSheet(BuildContext context) {
  final focusNode = FocusNode();
  final nameController = TextEditingController();
  bool isPublic = false;
  showMaterialModalBottomSheet(
    context: context,
    expand: false,
    animationCurve: Curves.easeIn,
    duration: const Duration(milliseconds: 300),
    elevation: 20,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        Future<void> createNow() async {
          focusNode.unfocus();
          final name = nameController.text.trim();
          if (name.isEmpty || name.length < 3) {
            SnackbarService.showMessage(
                'Playlist name must be at least 3 characters');
            return;
          }

          final exists = await BloomeeDBService.playlistExists(name);
          if (exists) {
            SnackbarService.showMessage(
                'A playlist named "$name" already exists');
            return;
          }

          context
              .read<BloomeeDBCubit>()
              .addNewPlaylistToDB(MediaPlaylistDB(playlistName: name));

          final auth = context.read<AuthCubit>();
          final user = auth.currentUser;
          if (user != null && !user.isAnonymous) {
            try {
              await FirestoreService().setPlaylistVisibility(
                userId: user.uid,
                playlistName: name,
                isPublic: isPublic,
              );
            } catch (_) {}
          }

          if (context.mounted) context.pop();
        }

        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40), topRight: Radius.circular(40)),
            child: Container(
              height: (MediaQuery.of(context).size.height * 0.50) + 10,
              color: Default_Theme.accentColor2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Spacer(),
                  LayoutBuilder(builder: (context, constraints) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.50,
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
                                                color:
                                                    Default_Theme.accentColor2,
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
                                      controller: nameController,
                                      autofocus: true,
                                      textInputAction: TextInputAction.done,
                                      maxLines: 2,
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      textAlign: TextAlign.center,
                                      focusNode: focusNode,
                                      cursorHeight: 60,
                                      showCursor: true,
                                      cursorWidth: 5,
                                      cursorRadius: const Radius.circular(5),
                                      cursorColor: Default_Theme.accentColor2,
                                      style: TextStyle(
                                              fontSize: 45,
                                              color:
                                                  Default_Theme.accentColor2)
                                          .merge(Default_Theme
                                              .secondoryTextStyleMedium),
                                      decoration: const InputDecoration(
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                style: BorderStyle.none),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide.none,
                                          )),
                                      onTapOutside: (event) {
                                        focusNode.unfocus();
                                      },
                                      onSubmitted: (_) async {
                                        await createNow();
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24),
                                    child: SwitchListTile(
                                      value: isPublic,
                                      onChanged: (v) {
                                        setState(() {
                                          isPublic = v;
                                        });
                                      },
                                      title: Text(
                                        'Public playlist',
                                        style: Default_Theme
                                            .secondoryTextStyleMedium
                                            .merge(TextStyle(
                                                color: Default_Theme
                                                    .primaryColor1)),
                                      ),
                                      subtitle: Text(
                                        'Public playlists can be found and imported by others',
                                        style: Default_Theme.secondoryTextStyle
                                            .merge(TextStyle(
                                                color: Default_Theme
                                                    .primaryColor1
                                                    .withOpacity(0.7),
                                                fontSize: 12)),
                                      ),
                                      activeColor: Default_Theme.accentColor2,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Default_Theme.accentColor2,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                        onPressed: () async {
                                          await createNow();
                                        },
                                        child: const Text('Create'),
                                      ),
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
      });
    },
  );
}
