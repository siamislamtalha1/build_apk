import 'package:Bloomee/blocs/settings_cubit/cubit/settings_cubit.dart';
import 'package:Bloomee/screens/widgets/setting_tile.dart';
import 'package:flutter/material.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlayerSettings extends StatelessWidget {
  const PlayerSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          'Audio Player',
          style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)
              .merge(Default_Theme.secondoryTextStyle),
        ),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            children: [
              SettingTile(
                title: "Streaming Quality",
                subtitle:
                    "Quality of audio files streamed from online sources.",
                trailing: DropdownButton(
                  value: state.strmQuality,
                  dropdownColor: scheme.surface,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ).merge(Default_Theme.secondoryTextStyle),
                  underline: const SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      context.read<SettingsCubit>().setStrmQuality(newValue);
                    }
                  },
                  items: <String>['96 kbps', '160 kbps', '320 kbps']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                      ),
                    );
                  }).toList(),
                ),
                onTap: () {},
              ),
              SettingTile(
                title: "Youtube Songs Streaming Quality",
                subtitle:
                    "Quality of Youtube audio files streamed from Youtube.",
                trailing: DropdownButton(
                  value: state.ytStrmQuality,
                  dropdownColor: scheme.surface,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ).merge(Default_Theme.secondoryTextStyle),
                  underline: const SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      context.read<SettingsCubit>().setYtStrmQuality(newValue);
                    }
                  },
                  items: <String>['High', 'Low']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                      ),
                    );
                  }).toList(),
                ),
                onTap: () {},
              ),
              SwitchListTile(
                  value: state.autoPlay,
                  title: Text(
                    "Auto Play",
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ).merge(Default_Theme.secondoryTextStyle),
                  ),
                  subtitle: Text(
                    "Automatically add similar songs to the queue.",
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onChanged: (value) {
                    context.read<SettingsCubit>().setAutoPlay(value);
                  }),
            ],
          );
        },
      ),
    );
  }
}
