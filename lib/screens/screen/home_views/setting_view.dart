// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:Bloomee/screens/screen/home_views/setting_views/appui_setting.dart';
import 'package:Bloomee/screens/screen/home_views/setting_views/storage_setting.dart';
import 'package:Bloomee/screens/screen/home_views/setting_views/country_setting.dart';
import 'package:Bloomee/screens/screen/home_views/setting_views/download_setting.dart';
import 'package:Bloomee/screens/screen/home_views/setting_views/lastfm_setting.dart'; // Restored
import 'package:Bloomee/screens/screen/home_views/setting_views/player_setting.dart';
import 'package:Bloomee/screens/screen/home_views/setting_views/updates_setting.dart';
import 'package:Bloomee/screens/widgets/global_footer.dart';
import 'package:flutter/material.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:go_router/go_router.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

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
          'Settings',
          style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)
              .merge(Default_Theme.secondoryTextStyle),
        ),
      ),
      body: ListView(
        children: [
          settingListTile(
              context: context,
              title: "Updates",
              subtitle: "Check for new updates",
              icon: MingCute.download_3_fill,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GlobalBackdropWrapper(
                      child: UpdatesSettings(),
                    ),
                  ),
                );
              }),
          settingListTile(
              context: context,
              title: "Downloads",
              subtitle: "Download Path,Download Quality and more...",
              icon: MingCute.folder_download_fill,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GlobalBackdropWrapper(
                      child: DownloadSettings(),
                    ),
                  ),
                );
              }),
          settingListTile(
              context: context,
              title: "Player Settings",
              subtitle: "Stream quality, Auto Play, etc.",
              icon: MingCute.airpods_fill,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GlobalBackdropWrapper(
                      child: PlayerSettings(),
                    ),
                  ),
                );
              }),
          settingListTile(
              context: context,
              title: "UI Elements & Services",
              subtitle: "Auto slide, Source Engines etc.",
              icon: MingCute.display_fill,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GlobalBackdropWrapper(
                      child: AppUISettings(),
                    ),
                  ),
                );
              }),
          settingListTile(
              context: context,
              title: "Last.FM Settings",
              subtitle: "API Key, Secret, and Scrobbling settings.",
              icon: FontAwesome.lastfm_brand,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GlobalBackdropWrapper(
                      child: LastDotFM(),
                    ),
                  ),
                );
              }),
          settingListTile(
              context: context,
              title: "Storage",
              subtitle: "Backup, Cache, History, Restore and more...",
              icon: MingCute.coin_2_fill,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GlobalBackdropWrapper(
                      child: BackupSettings(),
                    ),
                  ),
                );
              }),
          settingListTile(
              context: context,
              title: "Advanced Settings",
              subtitle: "Audio engine, Persistence, Maintenance",
              icon: Icons.settings,
              onTap: () {
                context.push('/AdvancedSettings');
              }),
          settingListTile(
              context: context,
              title: "Developer Tools",
              subtitle: "Debug tools and logs",
              icon: Icons.code,
              onTap: () {
                context.push('/DeveloperTools');
              }),
          settingListTile(
              context: context,
              title: "Language & Country",
              subtitle: "Select your language and country.",
              icon: MingCute.globe_fill,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GlobalBackdropWrapper(
                      child: CountrySettings(),
                    ),
                  ),
                );
              }),
          settingListTile(
              context: context,
              title: "About",
              subtitle: "About the app, version, developer, etc.",
              icon: MingCute.github_fill,
              onTap: () {
                context.push('/About');
              }),
        ],
      ),
    );
  }

  ListTile settingListTile(
      {required BuildContext context,
      required String title,
      required String subtitle,
      required IconData icon,
      VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(
        icon,
        size: 27,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      title: Text(
        title,
        style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface, fontSize: 16)
            .merge(Default_Theme.secondoryTextStyleMedium),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
                fontSize: 12)
            .merge(Default_Theme.secondoryTextStyleMedium),
      ),
      onTap: () {
        if (onTap != null) {
          onTap();
        }
      },
    );
  }
}
