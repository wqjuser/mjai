import 'package:flutter/material.dart';
import '../../../../config/change_settings.dart';

// 通用文本按钮构建方法
Widget buildTextButton(
    String text, BuildContext context, Function(BuildContext context, bool isRegister) onTap, ChangeSettings settings) {
  return TextButton(
    onPressed: () {
      onTap(context, text == '注册');
    },
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: Text(
      text,
      style: TextStyle(
        color: settings.getSelectedBgColor(),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
