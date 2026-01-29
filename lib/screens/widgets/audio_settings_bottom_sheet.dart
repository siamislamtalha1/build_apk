import 'dart:ui';
import 'package:Bloomee/services/bloomeePlayer.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';

class AudioSettingsBottomSheet extends StatelessWidget {
  const AudioSettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.read<BloomeeMusicPlayer>();

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
                color: Colors.white.withValues(alpha: 0.1),
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
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const Text(
                'Audio Enhancements',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Unageo',
                ),
              ),
              const SizedBox(height: 20),

              // Speed Control
              _buildSliderControl(
                context,
                title: 'Playback Speed',
                stream: player.speed,
                min: 0.5,
                max: 2.0,
                divisions: 15, // 0.1 steps
                onChanged: (val) => player.setSpeed(val),
                formatValue: (val) => '${val.toStringAsFixed(1)}x',
              ),

              const SizedBox(height: 20),

              // Pitch Control
              _buildSliderControl(
                context,
                title: 'Pitch',
                stream: player.pitch,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                onChanged: (val) => player.setPitch(val),
                formatValue: (val) => '${val.toStringAsFixed(1)}x',
              ),

              const SizedBox(height: 20),

              // Toggles
              _buildToggle(
                context,
                title: 'Smart Silence Skip',
                subtitle: 'Skip intros and outros without audio',
                stream: player.skipSilenceEnabled,
                onChanged: (val) => player.setSkipSilenceEnabled(val),
              ),

              const SizedBox(height: 10),

              _buildToggle(
                context,
                title: 'Volume Normalization',
                subtitle: 'Balance volume between tracks',
                stream: player.volumeNormalizationEnabled,
                onChanged: (val) => player.setVolumeNormalization(val),
              ),

              const SizedBox(height: 20),

              // Reset Button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => player.resetAudioEffects(),
                  style: TextButton.styleFrom(
                    foregroundColor: Default_Theme.primaryColor1,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  icon: const Icon(MingCute.refresh_2_line, size: 18),
                  label: const Text('Reset to Default'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderControl(
    BuildContext context, {
    required String title,
    required Stream<double> stream,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
    required String Function(double) formatValue,
  }) {
    return StreamBuilder<double>(
      stream: stream,
      builder: (context, snapshot) {
        final value = snapshot.data ?? 1.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  formatValue(value),
                  style: const TextStyle(
                    color: Default_Theme.accentColor2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Default_Theme.accentColor2,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                thumbColor: Colors.white,
                overlayColor: Default_Theme.accentColor2.withValues(alpha: 0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToggle(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Stream<bool> stream,
    required Function(bool) onChanged,
  }) {
    return StreamBuilder<bool>(
      stream: stream,
      builder: (context, snapshot) {
        final value = snapshot.data ?? false;
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          value: value,
          onChanged: onChanged,
          activeColor: Default_Theme.accentColor2,
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Default_Theme.accentColor2.withValues(alpha: 0.5);
            }
            return Colors.white.withValues(alpha: 0.1);
          }),
        );
      },
    );
  }
}
