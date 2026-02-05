// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';
import 'package:Bloomee/model/search_filter_model.dart';
import 'package:Bloomee/model/playlist_onl_model.dart';
import 'package:Bloomee/repository/Youtube/ytm/ytmusic.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:Bloomee/model/album_onl_model.dart';
import 'package:Bloomee/model/artist_onl_model.dart';
import 'package:Bloomee/model/saavnModel.dart';
import 'package:Bloomee/model/songModel.dart';
import 'package:Bloomee/model/source_engines.dart';
import 'package:Bloomee/model/youtube_vid_model.dart';
import 'package:Bloomee/model/yt_music_model.dart';
import 'package:Bloomee/repository/Saavn/saavn_api.dart';
import 'package:Bloomee/repository/Youtube/youtube_api.dart';

enum LoadingState { initial, loading, loaded, noInternet }

enum ResultTypes {
  // all(val: 'All'),
  songs(val: 'Songs'),
  playlists(val: 'Playlists'),
  albums(val: 'Albums'),
  artists(val: 'Artists');

  final String val;
  const ResultTypes({required this.val});
}

class LastSearch {
  String query;
  int page = 1;
  final SourceEngine sourceEngine;
  bool hasReachedMax = false;
  List<MediaItemModel> mediaItemList = List.empty(growable: true);
  LastSearch({required this.query, required this.sourceEngine});
}

class FetchSearchResultsState extends Equatable {
  final LoadingState loadingState;
  final List<MediaItemModel> mediaItems;
  final List<AlbumModel> albumItems;
  final List<PlaylistOnlModel> playlistItems;
  final List<ArtistModel> artistItems;
  final SourceEngine? sourceEngine;
  final ResultTypes resultType;
  final bool hasReachedMax;
  const FetchSearchResultsState({
    required this.loadingState,
    required this.mediaItems,
    required this.albumItems,
    required this.artistItems,
    required this.playlistItems,
    required this.hasReachedMax,
    required this.resultType,
    this.sourceEngine,
  });

  @override
  List<Object?> get props => [
        loadingState,
        mediaItems,
        hasReachedMax,
        albumItems,
        artistItems,
        playlistItems,
        sourceEngine,
        resultType,
      ];

  FetchSearchResultsState copyWith({
    LoadingState? loadingState,
    List<MediaItemModel>? mediaItems,
    List<AlbumModel>? albumItems,
    List<PlaylistOnlModel>? playlistItems,
    List<ArtistModel>? artistItems,
    ResultTypes? resultType,
    SourceEngine? sourceEngine,
    bool? hasReachedMax,
  }) {
    return FetchSearchResultsState(
      loadingState: loadingState ?? this.loadingState,
      mediaItems: mediaItems ?? this.mediaItems,
      albumItems: albumItems ?? this.albumItems,
      playlistItems: playlistItems ?? this.playlistItems,
      artistItems: artistItems ?? this.artistItems,
      resultType: resultType ?? this.resultType,
      sourceEngine: sourceEngine ?? this.sourceEngine,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}

final class FetchSearchResultsInitial extends FetchSearchResultsState {
  FetchSearchResultsInitial()
      : super(
          mediaItems: [],
          loadingState: LoadingState.initial,
          hasReachedMax: false,
          albumItems: [],
          artistItems: [],
          playlistItems: [],
          resultType: ResultTypes.songs,
        );
}

final class FetchSearchResultsLoading extends FetchSearchResultsState {
  @override
  final ResultTypes resultType;
  FetchSearchResultsLoading({
    this.resultType = ResultTypes.songs,
  }) : super(
          mediaItems: [],
          loadingState: LoadingState.loading,
          hasReachedMax: false,
          albumItems: [],
          artistItems: [],
          playlistItems: [],
          resultType: resultType,
        );
}

final class FetchSearchResultsLoaded extends FetchSearchResultsState {
  @override
  final ResultTypes resultType;
  FetchSearchResultsLoaded({
    this.resultType = ResultTypes.songs,
  }) : super(
          mediaItems: [],
          loadingState: LoadingState.loaded,
          hasReachedMax: false,
          albumItems: [],
          artistItems: [],
          playlistItems: [],
          resultType: resultType,
        );
}
//------------------------------------------------------------------------

class FetchSearchResultsCubit extends Cubit<FetchSearchResultsState> {
  FetchSearchResultsCubit() : super(FetchSearchResultsInitial()) {
    YTMusic();
  }

  int _activeSearchToken = 0;

  final Map<String, Map<String, List<dynamic>>> _unifiedCache =
      <String, Map<String, List<dynamic>>>{};

  LastSearch last_YTM_search =
      LastSearch(query: "", sourceEngine: SourceEngine.eng_YTM);
  LastSearch last_YTV_search =
      LastSearch(query: "", sourceEngine: SourceEngine.eng_YTV);
  LastSearch last_JIS_search =
      LastSearch(query: "", sourceEngine: SourceEngine.eng_JIS);

  List<MediaItemModel> _mediaItemList = List.empty(growable: true);

  // check if the search is already loaded and if not then load it (when resultType or sourceEngine is changed)
  Future<void> checkAndRefreshSearch(
      {required String query,
      required SourceEngine sE,
      required ResultTypes rT}) async {
    if ((state.sourceEngine != sE || state.resultType != rT) &&
        state is! FetchSearchResultsLoading &&
        query.isNotEmpty) {
      log("Refreshing Search", name: "FetchSearchRes");
      search(query, sourceEngine: sE, resultType: rT);
    }
  }

  Future<void> searchYTMTracks(
    String query, {
    ResultTypes resultType = ResultTypes.songs,
  }) async {
    log("Youtube Music Search", name: "FetchSearchRes");

    last_YTM_search.query = query;
    emit(FetchSearchResultsLoading(resultType: resultType));
    switch (resultType) {
      case ResultTypes.songs:
        final searchResults = await YTMusic().searchYtm(query, type: "songs");
        if (searchResults == null) {
          emit(state.copyWith(
            mediaItems: [],
            loadingState: LoadingState.loaded,
            hasReachedMax: true,
            resultType: ResultTypes.songs,
            sourceEngine: SourceEngine.eng_YTM,
          ));
          return;
        } else {
          last_YTM_search.mediaItemList =
              ytmMapList2MediaItemList(searchResults['songs']);
          emit(state.copyWith(
            mediaItems:
                List<MediaItemModel>.from(last_YTM_search.mediaItemList),
            loadingState: LoadingState.loaded,
            hasReachedMax: true,
            resultType: ResultTypes.songs,
            sourceEngine: SourceEngine.eng_YTM,
          ));
        }
        break;
      case ResultTypes.playlists:
        final res = await YTMusic().searchYtm(query, type: "playlists");
        if (res == null) {
          emit(state.copyWith(
            playlistItems: [],
            loadingState: LoadingState.loaded,
            hasReachedMax: true,
            resultType: ResultTypes.playlists,
            sourceEngine: SourceEngine.eng_YTM,
          ));
          return;
        }
        final playlist = ytmMap2Playlists(res['playlists']);
        emit(state.copyWith(
          playlistItems: List<PlaylistOnlModel>.from(playlist),
          loadingState: LoadingState.loaded,
          hasReachedMax: true,
          resultType: ResultTypes.playlists,
          sourceEngine: SourceEngine.eng_YTM,
        ));
        log("Got results: ${playlist.length}", name: "FetchSearchRes");
        break;
      case ResultTypes.albums:
        final res = await YTMusic().searchYtm(query, type: "albums");
        if (res == null) {
          emit(state.copyWith(
            albumItems: [],
            loadingState: LoadingState.loaded,
            hasReachedMax: true,
            resultType: ResultTypes.albums,
            sourceEngine: SourceEngine.eng_YTM,
          ));
          return;
        }
        final albums = ytmMap2Albums(res['albums']);
        emit(state.copyWith(
          albumItems: List<AlbumModel>.from(albums),
          loadingState: LoadingState.loaded,
          hasReachedMax: true,
          resultType: ResultTypes.albums,
          sourceEngine: SourceEngine.eng_YTM,
        ));
        log("Got results: ${albums.length}", name: "FetchSearchRes");
        break;
      case ResultTypes.artists:
        final res = await YTMusic().searchYtm(query, type: "artists");
        if (res == null) {
          emit(state.copyWith(
            artistItems: [],
            loadingState: LoadingState.loaded,
            hasReachedMax: true,
            resultType: ResultTypes.artists,
            sourceEngine: SourceEngine.eng_YTM,
          ));
          return;
        }
        final artists = ytmMap2Artists(res['artists']);
        emit(state.copyWith(
          artistItems: List<ArtistModel>.from(artists),
          loadingState: LoadingState.loaded,
          hasReachedMax: true,
          resultType: ResultTypes.artists,
          sourceEngine: SourceEngine.eng_YTM,
        ));
        log("Got results: ${artists.length}", name: "FetchSearchRes");
        break;
    }

    log("got all searches ${last_YTM_search.mediaItemList.length}",
        name: "FetchSearchRes");
  }

  Future<void> searchYTVTracks(String query,
      {ResultTypes resultType = ResultTypes.songs}) async {
    log("Youtube Video Search", name: "FetchSearchRes");

    last_YTV_search.query = query;
    emit(FetchSearchResultsLoading(resultType: resultType));

    switch (resultType) {
      case ResultTypes.playlists:
        final res =
            await YouTubeServices().fetchSearchResults(query, playlist: true);
        final List<PlaylistOnlModel> playlists = ytvMap2Playlists({
          'playlists': res[0]['items'],
        });
        emit(state.copyWith(
          playlistItems: List<PlaylistOnlModel>.from(playlists),
          resultType: ResultTypes.playlists,
          hasReachedMax: true,
          loadingState: LoadingState.loaded,
          sourceEngine: SourceEngine.eng_YTV,
        ));
        break;
      case ResultTypes.albums:
      case ResultTypes.artists:
      case ResultTypes.songs:
        final searchResults = await YouTubeServices().fetchSearchResults(query);
        last_YTV_search.mediaItemList =
            (fromYtVidSongMapList2MediaItemList(searchResults[0]['items']));
        emit(state.copyWith(
          mediaItems: List<MediaItemModel>.from(last_YTV_search.mediaItemList),
          loadingState: LoadingState.loaded,
          resultType: ResultTypes.songs,
          hasReachedMax: true,
          sourceEngine: SourceEngine.eng_YTV,
        ));
        log("got all searches ${last_YTV_search.mediaItemList.length}",
            name: "FetchSearchRes");
        break;
    }
  }

  Future<void> searchJISTracks(
    String query, {
    bool loadMore = false,
    ResultTypes resultType = ResultTypes.songs,
  }) async {
    switch (resultType) {
      case ResultTypes.songs:
        if (!loadMore) {
          emit(FetchSearchResultsLoading(resultType: resultType));
          last_JIS_search.query = query;
          last_JIS_search.mediaItemList.clear();
          last_JIS_search.hasReachedMax = false;
          last_JIS_search.page = 1;
        }
        log("JIOSaavn Search", name: "FetchSearchRes");
        final searchResults = await SaavnAPI().fetchSongSearchResults(
            searchQuery: query, page: last_JIS_search.page);
        last_JIS_search.page++;
        _mediaItemList =
            fromSaavnSongMapList2MediaItemList(searchResults['songs']);
        if (_mediaItemList.length < 20) {
          last_JIS_search.hasReachedMax = true;
        }
        last_JIS_search.mediaItemList.addAll(_mediaItemList);

        emit(state.copyWith(
          mediaItems: List<MediaItemModel>.from(last_JIS_search.mediaItemList),
          loadingState: LoadingState.loaded,
          hasReachedMax: last_JIS_search.hasReachedMax,
          resultType: ResultTypes.songs,
          sourceEngine: SourceEngine.eng_JIS,
        ));

        log("got all searches ${last_JIS_search.mediaItemList.length}",
            name: "FetchSearchRes");
        break;
      case ResultTypes.albums:
        emit(FetchSearchResultsLoading(resultType: resultType));
        final res = await SaavnAPI().fetchAlbumResults(query);
        final albumList = saavnMap2Albums({'Albums': res});
        log("Got results: ${albumList.length}", name: "FetchSearchRes");
        emit(state.copyWith(
          albumItems: List<AlbumModel>.from(albumList),
          loadingState: LoadingState.loaded,
          hasReachedMax: true,
          resultType: ResultTypes.albums,
          sourceEngine: SourceEngine.eng_JIS,
        ));
        break;
      case ResultTypes.playlists:
        emit(FetchSearchResultsLoading(resultType: resultType));
        final res = await SaavnAPI().fetchPlaylistResults(query);
        final playlistList = saavnMap2Playlists({'Playlists': res});
        log("Got results: ${playlistList.length}", name: "FetchSearchRes");
        emit(state.copyWith(
          playlistItems: List<PlaylistOnlModel>.from(playlistList),
          loadingState: LoadingState.loaded,
          hasReachedMax: true,
          resultType: ResultTypes.playlists,
          sourceEngine: SourceEngine.eng_JIS,
        ));
        break;
      case ResultTypes.artists:
        emit(FetchSearchResultsLoading(resultType: resultType));
        final res = await SaavnAPI().fetchArtistResults(query);
        final artistList = saavnMap2Artists({'Artists': res});
        log("Got results: ${artistList.length}", name: "FetchSearchRes");
        emit(state.copyWith(
          artistItems: List<ArtistModel>.from(artistList),
          loadingState: LoadingState.loaded,
          hasReachedMax: true,
          resultType: ResultTypes.artists,
          sourceEngine: SourceEngine.eng_JIS,
        ));
        break;
    }
  }

  Future<void> search(String query,
      {SourceEngine sourceEngine = SourceEngine.eng_YTM,
      ResultTypes resultType = ResultTypes.songs}) async {
    switch (sourceEngine) {
      case SourceEngine.eng_YTM:
        searchYTMTracks(query, resultType: resultType);
        break;
      case SourceEngine.eng_YTV:
        searchYTVTracks(query, resultType: resultType);
        break;
      case SourceEngine.eng_JIS:
        searchJISTracks(query, resultType: resultType);
        break;
    }
  }

  void clearSearch() {
    emit(FetchSearchResultsInitial());
  }

  /// Unified search across all sources (JioSaavn, YT Music, YT Video)
  Future<void> searchAllSources(
    String query, {
    ResultTypes resultType = ResultTypes.songs,
    SearchFilter? filter,
  }) async {
    if (query.isEmpty) return;

    final cacheKey =
        '${query.toLowerCase()}|${resultType.name}|${(filter?.includeJioSaavn ?? true) ? 1 : 0}${(filter?.includeYTMusic ?? true) ? 1 : 0}${(filter?.includeYTVideo ?? true) ? 1 : 0}';
    final cached = _unifiedCache[cacheKey];
    if (cached != null) {
      emit(state.copyWith(
        loadingState: LoadingState.loaded,
        hasReachedMax: true,
        resultType: resultType,
        sourceEngine: null,
        mediaItems: (cached['songs'] as List?)?.cast<MediaItemModel>() ?? const [],
        albumItems: (cached['albums'] as List?)?.cast<AlbumModel>() ?? const [],
        playlistItems:
            (cached['playlists'] as List?)?.cast<PlaylistOnlModel>() ?? const [],
        artistItems: (cached['artists'] as List?)?.cast<ArtistModel>() ?? const [],
      ));
      return;
    }

    final token = ++_activeSearchToken;

    log("Unified Search across all sources with filter: ${filter?.includeJioSaavn}, ${filter?.includeYTMusic}, ${filter?.includeYTVideo}",
        name: "FetchSearchRes");
    emit(FetchSearchResultsLoading(resultType: resultType));

    try {
      final emptyResults = {
        'songs': <MediaItemModel>[],
        'albums': <AlbumModel>[],
        'playlists': <PlaylistOnlModel>[],
        'artists': <ArtistModel>[],
      };

      final jisFuture = (filter?.includeJioSaavn ?? true)
          ? _searchJISWithFallback(query, resultType)
          : Future.value(emptyResults);
      final ytmFuture = (filter?.includeYTMusic ?? true)
          ? _searchYTMWithFallback(query, resultType)
          : Future.value(emptyResults);
      final ytvFuture = (filter?.includeYTVideo ?? true)
          ? _searchYTVWithFallback(query, resultType)
          : Future.value(emptyResults);

      Map<String, List<dynamic>> jisResults =
          emptyResults.map((k, v) => MapEntry(k, List<dynamic>.from(v)));
      Map<String, List<dynamic>> ytmResults =
          emptyResults.map((k, v) => MapEntry(k, List<dynamic>.from(v)));
      Map<String, List<dynamic>> ytvResults =
          emptyResults.map((k, v) => MapEntry(k, List<dynamic>.from(v)));

      void emitProgress() {
        if (_activeSearchToken != token) return;
        switch (resultType) {
          case ResultTypes.songs:
            final allSongs = _intelligentInterleave(
              jisResults['songs']!.cast<MediaItemModel>(),
              ytmResults['songs']!.cast<MediaItemModel>(),
              ytvResults['songs']!.cast<MediaItemModel>(),
            );
            emit(state.copyWith(
              mediaItems: allSongs,
              loadingState: LoadingState.loaded,
              hasReachedMax: true,
              resultType: ResultTypes.songs,
              sourceEngine: null,
            ));
            break;
          case ResultTypes.albums:
            emit(state.copyWith(
              albumItems: <AlbumModel>[
                ...jisResults['albums']!.cast<AlbumModel>(),
                ...ytmResults['albums']!.cast<AlbumModel>(),
              ],
              loadingState: LoadingState.loaded,
              hasReachedMax: true,
              resultType: ResultTypes.albums,
              sourceEngine: null,
            ));
            break;
          case ResultTypes.playlists:
            emit(state.copyWith(
              playlistItems: <PlaylistOnlModel>[
                ...jisResults['playlists']!.cast<PlaylistOnlModel>(),
                ...ytmResults['playlists']!.cast<PlaylistOnlModel>(),
                ...ytvResults['playlists']!.cast<PlaylistOnlModel>(),
              ],
              loadingState: LoadingState.loaded,
              hasReachedMax: true,
              resultType: ResultTypes.playlists,
              sourceEngine: null,
            ));
            break;
          case ResultTypes.artists:
            emit(state.copyWith(
              artistItems: <ArtistModel>[
                ...jisResults['artists']!.cast<ArtistModel>(),
                ...ytmResults['artists']!.cast<ArtistModel>(),
              ],
              loadingState: LoadingState.loaded,
              hasReachedMax: true,
              resultType: ResultTypes.artists,
              sourceEngine: null,
            ));
            break;
        }
      }

      jisFuture.then((res) {
        if (_activeSearchToken != token) return;
        jisResults = res;
        emitProgress();
      });
      ytmFuture.then((res) {
        if (_activeSearchToken != token) return;
        ytmResults = res;
        emitProgress();
      });
      ytvFuture.then((res) {
        if (_activeSearchToken != token) return;
        ytvResults = res;
        emitProgress();
      });

      await Future.wait([jisFuture, ytmFuture, ytvFuture]);
      if (_activeSearchToken != token) return;

      final cacheValue = <String, List<dynamic>>{
        'songs': <MediaItemModel>[
          ...jisResults['songs']!.cast<MediaItemModel>(),
          ...ytmResults['songs']!.cast<MediaItemModel>(),
          ...ytvResults['songs']!.cast<MediaItemModel>(),
        ],
        'albums': <AlbumModel>[
          ...jisResults['albums']!.cast<AlbumModel>(),
          ...ytmResults['albums']!.cast<AlbumModel>(),
        ],
        'playlists': <PlaylistOnlModel>[
          ...jisResults['playlists']!.cast<PlaylistOnlModel>(),
          ...ytmResults['playlists']!.cast<PlaylistOnlModel>(),
          ...ytvResults['playlists']!.cast<PlaylistOnlModel>(),
        ],
        'artists': <ArtistModel>[
          ...jisResults['artists']!.cast<ArtistModel>(),
          ...ytmResults['artists']!.cast<ArtistModel>(),
        ],
      };
      _unifiedCache[cacheKey] = cacheValue;
    } catch (e) {
      log("Unified search error: $e", name: "FetchSearchRes");
      emit(state.copyWith(
        loadingState: LoadingState.loaded,
        hasReachedMax: true,
      ));
    }
  }

  /// Helper method to search JioSaavn with error handling
  Future<Map<String, List<dynamic>>> _searchJISWithFallback(
    String query,
    ResultTypes resultType,
  ) async {
    try {
      switch (resultType) {
        case ResultTypes.songs:
          final res = await SaavnAPI().fetchSongSearchResults(
            searchQuery: query,
            page: 1,
          );
          return {
            'songs': fromSaavnSongMapList2MediaItemList(res['songs']),
            'albums': <AlbumModel>[],
            'playlists': <PlaylistOnlModel>[],
            'artists': <ArtistModel>[],
          };

        case ResultTypes.albums:
          final res = await SaavnAPI().fetchAlbumResults(query);
          return {
            'songs': <MediaItemModel>[],
            'albums': saavnMap2Albums({'Albums': res}),
            'playlists': <PlaylistOnlModel>[],
            'artists': <ArtistModel>[],
          };

        case ResultTypes.playlists:
          final res = await SaavnAPI().fetchPlaylistResults(query);
          return {
            'songs': <MediaItemModel>[],
            'albums': <AlbumModel>[],
            'playlists': saavnMap2Playlists({'Playlists': res}),
            'artists': <ArtistModel>[],
          };

        case ResultTypes.artists:
          final res = await SaavnAPI().fetchArtistResults(query);
          return {
            'songs': <MediaItemModel>[],
            'albums': <AlbumModel>[],
            'playlists': <PlaylistOnlModel>[],
            'artists': saavnMap2Artists({'Artists': res}),
          };
      }
    } catch (e) {
      log("JioSaavn search failed: $e", name: "FetchSearchRes");
      return {
        'songs': <MediaItemModel>[],
        'albums': <AlbumModel>[],
        'playlists': <PlaylistOnlModel>[],
        'artists': <ArtistModel>[],
      };
    }
  }

  /// Helper method to search YT Music with error handling
  Future<Map<String, List<dynamic>>> _searchYTMWithFallback(
    String query,
    ResultTypes resultType,
  ) async {
    try {
      switch (resultType) {
        case ResultTypes.songs:
          final res = await YTMusic().searchYtm(query, type: "songs");
          if (res == null) {
            return {
              'songs': <MediaItemModel>[],
              'albums': <AlbumModel>[],
              'playlists': <PlaylistOnlModel>[],
              'artists': <ArtistModel>[],
            };
          }
          return {
            'songs': ytmMapList2MediaItemList(res['songs']),
            'albums': <AlbumModel>[],
            'playlists': <PlaylistOnlModel>[],
            'artists': <ArtistModel>[],
          };

        case ResultTypes.albums:
          final res = await YTMusic().searchYtm(query, type: "albums");
          if (res == null) {
            return {
              'songs': <MediaItemModel>[],
              'albums': <AlbumModel>[],
              'playlists': <PlaylistOnlModel>[],
              'artists': <ArtistModel>[],
            };
          }
          return {
            'songs': <MediaItemModel>[],
            'albums': ytmMap2Albums(res['albums']),
            'playlists': <PlaylistOnlModel>[],
            'artists': <ArtistModel>[],
          };

        case ResultTypes.playlists:
          final res = await YTMusic().searchYtm(query, type: "playlists");
          if (res == null) {
            return {
              'songs': <MediaItemModel>[],
              'albums': <AlbumModel>[],
              'playlists': <PlaylistOnlModel>[],
              'artists': <ArtistModel>[],
            };
          }
          return {
            'songs': <MediaItemModel>[],
            'albums': <AlbumModel>[],
            'playlists': ytmMap2Playlists(res['playlists']),
            'artists': <ArtistModel>[],
          };

        case ResultTypes.artists:
          final res = await YTMusic().searchYtm(query, type: "artists");
          if (res == null) {
            return {
              'songs': <MediaItemModel>[],
              'albums': <AlbumModel>[],
              'playlists': <PlaylistOnlModel>[],
              'artists': <ArtistModel>[],
            };
          }
          return {
            'songs': <MediaItemModel>[],
            'albums': <AlbumModel>[],
            'playlists': <PlaylistOnlModel>[],
            'artists': ytmMap2Artists(res['artists']),
          };
      }
    } catch (e) {
      log("YT Music search failed: $e", name: "FetchSearchRes");
      return {
        'songs': <MediaItemModel>[],
        'albums': <AlbumModel>[],
        'playlists': <PlaylistOnlModel>[],
        'artists': <ArtistModel>[],
      };
    }
  }

  /// Helper method to search YT Video with error handling
  Future<Map<String, List<dynamic>>> _searchYTVWithFallback(
    String query,
    ResultTypes resultType,
  ) async {
    try {
      switch (resultType) {
        case ResultTypes.songs:
          final res = await YouTubeServices().fetchSearchResults(query);
          return {
            'songs': fromYtVidSongMapList2MediaItemList(res[0]['items']),
            'albums': <AlbumModel>[],
            'playlists': <PlaylistOnlModel>[],
            'artists': <ArtistModel>[],
          };

        case ResultTypes.playlists:
          final res = await YouTubeServices().fetchSearchResults(
            query,
            playlist: true,
          );
          return {
            'songs': <MediaItemModel>[],
            'albums': <AlbumModel>[],
            'playlists': ytvMap2Playlists({'playlists': res[0]['items']}),
            'artists': <ArtistModel>[],
          };

        case ResultTypes.albums:
        case ResultTypes.artists:
          // YT Video doesn't support albums/artists
          return {
            'songs': <MediaItemModel>[],
            'albums': <AlbumModel>[],
            'playlists': <PlaylistOnlModel>[],
            'artists': <ArtistModel>[],
          };
      }
    } catch (e) {
      log("YT Video search failed: $e", name: "FetchSearchRes");
      return {
        'songs': <MediaItemModel>[],
        'albums': <AlbumModel>[],
        'playlists': <PlaylistOnlModel>[],
        'artists': <ArtistModel>[],
      };
    }
  }

  /// Intelligent interleaving of search results from multiple sources
  ///
  /// Strategy:
  /// 1. Prioritize diversity (Round Robin)
  /// 2. Prioritize quality (YTM > JIS > YTV)
  /// 3. Heuristic deduplication (remove exact title matches unless remix/live)
  List<MediaItemModel> _intelligentInterleave(
    List<MediaItemModel> jis,
    List<MediaItemModel> ytm,
    List<MediaItemModel> ytv,
  ) {
    List<MediaItemModel> interleaved = [];

    // Find the maximum length among all lists
    int maxLen = 0;
    if (jis.length > maxLen) maxLen = jis.length;
    if (ytm.length > maxLen) maxLen = ytm.length;
    if (ytv.length > maxLen) maxLen = ytv.length;

    // To track duplicates
    Set<String> addedTitles = {};

    for (int i = 0; i < maxLen; i++) {
      // Priority Order:
      // 1. YouTube Music (Generally unmatched audio quality & metadata)
      // 2. JioSaavn (Good regional content, 320kbps)
      // 3. YouTube Video (Fallback, video audio)

      // 1. Try add YT Music
      if (i < ytm.length) {
        _addIfUniqueAndRelevant(ytm[i], interleaved, addedTitles);
      }

      // 2. Try add JioSaavn
      if (i < jis.length) {
        _addIfUniqueAndRelevant(jis[i], interleaved, addedTitles);
      }

      // 3. Try add YT Video
      if (i < ytv.length) {
        _addIfUniqueAndRelevant(ytv[i], interleaved, addedTitles);
      }
    }

    return interleaved;
  }

  void _addIfUniqueAndRelevant(
    MediaItemModel item,
    List<MediaItemModel> list,
    Set<String> titles,
  ) {
    // Basic normalization for fuzzy matching
    // e.g. "Song Name" == "song name"
    String cleanTitle = item.title.toLowerCase().trim();

    // Check if we strictly already have this song
    bool isDuplicate = titles.contains(cleanTitle);

    // Heuristics to keep duplicates if they are interesting
    bool isInteresting = cleanTitle.contains("remix") ||
        cleanTitle.contains("live") ||
        cleanTitle.contains("cover") ||
        cleanTitle.contains("acoustic") ||
        cleanTitle.contains("slowed") ||
        cleanTitle.contains("reverb");

    if (!isDuplicate || isInteresting) {
      list.add(item);
      // Only mark as "seen" if it's a standard track to allow variations
      if (!isInteresting) {
        titles.add(cleanTitle);
      }
    }
  }
}
