import 'package:Bloomee/screens/widgets/global_footer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:Bloomee/routes_and_consts/global_str_consts.dart';
import 'package:Bloomee/screens/screen/common_views/add_to_playlist_screen.dart';
import 'package:Bloomee/screens/screen/player_screen.dart';
import 'package:Bloomee/screens/screen/explore_screen.dart';
import 'package:Bloomee/screens/screen/library_screen.dart';
import 'package:Bloomee/screens/screen/library_views/import_media_view.dart';
import 'package:Bloomee/screens/screen/library_views/playlist_screen.dart';
import 'package:Bloomee/screens/screen/offline_screen.dart';
import 'package:Bloomee/screens/screen/search_screen.dart';
import 'package:Bloomee/screens/screen/chart/chart_view.dart';
import 'package:Bloomee/screens/screen/statistics_screen.dart';
import 'package:Bloomee/screens/screen/moods_genres_screen.dart';
import 'package:Bloomee/screens/screen/settings_views/advanced_settings_screen.dart';
import 'package:Bloomee/screens/screen/settings_views/developer_tools_screen.dart';
import 'package:Bloomee/screens/screen/auth/login_screen.dart';
import 'package:Bloomee/screens/screen/auth/signup_screen.dart';
import 'package:Bloomee/screens/screen/profile_screen.dart';
import 'package:Bloomee/screens/screen/ai_playlist_screen.dart';
import 'package:Bloomee/screens/screen/home_views/setting_views/about.dart';
import 'package:Bloomee/screens/screen/home_views/setting_view.dart';

import 'package:Bloomee/blocs/auth/auth_cubit.dart';
import 'package:Bloomee/routes_and_consts/go_router_refresh_stream.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GlobalRoutes {
  static final globalRouterKey = GlobalKey<NavigatorState>();

  static GoRouter getRouter(AuthCubit authCubit) {
    return GoRouter(
      debugLogDiagnostics: true,
      initialLocation: '/Explore',
      navigatorKey: globalRouterKey,
      refreshListenable: GoRouterRefreshStream(authCubit.stream),
      redirect: (context, state) {
        final path = state.uri.path;
        if (path.length > 1 && path.endsWith('/')) {
          final trimmedPath = path.substring(0, path.length - 1);
          final query = state.uri.hasQuery ? '?${state.uri.query}' : '';
          return '$trimmedPath$query';
        }
        final authState = authCubit.state;
        if (authState is AuthInitial || authState is AuthLoading) {
          return null;
        }

        final firebaseUser = FirebaseAuth.instance.currentUser;
        final bool isAuthenticated = firebaseUser != null && !firebaseUser.isAnonymous;
        final bool isGuest = firebaseUser != null && firebaseUser.isAnonymous;
        final bool isLoggingIn = path == '/Login' || path == '/Signup';

        // 1. If not logged in and not on login/signup page -> Redirect to Login
        if (firebaseUser == null && !isLoggingIn) {
          return '/Login';
        }

        // 2. If fully logged in (non-guest) and on login/signup page -> Redirect to Explore
        // Guests must be allowed to open Login/Signup to upgrade their account.
        if (isAuthenticated && isLoggingIn) {
          return '/Explore';
        }

        // 3. Guest users are allowed to stay on Login/Signup
        if (isGuest && isLoggingIn) {
          return null;
        }

        // No redirect needed
        return null;
      },
      routes: [
        GoRoute(
          name: GlobalStrConsts.playerScreen,
          path: "/MusicPlayer",
          parentNavigatorKey: globalRouterKey,
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              child: const AudioPlayerView(),
              transitionDuration: const Duration(milliseconds: 100),
              reverseTransitionDuration: const Duration(milliseconds: 100),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                final tween = Tween(begin: begin, end: end);
                final curvedAnimation = CurvedAnimation(
                  parent: animation,
                  reverseCurve: Curves.easeIn,
                  curve: Curves.easeInOut,
                );
                final offsetAnimation = curvedAnimation.drive(tween);
                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
            );
          },
        ),
        GoRoute(
          path: '/AddToPlaylist',
          parentNavigatorKey: globalRouterKey,
          name: GlobalStrConsts.addToPlaylistScreen,
          builder: (context, state) => const AddToPlaylistScreen(),
        ),
        GoRoute(
          path: '/Statistics',
          parentNavigatorKey: globalRouterKey,
          name: GlobalStrConsts.statisticsScreen,
          builder: (context, state) => const StatisticsScreen(),
        ),
        GoRoute(
          path: '/MoodsGenres',
          parentNavigatorKey: globalRouterKey,
          name: GlobalStrConsts.moodsGenresScreen,
          builder: (context, state) => const MoodsGenresScreen(),
        ),
        GoRoute(
          path: '/AdvancedSettings',
          parentNavigatorKey: globalRouterKey,
          name: GlobalStrConsts.advancedSettingsScreen,
          builder: (context, state) => const AdvancedSettingsScreen(),
        ),
        GoRoute(
          path: '/DeveloperTools',
          parentNavigatorKey: globalRouterKey,
          name: GlobalStrConsts.developerToolsScreen,
          builder: (context, state) => const DeveloperToolsScreen(),
        ),
        GoRoute(
          path: '/Login',
          parentNavigatorKey: globalRouterKey,
          name: 'Login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/Signup',
          parentNavigatorKey: globalRouterKey,
          name: 'Signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/AIPlaylist',
          parentNavigatorKey: globalRouterKey,
          name: 'AIPlaylist',
          builder: (context, state) => const AIPlaylistScreen(),
        ),
        GoRoute(
          path: '/Settings',
          parentNavigatorKey: globalRouterKey,
          name: 'Settings',
          builder: (context, state) => const SettingsView(),
        ),
        GoRoute(
          path: '/About',
          parentNavigatorKey: globalRouterKey,
          name: 'About',
          builder: (context, state) => const AboutHub(),
        ),
        GoRoute(
          path: '/Settings/About',
          parentNavigatorKey: globalRouterKey,
          name: 'SettingsAbout',
          builder: (context, state) => const AboutHub(),
        ),
        GoRoute(
          path: '/About/Developer',
          parentNavigatorKey: globalRouterKey,
          name: 'AboutDeveloper',
          builder: (context, state) => const About(),
        ),
        GoRoute(
          path: '/About/App',
          parentNavigatorKey: globalRouterKey,
          name: 'AboutApp',
          builder: (context, state) => const AppAbout(),
        ),
        StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                GlobalFooter(navigationShell: navigationShell),
            branches: [
              // StatefulShellBranch(routes: [
              //   GoRoute(
              //     name: GlobalStrConsts.testScreen,
              //     path: '/Test',
              //     builder: (context, state) => TestView(),
              //   ),
              // ]),
              StatefulShellBranch(routes: [
                GoRoute(
                    name: GlobalStrConsts.exploreScreen,
                    path: '/Explore',
                    builder: (context, state) => const ExploreScreen(),
                    routes: [
                      GoRoute(
                          name: GlobalStrConsts.ChartScreen,
                          path: 'ChartScreen:chartName',
                          builder: (context, state) => ChartScreen(
                              chartName:
                                  state.pathParameters['chartName'] ?? "none")),
                    ])
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                    name: GlobalStrConsts.libraryScreen,
                    path: '/Library',
                    builder: (context, state) => const LibraryScreen(),
                    routes: [
                      GoRoute(
                        path: GlobalStrConsts.ImportMediaFromPlatforms,
                        name: GlobalStrConsts.ImportMediaFromPlatforms,
                        builder: (context, state) =>
                            const ImportMediaFromPlatformsView(),
                      ),
                      GoRoute(
                        name: GlobalStrConsts.playlistView,
                        path: GlobalStrConsts.playlistView,
                        builder: (context, state) {
                          return const PlaylistView();
                        },
                      ),
                    ]),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  name: GlobalStrConsts.searchScreen,
                  path: '/Search',
                  builder: (context, state) {
                    if (state.uri.queryParameters['query'] != null) {
                      return SearchScreen(
                        searchQuery:
                            state.uri.queryParameters['query']!.toString(),
                      );
                    } else {
                      return const SearchScreen();
                    }
                  },
                ),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  name: GlobalStrConsts.offlineScreen,
                  path: '/Offline',
                  builder: (context, state) => const OfflineScreen(),
                ),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  name: GlobalStrConsts.profileScreen,
                  path: '/Profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ]),
            ])
      ],
    );
  }
}
