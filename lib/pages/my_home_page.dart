import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart' as dio;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/stdio.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:system_tray/system_tray.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/config/config.dart';
import 'package:tuitu/config/default_settings.dart';
import 'package:tuitu/config/global_params.dart';
import 'package:tuitu/listeners/my_window_listener.dart';
import 'package:tuitu/net/my_api.dart';
import 'package:tuitu/pages/ai_art_images.dart';
import 'package:tuitu/pages/ai_chat_page.dart';
import 'package:tuitu/pages/ai_music_page.dart';
import 'package:tuitu/pages/ai_video_page.dart';
import 'package:tuitu/pages/article_generator_view.dart';
import 'package:tuitu/pages/create_knowledge_base_page.dart';
import 'package:tuitu/pages/manage_packages_page.dart';
import 'package:tuitu/pages/manage_user_page.dart';
import 'package:tuitu/pages/random_generator_view.dart';
import 'package:tuitu/pages/settings/view/settings_page.dart';
import 'package:tuitu/pages/work_flows/views/work_flows_view.dart';
import 'package:tuitu/params/preset_character.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'package:tuitu/utils/eventbus_utils.dart';
import 'package:tuitu/utils/keyboard_service.dart';
import 'package:tuitu/utils/my_openai_client.dart';
import 'package:tuitu/utils/native_communication.dart';
import 'package:tuitu/utils/supabase_helper.dart';
import 'package:tuitu/widgets/auto_scroll_text.dart';
import 'package:tuitu/widgets/custom_carousel.dart';
import 'package:tuitu/widgets/custom_dialog.dart';
import 'package:tuitu/widgets/download_progress_dialog.dart';
import 'package:tuitu/widgets/file_picker_dialog.dart';
import 'package:tuitu/widgets/image_preview_widget.dart';
import 'package:tuitu/widgets/keep_alive_page.dart';
import 'package:tuitu/widgets/login_dialog.dart';
import 'package:tuitu/widgets/menu_item.dart';
import 'package:tuitu/widgets/sponsor_dialog.dart';
import 'package:tuitu/widgets/user_info_dialog_widget.dart';
import 'package:tuitu/widgets/window_button.dart';
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart';
import 'package:path/path.dart' as path;

@Deprecated('Use /pages/main/view/main_page instead')
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum PageOrientation {
  all, // 支持所有方向
  landscape, // 仅支持横屏
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  String title = 'AI助手';
  List<String> titles = ['AI助手', 'AI绘画', 'AI视频', 'AI音乐', '小说推文助手', '艺术图片生成', '工作流', '知识库', '画廊', '用户管理', '套餐设置', '购买套餐', '设置'];
  String preChatVer = '';
  int _selectedIndex = 0;
  Map<String, String> envVars = Platform.environment;
  final KeyboardService _keyboardService = KeyboardService();
  var supabaseHelper = SupabaseHelper();
  bool isRegistered = false;
  bool isLogin = false;
  String userName = '';
  String email = '';
  String password = '';
  late MyApi myApi;
  String inviteCode = generateRandomString(8);
  final box = GetStorage();
  late PageController _pageController;
  String qrcodeDialogTitle = 'QQ扫码';
  final SystemTray systemTray = SystemTray();
  late AppWindow appWindow;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isAppIntoFullScreen = false;
  List imagesList = [];
  String topImageUrl = '';
  double sponsorAmount = 10.0;
  late final settings = context.read<ChangeSettings>();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = true;
  Map userQuotas = {};
  Timer? _debounce;
  final loginChannel = SupabaseHelper().channel('login_channel');
  final menuChannel = SupabaseHelper().channel('menus');
  final versionChannel = SupabaseHelper().channel('versions');
  final aiModelChannel = SupabaseHelper().channel('ai_models');
  final userChannel = SupabaseHelper().channel('my_users');
  final broadcastChannel = SupabaseHelper().channel('broadcast');
  bool isSSODialogOpen = false;

  //记住用户退出应用的操作
  bool rememberChoice = true;
  double windowHeight = 750;
  bool _showBroadcast = false;
  String _broadcastMessage = '';
  MyWindowListener? _windowListener;

  // 添加成员变量
  PlatformDispatcher? _platformDispatcher;

  @override
  void initState() {
    _pageController = PageController();
    super.initState();
    myApi = MyApi();
    initSystemTray();
    listenStorage();
    initData();
    initDBBroadcast();
    initHotKeys();
    initEasyLoading();
    _initializeWindowListener();
    _keyboardService.init();
    _keyboardService.onF1Pressed = _handleF1Press;
    // 添加亮暗主题变化监听
    WidgetsBinding.instance.addObserver(this);
    // 添加滚动监听
    _scrollController.addListener(_scrollListener);
    // 在下一帧检查是否需要显示指示器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollIndicator();
    });
    getAiModels();
    getImages();
    getMenus();
    checkForUpdate();
  }

  void initEasyLoading() {
    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 2000)
      ..indicatorType = EasyLoadingIndicatorType.circle
      ..loadingStyle = getRealDarkMode(settings) ? EasyLoadingStyle.dark : EasyLoadingStyle.light
      ..indicatorSize = 45.0
      ..radius = 10.0
      ..progressColor = Colors.white
      ..backgroundColor = Colors.blueAccent
      ..indicatorColor = Colors.white
      ..textColor = Colors.white
      ..userInteractions = true
      ..dismissOnTap = true;
  }

  // 滚动监听器
  void _scrollListener() {
    _checkScrollIndicator();
  }

  void _initializeWindowListener() {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      _windowListener = MyWindowListener(onMyWindowClose: () async {
        // 处理窗口关闭事件
        final settings = context.read<ChangeSettings>();
        var savedSettings = await Config.loadSettings();
        int exitAppMethod = savedSettings['exit_app_method'] ?? -1;
        switch (exitAppMethod) {
          case 0:
            //最小化到托盘
            appWindow.hide();
            break;
          case 1:
            //直接退出应用
            _handleExit();
            break;
          default:
            //用户没有保存过退出APP的操作
            bool isPreventClose = await windowManager.isPreventClose();
            if (isPreventClose) {
              if (mounted) {
                showDialog(
                  context: context,
                  barrierColor: Colors.black.withAlpha(153),
                  barrierDismissible: true,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: settings.getForegroundColor().withAlpha(25),
                          width: 1,
                        ),
                      ),
                      backgroundColor: settings.getBackgroundColor(),
                      elevation: 0,
                      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      title: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: settings.getForegroundColor(),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '退出魔镜AI',
                              style: TextStyle(
                                color: settings.getForegroundColor(),
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "确认要退出应用吗?",
                            style: TextStyle(
                              color: settings.getForegroundColor().withAlpha(230),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _buildButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      if (rememberChoice) {
                                        Map<String, dynamic> rememberExitChoice = {};
                                        rememberExitChoice['exit_app_method'] = 0;
                                        await Config.saveSettings(rememberExitChoice);
                                      }
                                      appWindow.hide();
                                    },
                                    text: Platform.isWindows ? '最小化到系统托盘' : '最小化到程序坞',
                                    settings: settings,
                                    isPrimary: false,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    text: '取消',
                                    settings: settings,
                                    isPrimary: false,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      if (rememberChoice) {
                                        Map<String, dynamic> rememberExitChoice = {};
                                        rememberExitChoice['exit_app_method'] = 1;
                                        await Config.saveSettings(rememberExitChoice);
                                      }
                                      _handleExit();
                                    },
                                    text: '确认退出',
                                    settings: settings,
                                    isPrimary: true,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Checkbox(
                                    value: rememberChoice,
                                    onChanged: (value) {
                                      setState(() {
                                        rememberChoice = value ?? false;
                                      });
                                    },
                                    activeColor: settings.getSelectedBgColor(),
                                    side: BorderSide(
                                      color: settings.getForegroundColor().withAlpha(128),
                                    ),
                                  ),
                                  Text(
                                    '记住我的选择(可随时在设置页面修改)',
                                    style: TextStyle(
                                      color: settings.getForegroundColor().withAlpha(230),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
            }
            break;
        }
      }, onMyWindowFocus: () {
        // 处理窗口获得焦点事件
        setState(() {});
      }, onMyWindowBlur: () {
        // 处理窗口失去焦点事件
      }, onMyWindowMaximize: () {
        // 处理窗口最小化事件
        setState(() {
          isAppIntoFullScreen = true;
          _showScrollIndicator = false;
        });
      }, onMyWindowUnmaximize: () async {
        var windowSize = await windowManager.getSize();
        double showHeight = GlobalParams.isAdminVersion ? 990 : 865;
        if (windowSize.height < showHeight) {
          if (_scrollController.hasClients) {
            setState(() {
              _showScrollIndicator = _scrollController.position.pixels < _scrollController.position.maxScrollExtent;
            });
          }
        } else {
          setState(() {
            _showScrollIndicator = false;
          });
        }
        setState(() {
          isAppIntoFullScreen = false;
        });
      }, onMyWindowResize: () async {
        var windowSize = await windowManager.getSize();
        double showHeight = GlobalParams.isAdminVersion ? 990 : 865;
        if (windowSize.height < showHeight) {
          setState(() {
            if (_scrollController.hasClients) {
              _showScrollIndicator = _scrollController.position.pixels < _scrollController.position.maxScrollExtent;
            }
          });
        } else {
          setState(() {
            _showScrollIndicator = false;
          });
        }
        // 保存用户设置的窗口大小，下次打开的时候恢复本次的窗口大小
        if (_debounce?.isActive ?? false) _debounce!.cancel();
        _debounce = Timer(const Duration(milliseconds: 1000), () async {
          // 保存用户设置的窗口大小，下次打开的时候恢复本次的窗口大小
          Map<String, dynamic> userWindowSize = {};
          userWindowSize['window_width'] = windowSize.width;
          userWindowSize['window_height'] = windowSize.height;
          await Config.saveSettings(userWindowSize);
        });
      });
      windowManager.addListener(_windowListener!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!Platform.isMacOS) {
      // 非 macOS 平台使用原来的方式监听
      _platformDispatcher = View.of(context).platformDispatcher;
      _platformDispatcher?.onPlatformBrightnessChanged = () {
        settings.handleSystemBrightnessChanged();
      };
    }
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    if (settings.isAutoMode) {
      settings.handleSystemBrightnessChanged();
    }
  }

  // 检查是否需要显示滚动指示器
  void _checkScrollIndicator() {
    if (!_scrollController.hasClients) return;

    bool newShowScrollIndicator = _scrollController.position.pixels < _scrollController.position.maxScrollExtent;

    if (newShowScrollIndicator != _showScrollIndicator) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _showScrollIndicator = newShowScrollIndicator;
          });
        }
      });
    }
  }

  // 滚动到底部的方法
  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void initHotKeys() async {
    if (Platform.isWindows || Platform.isMacOS) {
      HotKey showAppHotKey = HotKey(
        key: PhysicalKeyboardKey.keyM,
        modifiers: [!Platform.isWindows ? HotKeyModifier.meta : HotKeyModifier.alt, HotKeyModifier.control],
        scope: HotKeyScope.system,
      );
      HotKey hideAppHotKey = HotKey(
        key: PhysicalKeyboardKey.keyH,
        modifiers: [!Platform.isWindows ? HotKeyModifier.meta : HotKeyModifier.alt, HotKeyModifier.control],
        scope: HotKeyScope.system,
      );
      await hotKeyManager.register(
        showAppHotKey,
        keyDownHandler: (hotKey) {
          Platform.isWindows ? windowManager.show() : appWindow.show();
        },
      );
      await hotKeyManager.register(
        hideAppHotKey,
        keyDownHandler: (hotKey) {
          appWindow.hide();
        },
      );
      await hotKeyManager.register(
        HotKey(
          key: PhysicalKeyboardKey.keyX,
          modifiers: [HotKeyModifier.alt],
          scope: HotKeyScope.system,
        ),
        keyDownHandler: (_) async {},
      );
    }
  }

  Future<void> initSystemTray() async {
    if (Platform.isWindows || Platform.isMacOS) {
      appWindow = AppWindow();
      String iconPath = Platform.isWindows ? 'assets/images/app_icon.ico' : 'assets/images/app_icon.png';
      await systemTray.initSystemTray(iconPath: iconPath, toolTip: "魔镜AI");
      // 创建托盘菜单
      final Menu menu = Menu();
      await menu.buildFrom([
        MenuItemLabel(label: '打开', onClicked: (menuItem) => Platform.isWindows ? windowManager.show() : appWindow.show()),
        MenuItemLabel(label: '隐藏', onClicked: (menuItem) => appWindow.hide()),
        MenuItemLabel(
            label: '退出',
            onClicked: (menuItem) {
              _handleExit();
            }),
      ]);

      // 设置托盘图标的右键菜单
      await systemTray.setContextMenu(menu);

      // 点击托盘图标时，恢复窗口
      systemTray.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick) {
          Platform.isWindows ? windowManager.show() : systemTray.popUpContextMenu();
        } else if (eventName == kSystemTrayEventRightClick) {
          Platform.isWindows ? systemTray.popUpContextMenu() : appWindow.show();
        }
      });
    }
  }

  Future<void> createDirectory(String dirName) async {
    final path = '${envVars['USERPROFILE']}${Platform.pathSeparator}Pictures${Platform.pathSeparator}$dirName';
    final directory = Directory(path);
    if (await directory.exists()) {
      return;
    } else {
      await directory.create(recursive: true).then((Directory directory) {
        commonPrint('目录 ${directory.path}被创建');
      });
    }
  }

  Future<void> generateDefaultValues({String savePath = '', isLogout = false}) async {
    const dirName = 'ImageGenerator';
    const uuid = Uuid();
    final newUuid = uuid.v4();
    final randomEncryptKey = uuid.v4().substring(0, 8);
    final path = Platform.isWindows
        ? '${envVars['USERPROFILE']}${Platform.pathSeparator}Pictures${Platform.pathSeparator}$dirName'
        : savePath;
    Map<String, dynamic> settings = defaultSettings;
    settings['client_id'] = newUuid;
    settings['image_save_path'] = path;
    settings['chatSettings_privateModeKey'] = randomEncryptKey;
    if (isLogout) {
      var savedSettings = await Config.loadSettings();
      settings['client_id'] = savedSettings['client_id'];
      settings['user_name'] = savedSettings['user_name'];
      settings['user_id'] = savedSettings['user_id'];
      settings['password'] = savedSettings['password'];
      settings['email'] = savedSettings['email'];
      settings['image_save_path'] = savedSettings['image_save_path'];
      settings['exit_app_method'] = savedSettings['exit_app_method'];
      settings['supabase_key'] = savedSettings['supabase_key'];
      settings['supabase_url'] = savedSettings['supabase_url'];
    }
    await Config.saveSettings(settings);
    box.write('needRefreshSettings', true);
  }

  Future<void> requestDocumentsPermission(bool? isFirstUse, Map<String, dynamic> settings) async {
    // 先尝试获取已存在的路径
    String? path = await NativeCommunication.getMJAIPath();
    if (path != null) {
      // 已有权限，直接使用路径
      await macFirstUse(isFirstUse, path, settings);
      return;
    }
    // 没有权限，请求新的权限
    path = await NativeCommunication.requestAccess();
    if (path != null) {
      // 执行需要文档访问权限的操作
      await macFirstUse(isFirstUse, path, settings);
    } else {
      showHint('您拒绝了文件夹的访问权限，应用的部分功能将不可用', showType: 3);
    }
  }

  Future<void> macFirstUse(bool? isFirstUse, String path, Map<String, dynamic> settings) async {
    if (isFirstUse == null) {
      await Config.saveSettings(presetCharacter, type: 2);
      await generateDefaultValues(savePath: path); //首次使用创建默认参数
    } else {
      Map<String, dynamic> settings = {'image_save_path': path};
      await Config.saveSettings(settings);
    }
    await commonCreateDirectory('$path${Platform.pathSeparator}cu_workflows');
    if (isLogin) {
      // 这里增加打开软件就加载用户网络配置的方法
      await downloadSettings(settings);
    }
  }

  Future<void> loadSettings() async {
    final directory = await getApplicationDocumentsDirectory();
    String configPath = '${directory.path}${Platform.pathSeparator}HuituxuanConfig${Platform.pathSeparator}';
    await commonCreateDirectory(configPath);
    Map<String, dynamic> settings = await Config.loadSettings();
    bool? isFirstUse = settings['is_first_use'];
    isRegistered = settings['is_registered'] ?? false;
    isLogin = settings['is_login'] ?? false;
    setState(() {
      title = settings['curPageTitle'] ?? 'AI助手';
      _selectedIndex = settings['curPage'] ?? 0;
      _pageController.jumpToPage(_selectedIndex);
      windowHeight = (settings['window_height'] ?? 750).toDouble();
      double showHeight = GlobalParams.isAdminVersion ? 990 : 865;
      if (windowHeight < showHeight) {
        if (_scrollController.hasClients) {
          _showScrollIndicator = _scrollController.position.pixels < _scrollController.position.maxScrollExtent;
        }
      } else {
        _showScrollIndicator = false;
      }
    });
    if (isRegistered) {
      userName = settings['user_name'] ?? '';
      email = settings['email'] ?? '';
      password = settings['password'] ?? '';
    }
    if (Platform.isMacOS) {
      await requestDocumentsPermission(isFirstUse, settings);
    } else {
      if (isFirstUse == null) {
        await Config.saveSettings(presetCharacter, type: 2);
        await generateDefaultValues();
        await createDirectory('ImageGenerator');
        Map<String, dynamic> savedSettings = await Config.loadSettings();
        String savePath = savedSettings['image_save_path'] ?? '';
        await commonCreateDirectory('$savePath${Platform.pathSeparator}cu_workflows');
      } else {
        Map<String, dynamic> savedSettings = await Config.loadSettings();
        if (isLogin) {
          // 这里增加打开软件就加载用户网络配置的方法
          await downloadSettings(settings);
          String savePath = savedSettings['image_save_path'] ?? '';
          if (Platform.isWindows || Platform.isMacOS) {
            await commonCreateDirectory('$savePath${Platform.pathSeparator}cu_workflows');
          }
        }
      }
    }

    dio.Response response = await myApi.getCurrentIP();
    if (response.statusCode == 200) {
      if (response.data is String) {
        response.data = jsonDecode(response.data);
      }
      String ip = response.data['ip'];
      Map<String, dynamic> ipMap = {'ip': ip};
      await Config.saveSettings(ipMap);
    } else {
      Map<String, dynamic> ipMap = {'ip': '127.0.0.1'};
      await Config.saveSettings(ipMap);
    }
  }

  Future<void> downloadSettings(Map<String, dynamic> settings) async {
    bool isLogin = settings['is_login'] ?? false;
    String userEmail = settings['email'] ?? '';
    String userId = settings['user_id'] ?? '';
    String registerInviteCode = settings['register_invite_code'] ?? '';
    if (isLogin) {
      final data = await supabaseHelper.query('my_users', {'email': userEmail});
      final inviteUserData = await supabaseHelper.query('my_users', {'invite_code': registerInviteCode});
      if (data.isNotEmpty) {
        if (data[0]['is_delete']) {
          //用户被管理员删除
          showHint('该账户已被管理员禁用，如有疑问请联系管理员');
          //登出
          await supabaseHelper.signOut();
          //删除用户配置项
          final directory = await getApplicationDocumentsDirectory();
          String configPath = '${directory.path}${Platform.pathSeparator}HuituxuanConfig${Platform.pathSeparator}';
          await deleteFolder(configPath);
          return;
        }
        String? userSessionId = data[0]['session_id'];
        bool isNew = data[0]['is_new'] ?? false;
        await Config.saveSettings({'is_new': isNew});
        String? savedSessionId = await getCurrentSessionId();
        if (savedSessionId != null && savedSessionId != userSessionId) {
          //会话过期，需要重新登录
          await supabaseHelper.signOut();
          if (mounted) {
            if (!isSSODialogOpen) {
              showSSODialog('登录状态过期', '您的账号在其他设备上登录，您需要重新登录。如果不是您本人操作，说明你的账号存在安全风险，请尽快修改密码后重新登录。');
            }
          }
        }
        Map<String, dynamic> settingsFromUrl = data[0]['htx_settings'];
        Map<String, dynamic> inviteUserSettings = {};
        if (inviteUserData.isNotEmpty) {
          inviteUserSettings = inviteUserData[0]['htx_settings'];
        }
        settingsFromUrl['can_use_mj'] = data[0]['can_use_mj'];
        settingsFromUrl['mj_api_url'] = data[0]['mj_api_url'];
        settingsFromUrl['mj_api_secret'] = data[0]['mj_api_secret'];
        settingsFromUrl['invite_code'] = data[0]['invite_code'];
        if (!GlobalParams.isFreeVersion && !GlobalParams.isAdminVersion) {
          var savedSettings = await Config.loadSettings();
          var newSettingsFromUrl = removeSuperUserInfo(inviteUserSettings);
          var newSettings = fillMissingAttributes(savedSettings, newSettingsFromUrl);
          await Config.saveSettings(newSettings);
        } else {
          await Config.saveSettings(settingsFromUrl);
          String userAvatar = settingsFromUrl['user_avatar'] ?? '';
          if (mounted) {
            final changeSettings = context.read<ChangeSettings>();
            await changeSettings.updateUserAvatar(userAvatar);
          }
        }
        userQuotas = await checkUserQuota(userId);
      } else {
        commonPrint('配置下载失败');
      }
    }
  }

  void showSSODialog(String title, String desc) {
    isSSODialogOpen = true;
    final changeSettings = context.read<ChangeSettings>();
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return CustomDialog(
            title: title,
            description: desc,
            showConfirmButton: true,
            showCancelButton: true,
            confirmButtonText: '重新登录',
            cancelButtonText: '我知道了',
            titleColor: changeSettings.getForegroundColor(),
            contentBackgroundColor: changeSettings.getBackgroundColor(),
            descColor: changeSettings.getForegroundColor(),
            conformButtonColor: changeSettings.getSelectedBgColor(),
            cancelButtonColor: changeSettings.getSelectedBgColor(),
            isConformClose: false,
            onConfirm: () {
              isSSODialogOpen = false;
              showLoginDialog(isRegister: false);
            },
            onCancel: () {
              isSSODialogOpen = false;
              _handleLogout();
            },
          );
        });
  }

  Future<void> showLoginDialog({bool isRegister = true}) async {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      useSafeArea: false,
      barrierDismissible: true,
      builder: (BuildContext context) => LoginDialog(
        isRegister: isRegister,
        onSuccess: (User user, String? hashPassword, String? userName, String? inviteCode) {
          setState(() {
            isRegistered = true;
            isLogin = true;
            userName = userName;
          });
          if (hashPassword != null) {
            _handleSuccessfulRegistration(user, hashPassword, userName, inviteCode);
          } else {
            _handleSuccessfulLogin(user);
          }
        },
      ),
    );
  }

  // 处理成功注册后的操作
  Future<void> _handleSuccessfulRegistration(User user, String hashPassword, String? registerUserName, String? inviteCode) async {
    Map<String, dynamic> settings = {'is_login': true, 'is_registered': true, 'user_id': user.id, 'is_new': true};
    await Config.saveSettings(settings);
    setState(() {
      userName = registerUserName ?? '';
      isRegistered = true;
    });
    Map<String, dynamic> savedSettings = await Config.loadSettings();
    // Create new user
    await supabaseHelper.insert('my_users', {
      'name': registerUserName,
      'email': user.email,
      'password': hashPassword,
      'user_id': user.id,
      'client_id': savedSettings['client_id'] ?? const Uuid().v4(),
      'mj_account_id': '',
      'can_use_mj': true,
      'is_new': true,
      'invite_code': savedSettings['invite_code'],
      'register_invite_code': inviteCode ?? 'wqjuser',
      'htx_settings': savedSettings
    });
  }

  // 处理成功登录后的操作
  Future<void> _handleSuccessfulLogin(User user) async {
    showHint('登录成功,读取数据中...', showType: 2);
    String username = user.userMetadata!['username'];
    setState(() {
      userName = username;
      isRegistered = true;
      isLogin = true;
    });
    Map<String, dynamic> deviceInfo = await getDeviceInfo();
    String currentTime = getCurrentTimestamp(format: 'yyyy-MM-dd HH:mm:ss');
    String? sessionId = await getCurrentSessionId();
    if (sessionId == null) {
      sessionId = const Uuid().v4();
      await saveSessionId(sessionId);
    }
    await loginChannel?.sendBroadcastMessage(
      event: 'user_login',
      payload: {
        'user_id': user.id,
        'last_login_at': currentTime,
        'session_id': sessionId,
        'device_info': deviceInfo,
      },
    );
    Map<String, dynamic> settings = {'is_login': true, 'is_registered': true, 'user_name': username, 'user_id': user.id};
    await Config.saveSettings(settings);
    Map<String, dynamic> savedSettings = await Config.loadSettings();
    final data = await supabaseHelper.query('my_users', {'user_id': user.id});
    if (data.isNotEmpty) {
      if (!GlobalParams.isFreeVersion && !GlobalParams.isAdminVersion) {
        String inviteCode = data[0]['htx_settings']['register_invite_code'] ?? 'wqjuser';
        bool isNew = data[0]['is_new'] ?? false;
        await Config.saveSettings({'is_new': isNew});
        await _handleInviteCodeSettings(savedSettings, inviteCode: inviteCode, userId: user.id);
      } else {
        //管理员账户不同设备登录的时候也需要去除文件保存位置的属性,mac和win文件路径不同
        Map<String, dynamic> settingsFromUrl = data[0]['htx_settings'];
        if (settingsFromUrl.containsKey('image_save_path')) {
          settingsFromUrl.remove('image_save_path');
        }
        if (settingsFromUrl.containsKey('jy_draft_save_path')) {
          settingsFromUrl.remove('jy_draft_save_path');
        }
        await Config.saveSettings(settingsFromUrl);
        Map<String, dynamic> newSettings = await Config.loadSettings();
        String userAvatar = newSettings['user_avatar'] ?? '';
        if (mounted) {
          final changeSettings = context.read<ChangeSettings>();
          await changeSettings.updateUserAvatar(userAvatar);
        }
      }
    }
    await supabaseHelper.update('my_users', {
      'last_login_at': currentTime,
      'session_id': sessionId,
      'device_info': deviceInfo,
    }, updateMatchInfo: {
      'user_id': user.id
    });
    //重新获取模型列表
    await getAiModels();
    //这里登录后重新初始化 openai客户端
    await OpenAIClientSingleton.instance.init();
    await box.write('is_login', true);
    await box.write('user_id', user.id);
    await box.write('needRefreshSettings', true);
  }

  // 处理邀请码相关设置
  Future<void> _handleInviteCodeSettings(Map<String, dynamic> savedSettings, {String? inviteCode, String userId = ''}) async {
    final superUserData = await supabaseHelper.query('my_users', {'invite_code': inviteCode ?? 'wqjuser'});
    final userData = await supabaseHelper.query('my_users', {'user_id': userId});
    if (superUserData.isNotEmpty) {
      final settingsFromUrl = superUserData[0]['htx_settings'];
      var newSettingsFromUrl = removeSuperUserInfo(settingsFromUrl);
      var newSettings = fillMissingAttributes(savedSettings, newSettingsFromUrl);
      var allSettings = fillEmptyAttributes(userData[0]['htx_settings'], newSettings);
      await Config.saveSettings(allSettings);
      String userAvatar = allSettings['user_avatar'] ?? '';
      if (mounted) {
        final changeSettings = context.read<ChangeSettings>();
        await changeSettings.updateUserAvatar(userAvatar);
      }
      commonPrint('读取邀请者的配置项完成');
    }
  }

  Map<String, dynamic> removeSuperUserInfo(settingsFromUrl) {
    if (settingsFromUrl.containsKey('image_save_path')) {
      settingsFromUrl.remove('image_save_path');
    }
    if (settingsFromUrl.containsKey('jy_draft_save_path')) {
      settingsFromUrl.remove('jy_draft_save_path');
    }
    if (settingsFromUrl.containsKey('invite_code')) {
      settingsFromUrl.remove('invite_code');
    }
    if (settingsFromUrl.containsKey('is_login')) {
      settingsFromUrl.remove('is_login');
    }
    if (settingsFromUrl.containsKey('is_registered')) {
      settingsFromUrl.remove('is_registered');
    }
    if (settingsFromUrl.containsKey('ip')) {
      settingsFromUrl.remove('ip');
    }
    if (settingsFromUrl.containsKey('email')) {
      settingsFromUrl.remove('email');
    }
    if (settingsFromUrl.containsKey('client_id')) {
      settingsFromUrl.remove('client_id');
    }
    if (settingsFromUrl.containsKey('user_id')) {
      settingsFromUrl.remove('user_id');
    }
    if (settingsFromUrl.containsKey('user_name')) {
      settingsFromUrl.remove('user_name');
    }
    if (settingsFromUrl.containsKey('password')) {
      settingsFromUrl.remove('password');
    }
    if (settingsFromUrl.containsKey('user_avatar')) {
      settingsFromUrl.remove('user_avatar');
    }
    if (settingsFromUrl.containsKey('exit_app_method')) {
      settingsFromUrl.remove('exit_app_method');
    }
    if (settingsFromUrl.containsKey('is_new')) {
      settingsFromUrl.remove('is_new');
    }
    if (settingsFromUrl.containsKey('can_free_use')) {
      settingsFromUrl.remove('can_free_use');
    }
    if (settingsFromUrl.containsKey('drawEngine')) {
      settingsFromUrl.remove('drawEngine');
    }
    if (settingsFromUrl.containsKey('use_voice_mode')) {
      settingsFromUrl.remove('use_voice_mode');
    }
    if (settingsFromUrl.containsKey('window_width')) {
      settingsFromUrl.remove('window_width');
    }
    if (settingsFromUrl.containsKey('window_height')) {
      settingsFromUrl.remove('window_height');
    }
    List<String> keysToRemove = [];
    // 遍历所有键，收集以 'chatSettings' 开头的键
    for (var key in settingsFromUrl.keys) {
      if (key.startsWith('chatSettings')) {
        keysToRemove.add(key);
      }
    }
    // 从 map 中删除收集到的键
    for (var key in keysToRemove) {
      settingsFromUrl.remove(key);
    }
    return settingsFromUrl;
  }

  void initDBBroadcast() async {
    try {
      loginChannel
          ?.onBroadcast(
              event: 'user_login',
              callback: (info) async {
                String? sessionId = info['session_id'];
                String? savedSessionId = await getCurrentSessionId();
                var config = await Config.loadSettings();
                bool isLogin = config['is_login'] ?? false;
                String userId = config['user_id'] ?? '';
                String receivedUserId = info['user_id'] ?? '';
                if (sessionId != savedSessionId && userId == receivedUserId) {
                  // 登录状态不一致，说明异地登录需要退出登录状态
                  if (mounted && isLogin) {
                    if (!isSSODialogOpen) {
                      showSSODialog('您已被强制下线', '您的账号在其他设备上登录，您已被强制下线。如果不是您本人操作，说明你的账号存在安全风险，请尽快修改密码后重新登录。');
                    }
                  }
                }
              })
          .subscribe();
      menuChannel
          ?.onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'menus',
              callback: (info) {
                var newRow = info.newRecord;
                int index = int.parse(newRow['index']);
                bool canUse = newRow['can_use'] ?? true;
                String desc = newRow['desc'] ?? '';
                if (GlobalParams.menus.isNotEmpty) {
                  for (var menu in GlobalParams.menus) {
                    if (int.parse(menu['index']) == index) {
                      menu['can_use'] = canUse;
                      menu['desc'] = desc;
                      GlobalParams.menus[index] = menu;
                    }
                  }
                }
              })
          .subscribe();
      versionChannel
          ?.onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'versions',
              callback: (info) {
                ChangeSettings settings = context.read<ChangeSettings>();
                var newRow = info.newRecord;
                String downloadUrl = newRow['version_url'];
                String updateInfo = newRow['update_info'];
                String latestVersion = newRow['version_code'];
                int versionCompareResult = compareVersions(GlobalParams.version, latestVersion);
                if (versionCompareResult == 1) {
                  showUpdateDialog(settings, updateInfo, downloadUrl);
                }
              })
          .subscribe();
      broadcastChannel
          ?.onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'broadcast',
              callback: (info) {
                var newRow = info.newRecord;
                String broadcastInfo = newRow['info'] ?? '';
                String userId = newRow['user_id'] ?? '';
                if (userId.isEmpty || userId == SupabaseHelper().currentUserId) {
                  setState(() {
                    _broadcastMessage = broadcastInfo;
                    _showBroadcast = true;
                  });
                }
              })
          .subscribe();
      aiModelChannel
          ?.onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'ai_models',
              callback: (info) async {
                await getAiModels();
              })
          .subscribe();
      userChannel
          ?.onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'my_users',
              callback: (info) async {
                var config = await Config.loadSettings();
                String registerInviteCode = config['register_invite_code'] ?? '';
                var newRow = info.newRecord;
                String userId = newRow['user_id'] ?? '';
                bool isNew = newRow['is_new'] ?? false;
                bool canFreeUse = newRow['can_free_use'] ?? false;
                String inviteCode = newRow['invite_code'] ?? '';
                if (userId == SupabaseHelper().currentUserId) {
                  await Config.saveSettings({'is_new': isNew, 'can_free_use': canFreeUse});
                } else {
                  if (inviteCode == registerInviteCode) {
                    final settingsFromUrl = newRow['htx_settings'];
                    var newSettingsFromUrl = removeSuperUserInfo(settingsFromUrl ?? {});
                    await Config.saveSettings(newSettingsFromUrl);
                  }
                }
              })
          .subscribe();
    } catch (e) {
      commonPrint(e);
    }
  }

  void initData() async {
    await loadSettings();
  }

  Future<bool> checkLoginStatus() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    bool isLogin = settings['is_login'] ?? false;
    return isLogin;
  }

  void checkForUpdate({bool isAutoCheck = true}) async {
    final settings = context.read<ChangeSettings>();
    if (isAutoCheck) {
      await Future.delayed(const Duration(seconds: 3));
    } else {
      showHint('正在检查更新...', showType: 5);
    }
    try {
      // 从服务器获取最新版本信息
      final response = await SupabaseHelper().query('versions', {'is_delete': 0}, isOrdered: false, limitNum: 1);
      if (response.isNotEmpty) {
        var responseData = response[0];
        String latestVersion = responseData['version_code'];
        String endWith = Platform.isMacOS ? '.dmg' : '.exe';
        if (!GlobalParams.isFreeVersion && !GlobalParams.isAdminVersion) {
          endWith = endWith;
        } else if (GlobalParams.isAdminVersion && !GlobalParams.isFreeVersion) {
          endWith = '(管理版)$endWith';
        } else if (GlobalParams.isFreeVersion && !GlobalParams.isAdminVersion) {
          endWith = '(免费版)$endWith';
        }
        String downloadUrl = responseData['version_url'] + endWith;
        String updateInfo = responseData['update_info'];
        // 比较当前版本和最新版本
        int versionCompareResult = compareVersions(GlobalParams.version, latestVersion);
        if (versionCompareResult == 1) {
          dismissHint();
          // 显示更新提示
          showUpdateDialog(settings, updateInfo, downloadUrl);
        } else {
          if (mounted && !isAutoCheck) {
            showHint('当前已是最新版本', showType: 2);
          }
        }
      } else {
        if (mounted && !isAutoCheck) {
          showHint('当前已是最新版本', showType: 2);
        }
      }
    } catch (e) {
      commonPrint('检查更新失败: $e');
    }
  }

  void showUpdateDialog(ChangeSettings settings, String updateInfo, String downloadUrl) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomDialog(
            title: '发现新版本',
            titleColor: settings.getForegroundColor(),
            description: '有新版本可用,是否更新?\n\n更新日志:\n$updateInfo',
            descColor: settings.getForegroundColor(),
            confirmButtonText: '更新',
            contentBackgroundColor: settings.getBackgroundColor(),
            cancelButtonText: '取消',
            showCancelButton: true,
            conformButtonColor: settings.getSelectedBgColor(),
            onConfirm: () async {
              // 下载更新文件
              final savePath = await _downloadUpdate(downloadUrl);
              bool isRunning = await _isAppRunning();
              if (isRunning) {
                await systemTray.destroy();
                await _runUpdateFile(savePath);
                exit(0);
              } else {
                await _runUpdateFile(savePath);
              }
            },
            onCancel: () {},
          );
        },
      );
    }
  }

  Future<String> _downloadUpdate(String url) async {
    // 显示下载进度对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return DownloadProgressDialog(dialogContext: context);
      },
    );
    final savePath = await getTemporaryDirectory();
    final file = File('${savePath.path}/update${Platform.isWindows ? '.exe' : '.dmg'}');
    await myApi.downloadSth(url, file.path, onReceiveProgress: (int count, int total) {
      double progress = count / total;
      EventBusUtil().eventBus.fire(DownloadProgressEvent(progress));
      // commonPrint('下载中...${(count / total * 100).toStringAsFixed(2)}%');
    });
    if (mounted) {
      Navigator.of(context).pop();
    }
    return file.path;
  }

  Future<bool> _isAppRunning() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('tasklist', ['/FI', 'IMAGENAME eq MoJingAI.exe']);
        return result.stdout.contains('MoJingAI.exe');
      } else if (Platform.isMacOS) {
        // 使用 Bundle Identifier 进行检查
        final result = await Process.run('osascript', [
          '-e',
          '''
        tell application "System Events"
          return exists application id "com.wqj.tuitu"
        end tell
        '''
        ]);

        return result.stdout.trim().toLowerCase() == 'true';
      }
      return false;
    } catch (e) {
      commonPrint('Error checking app status: $e');
      return false;
    }
  }

  Future<void> _runUpdateFile(String filePath) async {
    if (Platform.isWindows) {
      await Process.start(filePath, []);
    } else if (Platform.isMacOS) {
      await Process.run('open', [filePath]);
    }
  }

  void _handleF1Press() {
    // 这里可以执行任何你需要的操作 当应用处于前台的时候，点击键盘F1，跳转到说明书界面
    Uri url = Uri.parse(GlobalParams.instructionsUrl);
    myLaunchUrl(url);
  }

  // 获取数据库的可用ai模型
  Future<void> getAiModels() async {
    if (!GlobalParams.isFreeVersion) {
      List<Map<String, dynamic>> aiModels =
          await SupabaseHelper().query('ai_models', {'is_delete': 0}, isOrdered: true, orderInfo: 'model_name');
      GlobalParams.aiModels = aiModels;
    }
  }

  // 获取数据库的菜单数据
  Future<void> getMenus() async {
    if (!GlobalParams.isFreeVersion) {
      List<Map<String, dynamic>> menus = await SupabaseHelper().query('menus', {'is_delete': 0});
      GlobalParams.menus = menus;
    }
  }

  Future<void> getImages() async {
    var settings = await Config.loadSettings();
    String userId = settings['user_id'] ?? '';
    if (settings['is_login'] ?? false) {
      List<Map<String, dynamic>> images = await SupabaseHelper()
          .query('images', {'is_delete': 0, 'user_id': userId}, selectInfo: 'info', isOrdered: false, limitNum: 200);
      imagesList = images;
      if (imagesList.isNotEmpty) {
        int imagesLength = imagesList.length;
        Random random = Random();
        int randomNumber = random.nextInt(imagesLength);
        var imageData = jsonDecode(imagesList[randomNumber]['info']);
        setState(() {
          topImageUrl = imageData['imageUrl'];
        });
      }
    }
  }

  @override
  void dispose() {
    if (!Platform.isMacOS) {
      if (_platformDispatcher != null) {
        _platformDispatcher!.onPlatformBrightnessChanged = null;
      }
    }
    if (_windowListener != null) {
      windowManager.removeListener(_windowListener!);
    }
    // 移除亮暗主题变化监听
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _debounce?.cancel();
    loginChannel?.unsubscribe();
    menuChannel?.unsubscribe();
    versionChannel?.unsubscribe();
    aiModelChannel?.unsubscribe();
    super.dispose();
  }

  Widget _buildButton({
    required VoidCallback onPressed,
    required String text,
    required settings,
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

  Future<void> _handleExit() async {
    showHint('应用设置数据保存并退出中...', showType: 5);
    try {
      Map<String, dynamic> savedSettings = await Config.loadSettings();
      String email = savedSettings['email'] ?? '';
      bool isLogin = savedSettings['is_login'] ?? false;
      //取消热键注册
      await hotKeyManager.unregisterAll();
      if (isLogin) {
        savedSettings.remove('image_save_path');
        savedSettings.remove('jy_draft_save_path');
        // 移除窗口大小信息，只在当前设备保存，避免因设备缩放比例不同造成的异常
        savedSettings.remove('window_width');
        savedSettings.remove('window_height');
        try {
          await supabaseHelper.update(
            'my_users',
            {'htx_settings': savedSettings},
            updateMatchInfo: {'email': email},
          );
        } catch (e) {
          commonPrint('数据库数据更新失败: $e');
        }
      }

      await Config.saveSettings({
        'current_novel_folder': '',
        'current_novel_title': '',
      });
    } catch (e) {
      commonPrint('退出过程中发生错误: $e');
    } finally {
      exit(0);
    }
  }

  void _onItemTapped(int index, String tappedTitle, {bool isMenu = true}) async {
    for (var menu in GlobalParams.menus) {
      if (int.parse(menu['index']) == index) {
        if (menu['can_use'] == false) {
          String message = menu['desc'].isEmpty ? '功能升级中，暂停使用，敬请期待！' : menu['desc'];
          showHint(message);
          return;
        }
      }
    }
    if (isMenu) {
      Navigator.pop(context); // 关闭抽屉
    }
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
        title = tappedTitle;
        _pageController.jumpToPage(index);
      });
      await box.write('curPage', index);
    }
    await Config.saveSettings({'curPage': index, 'curPageTitle': title});
  }

  void _onPageChanged(int index) async {
    FocusScope.of(context).unfocus();

    // 检查菜单权限
    if (!_checkMenuPermission(index)) {
      index++;
    }

    setState(() {
      _selectedIndex = index;
      title = _getPageTitle(index);
      _setPageOrientation(_getPageOrientation(index));
    });

    await Config.saveSettings({'curPage': index, 'curPageTitle': title});
  }

  bool _checkMenuPermission(int index) {
    final menu = GlobalParams.menus.firstWhere((menu) => int.parse(menu['index']) == index, orElse: () => {});

    if (menu['can_use'] != null && menu['can_use'] == false) {
      final message = menu['desc'].isEmpty ? '功能升级中，暂停使用，敬请期待！' : menu['desc'];
      showHint('$message 将滚到到下一页面。');
      return false;
    }
    return true;
  }

  String _getPageTitle(int index) {
    if (!GlobalParams.isAdminVersion) {
      if (GlobalParams.isFreeVersion) {
        return index == 9 ? '设置' : titles[index];
      } else {
        if (index == 9) return '购买套餐';
        if (index == 10) return '设置';
        return titles[index];
      }
    }
    return titles[index];
  }

  PageOrientation _getPageOrientation(int index) {
    // 特定页面(index为4)始终使用横屏
    if (index == 4) return PageOrientation.landscape;

    // 设置页面使用横屏
    if (!GlobalParams.isAdminVersion) {
      if (GlobalParams.isFreeVersion && index == 9) {
        return PageOrientation.landscape;
      } else if (!GlobalParams.isFreeVersion && index == 10) {
        return PageOrientation.landscape;
      }
    } else if (index == 12 || index == 9) {
      return PageOrientation.landscape;
    }

    return PageOrientation.all;
  }

  void _setPageOrientation(PageOrientation orientation) {
    final orientations = orientation == PageOrientation.all
        ? [
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]
        : [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ];

    SystemChrome.setPreferredOrientations(orientations);
  }

  Future<void> launchWebUrl() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String? gptKey = settings['chat_api_key'];
    String? gptUrl = settings['chat_api_url'];
    Uri url;
    Map<String, String> urlSet = {};
    if (gptKey != '') {
      if (gptUrl != '') {
        urlSet['key'] = gptKey ?? "";
        urlSet['url'] = gptUrl ?? "";
        url = Uri.parse('${GlobalParams.chatPageUrl}/#/?settings=${json.encode(urlSet)}');
      } else {
        urlSet['key'] = gptKey ?? "";
        url = Uri.parse('${GlobalParams.chatPageUrl}/#/?settings=${json.encode(urlSet)}');
      }
    } else {
      url = Uri.parse(GlobalParams.chatPageUrl);
    }
    myLaunchUrl(url);
  }

  void supportDeveloper(String money, String packageName, String payMethod) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String payName = payMethod == 'wxpay' ? '微信' : '支付宝';
    String merchantID = settings['merchant_id'] ?? '';
    String merchantKey = settings['merchant_key'] ?? '';
    String merchantUrl = settings['merchant_url'] ?? '';
    // 获取当前时间
    DateTime now = DateTime.now();
    // 使用DateFormat格式化日期
    DateFormat formatter = DateFormat('yyyy-MM-dd HH-mm-ss');
    String formatted = formatter.format(now);
    // 获取时间戳
    int timestamp = now.millisecondsSinceEpoch;
    // 组合最终的字符串
    String result = "魔镜AI--支持开发者--\n$formatted$timestamp".removeAllWhitespace.replaceAll('-', '');
    String ip = settings['ip'] ?? '';
    Map<String, dynamic> payParams = {
      "pid": int.parse(merchantID),
      "type": payMethod,
      "out_trade_no": result,
      "notify_url": GlobalParams.notifyUrl,
      "return_url": GlobalParams.notifyUrl,
      "name": packageName,
      "money": money,
      "clientip": ip
    };
    // 使用SplayTreeMap来自动按照key值排序
    var sortedMap = SplayTreeMap<String, dynamic>.from(payParams, (key1, key2) => key1.compareTo(key2));
    // 将排序后的Map转换为URL键值对格式
    String urlParams = sortedMap.entries.map((entry) => '${entry.key}=${entry.value}').join('&');
    var bytes = utf8.encode('$urlParams$merchantKey'); // 将输入字符串转换为字节
    var digest = md5.convert(bytes); // 对字节进行MD5加密
    payParams['sign'] = digest.toString();
    payParams['sign_type'] = 'MD5';
    try {
      showHint('创建赞助订单中，请稍后...', showType: 5);
      dio.Response response = await MyApi().createPay(merchantUrl, payParams);
      if (response.statusCode == 200) {
        if (response.data is String) {
          response.data = jsonDecode(response.data);
        }
        int code = response.data['code'] ?? -1;
        if (code == 1 || code == 200) {
          if (code == 1) {
            String payUrl = response.data['payurl'] ?? '';
            String qrcode = response.data['qrcode'] ?? '';
            if (qrcode != '') {
              dealPay(response, payMethod, payName, payParams);
            } else if (payUrl != '') {
              myLaunchUrl(Uri.parse(payUrl));
            } else {
              showHint('创建赞助订单失败,请稍后重试', showType: 3);
              dismissHint();
            }
          } else {
            dealPay(response, payMethod, payName, payParams);
            dismissHint();
          }
        } else {
          dismissHint();
          if (mounted) {
            showHint('创建赞助订单失败,请稍后重试...', showType: 3);
          }
        }
      } else {
        dismissHint();
        if (mounted) {
          showHint('创建赞助订单失败,请稍后重试...', showType: 3);
        }
        commonPrint(response.data);
      }
    } catch (e) {
      if (mounted) {
        showHint('创建赞助订单失败,请稍后重试...', showType: 3);
      }
      commonPrint(e);
      dismissHint();
    }
  }

  void dealPay(dio.Response<dynamic> response, String payMethod, String payName, Map<String, dynamic> payParams) {
    String? qrcode = response.data['qrcode'];
    String? codeUrl = response.data['code_url'];
    String? tradeNo = response.data['trade_no'];
    dismissHint();
    if (codeUrl != null && codeUrl != '' && payMethod == 'alipay') {
      showPayDialog(payName, codeUrl, tradeNo);
      insertOrder(payParams, tradeNo);
    } else if (qrcode != null && qrcode != '') {
      showPayDialog(payName, qrcode, tradeNo);
      insertOrder(payParams, tradeNo);
    }
  }

  void showPayDialog(String payName, String codeUrl, String? tradeNo) {
    final settings = context.read<ChangeSettings>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CustomDialog(
          title: '支持开发者',
          descColor: settings.getForegroundColor(),
          description: '请使用$payName扫描下方二维码进行支付。不支付也没关系，您在精神上已经支持了开发者。',
          warn: '(付款后请务必稍等30秒或者1分钟左右再点击已付款按钮)',
          warnColor: settings.getWarnTextColor(),
          titleColor: settings.getForegroundColor(),
          showCancelButton: true,
          confirmButtonText: '已付款',
          cancelButtonText: '取消',
          isConformClose: false,
          conformButtonColor: settings.getSelectedBgColor(),
          contentBackgroundColor: settings.getBackgroundColor(),
          content: buildQRCodeContent(codeUrl, payName),
          onCancel: () {},
          onConfirm: () async {
            showHint('查询订单支付状态中，请稍后...', showType: 5);
            await checkOrderInfo(tradeNo, context);
          },
        );
      },
    );
  }

  Future<void> insertOrder(Map<String, dynamic> payParams, String? tradeNo) async {
    if (payParams.containsKey('notify_url')) {
      payParams.remove('notify_url');
    }
    if (payParams.containsKey('return_url')) {
      payParams.remove('return_url');
    }
    if (payParams.containsKey('clientip')) {
      payParams.remove('clientip');
    }
    Map<String, dynamic> settings = await Config.loadSettings();
    String userId = settings['user_id'] ?? '';
    payParams['user_id'] = userId;
    payParams['trade_no'] = tradeNo;
    payParams['trade_status'] = 'TRADE_PENDING';
    await supabaseHelper.insert('orders', payParams);
  }

  Future<void> checkOrderInfo(String? tradeNo, BuildContext context) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String merchantID = settings['merchant_id'] ?? '';
    String merchantKey = settings['merchant_key'] ?? '';
    Map<String, dynamic> paidInfo = {};
    paidInfo['trade_no'] = tradeNo;
    paidInfo['act'] = 'order';
    paidInfo['pid'] = int.parse(merchantID);
    paidInfo['key'] = merchantKey;
    try {
      var orderInfo = await supabaseHelper.query('orders', {'trade_no': tradeNo!});
      if (orderInfo.isNotEmpty) {
        var order = orderInfo[0];
        String orderStatus = order['trade_status'];
        if (orderStatus == 'TRADE_SUCCESS') {
          if (context.mounted) {
            showHint('感谢你付出实际行动支持了开发者，爱你呦ღ( ´･ᴗ･` )比心', showType: 2);
            Navigator.of(context).pop();
          }
        } else {
          if (context.mounted) {
            showHint('虽然未成功支付，但是你的行动已经在精神上支持了开发者，感谢你。');
            Navigator.of(context).pop();
          }
        }
      } else {
        if (context.mounted) {
          showHint('虽然未成功支付，但是你的行动已经在精神上支持了开发者，感谢你。');
          Navigator.of(context).pop();
        }
      }
      return;
    } catch (e) {
      commonPrint(e);
    } finally {
      dismissHint();
    }
  }

  //读取内存的键值对
  void listenStorage() async {
    box.listenKey('gotoPage', (value) {
      _onItemTapped(value, titles[value], isMenu: false);
    });
    box.listenKey('capture_close_window', (value) {
      if (value) {
        appWindow.hide();
      } else {
        Platform.isWindows ? windowManager.show() : appWindow.show();
      }
    });
    box.listenKey('is_login', (value) async {
      if (!value) {
        //退出登录了
        setState(() {
          topImageUrl = '';
        });
      } else {
        //登录了
        //刷新侧边菜单的头部图片
        getImages();
      }
    });
  }

  // 辅助方法: 构建菜单组
  Widget _buildMenuGroup({
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

  // 通用文本按钮构建方法
  Widget _buildTextButton(String text, VoidCallback onTap, ChangeSettings settings) {
    return TextButton(
      onPressed: onTap,
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

// 辅助方法: 构建登录状态
  Widget _buildLoginStatus(ChangeSettings settings) {
    return Stack(
      children: [
        Center(
          child: !isLogin
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTextButton('注册', () => showLoginDialog(), settings),
                    Text(
                      ' / ',
                      style: TextStyle(
                        color: settings.getSelectedBgColor(),
                      ),
                    ),
                    _buildTextButton('登录', () => showLoginDialog(isRegister: false), settings),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        // 显示用户信息
                        showUserQuotaDialog(context: context, userName: userName);
                      },
                      child: Text(
                        '已登录: $userName',
                        style: TextStyle(
                          color: settings.getForegroundColor(),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    TextButton(
                      onPressed: _handleLogout,
                      child: Text(
                        '退出登录',
                        style: TextStyle(
                          color: settings.getSelectedBgColor(),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _handleLogout({needShowLogOut = true}) async {
    try {
      if (needShowLogOut) {
        // 显示加载提示
        showHint('账号退出中...', showType: 5);
      }
      final changeSettings = context.read<ChangeSettings>();
      await changeSettings.resetUserAvatar();
      // 获取保存的设置
      Map<String, dynamic> savedSettings = await Config.loadSettings();
      String email = savedSettings['email'] ?? '';
      int drawEngine = savedSettings['drawEngine'] ?? 0;
      // 清除特定路径设置
      savedSettings.removeWhere((key, value) => key == 'image_save_path' || key == 'jy_draft_save_path');
      // 更新用户设置到数据库
      if (email.isNotEmpty) {
        await supabaseHelper.update('my_users', {'htx_settings': savedSettings}, updateMatchInfo: {'email': email});
      }
      // 执行 Supabase 退出
      await supabaseHelper.signOut();
      // 更新状态
      setState(() {
        isLogin = false;
        userName = ''; // 清除用户名
      });

      // 重置绘图引擎
      if (drawEngine == 2) {
        drawEngine = 0;
      }
      // 重新生成默认值
      await generateDefaultValues(isLogout: true);
      // 更新本地存储
      await box.write('is_login', false);
      // 显示退出成功提示
      if (needShowLogOut) {
        showHint('退出登录成功', showType: 2);
      }
    } catch (e) {
      // 错误处理
      if (needShowLogOut) {
        showHint('退出登录失败: ${e.toString()}');
      }
      commonPrint('Logout error: $e');
    } finally {
      // 关闭加载提示
      dismissHint();
    }
  }

// 辅助方法: 构建联系信息
  Widget _buildContactInfo(ChangeSettings settings) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '有问题? 联系开发者:',
            style: TextStyle(
              color: settings.getForegroundColor(),
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          _buildTextButton('QQ', () => _showQRCode('QQ扫码', 'qq_qrcode.webp', settings), settings),
          const SizedBox(width: 8),
          _buildTextButton('微信', () => _showQRCode('微信扫码', 'wx_qrcode.webp', settings), settings),
        ],
      ),
    );
  }

// 辅助方法: 构建赞助信息
  Widget _buildSponsorInfo(ChangeSettings settings) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: TextButton(
        onPressed: () {
          _showSponsorDialog(settings);
        },
        child: Text(
          '软件对你有用？请作者喝杯咖啡☕',
          style: TextStyle(
            color: settings.getSelectedBgColor(),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // 显示二维码对话框
  void _showQRCode(String title, String qrcodePath, ChangeSettings settings) {
    String useImagePath = 'assets/images/$qrcodePath';
    List<String> images = [useImagePath];

    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomDialog(
            title: title,
            titleColor: settings.getForegroundColor(),
            showCancelButton: false,
            showConfirmButton: false,
            description: null,
            useScrollContent: false,
            contentBackgroundColor: settings.getBackgroundColor(),
            maxHeight: 332,
            content: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 5),
              child: CustomCarousel(
                useAssetImage: true,
                currentIndex: 0,
                imagePaths: images,
                autoScroll: false,
                aspectRatio: 1,
                isNeedIndicator: false,
                onPageChangedCallback: (int index, String imagePath) {},
              ),
            ),
          );
        },
      );
    }
  }

  // 显示赞助对话框
  void _showSponsorDialog(ChangeSettings settings) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return SponsorDialog(
            selectedBgColor: settings.getSelectedBgColor(),
            foregroundColor: settings.getForegroundColor(),
            backgroundColor: settings.getBackgroundColor(),
            onPay: (String amount, String payMethod) {
              supportDeveloper(amount, '感谢支持', payMethod);
            },
          );
        },
      );
    }
  }

  Future<void> showUserQuotaDialog({required BuildContext context, required String userName}) async {
    Navigator.of(context).pop();
    var savedSettings = await Config.loadSettings();
    String userAvatar = savedSettings['user_avatar'] ?? '';
    if (context.mounted) {
      return showDialog(
          context: context,
          barrierColor: Colors.black.withAlpha(76),
          builder: (BuildContext context) => UserInfoDialogWidget(
                userName: userName,
                userAvatar: userAvatar,
              ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    final Orientation orientation = MediaQuery.of(context).orientation;
    final bool isPC = Platform.isWindows || Platform.isMacOS;
    return Scaffold(
      key: _scaffoldKey,
      appBar: (isPC || (!isPC && orientation == Orientation.portrait))
          ? AppBar(
              automaticallyImplyLeading: false,
              toolbarHeight: isPC ? 80 : 48, // 增加AppBar高度
              backgroundColor: settings.getAppbarColor(),
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  color: settings.getAppbarColor(),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      if (isPC) ...[
                        SizedBox(
                          height: 32, // 设置固定高度以确保拖动区域稳定
                          child: Stack(
                            children: [
                              // 应用图标和标题
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/app_icon.png',
                                      height: 20,
                                      width: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '魔镜AI',
                                      style: TextStyle(color: settings.getAppbarTextColor()),
                                    ),
                                  ],
                                ),
                              ),
                              // 添加一个全屏的拖动区域作为底层
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent, // 确保即使是透明区域也能响应事件
                                  onPanStart: (details) {
                                    windowManager.startDragging();
                                  },
                                  onDoubleTap: () async {
                                    if (isAppIntoFullScreen) {
                                      windowManager.unmaximize();
                                    } else {
                                      windowManager.maximize();
                                    }
                                  },
                                  child: Container(
                                    color: Colors.transparent, // 透明容器，但可以接收事件
                                  ),
                                ),
                              ),
                              // 窗口控制按钮
                              if (Platform.isWindows)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      WindowButton(
                                        tooltip: '最小化',
                                        iconPath: 'assets/images/min_window.svg',
                                        onTap: () {
                                          windowManager.minimize();
                                        },
                                      ),
                                      WindowButton(
                                        isMaximizeButton: true,
                                        tooltip: isAppIntoFullScreen ? '向下还原' : '最大化',
                                        iconPath: isAppIntoFullScreen
                                            ? 'assets/images/max_window.svg'
                                            : 'assets/images/into_max_window.svg',
                                        onTap: () async {
                                          if (isAppIntoFullScreen) {
                                            windowManager.unmaximize();
                                          } else {
                                            windowManager.maximize();
                                          }
                                        },
                                      ),
                                      WindowButton(
                                        tooltip: '退出',
                                        iconPath: 'assets/images/close_window.svg',
                                        onTap: () {
                                          windowManager.close();
                                        },
                                        isCloseButton: true,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      // AppBar标题和操作按钮
                      Expanded(
                        child: Stack(
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(
                                    Icons.menu,
                                    color: settings.getAppbarTextColor(),
                                    size: 30,
                                  ),
                                  onPressed: () async {
                                    FocusScope.of(context).unfocus();
                                    _scaffoldKey.currentState?.openDrawer();
                                  },
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: settings.getAppbarTextColor(),
                                    fontSize: 24,
                                  ),
                                ),
                                Expanded(
                                    child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Tooltip(
                                      message: settings.nextThemeModeDescription,
                                      child: IconButton(
                                        icon: Icon(
                                          settings.themeIcon,
                                          color: settings.getAppbarTextColor(),
                                        ),
                                        onPressed: () {
                                          settings.toggleTheme();
                                          // showHint('已切换至${settings.themeModeDescription}', showType: 4, showTime: 100, showPosition: 3);
                                        },
                                      ),
                                    ),
                                    Visibility(
                                        visible: (GlobalParams.isAdminVersion && _selectedIndex == 12) ||
                                            (!GlobalParams.isAdminVersion && _selectedIndex == 9),
                                        child: Row(
                                          children: [
                                            Visibility(
                                                visible: GlobalParams.isAdminVersion || GlobalParams.isFreeVersion,
                                                child: Row(
                                                  children: [
                                                    Tooltip(
                                                      message: '上传配置',
                                                      child: IconButton(
                                                        icon: const Icon(Icons.cloud_upload),
                                                        color: settings.getAppbarTextColor(),
                                                        onPressed: () async {
                                                          Map<String, dynamic> settings = await Config.loadSettings();
                                                          bool isLogin = settings['is_login'] ?? false;
                                                          String userEmail = settings['email'];
                                                          if (isLogin) {
                                                            showHint('配置上传中...', showType: 5);
                                                            if (settings.containsKey('image_save_path')) {
                                                              settings.remove('image_save_path');
                                                            }
                                                            if (settings.containsKey('jy_draft_save_path')) {
                                                              settings.remove('jy_draft_save_path');
                                                            }
                                                            // 移除窗口大小信息，只在当前设备保存，避免因设备缩放比例不同造成的异常
                                                            settings.remove('window_width');
                                                            settings.remove('window_height');
                                                            await SupabaseHelper().update('my_users', {'htx_settings': settings},
                                                                updateMatchInfo: {'email': userEmail});
                                                            showHint('配置上传成功', showType: 2);
                                                          } else {
                                                            showHint('请先登录', showType: 3);
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                    Tooltip(
                                                      message: '下载配置',
                                                      child: IconButton(
                                                        icon: const Icon(Icons.cloud_download),
                                                        color: settings.getAppbarTextColor(),
                                                        onPressed: () async {
                                                          Map<String, dynamic> settings = await Config.loadSettings();
                                                          bool isLogin = settings['is_login'] ?? false;
                                                          String userEmail = settings['email'];
                                                          if (isLogin) {
                                                            showHint('配置下载中...');
                                                            final data =
                                                                await SupabaseHelper().query('my_users', {'email': userEmail});
                                                            if (data.isNotEmpty) {
                                                              Map<String, dynamic> settingsFromUrl = data[0]['htx_settings'];
                                                              await Config.saveSettings(settingsFromUrl);
                                                              await box.write('needRefreshSettings', true);
                                                              showHint('配置下载成功', showType: 2);
                                                            } else {
                                                              showHint('配置下载失败', showType: 3);
                                                            }
                                                          } else {
                                                            showHint('请先登录', showType: 3);
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                )),
                                          ],
                                        )),
                                  ],
                                )),
                              ],
                            ),
                            if (_showBroadcast) ...[
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0, // Leave space for close button
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: settings.getBackgroundColor().withAlpha(204),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 80, // Leave space for close button
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: AutoScrollText(
                                    text: _broadcastMessage,
                                    textStyle: TextStyle(
                                      fontSize: 16,
                                      color: settings.getForegroundColor(),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                  top: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.only(right: 16),
                                    decoration: const BoxDecoration(
                                      borderRadius:
                                          BorderRadius.only(bottomRight: Radius.circular(4), topRight: Radius.circular(4)),
                                    ),
                                    child: Center(
                                        child: TextButton(
                                      style: TextButton.styleFrom(
                                        backgroundColor: settings.getSelectedBgColor(),
                                        foregroundColor: settings.getCardTextColor(),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        '我知道了',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _showBroadcast = false;
                                        });
                                      },
                                    )),
                                  )),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
      drawer: Drawer(
        child: SafeArea(
            child: Container(
          decoration: BoxDecoration(color: settings.getBackgroundColor()),
          child: Column(
            children: <Widget>[
              // 抽屉头部
              Visibility(
                  visible: isPC || (!isPC && orientation == Orientation.portrait),
                  child: SizedBox(
                    height: 240,
                    width: double.infinity,
                    child: DrawerHeader(
                      padding: EdgeInsets.zero,
                      margin: EdgeInsets.zero,
                      child: Stack(fit: StackFit.expand, children: <Widget>[
                        topImageUrl != ''
                            ? ImagePreviewWidget(
                                imageUrl: topImageUrl,
                                previewWidth: double.infinity,
                                previewHeight: 240,
                                radius: 0,
                                padding: const EdgeInsets.all(0),
                                alignment: Alignment.topCenter,
                                onDoubleTap: () => getImages(),
                              )
                            : const Image(
                                image: AssetImage('assets/images/drawer_top_bg.png'),
                                fit: BoxFit.cover,
                              ),
                        if (getRealDarkMode(settings))
                          IgnorePointer(
                              child: Container(
                            color: Colors.black.withAlpha(76),
                          ))
                      ]),
                    ),
                  )),
              // 菜单列表
              Expanded(
                  child: Stack(
                fit: StackFit.expand,
                // 允许子组件超出Stack的范围
                clipBehavior: Clip.none,
                children: [
                  ListView(
                    padding: const EdgeInsets.all(0),
                    controller: _scrollController, // 添加滚动控制器
                    children: [
                      // AI 相关功能组
                      _buildMenuGroup(
                          title: "AI 创作",
                          items: [
                            MenuItem(
                              icon: Icons.chat,
                              title: 'AI助手',
                              onTap: () => _onItemTapped(0, 'AI助手'),
                              settings: settings,
                            ),
                            MenuItem(
                              icon: Icons.brush,
                              title: 'AI绘画',
                              onTap: () => _onItemTapped(1, 'AI绘画'),
                              settings: settings,
                            ),
                            MenuItem(
                              icon: Icons.video_library,
                              title: 'AI视频',
                              onTap: () => _onItemTapped(2, 'AI视频'),
                              settings: settings,
                            ),
                            MenuItem(
                              icon: Icons.music_note,
                              title: 'AI音乐',
                              onTap: () => _onItemTapped(3, 'AI音乐'),
                              settings: settings,
                            ),
                          ],
                          settings: settings),

                      Divider(
                        height: 1,
                        color: settings.getSelectedBgColor(),
                      ),

                      // 创作工具组
                      _buildMenuGroup(
                          title: "创作工具",
                          items: [
                            MenuItem(
                                icon: Icons.edit_note,
                                title: '小说推文助手',
                                onTap: () => _onItemTapped(4, '小说推文助手'),
                                settings: settings),
                            MenuItem(
                                icon: Icons.palette,
                                title: '艺术图片生成',
                                onTap: () => _onItemTapped(5, '艺术图片生成'),
                                settings: settings),
                            MenuItem(
                                icon: Icons.workspaces_filled,
                                title: '工作流',
                                onTap: () => _onItemTapped(6, '工作流'),
                                settings: settings),
                          ],
                          settings: settings),

                      Divider(
                        height: 1,
                        color: settings.getSelectedBgColor(),
                      ),

                      // 资源管理组
                      _buildMenuGroup(
                          title: "资源管理",
                          items: [
                            MenuItem(
                                icon: Icons.library_books,
                                title: '知识库',
                                onTap: () => _onItemTapped(7, '知识库'),
                                settings: settings),
                            MenuItem(
                                icon: Icons.photo_library, title: '画廊', onTap: () => _onItemTapped(8, '画廊'), settings: settings),
                          ],
                          settings: settings),

                      if (GlobalParams.isAdminVersion) ...[
                        Divider(
                          height: 1,
                          color: settings.getSelectedBgColor(),
                        ),
                        // 管理员功能组
                        _buildMenuGroup(
                            title: "管理功能",
                            items: [
                              MenuItem(
                                  icon: Icons.people, title: '用户管理', onTap: () => _onItemTapped(9, '用户管理'), settings: settings),
                              MenuItem(
                                  icon: Icons.card_membership,
                                  title: '套餐设置',
                                  onTap: () => _onItemTapped(10, '套餐设置'),
                                  settings: settings),
                            ],
                            settings: settings),
                      ],

                      if (!GlobalParams.isFreeVersion) ...[
                        Divider(
                          height: 1,
                          color: settings.getSelectedBgColor(),
                        ),
                        MenuItem(
                            icon: Icons.shopping_cart,
                            title: '购买套餐',
                            onTap: () => _onItemTapped(GlobalParams.isAdminVersion ? 11 : 9, '购买套餐'),
                            settings: settings),
                      ],

                      Divider(
                        height: 1,
                        color: settings.getSelectedBgColor(),
                      ),
                      MenuItem(
                          icon: Icons.settings,
                          title: '设置',
                          onTap: () => _onItemTapped(
                              GlobalParams.isFreeVersion
                                  ? 9
                                  : GlobalParams.isAdminVersion
                                      ? 12
                                      : 10,
                              '设置'),
                          settings: settings),
                    ],
                  ),
                  // 向下滚动指示器
                  if (_showScrollIndicator)
                    Visibility(
                        visible: true,
                        child: Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: settings.getBackgroundColor().withAlpha(204),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: IconButton(
                                  onPressed: _scrollToBottom,
                                  icon: Icon(
                                    Icons.arrow_circle_down,
                                    color: settings.getForegroundColor(),
                                    size: 24,
                                  ),
                                  padding: const EdgeInsets.all(5),
                                )),
                          ),
                        )),
                ],
              )),
              // 底部信息区域
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: settings.getBackgroundColor(),
                  border: Border(
                    top: BorderSide(
                      color: settings.getForegroundColor().withAlpha(25),
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 登录状态显示
                    _buildLoginStatus(settings),
                    const SizedBox(height: 4),
                    // 版本号
                    InkWell(
                      onTap: () => checkForUpdate(isAutoCheck: false),
                      onDoubleTap: () async {
                        if (GlobalParams.isAdminVersion) {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return FilePickerDialog(
                                  maxFiles: 1,
                                  title: '上传新版本',
                                  onConfirm: (List<PlatformFile> files, String updateInfo) async {
                                    if (files.isNotEmpty) {
                                      showHint('新版本上传在后台继续进行', showType: 2);
                                      String filePath = files.single.path!;
                                      String fileName = files.single.name;
                                      String fileNameWithoutExtension = path.basenameWithoutExtension(filePath);
                                      File file = File(files.single.path!);
                                      List<String> parts = fileName.split('-');
                                      String middlePart = parts[1];
                                      String fileUrl = GlobalParams.filesUrl +
                                          await uploadFileToALiOss(filePath, '', file,
                                              needDelete: false,
                                              fileType: Platform.isWindows ? 'exe' : 'dmg',
                                              setFileName: fileNameWithoutExtension);
                                      String fileUrlWithoutExtension = path.withoutExtension(fileUrl);
                                      await SupabaseHelper().insert('versions', {
                                        'version_name': fileNameWithoutExtension,
                                        'version_url': fileUrlWithoutExtension,
                                        'version_code': middlePart,
                                        'update_info': updateInfo,
                                      });
                                      showHint('新版本上传成功', showType: 4, showPosition: 3);
                                    } else {
                                      commonPrint('请先选择文件');
                                    }
                                  },
                                );
                              });
                        }
                      },
                      child: Text(
                        '版本号：${GlobalParams.version}',
                        style: TextStyle(
                          color: settings.getForegroundColor(),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 联系方式
                    _buildContactInfo(settings),
                    if (!GlobalParams.isFreeVersion) ...[
                      const SizedBox(height: 6),
                    ],
                    // 赞助信息
                    if (GlobalParams.isFreeVersion) ...[
                      _buildSponsorInfo(settings),
                    ]
                  ],
                ),
              ),
            ],
          ),
        )),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: GlobalParams.isAdminVersion
            ? 13
            : GlobalParams.isFreeVersion
                ? 10
                : 11, // 页面数量
        itemBuilder: (context, index) {
          switch (index) {
            case 0:
              return const KeepAlivePage(
                child: AIChatPage(),
              );
            case 1:
              return const KeepAlivePage(child: RandomGeneratorView(isGallery: false));
            case 2:
              return const KeepAlivePage(child: AiVideoPage());
            case 3:
              return const KeepAlivePage(child: AiMusicPage());
            case 4:
              return const KeepAlivePage(child: ArticleGeneratorView());
            case 5:
              return const KeepAlivePage(child: AIArtImagesView());
            case 6:
              return const KeepAlivePage(child: WorkFlowsView());
            case 7:
              return const KeepAlivePage(child: CreateKnowledgeBasePage());
            case 8:
              return const RandomGeneratorView(isGallery: true);
            case 9:
              return GlobalParams.isFreeVersion
                  ? const KeepAlivePage(child: SettingsPage())
                  : !GlobalParams.isAdminVersion
                      ? const ManagePackagesPage(isBuy: true)
                      : const KeepAlivePage(child: ManageUserPage());
            case 10:
              return GlobalParams.isAdminVersion
                  ? const KeepAlivePage(child: ManagePackagesPage(isBuy: false))
                  : const KeepAlivePage(child: SettingsPage());
            case 11:
              return const ManagePackagesPage(isBuy: true);
            case 12:
              return const KeepAlivePage(child: SettingsPage());
            default:
              return Container();
          }
        },
      ),
    );
  }
}
