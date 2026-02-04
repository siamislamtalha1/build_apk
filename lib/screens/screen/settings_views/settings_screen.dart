import 'package:Bloomee/blocs/settings_cubit/cubit/settings_cubit.dart';
import 'package:Bloomee/routes_and_consts/global_str_consts.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:Bloomee/l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoUpdateEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadAutoUpdateSetting();
  }

  Future<void> _loadAutoUpdateSetting() async {
    final enabled = await BloomeeDBService.getSettingBool(
      GlobalStrConsts.autoUpdateNotify,
      defaultValue: true,
    );
    if (mounted) {
      setState(() {
        _autoUpdateEnabled = enabled ?? true;
      });
    }
  }

  Future<void> _toggleAutoUpdate(bool value) async {
    await BloomeeDBService.putSettingBool(
      GlobalStrConsts.autoUpdateNotify,
      value,
    );
    setState(() {
      _autoUpdateEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          'Settings',
          style: Default_Theme.primaryTextStyle.merge(TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.bold,
          )),
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          final cubit = context.read<SettingsCubit>();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader(context, "General"),
              _buildLanguageTile(context, state, cubit),
              _buildThemeModeTile(context, state, cubit),
              _buildAutoUpdateTile(context),
              Divider(color: scheme.onSurface.withValues(alpha: 0.12)),
              _buildSectionHeader(
                  context, AppLocalizations.of(context)!.advanced), // Localize
              ListTile(
                leading:
                    Icon(MingCute.settings_2_line, color: scheme.onSurface),
                title: Text(
                    AppLocalizations.of(context)!.advancedSettings, // Localize
                    style: Default_Theme.primaryTextStyle
                        .merge(TextStyle(color: scheme.onSurface))),
                trailing: Icon(MingCute.right_line,
                    color: scheme.onSurface.withValues(alpha: 0.6)),
                onTap: () => context.push('/AdvancedSettings'),
              ),
              ListTile(
                leading: Icon(MingCute.code_line, color: scheme.onSurface),
                title: Text(
                    AppLocalizations.of(context)!.developerTools, // Localize
                    style: Default_Theme.primaryTextStyle
                        .merge(TextStyle(color: scheme.onSurface))),
                trailing: Icon(MingCute.right_line,
                    color: scheme.onSurface.withValues(alpha: 0.6)),
                onTap: () => context.push('/DeveloperTools'),
              ),
              Divider(color: scheme.onSurface.withValues(alpha: 0.12)),
              _buildSectionHeader(
                  context, AppLocalizations.of(context)!.about), // Localize
              ListTile(
                leading:
                    Icon(MingCute.information_line, color: scheme.onSurface),
                title: Text('About',
                    style: Default_Theme.primaryTextStyle
                        .merge(TextStyle(color: scheme.onSurface))),
                trailing: Icon(MingCute.right_line,
                    color: scheme.onSurface.withValues(alpha: 0.6)),
                onTap: () => context.push('/About'),
              ),
              ListTile(
                leading:
                    Icon(MingCute.information_line, color: scheme.onSurface),
                title: Text(AppLocalizations.of(context)!.version,
                    style: Default_Theme.primaryTextStyle
                        .merge(TextStyle(color: scheme.onSurface))), // Localize
                subtitle: const Text("1.0.0",
                    style: Default_Theme.secondoryTextStyle),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        title,
        style: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
      BuildContext context, SettingsState state, SettingsCubit cubit) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(MingCute.translate_line, color: scheme.onSurface),
      title: Text("Language",
          style: Default_Theme.primaryTextStyle
              .merge(TextStyle(color: scheme.onSurface))),
      trailing: DropdownButton<String>(
        value: state.locale,
        dropdownColor: scheme.surface,
        style: Default_Theme.primaryTextStyle
            .merge(TextStyle(color: scheme.onSurface)),
        underline: Container(),
        icon: Icon(MingCute.down_line,
            color: scheme.onSurface.withValues(alpha: 0.6)),
        items: const [
          DropdownMenuItem(value: 'en', child: Text('English')),
          DropdownMenuItem(value: 'es', child: Text('Aspaniol')),
          DropdownMenuItem(value: 'fr', child: Text('French')),
          DropdownMenuItem(value: 'de', child: Text('German')),
          DropdownMenuItem(value: 'it', child: Text('Italian')),
          DropdownMenuItem(value: 'pt', child: Text('Portuguese')),
          DropdownMenuItem(value: 'ru', child: Text('Russian')),
          DropdownMenuItem(value: 'ja', child: Text('Japanese')),
        ],
        onChanged: (val) {
          if (val != null) {
            cubit.setLocale(val);
          }
        },
      ),
    );
  }

  Widget _buildThemeModeTile(
      BuildContext context, SettingsState state, SettingsCubit cubit) {
    final scheme = Theme.of(context).colorScheme;
    String getThemeModeLabel(ThemeMode mode) {
      switch (mode) {
        case ThemeMode.light:
          return 'Light';
        case ThemeMode.dark:
          return 'Dark';
        case ThemeMode.system:
          return 'System';
      }
    }

    return ListTile(
      leading: Icon(
        state.themeMode == ThemeMode.light
            ? MingCute.sun_fill
            : state.themeMode == ThemeMode.dark
                ? MingCute.moon_fill
                : MingCute.settings_6_fill,
        color: scheme.onSurface,
      ),
      title: Text("Theme",
          style: Default_Theme.primaryTextStyle
              .merge(TextStyle(color: scheme.onSurface))),
      trailing: DropdownButton<ThemeMode>(
        value: state.themeMode,
        dropdownColor: scheme.surface,
        style: Default_Theme.primaryTextStyle
            .merge(TextStyle(color: scheme.onSurface)),
        underline: Container(),
        icon: Icon(MingCute.down_line,
            color: scheme.onSurface.withValues(alpha: 0.6)),
        items: [
          DropdownMenuItem(
            value: ThemeMode.dark,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(MingCute.moon_fill, size: 16),
                const SizedBox(width: 8),
                Text(getThemeModeLabel(ThemeMode.dark)),
              ],
            ),
          ),
          DropdownMenuItem(
            value: ThemeMode.light,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(MingCute.sun_fill, size: 16),
                const SizedBox(width: 8),
                Text(getThemeModeLabel(ThemeMode.light)),
              ],
            ),
          ),
          DropdownMenuItem(
            value: ThemeMode.system,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(MingCute.settings_6_fill, size: 16),
                const SizedBox(width: 8),
                Text(getThemeModeLabel(ThemeMode.system)),
              ],
            ),
          ),
        ],
        onChanged: (val) {
          if (val != null) {
            cubit.setThemeMode(val);
          }
        },
      ),
    );
  }

  Widget _buildAutoUpdateTile(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(MingCute.download_2_line, color: scheme.onSurface),
      title: Text("Auto-Update Notifications",
          style: Default_Theme.primaryTextStyle
              .merge(TextStyle(color: scheme.onSurface))),
      subtitle: Text(
        "Get notified when new updates are available",
        style: Default_Theme.secondoryTextStyle.merge(
          TextStyle(
            fontSize: 12,
            color: scheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
      trailing: Switch(
        value: _autoUpdateEnabled,
        onChanged: _toggleAutoUpdate,
        activeThumbColor: scheme.primary,
      ),
    );
  }
}
