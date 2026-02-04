import 'dart:async';
import 'dart:developer';
import 'package:Bloomee/blocs/mediaPlayer/bloomee_player_cubit.dart';
import 'package:Bloomee/model/lyrics_models.dart';
import 'package:Bloomee/model/songModel.dart';
import 'package:Bloomee/repository/Lyrics/lyrics.dart';
import 'package:Bloomee/routes_and_consts/global_conts.dart';
import 'package:Bloomee/routes_and_consts/global_str_consts.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:Bloomee/services/lyrics_translation_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'lyrics_state.dart';

class LyricsCubit extends Cubit<LyricsState> {
  StreamSubscription? _mediaItemSubscription;
  LyricsCubit(BloomeePlayerCubit playerCubit) : super(LyricsInitial()) {
    _mediaItemSubscription =
        playerCubit.bloomeePlayer.mediaItem.stream.listen((v) {
      if (v != null) {
        getLyrics(mediaItem2MediaItemModel(v));
      }
    });
  }

  void getLyrics(MediaItemModel mediaItem) async {
    if (state.mediaItem == mediaItem && state is LyricsLoaded) {
      return;
    } else {
      final prevTranslationEnabled = state.translationEnabled;
      final prevTargetLang = state.translationTargetLang;

      emit(LyricsLoading(mediaItem));
      Lyrics? lyrics = await BloomeeDBService.getLyrics(mediaItem.id);
      if (lyrics == null) {
        try {
          lyrics = await LyricsRepository.getLyrics(
              mediaItem.title, mediaItem.artist ?? "",
              album: mediaItem.album, duration: mediaItem.duration);
          if (lyrics.lyricsSynced == "No Lyrics Found") {
            lyrics = lyrics.copyWith(lyricsSynced: null);
          }
          lyrics = lyrics.copyWith(mediaID: mediaItem.id);
          emit(LyricsLoaded.withTranslation(
            lyrics,
            mediaItem,
            translationEnabled: prevTranslationEnabled,
            translationTargetLang: prevTargetLang,
            isTranslating: false,
            translatedPlain: null,
            translatedSyncedLines: null,
          ));
          await _restoreCachedTranslationIfAny(mediaItemId: mediaItem.id);
          if (state.translationEnabled) {
            await translateLyrics(force: false);
          }
          BloomeeDBService.getSettingBool(GlobalStrConsts.autoSaveLyrics)
              .then((value) {
            if ((value ?? false) && lyrics != null) {
              BloomeeDBService.putLyrics(lyrics);
              log("Lyrics saved for ID: ${mediaItem.id} Duration: ${lyrics.duration}",
                  name: "LyricsCubit");
            }
          });
          log("Lyrics loaded for ID: ${mediaItem.id} Duration: ${lyrics.duration} [Online]",
              name: "LyricsCubit");
        } catch (e) {
          emit(LyricsError(mediaItem));
        }
      } else if (lyrics.mediaID == mediaItem.id) {
        emit(LyricsLoaded.withTranslation(
          lyrics,
          mediaItem,
          translationEnabled: prevTranslationEnabled,
          translationTargetLang: prevTargetLang,
          isTranslating: false,
          translatedPlain: null,
          translatedSyncedLines: null,
        ));
        await _restoreCachedTranslationIfAny(mediaItemId: mediaItem.id);
        if (state.translationEnabled) {
          await translateLyrics(force: false);
        }
        log("Lyrics loaded for ID: ${mediaItem.id} Duration: ${lyrics.duration} [Offline]",
            name: "LyricsCubit");
      }
    }
  }

  Future<void> _restoreCachedTranslationIfAny({required String mediaItemId}) async {
    final cached = await LyricsTranslationService.getCached(
      mediaId: mediaItemId,
      targetLang: state.translationTargetLang,
    );
    if (cached == null) return;

    emit(state.copyWith(
      translatedPlain: cached.translatedPlain,
      translatedSyncedLines: cached.translatedSyncedLines,
    ));
  }

  Future<void> setTranslationTargetLang(String lang) async {
    if (lang.trim().isEmpty) return;

    emit(state.copyWith(
      translationTargetLang: lang,
      translatedPlain: null,
      translatedSyncedLines: null,
    ));

    if (!state.translationEnabled) return;
    await translateLyrics(force: false);
  }

  Future<void> toggleTranslationEnabled(bool enabled) async {
    emit(state.copyWith(
      translationEnabled: enabled,
    ));

    if (!enabled) return;
    await translateLyrics(force: false);
  }

  Future<void> translateLyrics({required bool force}) async {
    if (state is! LyricsLoaded) return;
    if (state.mediaItem == mediaItemModelNull) return;

    if (!force &&
        state.translatedPlain != null &&
        state.translatedPlain!.trim().isNotEmpty) {
      return;
    }

    emit(state.copyWith(isTranslating: true));

    try {
      final mediaId = state.mediaItem.id;
      final lang = state.translationTargetLang;

      if (!force) {
        final cached = await LyricsTranslationService.getCached(
          mediaId: mediaId,
          targetLang: lang,
        );
        if (cached != null) {
          emit(state.copyWith(
            isTranslating: false,
            translatedPlain: cached.translatedPlain,
            translatedSyncedLines: cached.translatedSyncedLines,
          ));
          return;
        }
      }

      final syncedLines = state.lyrics.parsedLyrics?.lyrics
          .map((e) => e.text)
          .toList(growable: false);

      final result = await LyricsTranslationService.translate(
        plainLyrics: state.lyrics.lyricsPlain,
        syncedLines: syncedLines,
        targetLang: lang,
      );

      await LyricsTranslationService.putCached(
        mediaId: mediaId,
        targetLang: lang,
        result: result,
      );

      emit(state.copyWith(
        isTranslating: false,
        translatedPlain: result.translatedPlain,
        translatedSyncedLines: result.translatedSyncedLines,
      ));
    } catch (e) {
      emit(state.copyWith(isTranslating: false));
    }
  }

  void setLyricsToDB(Lyrics lyrics, String mediaID) {
    final l1 = lyrics.copyWith(mediaID: mediaID);
    BloomeeDBService.putLyrics(l1).then((v) {
      emit(LyricsLoaded.withTranslation(
        l1,
        state.mediaItem,
        translationEnabled: state.translationEnabled,
        translationTargetLang: state.translationTargetLang,
        isTranslating: false,
        translatedPlain: state.translatedPlain,
        translatedSyncedLines: state.translatedSyncedLines,
      ));
    });
    log("Lyrics updated for ID: ${l1.mediaID} Duration: ${l1.duration}",
        name: "LyricsCubit");
  }

  void deleteLyricsFromDB(MediaItemModel mediaItem) {
    BloomeeDBService.removeLyricsById(mediaItem.id).then((value) {
      emit(LyricsInitial());
      getLyrics(mediaItem);

      log("Lyrics deleted for ID: ${mediaItem.id}", name: "LyricsCubit");
    });
  }

  @override
  Future<void> close() {
    _mediaItemSubscription?.cancel();
    return super.close();
  }
}
