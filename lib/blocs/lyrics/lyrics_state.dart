// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'lyrics_cubit.dart';

class LyricsState extends Equatable {
  const LyricsState(
    this.lyrics,
    this.mediaItem,
    this.translationEnabled,
    this.translationTargetLang,
    this.isTranslating,
    this.translatedPlain,
    this.translatedSyncedLines,
  );

  final Lyrics lyrics;
  final MediaItemModel mediaItem;
  final bool translationEnabled;
  final String translationTargetLang;
  final bool isTranslating;
  final String? translatedPlain;
  final List<String>? translatedSyncedLines;

  @override
  List<Object?> get props => [
        lyrics,
        lyrics.id,
        lyrics.title,
        mediaItem,
        translationEnabled,
        translationTargetLang,
        isTranslating,
        translatedPlain,
        translatedSyncedLines,
      ];

  LyricsState copyWith({
    Lyrics? lyrics,
    MediaItemModel? mediaItem,
    bool? translationEnabled,
    String? translationTargetLang,
    bool? isTranslating,
    String? translatedPlain,
    List<String>? translatedSyncedLines,
  }) {
    final nextLyrics = lyrics ?? this.lyrics;
    final nextMediaItem = mediaItem ?? this.mediaItem;
    final nextEnabled = translationEnabled ?? this.translationEnabled;
    final nextLang = translationTargetLang ?? this.translationTargetLang;
    final nextIsTranslating = isTranslating ?? this.isTranslating;
    final nextPlain = translatedPlain ?? this.translatedPlain;
    final nextLines = translatedSyncedLines ?? this.translatedSyncedLines;

    if (this is LyricsLoaded) {
      return LyricsLoaded.withTranslation(
        nextLyrics,
        nextMediaItem,
        translationEnabled: nextEnabled,
        translationTargetLang: nextLang,
        isTranslating: nextIsTranslating,
        translatedPlain: nextPlain,
        translatedSyncedLines: nextLines,
      );
    }

    return LyricsState(
      nextLyrics,
      nextMediaItem,
      nextEnabled,
      nextLang,
      nextIsTranslating,
      nextPlain,
      nextLines,
    );
  }
}

final class LyricsInitial extends LyricsState {
  LyricsInitial()
      : super(
            Lyrics(
                artist: "",
                title: "",
                id: "id",
                lyricsPlain: "",
                provider: LyricsProvider.none),
            mediaItemModelNull,
            false,
            'en',
            false,
            null,
            null);
}

final class LyricsLoading extends LyricsState {
  LyricsLoading(MediaItemModel mediaItem)
      : super(
            Lyrics(
                artist: "",
                title: "loading",
                id: "id",
                lyricsPlain: "",
                provider: LyricsProvider.none),
            mediaItem,
            false,
            'en',
            false,
            null,
            null);
}

final class LyricsError extends LyricsState {
  LyricsError(MediaItemModel mediaItem)
      : super(
            Lyrics(
                artist: "",
                title: "Error",
                id: "id",
                lyricsPlain: "",
                provider: LyricsProvider.none),
            mediaItem,
            false,
            'en',
            false,
            null,
            null);
}

final class LyricsLoaded extends LyricsState {
  const LyricsLoaded(Lyrics lyrics, MediaItemModel mediaItem)
      : super(lyrics, mediaItem, false, 'en', false, null, null);

  const LyricsLoaded.withTranslation(
    Lyrics lyrics,
    MediaItemModel mediaItem, {
    required bool translationEnabled,
    required String translationTargetLang,
    required bool isTranslating,
    required String? translatedPlain,
    required List<String>? translatedSyncedLines,
  }) : super(
          lyrics,
          mediaItem,
          translationEnabled,
          translationTargetLang,
          isTranslating,
          translatedPlain,
          translatedSyncedLines,
        );
}
