import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get_storage/get_storage.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/pages/main/views/main_page.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'package:tuitu/utils/my_openai_client.dart';
import 'package:tuitu/utils/screen_resolution_singleton.dart';
import 'package:tuitu/utils/supabase_helper.dart';
import 'package:window_manager/window_manager.dart';
import 'config/config.dart';

Future<void> main(List<String> args) async {
  await _initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ChangeSettings>(
          create: (context) => ChangeSettings(context),
        ),
      ],
      child: const MyApp(),
    ),
  );
  await _initializeServices();
}

Future<void> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeWindow();
  await SupabaseHelper().init();
  await GetStorage.init();
}

Future<void> _initializeWindow() async {
  if (!Platform.isWindows && !Platform.isMacOS) return;

  await windowManager.ensureInitialized();
  var settings = await Config.loadSettings();
  WindowOptions windowOptions = _createWindowOptions(settings);

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setPreventClose(true);
  });
}

WindowOptions _createWindowOptions(Map<String, dynamic> settings) {
  double windowWidth = (settings['window_width'] ?? 1280).toDouble();
  double windowHeight = (settings['window_height'] ?? 750).toDouble();

  return WindowOptions(
    size: Size(windowWidth, windowHeight),
    minimumSize: const Size(1280, 750),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
}

Future<void> _initializeServices() async {
  await OpenAIClientSingleton.instance.init();
  await ScreenResolutionSingleton.instance.init();
  MediaKit.ensureInitialized();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      final settings = context.watch<ChangeSettings>();
      return RefreshConfiguration(
        headerTriggerDistance: 80.0,
        springDescription: const SpringDescription(stiffness: 170, damping: 16, mass: 1.9),
        maxOverScrollExtent: 100,
        maxUnderScrollExtent: 0,
        enableScrollWhenRefreshCompleted: true,
        enableLoadingWhenFailed: true,
        hideFooterWhenNotFull: true,
        enableBallisticLoad: true,
        child: MaterialApp(
          title: '魔镜AI',
          theme: _buildTheme(ThemeData.light()),
          darkTheme: _buildTheme(ThemeData.dark()),
          themeMode: _getThemeMode(settings),
          home: const MainPage(),
          builder: _buildWithEasyLoading(settings),
        ),
      );
    });
  }

  ThemeData _buildTheme(ThemeData baseTheme) {
    return baseTheme.copyWith(textTheme: globalTextTheme);
  }

  ThemeMode _getThemeMode(ChangeSettings settings) {
    if (settings.isAutoMode) return ThemeMode.system;
    return settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Widget Function(BuildContext, Widget?) _buildWithEasyLoading(ChangeSettings settings) {
    return (context, child) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        settings.updateContext(context, notify: true);
      });
      return EasyLoading.init()(context, child ?? const SizedBox());
    };
  }
}
