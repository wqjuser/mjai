import 'package:flutter/material.dart';
import '../../../../config/change_settings.dart';

//构建win界面的控制按钮
Widget buildButton({
  required VoidCallback onPressed,
  required String text,
  required ChangeSettings settings,
  required bool isPrimary,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? settings.getSelectedBgColor() : settings.getSelectedBgColor().withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPrimary ? Colors.transparent : settings.getSelectedBgColor().withAlpha(76),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isPrimary ? settings.getBackgroundColor() : settings.getSelectedBgColor(),
            fontSize: 14,
            fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    ),
  );
}
