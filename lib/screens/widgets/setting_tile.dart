// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:Bloomee/theme_data/default.dart';
import 'package:flutter/material.dart';

class SettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Function? onTap;
  final Widget? trailing;

  const SettingTile({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      enabled: onTap != null,
      title: Text(
        title,
        style: TextStyle(color: scheme.onSurface, fontSize: 16)
            .merge(Default_Theme.secondoryTextStyleMedium),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12)
            .merge(Default_Theme.secondoryTextStyleMedium),
      ),
      onTap: () {
        onTap?.call();
      },
      dense: true,
      trailing: trailing,
    );
  }
}
