import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tuitu/utils/common_methods.dart';

import '../utils/theme_manager.dart';
import 'config.dart';

class ChangeSettings extends ChangeNotifier {
  final box = GetStorage();
  BuildContext? _context;
  String? _userAvatar; // 缓存头像路径

  // 接收 context 的构造函数
  ChangeSettings(BuildContext context) {
    _context = context;
    // 延迟一帧以确保 MediaQuery 等 widget 已经准备好
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserAvatar(); // 初始化时加载头像
      notifyListeners();
    });
  }

  // 获取用户头像
  String get userAvatar => _userAvatar ?? 'assets/images/chat_user_default_avatar.png';

  // 加载用户头像
  Future<void> _loadUserAvatar() async {
    try {
      final settings = await Config.loadSettings();
      _userAvatar = settings['user_avatar']?.isEmpty ?? true ? 'assets/images/chat_user_default_avatar.png' : settings['user_avatar'];
      notifyListeners();
    } catch (e) {
      commonPrint('加载用户头像失败: $e');
      _userAvatar = 'assets/images/chat_user_default_avatar.png';
      notifyListeners();
    }
  }

  // 更新用户头像
  Future<void> updateUserAvatar(String newAvatarPath) async {
    try {
      await box.write('user_avatar', newAvatarPath);
      _userAvatar = newAvatarPath.isEmpty ? 'assets/images/chat_user_default_avatar.png' : newAvatarPath;
      notifyListeners();
    } catch (e) {
      commonPrint('更新用户头像失败: $e');
      throw Exception('更新用户头像失败');
    }
  }

  // 重置用户头像到默认
  Future<void> resetUserAvatar() async {
    try {
      await box.write('user_avatar', '');
      _userAvatar = 'assets/images/chat_user_default_avatar.png';
      notifyListeners();
    } catch (e) {
      commonPrint('重置用户头像失败: $e');
      throw Exception('重置用户头像失败');
    }
  }

  bool get isDarkMode => box.read('isDarkMode') ?? false;

  bool get isAutoMode => box.read('isAutoMode') ?? true;

  // 修改系统主题判断逻辑，增加空值处理
  // 不在 getter 中更新 context
  bool get isSystemDarkMode {
    if (_context == null) return false;

    try {
      if (Platform.isMacOS) {
        final brightness = MediaQuery.platformBrightnessOf(_context!);
        return brightness == Brightness.dark;
      } else {
        final window = View.of(_context!).platformDispatcher;
        return window.platformBrightness == Brightness.dark;
      }
    } catch (e) {
      return false;
    }
  }

  void updateContext(BuildContext? newContext, {bool notify = false}) {
    if (_context != newContext) {
      _context = newContext;
      if (notify) {
        notifyListeners();
      }
    }
  }

  bool get effectiveDarkMode => isAutoMode ? isSystemDarkMode : isDarkMode;

  // 修改切换逻辑，采用循环模式：自动 -> 亮色 -> 暗色 -> 自动
  void toggleTheme() {
    if (isAutoMode) {
      // 从自动模式切换到亮色
      box.write('isAutoMode', false);
      box.write('isDarkMode', false);
    } else if (!isDarkMode) {
      // 从亮色切换到暗色
      box.write('isDarkMode', true);
    } else {
      // 从暗色切换到自动
      box.write('isAutoMode', true);
    }
    notifyListeners();
  }

  // 获取当前主题模式的描述
  String get themeModeDescription {
    if (isAutoMode) {
      return '自动模式';
    } else if (isDarkMode) {
      return '暗色模式';
    } else {
      return '亮色模式';
    }
  }

  // 获取下一个主题模式的描述
  String get nextThemeModeDescription {
    if (isAutoMode) {
      return '切换到亮色模式';
    } else if (!isDarkMode) {
      return '切换到暗色模式';
    } else {
      return '切换到自动模式';
    }
  }

  // 获取当前应该显示的图标
  IconData get themeIcon {
    if (isAutoMode) {
      return Icons.brightness_auto;
    } else if (isDarkMode) {
      return Icons.dark_mode;
    } else {
      return Icons.light_mode;
    }
  }

  void handleSystemBrightnessChanged() {
    if (isAutoMode) {
      notifyListeners();
    }
  }

  // 使用 effectiveDarkMode 获取实际的主题色
  Color getBackgroundColor() => ThemeManager.getBackgroundColor(effectiveDarkMode);

  Color getForegroundColor() => ThemeManager.getForegroundColor(effectiveDarkMode);

  Color getBorderColor() => ThemeManager.getBorderColor(effectiveDarkMode);

  Color getCardColor() => ThemeManager.getCardColor(effectiveDarkMode);

  Color getTextColor() => ThemeManager.getTextColor(effectiveDarkMode);

  Color getHintTextColor() => ThemeManager.getHintTextColor(effectiveDarkMode);

  Color getChatBgColorBot() => ThemeManager.getChatBgColorBot(effectiveDarkMode);

  Color getChatBgColorMe() => ThemeManager.getChatBgColorMe(effectiveDarkMode);

  Color getTextButtonColor() => ThemeManager.getTextButtonColor(effectiveDarkMode);

  Color getSelectedBgColor() => ThemeManager.getSelectedBgColor(effectiveDarkMode);

  Color getUnselectedBgColor() => ThemeManager.getUnselectedBgColor(effectiveDarkMode);

  Color getCardTextColor() => ThemeManager.getCardTextColor(effectiveDarkMode);

  Color getScrollbarColor() => ThemeManager.getScrollbarColor(effectiveDarkMode);

  Color getAppbarColor() => ThemeManager.getAppbarColor(effectiveDarkMode);

  Color getAppbarTextColor() => ThemeManager.getAppbarTextColor(effectiveDarkMode);

  Color getWarnTextColor() => ThemeManager.getWarnTextColor(effectiveDarkMode);

  final Map<String, dynamic> _changeValues = {};

  Map<String, dynamic> get changeValues => _changeValues;

  void changeValue(Map<String, dynamic> map) {
    map.forEach((key, value) {
      _changeValues[key] = value;
    });
    notifyListeners();
  }

  void listenToSystemThemeChanges(BuildContext context) {
    if (isAutoMode) {
      final window = View.of(context).platformDispatcher;
      window.onPlatformBrightnessChanged = () {
        if (isAutoMode) {
          notifyListeners();
        }
      };
    }
  }
}
