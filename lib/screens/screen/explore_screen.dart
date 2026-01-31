import 'dart:developer';
import 'dart:ui';
import 'package:Bloomee/blocs/explore/cubit/explore_cubits.dart';
import 'package:Bloomee/blocs/auth/auth_cubit.dart';
import 'package:Bloomee/blocs/internet_connectivity/cubit/connectivity_cubit.dart';
import 'package:Bloomee/blocs/lastdotfm/lastdotfm_cubit.dart';
import 'package:Bloomee/blocs/mediaPlayer/bloomee_player_cubit.dart';
import 'package:Bloomee/blocs/notification/notification_cubit.dart';
import 'package:Bloomee/blocs/settings_cubit/cubit/settings_cubit.dart';
import 'package:Bloomee/model/MediaPlaylistModel.dart';
import 'package:Bloomee/screens/screen/home_views/recents_view.dart';
import 'package:Bloomee/screens/widgets/more_bottom_sheet.dart';
import 'package:Bloomee/screens/widgets/sign_board_widget.dart';
import 'package:Bloomee/screens/widgets/song_tile.dart';

import 'package:flutter/material.dart';
import 'package:Bloomee/screens/screen/home_views/notification_view.dart';
import 'package:Bloomee/screens/screen/home_views/timer_view.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';
import 'chart/carousal_widget.dart';
import '../widgets/horizontal_card_view.dart';
import '../widgets/tabList_widget.dart';
import 'package:badges/badges.dart' as badges;

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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Removed SafeArea to fix "unwanted bar" (Edge-to-Edge)
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Default_Theme.themeColor,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Default_Theme.themeColor,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
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
              primary: false,
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              slivers: [
                CustomDiscoverBar(greeting: _getGreeting()),
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
                                                    .read<
                                                        BloomeePlayerCubit>()
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

class CustomDiscoverBar extends StatelessWidget {
  final String greeting;
  const CustomDiscoverBar({
    super.key,
    required this.greeting,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Get user name if logged in
    final user = context.read<AuthCubit>().currentUser;
    final String displayName =
        user?.displayName != null && user!.displayName!.isNotEmpty
            ? user.displayName!.split(' ')[0] // First name
            : 'User'; // Fallback if no name

    // If guest or no name, just use greeting. If name exists, add it.
    final String titleText =
        user == null || user.isAnonymous ? greeting : "$greeting, $displayName";

    return SliverAppBar(
      pinned: true,
      floating: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Default_Theme.themeColor,
      backgroundColor: Default_Theme.themeColor,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarColor: Default_Theme.themeColor,
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            // Use Expanded to avoid overflow with long names
            child: Text(titleText,
                overflow: TextOverflow.ellipsis,
                style: Default_Theme.primaryTextStyle.merge(TextStyle(
                    fontSize: 28, // Slightly reduced to fit longer greetings
                    color: Default_Theme.primaryColor1))),
          ),
          const SizedBox(width: 10),
          const _TopActionsPill(),
        ],
      ),
    );
  }
}

class _TopActionsPill extends StatelessWidget {
  const _TopActionsPill();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Default_Theme.themeColor.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Default_Theme.primaryColor1.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              NotificationIcon(size: 26),
              SizedBox(width: 2),
              TimerIcon(size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationIcon extends StatelessWidget {
  final double size;
  const NotificationIcon({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        if (state is NotificationInitial || state.notifications.isEmpty) {
          return IconButton(
            padding: const EdgeInsets.all(5),
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationView()));
            },
            icon: Icon(MingCute.notification_line,
                color: Default_Theme.primaryColor1, size: size),
          );
        }
        return badges.Badge(
          badgeContent: Padding(
            padding: const EdgeInsets.all(1.5),
            child: Text(
              state.notifications.length.toString(),
              style: Default_Theme.primaryTextStyle.merge(TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Default_Theme.primaryColor2)),
            ),
          ),
          badgeStyle: badges.BadgeStyle(
            badgeColor: Default_Theme.accentColor2,
            shape: badges.BadgeShape.circle,
          ),
          position: badges.BadgePosition.topEnd(top: -10, end: -5),
          child: IconButton(
            padding: const EdgeInsets.all(5),
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationView()));
            },
            icon: Icon(MingCute.notification_line,
                color: Default_Theme.primaryColor1, size: size),
          ),
        );
      },
    );
  }
}

class TimerIcon extends StatelessWidget {
  final double size;
  const TimerIcon({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: const EdgeInsets.all(5),
      constraints: const BoxConstraints(),
      onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const TimerView()));
      },
      icon: Icon(MingCute.stopwatch_line,
          color: Default_Theme.primaryColor1, size: size),
    );
  }
}
