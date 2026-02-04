import 'package:Bloomee/blocs/settings_cubit/cubit/settings_cubit.dart';
import 'package:Bloomee/screens/screen/home_views/setting_views/check_update_view.dart';
import 'package:Bloomee/screens/widgets/global_footer.dart';
import 'package:Bloomee/screens/widgets/setting_tile.dart';
import 'package:flutter/material.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpdatesSettings extends StatelessWidget {
  const UpdatesSettings({super.key});

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
          'Updates',
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
                title: "Check for updates",
                subtitle: "Check for new updates",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GlobalBackdropWrapper(
                        child: CheckUpdateView(),
                      ),
                    ),
                  );
                },
              ),
              SwitchListTile(
                  value: state.autoUpdateNotify,
                  subtitle: Text(
                    "Get notified when new updates are available in app start up.",
                    style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 12.5)
                        .merge(Default_Theme.secondoryTextStyleMedium),
                  ),
                  title: Text(
                    "Auto update notify",
                    style: TextStyle(
                            color: scheme.onSurface, fontSize: 17)
                        .merge(Default_Theme.secondoryTextStyleMedium),
                  ),
                  onChanged: (value) {
                    context.read<SettingsCubit>().setAutoUpdateNotify(value);
                  }),
            ],
          );
        },
      ),
    );
  }
}
