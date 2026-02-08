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
import 'package:Bloomee/screens/screen/auth/forgot_password_screen.dart';
import 'package:Bloomee/screens/screen/profile_screen.dart';
import 'package:Bloomee/screens/screen/ai_playlist_screen.dart';
import 'package:Bloomee/screens/screen/home_views/setting_views/about.dart';
import 'package:Bloomee/screens/screen/home_views/setting_view.dart';
import 'package:Bloomee/screens/screen/shared_playlist_screen.dart';

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

        User? firebaseUser;
        try {
          firebaseUser = FirebaseAuth.instance.currentUser;
        } catch (_) {
          firebaseUser = null;
        }
        final bool isAuthenticated =
            firebaseUser != null && !firebaseUser.isAnonymous;
        final bool isGuest = firebaseUser != null && firebaseUser.isAnonymous;
        final bool isLoggingIn =
            path == '/Login' || path == '/Signup' || path == '/ForgotPassword';

        // 1. If NOT logged in (and not a guest), enforce Login
        //    (Allow access to Login/Signup pages)
        if (firebaseUser == null && !isLoggingIn) {
          return '/Login';
        }

        // 2. If Authenticated (non-guest) and try to access Login/Signup:
        //    - If 'from' param exists (e.g. explicit navigation from Profile), ALLOW it.
        //    - If NO 'from' param (e.g. app startup or accidental back), REDIRECT to Explore.
        if (isAuthenticated && isLoggingIn) {
          if (state.uri.queryParameters.containsKey('from')) {
            return null;
          }
          return '/Explore';
        }

        // 3. Guest users:
        //    - Are allowed to be on Login/Signup (to upgrade account).
        //    - Are allowed to be on Rest of App (Explore, etc).
        //    - So if isGuest is true, we generally return null (allow access).
        //    - BUT if they are on Login/Signup, we allow it.
        //    - If they are on other pages, we allow it.
        if (isGuest) {
          return null;
        }

        // Default: Allow navigation
        return null;
      },
      routes: [
        GoRoute(
          path: '/ForgotPassword',
          parentNavigatorKey: globalRouterKey,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          name: GlobalStrConsts.playerScreen,
          path: "/MusicPlayer",
          parentNavigatorKey: globalRouterKey,
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              child: const AudioPlayerView(),
              transitionDuration: const Duration(milliseconds: 300),
              reverseTransitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.easeInOutCubic;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
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
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const AddToPlaylistScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
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
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const GlobalBackdropWrapper(
              child: AdvancedSettingsScreen(),
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          ),
        ),
        GoRoute(
          path: '/DeveloperTools',
          parentNavigatorKey: globalRouterKey,
          name: GlobalStrConsts.developerToolsScreen,
          builder: (context, state) => const GlobalBackdropWrapper(
            child: DeveloperToolsScreen(),
          ),
        ),
        GoRoute(
          path: '/share/playlist/:id',
          parentNavigatorKey: globalRouterKey,
          builder: (context, state) => SharedPlaylistHandler(
            shareId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/p/:id',
          parentNavigatorKey: globalRouterKey,
          builder: (context, state) => SharedPlaylistHandler(
            shareId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/Login',
          parentNavigatorKey: globalRouterKey,
          name: 'Login',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/Signup',
          parentNavigatorKey: globalRouterKey,
          name: 'Signup',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const SignupScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
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
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const GlobalBackdropWrapper(
              child: SettingsView(),
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0), // Slide from right
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          ),
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
              StatefulShellBranch(routes: [
                GoRoute(
                    name: GlobalStrConsts.exploreScreen,
                    path: '/Explore',
                    pageBuilder: (context, state) => CustomTransitionPage(
                          child: const ExploreScreen(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                                opacity: animation, child: child);
                          },
                        ),
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
                    pageBuilder: (context, state) => CustomTransitionPage(
                          child: const LibraryScreen(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                                opacity: animation, child: child);
                          },
                        ),
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
                  pageBuilder: (context, state) {
                    Widget page;
                    if (state.uri.queryParameters['query'] != null) {
                      page = SearchScreen(
                        searchQuery:
                            state.uri.queryParameters['query']!.toString(),
                      );
                    } else {
                      page = const SearchScreen();
                    }
                    return CustomTransitionPage(
                      child: page,
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                    );
                  },
                ),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  name: GlobalStrConsts.offlineScreen,
                  path: '/Offline',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    child: const OfflineScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                ),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  name: GlobalStrConsts.profileScreen,
                  path: '/Profile',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    child: const ProfileScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                ),
              ]),
            ])
      ],
    );
  }
}
