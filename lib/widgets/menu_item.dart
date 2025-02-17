import 'package:flutter/material.dart';

import '../config/change_settings.dart';

//应用主界面菜单项
class MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final ChangeSettings settings;
  final bool showTrailing;

  const MenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.settings,
    this.showTrailing = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: settings.getForegroundColor(),
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: settings.getForegroundColor(),
          fontSize: 15,
        ),
      ),
      trailing: showTrailing
          ? Icon(
              Icons.chevron_right,
              color: settings.getForegroundColor().withAlpha(128),
              size: 20,
            )
          : null,
      dense: true,
      onTap: onTap,
    );
  }
}
