// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:Bloomee/model/MediaPlaylistModel.dart';
import 'package:Bloomee/model/songModel.dart';
import 'package:Bloomee/services/db/GlobalDB.dart';
import 'package:Bloomee/services/db/cubit/bloomee_db_cubit.dart';
import 'package:Bloomee/utils/pallete_generator.dart';
part 'current_playlist_state.dart';

class CurrentPlaylistCubit extends Cubit<CurrentPlaylistState> {
  MediaPlaylist? mediaPlaylist;
  PaletteGenerator? paletteGenerator;
  late BloomeeDBCubit bloomeeDBCubit;
  CurrentPlaylistCubit({
    this.mediaPlaylist,
    required this.bloomeeDBCubit,
  }) : super(const CurrentPlaylistInitial());

  Future<void> setupPlaylist(String playlistName) async {
    if (isClosed) return;
    emit(const CurrentPlaylistLoading());
    try {
      mediaPlaylist = await bloomeeDBCubit
          .getPlaylistItems(MediaPlaylistDB(playlistName: playlistName));
    } catch (_) {
      mediaPlaylist = null;
    }

    if (isClosed) return;

    final resolved = mediaPlaylist ??
        MediaPlaylist(mediaItems: const [], playlistName: playlistName);

    if (resolved.mediaItems.isNotEmpty) {
      paletteGenerator = await getPalleteFromImage(
          resolved.mediaItems[0].artUri.toString());
    } else {
      paletteGenerator = null;
    }

    if (isClosed) return;

    emit(state.copyWith(
      isFetched: true,
      mediaPlaylist: resolved,
    ));
  }

  Future<List<int>> getItemOrder() async {
    final name = mediaPlaylist?.playlistName ?? state.mediaPlaylist.playlistName;
    if (name.isEmpty) return [];
    return await BloomeeDBService.getPlaylistItemsRankByName(name);
  }

  String getTitle() {
    return state.mediaPlaylist.playlistName;
  }

  Future<void> updatePlaylist(List<int> newOrder) async {
    final oldOrder = await getItemOrder();
    if (!listEquals(newOrder, oldOrder) &&
        mediaPlaylist != null &&
        newOrder.length >= mediaPlaylist!.mediaItems.length) {
      await BloomeeDBService.updatePltItemsRankByName(
          mediaPlaylist!.playlistName, newOrder);
      final playlist = await bloomeeDBCubit.getPlaylistItems(
          MediaPlaylistDB(playlistName: mediaPlaylist!.playlistName));
      setupPlaylist(playlist.playlistName);
    }
  }

  Future<bool> renamePlaylist(String newPlaylistName) async {
    final oldName = state.mediaPlaylist.playlistName;
    final next = newPlaylistName.trim();
    if (oldName.isEmpty || next.isEmpty) return false;
    final ok = await BloomeeDBService.renamePlaylist(oldName, next);
    if (ok) {
      await setupPlaylist(next);
    }
    return ok;
  }

  Future<void> updatePlaylistInfo({
    String? description,
    String? artURL,
  }) async {
    final name = state.mediaPlaylist.playlistName;
    if (name.isEmpty) return;
    await BloomeeDBService.upsertPlaylistInfo(
      name,
      description: description,
      artURL: artURL,
      isAlbum: state.mediaPlaylist.isAlbum,
    );
    await setupPlaylist(name);
  }

  int getPlaylistLength() {
    if (mediaPlaylist != null) {
      return mediaPlaylist?.mediaItems.length ?? 0;
    } else {
      return 0;
    }
  }

  String? getPlaylistCoverArt() {
    if (mediaPlaylist?.mediaItems.isNotEmpty ?? false) {
      return mediaPlaylist?.mediaItems[0].artUri.toString();
    } else {
      return "";
    }
  }

  PaletteGenerator? getCurrentPlaylistPallete() {
    return paletteGenerator;
  }
}
