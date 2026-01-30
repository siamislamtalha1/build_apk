import 'dart:ui';

import 'package:Bloomee/blocs/mediaPlayer/bloomee_player_cubit.dart';
import 'package:Bloomee/blocs/mini_player/mini_player_bloc.dart';
import 'package:Bloomee/blocs/player_overlay/player_overlay_cubit.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:Bloomee/utils/imgurl_formator.dart';
import 'package:Bloomee/utils/load_Image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:responsive_framework/responsive_framework.dart';

class MiniPlayerWidget extends StatelessWidget {
  const MiniPlayerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MiniPlayerBloc, MiniPlayerState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            const begin = Offset(0.0, 2.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end);
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );
            final offsetAnimation = curvedAnimation.drive(tween);
            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
          child: switch (state) {
            MiniPlayerInitial() => const SizedBox(),
            MiniPlayerCompleted() => MiniPlayerCard(
                state: state,
                isCompleted: true,
              ),
            MiniPlayerWorking() => MiniPlayerCard(
                state: state,
                isProcessing: state.isBuffering,
              ),
            MiniPlayerError() => const SizedBox(),
            MiniPlayerProcessing() => MiniPlayerCard(
                state: state,
                isProcessing: true,
              ),
          },
        );
      },
    );
  }
}

class MiniPlayerCard extends StatelessWidget {
  final MiniPlayerState state;
  final bool isCompleted;
  final bool isProcessing;

  const MiniPlayerCard({
    super.key,
    required this.state,
    this.isCompleted = false,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<PlayerOverlayCubit>().showPlayer();
      },
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < -10) {
          context.read<BloomeePlayerCubit>().bloomeePlayer.skipToNext();
        }
        if (details.primaryVelocity! > 10) {
          context.read<BloomeePlayerCubit>().bloomeePlayer.skipToPrevious();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1.0,
                ),
                boxShadow: [],
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Pure glassmorphic overlay - no background image
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        // Extremely subtle tint for better readability, almost fully transparent
                        color: Default_Theme.themeColor
                            .withValues(alpha: 0.02), // Reduced from 0.05
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        // Album art
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: LoadImageCached(
                              imageUrl: formatImgURL(
                                  state.song.artUri.toString(),
                                  ImageQuality.low),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Song info
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.song.title,
                                style: Default_Theme.secondoryTextStyle.merge(
                                    const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Default_Theme.primaryColor1)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                state.song.artist ?? 'Unknown Artist',
                                style: Default_Theme.secondoryTextStyle.merge(
                                    TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12.5,
                                        color: Default_Theme.primaryColor1
                                            .withValues(alpha: 0.7))),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Desktop controls
                        if (ResponsiveBreakpoints.of(context).isDesktop) ...[
                          IconButton(
                            icon: const Icon(
                              FontAwesome.backward_step_solid,
                              size: 20,
                              color: Default_Theme.primaryColor1,
                            ),
                            onPressed: () {
                              context
                                  .read<BloomeePlayerCubit>()
                                  .bloomeePlayer
                                  .skipToPrevious();
                            },
                          ),
                        ],
                        // Play/Pause button
                        (state.isBuffering || isProcessing)
                            ? const Padding(
                                padding: EdgeInsets.all(10.0),
                                child: SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      color: Default_Theme.accentColor2,
                                      strokeWidth: 2.5,
                                    )),
                              )
                            : (isCompleted
                                ? IconButton(
                                    onPressed: () {
                                      context
                                          .read<BloomeePlayerCubit>()
                                          .bloomeePlayer
                                          .rewind();
                                    },
                                    icon: const Icon(
                                      FontAwesome.rotate_right_solid,
                                      size: 22,
                                      color: Default_Theme.accentColor2,
                                    ))
                                : IconButton(
                                    icon: Icon(
                                      state.isPlaying
                                          ? FontAwesome.pause_solid
                                          : FontAwesome.play_solid,
                                      size: 22,
                                      color: Default_Theme.accentColor2,
                                    ),
                                    onPressed: () {
                                      state.isPlaying
                                          ? context
                                              .read<BloomeePlayerCubit>()
                                              .bloomeePlayer
                                              .pause()
                                          : context
                                              .read<BloomeePlayerCubit>()
                                              .bloomeePlayer
                                              .play();
                                    },
                                  )),
                        // Desktop controls
                        if (ResponsiveBreakpoints.of(context).isDesktop) ...[
                          IconButton(
                            icon: const Icon(
                              FontAwesome.forward_step_solid,
                              size: 20,
                              color: Default_Theme.primaryColor1,
                            ),
                            onPressed: () {
                              context
                                  .read<BloomeePlayerCubit>()
                                  .bloomeePlayer
                                  .skipToNext();
                            },
                          ),
                        ],
                        // Close button
                        IconButton(
                          onPressed: () {
                            context
                                .read<BloomeePlayerCubit>()
                                .bloomeePlayer
                                .stop();
                            context
                                .read<MiniPlayerBloc>()
                                .add(MiniPlayerInitialEvent());
                          },
                          icon: const Icon(
                            MingCute.close_circle_fill,
                            size: 24,
                            color: Default_Theme.primaryColor1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Progress bar
                  if (!isCompleted)
                    Positioned(
                      bottom: 0,
                      left: 12,
                      right: 12,
                      height: 3,
                      child: StreamBuilder<ProgressBarStreams>(
                        stream:
                            context.watch<BloomeePlayerCubit>().progressStreams,
                        builder: (context, snapshot) {
                          if (snapshot.hasData &&
                              snapshot.data!.currentPlaybackState.duration !=
                                  null) {
                            final progress = snapshot.data!.currentPos;
                            final total =
                                snapshot.data!.currentPlaybackState.duration!;
                            final progressFraction = total.inMilliseconds > 0
                                ? progress.inMilliseconds / total.inMilliseconds
                                : 0.0;
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: progressFraction.clamp(0.0, 1.0),
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.1),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Default_Theme.accentColor2,
                                ),
                                minHeight: 3,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
