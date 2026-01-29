import 'package:Bloomee/blocs/player_overlay/player_overlay_cubit.dart';
import 'package:Bloomee/screens/widgets/player_overlay_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:Bloomee/screens/widgets/mini_player_widget.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../theme_data/default.dart';
import 'dart:ui';

class GlobalFooter extends StatelessWidget {
  const GlobalFooter({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return PlayerOverlayWrapper(
      child: PopScope(
        canPop: !context.watch<PlayerOverlayCubit>().state &&
            navigationShell.currentIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            final playerOverlayCubit = context.read<PlayerOverlayCubit>();
            // First check if player overlay is open
            if (playerOverlayCubit.state) {
              // First try to collapse UpNext panel if expanded
              if (!playerOverlayCubit.collapseUpNextPanel()) {
                // If panel was not expanded, hide the player
                playerOverlayCubit.hidePlayer();
              }
            } else {
              navigationShell.goBranch(0);
            }
          }
        },
        child: Scaffold(
          body: ResponsiveBreakpoints.of(context).isMobile
              ? _AnimatedPageView(navigationShell: navigationShell)
              : Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: VerticalNavBar(navigationShell: navigationShell),
                    ),
                    Expanded(
                      child:
                          _AnimatedPageView(navigationShell: navigationShell),
                    ),
                  ],
                ),
          backgroundColor: Default_Theme.themeColor,
          drawerScrimColor: Default_Theme.themeColor,
          bottomNavigationBar: SafeArea(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniPlayerWidget(),
              Container(
                color: Colors.transparent,
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: ResponsiveBreakpoints.of(context).isMobile
                    ? HorizontalNavBar(navigationShell: navigationShell)
                    : const Wrap(),
              ),
            ],
          )),
        ),
      ),
    );
  }
}

class _AnimatedPageView extends StatefulWidget {
  const _AnimatedPageView({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  State<_AnimatedPageView> createState() => _AnimatedPageViewState();
}

class _AnimatedPageViewState extends State<_AnimatedPageView>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      // A shorter duration for a faster animation
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        // A curve that starts fast and slows down for a smooth feel
        curve: Curves.easeOutCubic,
      ),
    );

    // Scale (zoom) animation
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _previousIndex = widget.navigationShell.currentIndex;

    // Trigger the animation on the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(_AnimatedPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell.currentIndex != _previousIndex) {
      _previousIndex = widget.navigationShell.currentIndex;
      // Reset and restart the animation for subsequent page changes
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.navigationShell,
      ),
    );
  }
}

class VerticalNavBar extends StatelessWidget {
  const VerticalNavBar({
    super.key,
    required this.navigationShell,
  });
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.0,
              ),
            ),
            child: NavigationRail(
              backgroundColor: Colors.transparent,
              destinations: const [
                NavigationRailDestination(
                    icon: Icon(MingCute.home_4_fill), label: Text('Home')),
                NavigationRailDestination(
                    icon: Icon(MingCute.book_5_fill), label: Text('Library')),
                NavigationRailDestination(
                    icon: Icon(MingCute.search_2_fill), label: Text('Search')),
                NavigationRailDestination(
                    icon: Icon(MingCute.folder_download_fill),
                    label: Text('Offline')),
                NavigationRailDestination(
                    icon: Icon(MingCute.user_3_fill), label: Text('Account')),
              ],
              selectedIndex: navigationShell.currentIndex,
              minWidth: 75, // More spacious for Windows
              onDestinationSelected: (value) {
                navigationShell.goBranch(value);
              },
              groupAlignment: 0.0,
              unselectedIconTheme:
                  const IconThemeData(color: Default_Theme.primaryColor2),
              indicatorColor:
                  Default_Theme.accentColor2.withValues(alpha: 0.25),
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HorizontalNavBar extends StatelessWidget {
  const HorizontalNavBar({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
            decoration: BoxDecoration(
            // Pure glassmorphic - transparent background like mini player
            color: Default_Theme.themeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                context,
                icon: MingCute.home_4_fill,
                label: 'Home',
                index: 0,
              ),
              _buildNavItem(
                context,
                icon: MingCute.book_5_fill,
                label: 'Library',
                index: 1,
              ),
              _buildNavItem(
                context,
                icon: MingCute.search_2_fill,
                label: 'Search',
                index: 2,
              ),
              _buildNavItem(
                context,
                icon: MingCute.folder_download_fill,
                label: 'Offline',
                index: 3,
              ),
              _buildNavItem(
                context,
                icon: MingCute.user_3_fill,
                label: 'Account',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = navigationShell.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => navigationShell.goBranch(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Default_Theme.accentColor2.withValues(alpha: 0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Default_Theme.accentColor2
                    : Default_Theme.primaryColor2,
                size: 24,
              ),
              if (isSelected) ...{
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: Default_Theme.secondoryTextStyleMedium.merge(
                      const TextStyle(
                        color: Default_Theme.accentColor2,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}
