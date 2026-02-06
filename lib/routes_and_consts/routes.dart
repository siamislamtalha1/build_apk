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
        final bool isAuthenticated =
            firebaseUser != null && !firebaseUser.isAnonymous;
        final bool isGuest = firebaseUser != null && firebaseUser.isAnonymous;
        final bool isLoggingIn = path == '/Login' || path == '/Signup';

        // 1. If not logged in and not on login/signup page -> Redirect to Login
        if (firebaseUser == null && !isLoggingIn) {
          return '/Login';
        }

        // 2. If fully logged in (non-guest) and on login/signup page -> Redirect to Explore
        // Guests must be allowed to open Login/Signup to upgrade their account.
        // Also allow if user is deliberately navigating to Login/Signup (e.g. from Profile)
        // actually, we should only redirect to Explore if they are already authenticated AND
        // the App started there (not navigating there).
        // But the previous logic was:
        // if (isAuthenticated && isLoggingIn) { return '/Explore'; }
        // This prevents "Sign In to Sync" working for Guest? No, Guest is !isAuthenticated in your logic?
        // Wait: isAuthenticated = firebaseUser != null && !firebaseUser.isAnonymous;
        // isGuest = firebaseUser != null && firebaseUser.isAnonymous;

        // If I am a GUEST, isAuthenticated is FALSE. isGuest is TRUE.
        // So step 2 doesn't apply to Guest.
        // But maybe I was logged in as a normal user?
        // The Issue reported is: "Some time when i not logged in, click on sign in to sync button in account page is showing explore page ui in account page."
        // "This should never happen."
        // This implies they are seeing the Explore page INSTEAD of the Login page.
        // If they are "Not logged in" -> firebaseUser == null OR isGuest == true.
        // If firebaseUser == null -> Step 1 sends them to /Login.
        // If isGuest == true -> Step 3 returns null (allow).

        // If the user says "showing explore page ui in account page", it might mean
        // the router decided to redirect them to /Explore?
        // If they are Guest, isLoggingIn is true.
        // Step 1: false.
        // Step 2: false.
        // Step 3: true -> return null.

        // However, if the user was somehow considered "Authenticated" incorrectly?
        // Or if the initialLocation /Explore was taking over?

        // Let's look at the fix proposed in Plan:
        // "Refine the GoRouter redirect logic to prevent authenticated users (or those perceived as such) from being forcefully redirected to /Explore if they are explicitly trying to access /Login (e.g., from Profile page)."

        // If I am a GUEST, I click "Sign in". Router goes to /Login.
        // isAuthenticated is false.

        // If the user meant: They click "Sign in" and suddenly they see the Explore page...
        // Maybe `refreshListenable` triggered a state change that made them look authenticated?
        // Or maybe `from=profile` param caused an issue?

        // Wait, if I am a Guest, and I go to /Login.
        // If I successfully Login, I become Authenticated.
        // Then the Router sees: Authenticated = true, path = /Login.
        // THEN Step 2 kicks in: return '/Explore'.
        // This overrides the Login page's own logic to redirect to `target`.

        // FIX: If we are on Login/Signup, DO NOT redirect to Explore if there is a 'from' parameter?
        // Or just let the Login page handle the redirection upon success.

        if (isAuthenticated && isLoggingIn) {
          // If we have query params (like from=profile), let the page handle it
          // OR if we are explicitly on these pages, maybe we shouldn't redirect?
          // BUT if we are authenticated, we usually don't want to see Login page.
          // EXCEPTION: If I am authenticated but I want to "Switch Account" or similar?
          // In this app context, if I am authenticated, I shouldn't be on Login unless I just logged in.
          // If I just logged in, the Login page handles the redirection.

          // CRITICAL FIX: If we are here because we just got authenticated (e.g. via listener),
          // we might want to let the Login page's listener handle the navigation logic
          // which knows about the 'from' parameter.
          if (state.uri.queryParameters.containsKey('from')) {
            return null;
          }
          return null;
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
          builder: (context, state) => const GlobalBackdropWrapper(
            child: AdvancedSettingsScreen(),
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
          builder: (context, state) => const GlobalBackdropWrapper(
            child: SettingsView(),
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
