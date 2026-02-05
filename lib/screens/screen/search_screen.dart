// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';
import 'package:Bloomee/blocs/mediaPlayer/bloomee_player_cubit.dart';
import 'package:Bloomee/screens/widgets/album_card.dart';
import 'package:Bloomee/screens/widgets/artist_card.dart';
import 'package:Bloomee/screens/widgets/more_bottom_sheet.dart';
import 'package:Bloomee/screens/widgets/playlist_card.dart';
import 'package:Bloomee/screens/widgets/sign_board_widget.dart';
import 'package:Bloomee/screens/widgets/song_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:Bloomee/blocs/internet_connectivity/cubit/connectivity_cubit.dart';
import 'package:Bloomee/blocs/search/fetch_search_results.dart';
import 'package:Bloomee/screens/screen/search_views/search_page.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:Bloomee/model/search_filter_model.dart';
import 'package:Bloomee/screens/widgets/search_filter_bottom_sheet.dart';
import 'package:Bloomee/screens/widgets/glass_widgets.dart';

class SearchScreen extends StatefulWidget {
  final String searchQuery;
  const SearchScreen({
    Key? key,
    this.searchQuery = "",
  }) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<ResultTypes> resultType =
      ValueNotifier(ResultTypes.songs);
  SearchFilter _searchFilter = const SearchFilter();

  @override
  void dispose() {
    _scrollController.removeListener(loadMoreResults);
    _scrollController.dispose();
    _textEditingController.dispose();
    resultType.dispose();
    super.dispose();
  }

  void loadMoreResults() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        context.read<FetchSearchResultsCubit>().state.hasReachedMax == false) {
      // Unified search doesn't support pagination yet, or handles it internally
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(loadMoreResults);
    if (widget.searchQuery != "") {
      _textEditingController.text = widget.searchQuery;
      // Use unified search across all sources
      context.read<FetchSearchResultsCubit>().searchAllSources(
            widget.searchQuery.toString(),
            resultType: resultType.value,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        onVerticalDragEnd: (DragEndDetails details) =>
            FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: scheme.surface,
          appBar: AppBar(
            forceMaterialTransparency: true,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            toolbarHeight: kToolbarHeight + headerPillTopSpacing(context),
            title: Padding(
              padding: EdgeInsets.only(top: headerPillTopSpacing(context)),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        showSearch(
                                context: context,
                                delegate: SearchPageDelegate(
                                  resultType.value,
                                  filter: _searchFilter,
                                ),
                                query: _textEditingController.text)
                            .then((value) {
                          if (value != null) {
                            _textEditingController.text = value.toString();
                          }
                        });
                      },
                      child: HeaderGlassPill(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _textEditingController.text.isEmpty
                                    ? "Find your next song obsession..."
                                    : _textEditingController.text,
                                textAlign: TextAlign.center,
                                style: Default_Theme.secondoryTextStyle.merge(
                                  TextStyle(
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.65),
                                  ),
                                ),
                              ),
                            ),
                            Icon(
                              MingCute.search_2_fill,
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  HeaderGlassIconPill(
                    children: [
                      IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (context) => SearchFilterBottomSheet(
                              currentFilter: _searchFilter,
                              onFilterChanged: (newFilter) {
                                setState(() {
                                  _searchFilter = newFilter;
                                });
                                if (_textEditingController.text.isNotEmpty) {
                                  context
                                      .read<FetchSearchResultsCubit>()
                                      .searchAllSources(
                                        _textEditingController.text,
                                        resultType: resultType.value,
                                        filter: newFilter,
                                      );
                                }
                              },
                            ),
                          );
                        },
                        icon: Icon(
                          MingCute.filter_2_fill,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: HeaderGlassPill(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: SizedBox(
                      height: 50,
                      child: ValueListenableBuilder(
                        valueListenable: resultType,
                        builder: (context, value, child) {
                          return Row(
                            children: ResultTypes.values.map((type) {
                              final isSelected = resultType.value == type;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    resultType.value = type;
                                    if (_textEditingController.text.isNotEmpty) {
                                      context
                                          .read<FetchSearchResultsCubit>()
                                          .searchAllSources(
                                            _textEditingController.text
                                                .toString(),
                                            resultType: type,
                                          );
                                    }
                                  },
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? scheme.primary.withValues(alpha: 0.18)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: Center(
                                      child: Text(
                                        type.val,
                                        style: Default_Theme
                                            .secondoryTextStyleMedium
                                            .merge(
                                          TextStyle(
                                            color: isSelected
                                                ? scheme.onSurface
                                                : scheme.onSurface
                                                    .withValues(alpha: 0.70),
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
            body: BlocBuilder<ConnectivityCubit, ConnectivityState>(
              builder: (context, state) {
                return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: state == ConnectivityState.disconnected
                        ? const SignBoardWidget(
                            icon: MingCute.wifi_off_line,
                            message: "No internet connection!",
                          )
                        : BlocConsumer<FetchSearchResultsCubit,
                            FetchSearchResultsState>(
                            builder: (context, state) {
                              if (state is FetchSearchResultsLoading) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: scheme.primary,
                                  ),
                                );
                              } else if (state.loadingState ==
                                  LoadingState.loaded) {
                                if (state.resultType == ResultTypes.songs &&
                                    state.mediaItems.isNotEmpty) {
                                  log("Search Results: ${state.mediaItems.length}",
                                      name: "SearchScreen");
                                  return ListView.builder(
                                    controller: _scrollController,
                                    itemCount: state.hasReachedMax
                                        ? state.mediaItems.length
                                        : state.mediaItems.length + 1,
                                    itemBuilder: (context, index) {
                                      if (index == state.mediaItems.length) {
                                        return Center(
                                          child: SizedBox(
                                            height: 30,
                                            width: 30,
                                            child: CircularProgressIndicator(
                                              color: scheme.primary,
                                            ),
                                          ),
                                        );
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: SongCardWidget(
                                          song: state.mediaItems[index],
                                          onTap: () {
                                            context
                                                .read<BloomeePlayerCubit>()
                                                .bloomeePlayer
                                                .updateQueue(
                                              [state.mediaItems[index]],
                                              doPlay: true,
                                            );
                                          },
                                          onOptionsTap: () =>
                                              showMoreBottomSheet(context,
                                                  state.mediaItems[index]),
                                        ),
                                      );
                                    },
                                  );
                                } else if (state.resultType ==
                                        ResultTypes.albums &&
                                    state.albumItems.isNotEmpty) {
                                  return Align(
                                    alignment: Alignment.topCenter,
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: Wrap(
                                        alignment: WrapAlignment.center,
                                        runSpacing: 10,
                                        children: [
                                          for (var album in state.albumItems)
                                            AlbumCard(album: album)
                                        ],
                                      ),
                                    ),
                                  );
                                } else if (state.resultType ==
                                        ResultTypes.artists &&
                                    state.artistItems.isNotEmpty) {
                                  return Align(
                                    alignment: Alignment.topCenter,
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: Wrap(
                                        alignment: WrapAlignment.center,
                                        runSpacing: 10,
                                        children: [
                                          for (var artist in state.artistItems)
                                            ArtistCard(artist: artist)
                                        ],
                                      ),
                                    ),
                                  );
                                } else if (state.resultType ==
                                        ResultTypes.playlists &&
                                    state.playlistItems.isNotEmpty) {
                                  return Align(
                                    alignment: Alignment.topCenter,
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: Wrap(
                                        alignment: WrapAlignment.center,
                                        runSpacing: 10,
                                        children: [
                                          for (var playlist
                                              in state.playlistItems)
                                            PlaylistCard(
                                              playlist: playlist,
                                            )
                                        ],
                                      ),
                                    ),
                                  );
                                } else {
                                  return const SignBoardWidget(
                                      message:
                                          "No results found!\nTry another keyword or source engine!",
                                      icon: MingCute.sweats_line);
                                }
                              } else {
                                return const SignBoardWidget(
                                    message:
                                        "Search for your favorite songs\nand discover new ones!",
                                    icon: MingCute.search_2_line);
                              }
                            },
                            listener: (BuildContext context,
                                FetchSearchResultsState state) {
                              resultType.value = state.resultType;
                            },
                          ));
              },
            ),
          ),
        ),
      ),
    );
  }
}
