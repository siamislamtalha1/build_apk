// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';
import 'dart:ui';
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
    return SafeArea(
      bottom: false,
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        onVerticalDragEnd: (DragEndDetails details) =>
            FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            forceMaterialTransparency: true,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50.0,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 10,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
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
                        child: TextField(
                          controller: _textEditingController,
                          enabled: false,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Default_Theme.primaryColor1
                                  .withValues(alpha: 0.55)),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                              filled: true,
                              suffixIcon: Icon(
                                MingCute.search_2_fill,
                                color: Default_Theme.primaryColor1
                                    .withValues(alpha: 0.4),
                              ),
                              fillColor: Default_Theme.primaryColor2
                                  .withValues(alpha: 0.07),
                              contentPadding: const EdgeInsets.only(
                                  top: 20, left: 15, right: 5),
                              hintText: "Find your next song obsession...",
                              hintStyle: TextStyle(
                                color: Default_Theme.primaryColor1
                                    .withValues(alpha: 0.3),
                                fontFamily: "Unageo",
                                fontWeight: FontWeight.normal,
                              ),
                              disabledBorder: OutlineInputBorder(
                                  borderSide:
                                      const BorderSide(style: BorderStyle.none),
                                  borderRadius: BorderRadius.circular(50)),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Default_Theme.primaryColor1
                                          .withValues(alpha: 0.7)),
                                  borderRadius: BorderRadius.circular(50))),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) => SearchFilterBottomSheet(
                        currentFilter: _searchFilter,
                        onFilterChanged: (newFilter) {
                          setState(() {
                            _searchFilter = newFilter;
                          });
                          // Re-search with new filters
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
                    color: Default_Theme.primaryColor1,
                  ),
                ),
              ],
            ),
          ),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color:
                              Default_Theme.themeColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
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
                                      // Use unified search when result type changes
                                      if (_textEditingController
                                          .text.isNotEmpty) {
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
                                            ? Default_Theme.accentColor2
                                                .withValues(alpha: 0.3)
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
                                                  ? Default_Theme.accentColor2
                                                  : Default_Theme.primaryColor1
                                                      .withValues(alpha: 0.7),
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
                                    color: Default_Theme.accentColor2,
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
                                              color: Default_Theme.accentColor2,
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
