import 'package:flutter/material.dart';
import 'package:tuitu/config/global_params.dart';

class ThemeManager {
  static Color getBackgroundColor(bool isDarkMode) => isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;

  static Color getForegroundColor(bool isDarkMode) => isDarkMode ? Colors.white : Colors.black;

  static Color getBorderColor(bool isDarkMode) => isDarkMode ? Colors.white.withAlpha(128) : Colors.blueAccent;

  static Color getCardColor(bool isDarkMode) => isDarkMode ? const Color(0xFF2D2D2D) : Colors.white;

  static Color getTextColor(bool isDarkMode) => isDarkMode ? const Color(0xFFBBBBBB) : Colors.black;

  static Color getHintTextColor(bool isDarkMode) => isDarkMode ? const Color(0xFFA6A6A6) : const Color(0xFFAAAAAA);

  static Color getChatBgColorBot(bool isDarkMode) => isDarkMode ? const Color(0xFF1C1C1C) : const Color(0xFFF2F2F2);

  static Color getChatBgColorMe(bool isDarkMode) => isDarkMode ? const Color(0xFF1B262A) : const Color(0xFFE7F8FF);

  static Color getTextButtonColor(bool isDarkMode) => isDarkMode ? const Color(0xFFE7F8FF) : const Color(0xFFFFFFFF);

  static Color getSelectedBgColor(bool isDarkMode) => isDarkMode ? const Color(0xFFE46747) : Colors.blue;

  static Color getUnselectedBgColor(bool isDarkMode) => isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey;

  static Color getIconColor(bool isDarkMode) => isDarkMode ? Colors.white : Colors.black;

  static Color getCardTextColor(bool isDarkMode) => Colors.white;

  static Color getScrollbarColor(bool isDarkMode) => isDarkMode ? const Color(0xFF666666) : const Color(0xFFCCCCCC);

  static Color getAppbarColor(bool isDarkMode) => isDarkMode ? const Color(0xFF1A1A1A) : GlobalParams.themeColor;

  static Color getAppbarTextColor(bool isDarkMode) => Colors.white;

  static Color getWarnTextColor(bool isDarkMode) => isDarkMode ? const Color(0xFFE46747) : Colors.red;
}
