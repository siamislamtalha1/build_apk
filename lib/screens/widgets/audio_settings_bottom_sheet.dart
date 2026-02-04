import 'dart:ui';
import 'package:Bloomee/blocs/mediaPlayer/bloomee_player_cubit.dart';
import 'package:Bloomee/blocs/settings_cubit/cubit/settings_cubit.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AudioSettingsBottomSheet extends StatelessWidget {
  const AudioSettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final player = context.read<BloomeePlayerCubit>().bloomeePlayer;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Default_Theme.themeColor.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(
              top: BorderSide(
                color: scheme.onSurface.withValues(alpha: isDark ? 0.10 : 0.08),
                width: 1.5,
              ),
            ),
          ),
          padding:
              const EdgeInsets.only(top: 10, bottom: 30, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: isDark ? 0.30 : 0.20),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                'Audio Enhancements',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Unageo',
                ),
              ),
              const SizedBox(height: 20),

              BlocBuilder<SettingsCubit, SettingsState>(
                buildWhen: (p, n) =>
                    p.playbackSpeed != n.playbackSpeed ||
                    p.playbackPitch != n.playbackPitch,
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SliderRow(
                        icon: Icons.speed,
                        title: 'Speed',
                        value: state.playbackSpeed,
                        min: 0.5,
                        max: 2.0,
                        divisions: 30,
                        onChanged: (v) async {
                          await context
                              .read<SettingsCubit>()
                              .setPlaybackSpeed(v);
                          await player.setPlaybackSpeed(v);
                        },
                      ),
                      const SizedBox(height: 12),
                      _SliderRow(
                        icon: MingCute.music_2_line,
                        title: 'Pitch',
                        value: state.playbackPitch,
                        min: 0.5,
                        max: 2.0,
                        divisions: 30,
                        onChanged: (v) async {
                          await context
                              .read<SettingsCubit>()
                              .setPlaybackPitch(v);
                          await player.setPlaybackPitch(v);
                        },
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 10),

              BlocBuilder<SettingsCubit, SettingsState>(
                buildWhen: (p, n) => p.skipSilenceEnabled != n.skipSilenceEnabled,
                builder: (context, state) {
                  return SwitchListTile(
                    value: state.skipSilenceEnabled,
                    onChanged: (v) async {
                      await context
                          .read<SettingsCubit>()
                          .setSkipSilenceEnabled(v);
                      await player.setSkipSilenceEnabled(v);
                    },
                    activeColor: Default_Theme.accentColor1,
                    title: Text(
                      'Skip silence',
                      style: TextStyle(
                        color: Default_Theme.primaryColor1,
                        fontFamily: 'Unageo',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'May be unsupported on some platforms',
                      style: TextStyle(
                        color:
                            Default_Theme.primaryColor1.withValues(alpha: 0.65),
                        fontFamily: 'Unageo',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),

              BlocBuilder<SettingsCubit, SettingsState>(
                buildWhen: (p, n) => p.equalizerEnabled != n.equalizerEnabled,
                builder: (context, state) {
                  return SwitchListTile(
                    value: state.equalizerEnabled,
                    onChanged: (v) async {
                      await context
                          .read<SettingsCubit>()
                          .setEqualizerEnabled(v);
                    },
                    activeColor: Default_Theme.accentColor1,
                    title: Text(
                      'Equalizer',
                      style: TextStyle(
                        color: Default_Theme.primaryColor1,
                        fontFamily: 'Unageo',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Android system EQ if available',
                      style: TextStyle(
                        color:
                            Default_Theme.primaryColor1.withValues(alpha: 0.65),
                        fontFamily: 'Unageo',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),

              BlocBuilder<SettingsCubit, SettingsState>(
                buildWhen: (p, n) =>
                    p.normalizationEnabled != n.normalizationEnabled ||
                    p.normalizationGainMb != n.normalizationGainMb,
                builder: (context, state) {
                  final gainDb = (state.normalizationGainMb / 100).toDouble();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        value: state.normalizationEnabled,
                        onChanged: (v) async {
                          await context
                              .read<SettingsCubit>()
                              .setNormalizationEnabled(v);
                          await player.setNormalization(
                            enabled: v,
                            gainMb: state.normalizationGainMb,
                          );
                        },
                        activeColor: Default_Theme.accentColor1,
                        title: Text(
                          'Normalization',
                          style: TextStyle(
                            color: Default_Theme.primaryColor1,
                            fontFamily: 'Unageo',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Android loudness enhancer',
                          style: TextStyle(
                            color: Default_Theme.primaryColor1
                                .withValues(alpha: 0.65),
                            fontFamily: 'Unageo',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: state.normalizationEnabled ? 1.0 : 0.5,
                        child: IgnorePointer(
                          ignoring: !state.normalizationEnabled,
                          child: _SliderRow(
                            icon: Icons.graphic_eq,
                            title: 'Gain (dB)',
                            value: gainDb,
                            min: 0.0,
                            max: 20.0,
                            divisions: 40,
                            onChanged: (v) async {
                              final mb = (v * 100).round();
                              await context
                                  .read<SettingsCubit>()
                                  .setNormalizationGainMb(mb);
                              await player.setNormalization(
                                enabled: state.normalizationEnabled,
                                gainMb: mb,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 6),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    await player.openSystemEqualizer();
                  },
                  icon: Icon(
                    Icons.equalizer,
                    size: 18,
                    color: Default_Theme.primaryColor1,
                  ),
                  label: Text(
                    'Open Equalizer',
                    style: TextStyle(
                      color: Default_Theme.primaryColor1,
                      fontFamily: 'Unageo',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: scheme.onSurface.withValues(alpha: isDark ? 0.9 : 0.85),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Default_Theme.primaryColor1,
                  fontFamily: 'Unageo',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                color: Default_Theme.primaryColor1.withValues(alpha: 0.8),
                fontFamily: 'Unageo',
                fontSize: 12,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: Default_Theme.accentColor1,
          inactiveColor: scheme.onSurface.withValues(alpha: isDark ? 0.25 : 0.18),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
