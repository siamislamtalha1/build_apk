import 'dart:developer';
import 'package:Bloomee/blocs/explore/cubit/explore_cubits.dart';
import 'package:Bloomee/blocs/internet_connectivity/cubit/connectivity_cubit.dart';
import 'package:Bloomee/blocs/lastdotfm/lastdotfm_cubit.dart';
import 'package:Bloomee/blocs/mediaPlayer/bloomee_player_cubit.dart';

import 'package:Bloomee/blocs/settings_cubit/cubit/settings_cubit.dart';
import 'package:Bloomee/model/MediaPlaylistModel.dart';
import 'package:Bloomee/screens/screen/home_views/recents_view.dart';

import 'package:Bloomee/screens/widgets/more_bottom_sheet.dart';
import 'package:Bloomee/screens/widgets/sign_board_widget.dart';
import 'package:Bloomee/screens/widgets/song_tile.dart';
import 'package:flutter/material.dart';

import 'package:Bloomee/theme_data/default.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';
import 'chart/carousal_widget.dart';
import '../widgets/horizontal_card_view.dart';
import '../widgets/tabList_widget.dart';


class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  bool isUpdateChecked = false;
  YTMusicCubit yTMusicCubit = YTMusicCubit();
  Future<MediaPlaylist> lFMData =
      Future.value(const MediaPlaylist(mediaItems: [], playlistName: ""));

  @override
  void initState() {
    super.initState();
  }

  Future<MediaPlaylist> fetchLFMPicks(bool state, BuildContext ctx) async {
    if (state) {
      try {
        final data = await lFMData;
        if (data.mediaItems.isNotEmpty) {
          return data;
        }

        if (ctx.mounted) {
          lFMData = ctx.read<LastdotfmCubit>().getRecommendedTracks();
        }
        return (await lFMData);
      } catch (e) {
        log(e.toString(), name: "ExploreScreen");
      }
    }
    return const MediaPlaylist(mediaItems: [], playlistName: "");
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: MultiBlocProvider(
        providers: [
          BlocProvider<RecentlyCubit>(
            create: (context) => RecentlyCubit(),
            lazy: false,
          ),
          BlocProvider(
            create: (context) => yTMusicCubit,
            lazy: false,
          ),
          BlocProvider(
            create: (context) => FetchChartCubit(),
            lazy: false,
          ),
        ],
        child: Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              await yTMusicCubit.fetchYTMusic();
            },
            child: CustomScrollView(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      CaraouselWidget(),
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: SizedBox(
                          child:
                              BlocBuilder<RecentlyCubit, RecentlyCubitState>(
                            builder: (context, state) {
                              if (state is RecentlyCubitInitial) {
                                return Center(
                                  child: SizedBox(
                                      height: 60,
                                      width: 60,
                                      child: CircularProgressIndicator(
                                        color: Default_Theme.accentColor2,
                                      )),
                                );
                              }
                              if (state.mediaPlaylist.mediaItems.isNotEmpty) {
                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const HistoryView()));
                                  },
                                  child: TabSongListWidget(
                                    list: state.mediaPlaylist.mediaItems
                                        .map((e) {
                                      return SongCardWidget(
                                        song: e,
                                        onTap: () {
                                          context
                                              .read<BloomeePlayerCubit>()
                                              .bloomeePlayer
                                              .updateQueue(
                                            [e],
                                            doPlay: true,
                                          );
                                        },
                                        onOptionsTap: () =>
                                            showMoreBottomSheet(context, e),
                                      );
                                    }).toList(),
                                    category: "Recently",
                                    columnSize: 3,
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                      ),
                      BlocBuilder<SettingsCubit, SettingsState>(
                        builder: (context, state) {
                          if (state.lFMPicks) {
                            return FutureBuilder(
                                future:
                                    fetchLFMPicks(state.lFMPicks, context),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      (snapshot.data?.mediaItems.isNotEmpty ??
                                          false)) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(top: 15.0),
                                      child: TabSongListWidget(
                                          list: snapshot.data!.mediaItems
                                              .map((e) {
                                            return SongCardWidget(
                                              song: e,
                                              onTap: () {
                                                context
                                                    .read<BloomeePlayerCubit>()
                                                    .bloomeePlayer
                                                    .loadPlaylist(
                                                      snapshot.data!,
                                                      idx: snapshot
                                                          .data!.mediaItems
                                                          .indexOf(e),
                                                      doPlay: true,
                                                    );
                                              },
                                              onOptionsTap: () =>
                                                  showMoreBottomSheet(
                                                      context, e),
                                            );
                                          }).toList(),
                                          category: "Last.Fm Picks",
                                          columnSize: 3),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                });
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      BlocBuilder<YTMusicCubit, YTMusicCubitState>(
                        builder: (context, state) {
                          if (state is YTMusicCubitInitial) {
                            return BlocBuilder<ConnectivityCubit,
                                ConnectivityState>(
                              builder: (context, state2) {
                                if (state2 ==
                                    ConnectivityState.disconnected) {
                                  return const SignBoardWidget(
                                    message: "No Internet Connection!",
                                    icon: MingCute.wifi_off_line,
                                  );
                                }
                                return const SizedBox();
                              },
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            itemExtent: 275,
                            padding: const EdgeInsets.only(top: 0),
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.ytmData["body"]!.length,
                            itemBuilder: (context, index) {
                              return HorizontalCardView(
                                  data: state.ytmData["body"]![index]);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          backgroundColor: Default_Theme.themeColor,
        ),
      ),
    );
  }
}


