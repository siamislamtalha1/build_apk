import 'package:Bloomee/blocs/settings_cubit/cubit/settings_cubit.dart';
import 'package:Bloomee/model/source_engines.dart';
import 'package:Bloomee/repository/LastFM/lastfmapi.dart';
import 'package:Bloomee/screens/screen/chart/show_charts.dart';
import 'package:Bloomee/screens/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppUISettings extends StatefulWidget {
  const AppUISettings({super.key});

  @override
  State<AppUISettings> createState() => _AppUISettingsState();
}

class _AppUISettingsState extends State<AppUISettings> {
  List<bool> sourceEngineSwitches =
      SourceEngine.values.map((e) => true).toList();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'UI & Services Settings',
          style: TextStyle(
                  color: Default_Theme.primaryColor1,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)
              .merge(Default_Theme.secondoryTextStyle),
        ),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            children: [
              // Theme Mode Setting
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "App Theme",
                      style: TextStyle(
                              color: Default_Theme.primaryColor1, fontSize: 16)
                          .merge(Default_Theme.secondoryTextStyleMedium),
                    ),
                    DropdownButton<ThemeMode>(
                      value: state.themeMode,
                      dropdownColor: Default_Theme.themeColor,
                      style: TextStyle(color: Default_Theme.primaryColor1),
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text("System"),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text("Light"),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text("Dark"),
                        ),
                      ],
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          context.read<SettingsCubit>().setThemeMode(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10),
              SwitchListTile(
                  value: state.autoSlideCharts,
                  subtitle: Text(
                    "Slide charts automatically in home screen.",
                    style: TextStyle(
                            color: Default_Theme.primaryColor1
                                .withValues(alpha: 0.5),
                            fontSize: 12)
                        .merge(Default_Theme.secondoryTextStyleMedium),
                  ),
                  title: Text(
                    "Auto slide charts",
                    style: TextStyle(
                            color: Default_Theme.primaryColor1, fontSize: 16)
                        .merge(Default_Theme.secondoryTextStyleMedium),
                  ),
                  onChanged: (value) {
                    context.read<SettingsCubit>().setAutoSlideCharts(value);
                  }),
              SwitchListTile(
                  value: state.lFMPicks,
                  subtitle: Text(
                    "Suggestions from Last.FM will be shown in the home screen. (Login & Restart required)",
                    style: TextStyle(
                            color: Default_Theme.primaryColor1
                                .withValues(alpha: 0.5),
                            fontSize: 12)
                        .merge(Default_Theme.secondoryTextStyleMedium),
                  ),
                  title: Text(
                    "Last.FM Suggested Picks",
                    style: TextStyle(
                            color: Default_Theme.primaryColor1, fontSize: 16)
                        .merge(Default_Theme.secondoryTextStyleMedium),
                  ),
                  onChanged: (value) {
                    context.read<SettingsCubit>().setLastFMExpore(value);
                    if (value && LastFmAPI.initialized == false) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        context.read<SettingsCubit>().setLastFMExpore(false);
                      });
                      SnackbarService.showMessage(
                          "Please login to Last.FM first.");
                    }
                  }),
              ExpansionTile(
                title: Text(
                  "Source Engines",
                  style: TextStyle(
                          color: Default_Theme.primaryColor1, fontSize: 16)
                      .merge(Default_Theme.secondoryTextStyleMedium),
                ),
                subtitle: Text(
                  "Manage the source engines you want to use for Music search. (Restart required)",
                  style: TextStyle(
                          color: Default_Theme.primaryColor1
                              .withValues(alpha: 0.5),
                          fontSize: 12)
                      .merge(Default_Theme.secondoryTextStyleMedium),
                ),
                collapsedIconColor: Default_Theme.primaryColor1,
                children: SourceEngine.values.map((e) {
                  if (e == SourceEngine.eng_YTM) return Container();
                  return SwitchListTile(
                      value: state
                          .sourceEngineSwitches[SourceEngine.values.indexOf(e)],
                      title: Text(
                        e.value,
                        style: TextStyle(
                                color: Default_Theme.primaryColor1,
                                fontSize: 17)
                            .merge(Default_Theme.secondoryTextStyleMedium),
                      ),
                      onChanged: (b) {
                        context.read<SettingsCubit>().setSourceEngineSwitches(
                            SourceEngine.values.indexOf(e), b);
                      });
                }).toList(),
              ),
              ExpansionTile(
                title: Text(
                  "Allowed Chart Sources",
                  style: TextStyle(
                          color: Default_Theme.primaryColor1, fontSize: 16)
                      .merge(Default_Theme.secondoryTextStyleMedium),
                ),
                subtitle: Text(
                  "Manage the chart sources you want to see in the home screen.",
                  style: TextStyle(
                          color: Default_Theme.primaryColor1
                              .withValues(alpha: 0.5),
                          fontSize: 12)
                      .merge(Default_Theme.secondoryTextStyleMedium),
                ),
                collapsedIconColor: Default_Theme.primaryColor1,
                children: chartInfoList.map((e) {
                  return SwitchListTile(
                      value: state.chartMap[e.title] ?? true,
                      title: Text(
                        e.title,
                        style: TextStyle(
                                color: Default_Theme.primaryColor1,
                                fontSize: 17)
                            .merge(Default_Theme.secondoryTextStyleMedium),
                      ),
                      onChanged: (b) {
                        context.read<SettingsCubit>().setChartShow(e.title, b);
                      });
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
