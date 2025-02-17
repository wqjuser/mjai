import 'package:flutter/material.dart';

import '../../../../config/change_settings.dart';

// 辅助方法: 构建菜单组
Widget buildMenuGroup({
  required String title,
  required List<Widget> items,
  required ChangeSettings settings,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          title,
          style: TextStyle(
            color: settings.getForegroundColor().withAlpha(128),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      ...items,
    ],
  );
}
