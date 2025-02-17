import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:system_tray/system_tray.dart';
import 'package:tuitu/listeners/my_window_listener.dart';
import 'package:tuitu/net/my_api.dart';
import 'package:tuitu/pages/main/models/main_model.dart';
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart';
import '../../../config/change_settings.dart';
import '../../../config/config.dart';
import '../../../config/default_settings.dart';
import '../../../config/global_params.dart';
import '../../../params/preset_character.dart';
import '../../../utils/common_methods.dart';
import '../../../utils/eventbus_utils.dart';
import '../../../utils/keyboard_service.dart';
import '../../../utils/my_openai_client.dart';
import '../../../utils/native_communication.dart';
import '../../../utils/supabase_helper.dart';
import '../../../widgets/custom_carousel.dart';
import '../../../widgets/custom_dialog.dart';
import '../../../widgets/download_progress_dialog.dart';
import '../../../widgets/file_picker_dialog.dart';
import '../../../widgets/login_dialog.dart';
import '../../../widgets/sponsor_dialog.dart';
import '../../../widgets/user_info_dialog_widget.dart';
import '../views/widgets/button.dart';
import 'package:dio/dio.dart' as dio;
import 'package:path/path.dart' as path;

enum PageOrientation {
  all, // 支持所有方向
  landscape, // 仅支持横屏
}

class MainViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final Map<String, String> envVars = Platform.environment;
  final _keyboardService = KeyboardService();
  final _supabaseHelper = SupabaseHelper();
  // final _inviteCode = generateRandomString(8);
  final box = GetStorage();
  final _model = MainModel();
  final _pageController = PageController();
  final _systemTray = SystemTray();
  late final AppWindow _appWindow;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();
  final _loginChannel = SupabaseHelper().channel('login_channel');
  final _menuChannel = SupabaseHelper().channel('menus');
  final _versionChannel = SupabaseHelper().channel('versions');
  final _aiModelChannel = SupabaseHelper().channel('ai_models');
  final _userChannel = SupabaseHelper().channel('my_users');
  final _broadcastChannel = SupabaseHelper().channel('broadcast');
  late MyWindowListener? _windowListener;
  late PlatformDispatcher? _platformDispatcher;
  Timer? _debounce;
  final MyApi _myApi = MyApi();

  // Getters
  String get title => _model.title;

  List<String> get titles => _model.titles;

  int get selectedIndex => _model.selectedIndex;

  bool get isRegistered => _model.isRegistered;

  bool get isLogin => _model.isLogin;

  String get userName => _model.userName;

  String get email => _model.email;

  String get password => _model.password;

  bool get showBroadcast => _model.showBroadcast;

  String get broadcastMessage => _model.broadcastMessage;

  bool get showScrollIndicator => _model.showScrollIndicator;

  bool get isAppIntoFullScreen => _model.isAppIntoFullScreen;

  Map<String, dynamic> get userQuotas => _model.userQuotas;

  List get imagesList => _model.imagesList;

  String get topImageUrl => _model.topImageUrl;

  double get sponsorAmount => _model.sponsorAmount;

  double get windowHeight => _model.windowHeight;

  bool get rememberChoice => _model.rememberChoice;

  List<Map<String, dynamic>> get menus => _model.menus;

  bool get isSSODialogOpen => _model.isSSODialogOpen;

  // Setters
  set title(String value) {
    _model.title = value;
    notifyListeners();
  }

  set selectedIndex(int value) {
    _model.selectedIndex = value;
    notifyListeners();
  }

  set isRegistered(bool value) {
    _model.isRegistered = value;
    notifyListeners();
  }

  set isLogin(bool value) {
    _model.isLogin = value;
    notifyListeners();
  }

  set userName(String value) {
    _model.userName = value;
    notifyListeners();
  }

  set email(String value) {
    _model.email = value;
    notifyListeners();
  }

  set password(String value) {
    _model.password = value;
    notifyListeners();
  }

  set showBroadcast(bool value) {
    _model.showBroadcast = value;
    notifyListeners();
  }

  set broadcastMessage(String value) {
    _model.broadcastMessage = value;
    notifyListeners();
  }

  set showScrollIndicator(bool value) {
    _model.showScrollIndicator = value;
    notifyListeners();
  }

  set isAppIntoFullScreen(bool value) {
    _model.isAppIntoFullScreen = value;
    notifyListeners();
  }

  set userQuotas(Map<String, dynamic> value) {
    _model.userQuotas = value;
    notifyListeners();
  }

  set imagesList(List value) {
    _model.imagesList = value;
    notifyListeners();
  }

  set topImageUrl(String value) {
    _model.topImageUrl = value;
    notifyListeners();
  }

  set sponsorAmount(double value) {
    _model.sponsorAmount = value;
    notifyListeners();
  }

  set windowHeight(double value) {
    _model.windowHeight = value;
    notifyListeners();
  }

  set rememberChoice(bool value) {
    _model.rememberChoice = value;
    notifyListeners();
  }

  set menus(List<Map<String, dynamic>> value) {
    _model.menus = value;
    notifyListeners();
  }

  set isSSODialogOpen(bool value) {
    _model.isSSODialogOpen = value;
    notifyListeners();
  }

  // 页面控制器
  PageController get pageController => _pageController;

  // 键盘服务
  KeyboardService get keyboardService => _keyboardService;

  // 系统托盘
  SystemTray get systemTray => _systemTray;

  // 窗口控制器
  AppWindow get appWindow => _appWindow;

  // 全局键
  GlobalKey<ScaffoldState> get scaffoldKey => _scaffoldKey;

  // 滚动控制器
  ScrollController get scrollController => _scrollController;

  void init(BuildContext context) async {
    // 添加亮暗主题变化监听
    WidgetsBinding.instance.addObserver(this);
    // 在下一帧检查是否需要显示指示器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollIndicator();
    });
    _scrollController.addListener(_scrollListener);
    _initializeWindowListener(context);
    _initHotKeys();
    _initSystemTray();
    _loadSettings(context);
    _initDBBroadcast(context);
    _listenStorage(context);
    _keyboardService.init();
    _keyboardService.onF1Pressed = _handleF1Press;
    getAiModels();
    getImages();
    _getMenus();
    checkForUpdate(context);
  }

  void uploadSettings() async {
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
      await SupabaseHelper().update('my_users', {'htx_settings': settings}, updateMatchInfo: {'email': userEmail});
      showHint('配置上传成功', showType: 2);
    } else {
      showHint('请先登录', showType: 3);
    }
  }

  void downloadNetSettings() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    bool isLogin = settings['is_login'] ?? false;
    String userEmail = settings['email'];
    if (isLogin) {
      showHint('配置下载中...');
      final data = await SupabaseHelper().query('my_users', {'email': userEmail});
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
  }

  //监听内存的键值对
  void _listenStorage(BuildContext context) async {
    box.listenKey('gotoPage', (value) {
      onItemTapped(value, titles[value], context, isMenu: false);
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
        topImageUrl = '';
      } else {
        //登录了
        //刷新侧边菜单的头部图片
        getImages();
      }
    });
  }

  //点击登录
  void onLoginTap(BuildContext context, bool isRegister) {
    showLoginDialog(context, isRegister: isRegister);
  }

  void onLogoutTap(BuildContext context) {
    _handleLogout(context);
  }

  void onUserTap(BuildContext context) {
    _showUserQuotaDialog(context: context, userName: userName);
  }

  void onContactInfoTap(String text, BuildContext context) {
    final settings = context.read<ChangeSettings>();
    final qrcodePath = text == 'QQ' ? 'qq_qrcode.webp' : 'wx_qrcode.webp';
    _showQRCode(text, qrcodePath, settings, context);
  }

  void onSponsorInfoTap(BuildContext context, bool _) {
    final settings = context.read<ChangeSettings>();
    _showSponsorDialog(settings, context);
  }

  void showUploadNewVersionFileDialog(BuildContext context) async {
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
                          needDelete: false, fileType: Platform.isWindows ? 'exe' : 'dmg', setFileName: fileNameWithoutExtension);
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
  }

  Future<void> _showUserQuotaDialog({required BuildContext context, required String userName}) async {
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
  void dispose() {
    super.dispose();
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
    _loginChannel?.unsubscribe();
    _menuChannel?.unsubscribe();
    _versionChannel?.unsubscribe();
    _aiModelChannel?.unsubscribe();
  }

  void onItemTapped(int index, String tappedTitle, BuildContext context, {bool isMenu = true}) async {
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
    if (index != selectedIndex) {
      selectedIndex = index;
      title = tappedTitle;
      _pageController.jumpToPage(index);

      await box.write('curPage', index);
    }
    await Config.saveSettings({'curPage': index, 'curPageTitle': title});
  }

  void onPageChanged(int index, BuildContext context) async {
    FocusScope.of(context).unfocus();

    // 检查菜单权限
    if (!checkMenuPermission(index)) {
      index++;
    }

    selectedIndex = index;
    title = getPageTitle(index);
    setPageOrientation(getPageOrientation(index));

    await Config.saveSettings({'curPage': index, 'curPageTitle': title});
  }

  bool checkMenuPermission(int index) {
    final menu = GlobalParams.menus.firstWhere((menu) => int.parse(menu['index']) == index, orElse: () => {});

    if (menu['can_use'] != null && menu['can_use'] == false) {
      final message = menu['desc'].isEmpty ? '功能升级中，暂停使用，敬请期待！' : menu['desc'];
      showHint('$message 将滚到到下一页面。');
      return false;
    }
    return true;
  }

  String getPageTitle(int index) {
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

  PageOrientation getPageOrientation(int index) {
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

  void setPageOrientation(PageOrientation orientation) {
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

  void checkForUpdate(BuildContext context, {bool isAutoCheck = true}) async {
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
          if (context.mounted) {
            showUpdateDialog(settings, updateInfo, downloadUrl, context);
          }
        } else {
          if (!isAutoCheck) {
            showHint('当前已是最新版本', showType: 2);
          }
        }
      } else {
        if (!isAutoCheck) {
          showHint('当前已是最新版本', showType: 2);
        }
      }
    } catch (e) {
      commonPrint('检查更新失败: $e');
    }
  }

  // 监听F1键
  void _handleF1Press() {
    // 当应用处于前台的时候，点击键盘F1，跳转到说明书界面
    Uri url = Uri.parse(GlobalParams.instructionsUrl);
    myLaunchUrl(url);
  }

  // 滚动监听器
  void _scrollListener() {
    _checkScrollIndicator();
  }

  void _initializeWindowListener(BuildContext context) {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      _windowListener = MyWindowListener(
          onMyWindowClose: () async {
            // 处理窗口关闭事件
            final settings = context.read<ChangeSettings>();
            var savedSettings = await Config.loadSettings();
            int exitAppMethod = savedSettings['exit_app_method'] ?? -1;
            switch (exitAppMethod) {
              case 0:
                //最小化到托盘
                _appWindow.hide();
                break;
              case 1:
                //直接退出应用
                _handleExit();
                break;
              default:
                //用户没有保存过退出APP的操作
                bool isPreventClose = await windowManager.isPreventClose();
                if (isPreventClose) {
                  if (context.mounted) {
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
                                      buildButton(
                                        onPressed: () async {
                                          Navigator.of(context).pop();
                                          if (rememberChoice) {
                                            Map<String, dynamic> rememberExitChoice = {};
                                            rememberExitChoice['exit_app_method'] = 0;
                                            await Config.saveSettings(rememberExitChoice);
                                          }
                                          _appWindow.hide();
                                        },
                                        text: Platform.isWindows ? '最小化到系统托盘' : '最小化到程序坞',
                                        settings: settings,
                                        isPrimary: false,
                                      ),
                                      const SizedBox(width: 8),
                                      buildButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        text: '取消',
                                        settings: settings,
                                        isPrimary: false,
                                      ),
                                      const SizedBox(width: 8),
                                      buildButton(
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
                                          _model.rememberChoice = value ?? false;
                                          notifyListeners();
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
          },
          onMyWindowFocus: () {},
          onMyWindowBlur: () {
            // 处理窗口失去焦点事件
          },
          onMyWindowMaximize: () {
            // 处理窗口最小化事件
            showScrollIndicator = false;
            isAppIntoFullScreen = true;
          },
          onMyWindowUnmaximize: () async {
            var windowSize = await windowManager.getSize();
            double showHeight = GlobalParams.isAdminVersion ? 990 : 865;
            if (windowSize.height < showHeight) {
              if (_scrollController.hasClients) {
                showScrollIndicator = _scrollController.position.pixels < _scrollController.position.maxScrollExtent;
              }
            } else {
              showScrollIndicator = false;
            }
          },
          onMyWindowResize: () async {
            var windowSize = await windowManager.getSize();
            double showHeight = GlobalParams.isAdminVersion ? 990 : 865;
            if (windowSize.height < showHeight) {
              if (_scrollController.hasClients) {
                showScrollIndicator = _scrollController.position.pixels < _scrollController.position.maxScrollExtent;
              }
            } else {
              showScrollIndicator = false;
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

  // 检查是否需要显示滚动指示器
  void _checkScrollIndicator() {
    if (!_scrollController.hasClients) return;

    bool newShowScrollIndicator = _scrollController.position.pixels < _scrollController.position.maxScrollExtent;

    if (newShowScrollIndicator != showScrollIndicator) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _model.showScrollIndicator = newShowScrollIndicator;
        notifyListeners();
      });
    }
  }

  // 处理退出应用
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
          await _supabaseHelper.update(
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

  // 初始化热键
  Future<void> _initHotKeys() async {
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

  // 初始化系统托盘
  Future<void> _initSystemTray() async {
    if (Platform.isWindows || Platform.isMacOS) {
      _appWindow = AppWindow();
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

  // 检查目录是否存在
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

  // 生成默认值
  Future<void> generateDefaultValues({String savePath = '', isLogout = false}) async {
    const dirName = 'ImageGenerator';
    const uuid = Uuid();
    final newUuid = uuid.v4();
    final randomEncryptKey = uuid.v4().substring(0, 8);
    final path = Platform.isWindows ? '${envVars['USERPROFILE']}${Platform.pathSeparator}Pictures${Platform.pathSeparator}$dirName' : savePath;
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
    await box.write('needRefreshSettings', true);
  }

  // 初始化用户信息
  Future<void> requestDocumentsPermission(bool? isFirstUse, Map<String, dynamic> settings, BuildContext context) async {
    // 先尝试获取已存在的路径
    String? path = await NativeCommunication.getMJAIPath();
    if (path != null) {
      // 已有权限，直接使用路径
      if (context.mounted) {
        await macFirstUse(isFirstUse, path, settings, context);
      }
      return;
    }
    // 没有权限，请求新的权限
    path = await NativeCommunication.requestAccess();
    if (path != null) {
      // 执行需要文档访问权限的操作
      if (context.mounted) {
        await macFirstUse(isFirstUse, path, settings, context);
      }
    } else {
      showHint('您拒绝了文件夹的访问权限，应用的部分功能将不可用', showType: 3);
    }
  }

  // mac首次使用
  Future<void> macFirstUse(bool? isFirstUse, String path, Map<String, dynamic> settings, BuildContext context) async {
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
      if (context.mounted) {
        await downloadSettings(settings, context);
      }
    }
  }

  // 加载设置
  Future<void> _loadSettings(BuildContext context) async {
    final directory = await getApplicationDocumentsDirectory();
    String configPath = '${directory.path}${Platform.pathSeparator}HuituxuanConfig${Platform.pathSeparator}';
    await commonCreateDirectory(configPath);
    Map<String, dynamic> settings = await Config.loadSettings();
    bool? isFirstUse = settings['is_first_use'];
    isRegistered = settings['is_registered'] ?? false;
    isLogin = settings['is_login'] ?? false;
    title = settings['curPageTitle'] ?? 'AI助手';
    selectedIndex = settings['curPage'] ?? 0;
    _pageController.jumpToPage(selectedIndex);
    windowHeight = (settings['window_height'] ?? 750).toDouble();
    double showHeight = GlobalParams.isAdminVersion ? 990 : 865;
    if (windowHeight < showHeight) {
      if (_scrollController.hasClients) {
        showScrollIndicator = _scrollController.position.pixels < _scrollController.position.maxScrollExtent;
      }
    } else {
      showScrollIndicator = false;
    }
    if (isRegistered) {
      userName = settings['user_name'] ?? '';
      email = settings['email'] ?? '';
      password = settings['password'] ?? '';
    }
    if (Platform.isMacOS) {
      if (context.mounted) {
        await requestDocumentsPermission(isFirstUse, settings, context);
      }
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
          if (context.mounted) {
            await downloadSettings(settings, context);
          }
          String savePath = savedSettings['image_save_path'] ?? '';
          if (Platform.isWindows || Platform.isMacOS) {
            await commonCreateDirectory('$savePath${Platform.pathSeparator}cu_workflows');
          }
        }
      }
    }

    dio.Response response = await _myApi.getCurrentIP();
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

  // 下载配置项
  Future<void> downloadSettings(Map<String, dynamic> settings, BuildContext context) async {
    bool isLogin = settings['is_login'] ?? false;
    String userEmail = settings['email'] ?? '';
    String userId = settings['user_id'] ?? '';
    String registerInviteCode = settings['register_invite_code'] ?? '';
    if (isLogin) {
      final data = await _supabaseHelper.query('my_users', {'email': userEmail});
      final inviteUserData = await _supabaseHelper.query('my_users', {'invite_code': registerInviteCode});
      if (data.isNotEmpty) {
        if (data[0]['is_delete']) {
          //用户被管理员删除
          showHint('该账户已被管理员禁用，如有疑问请联系管理员');
          //登出
          await _supabaseHelper.signOut();
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
          await _supabaseHelper.signOut();
          if (context.mounted) {
            if (!isSSODialogOpen) {
              showSSODialog('登录状态过期', '您的账号在其他设备上登录，您需要重新登录。如果不是您本人操作，说明你的账号存在安全风险，请尽快修改密码后重新登录。', context);
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
          if (context.mounted) {
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

  // 展示单点登录弹窗
  void showSSODialog(String title, String desc, BuildContext context) {
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
              showLoginDialog(context, isRegister: false);
            },
            onCancel: () {
              isSSODialogOpen = false;
              _handleLogout(context);
            },
          );
        });
  }

  // 显示登录弹窗
  Future<void> showLoginDialog(BuildContext inputContext, {bool isRegister = true}) async {
    Navigator.of(inputContext).pop();
    showDialog(
      context: inputContext,
      useSafeArea: true,
      barrierDismissible: true,
      builder: (BuildContext context) => LoginDialog(
        isRegister: isRegister,
        onSuccess: (User user, String? hashPassword, String? userName, String? inviteCode) {
          isRegistered = true;
          isLogin = true;
          userName = userName;
          if (hashPassword != null) {
            _handleSuccessfulRegistration(user, hashPassword, userName, inviteCode);
          } else {
            _handleSuccessfulLogin(user, inputContext);
          }
        },
      ),
    );
  }

  // 处理成功注册后的操作
  Future<void> _handleSuccessfulRegistration(User user, String hashPassword, String? registerUserName, String? inviteCode) async {
    Map<String, dynamic> settings = {'is_login': true, 'is_registered': true, 'user_id': user.id, 'is_new': true};
    await Config.saveSettings(settings);

    userName = registerUserName ?? '';
    isRegistered = true;

    Map<String, dynamic> savedSettings = await Config.loadSettings();
    // Create new user
    await _supabaseHelper.insert('my_users', {
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
  Future<void> _handleSuccessfulLogin(User user, BuildContext context) async {
    showHint('登录成功,读取数据中...', showType: 2);
    String username = user.userMetadata!['username'];

    userName = username;
    isRegistered = true;
    isLogin = true;

    Map<String, dynamic> deviceInfo = await getDeviceInfo();
    String currentTime = getCurrentTimestamp(format: 'yyyy-MM-dd HH:mm:ss');
    String? sessionId = await getCurrentSessionId();
    if (sessionId == null) {
      sessionId = const Uuid().v4();
      await saveSessionId(sessionId);
    }
    await _loginChannel?.sendBroadcastMessage(
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
    final data = await _supabaseHelper.query('my_users', {'user_id': user.id});
    if (data.isNotEmpty) {
      if (!GlobalParams.isFreeVersion && !GlobalParams.isAdminVersion) {
        String inviteCode = data[0]['htx_settings']['register_invite_code'] ?? 'wqjuser';
        bool isNew = data[0]['is_new'] ?? false;
        await Config.saveSettings({'is_new': isNew});
        if (context.mounted) {
          await _handleInviteCodeSettings(savedSettings, context, inviteCode: inviteCode, userId: user.id);
        }
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
        if (context.mounted) {
          final changeSettings = context.read<ChangeSettings>();
          await changeSettings.updateUserAvatar(userAvatar);
        }
      }
    }
    await _supabaseHelper.update('my_users', {
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
  Future<void> _handleInviteCodeSettings(Map<String, dynamic> savedSettings, BuildContext context, {String? inviteCode, String userId = ''}) async {
    final superUserData = await _supabaseHelper.query('my_users', {'invite_code': inviteCode ?? 'wqjuser'});
    final userData = await _supabaseHelper.query('my_users', {'user_id': userId});
    if (superUserData.isNotEmpty) {
      final settingsFromUrl = superUserData[0]['htx_settings'];
      var newSettingsFromUrl = removeSuperUserInfo(settingsFromUrl);
      var newSettings = fillMissingAttributes(savedSettings, newSettingsFromUrl);
      var allSettings = fillEmptyAttributes(userData[0]['htx_settings'], newSettings);
      await Config.saveSettings(allSettings);
      String userAvatar = allSettings['user_avatar'] ?? '';
      if (context.mounted) {
        final changeSettings = context.read<ChangeSettings>();
        await changeSettings.updateUserAvatar(userAvatar);
      }
      commonPrint('读取邀请者的配置项完成');
    }
  }

  // 移除超级用户信息
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

  // 处理注销
  Future<void> _handleLogout(BuildContext context, {needShowLogOut = true}) async {
    try {
      await box.write('needRefreshSettings', false);
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
        await _supabaseHelper.update('my_users', {'htx_settings': savedSettings}, updateMatchInfo: {'email': email});
      }
      // 执行 Supabase 退出
      await _supabaseHelper.signOut();
      // 更新状态

      isLogin = false;
      userName = ''; // 清除用户名

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

  // 获取数据库的可用ai模型
  Future<void> getAiModels() async {
    if (!GlobalParams.isFreeVersion) {
      List<Map<String, dynamic>> aiModels = await SupabaseHelper().query('ai_models', {'is_delete': 0}, isOrdered: true, orderInfo: 'model_name');
      GlobalParams.aiModels = aiModels;
    }
  }

  // 初始化数据库通知通道
  void _initDBBroadcast(BuildContext context) async {
    try {
      _loginChannel
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
                  if (context.mounted && isLogin) {
                    if (!isSSODialogOpen) {
                      showSSODialog('您已被强制下线', '您的账号在其他设备上登录，您已被强制下线。如果不是您本人操作，说明你的账号存在安全风险，请尽快修改密码后重新登录。', context);
                    }
                  }
                }
              })
          .subscribe();
      _menuChannel
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
      _versionChannel
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
                  showUpdateDialog(settings, updateInfo, downloadUrl, context);
                }
              })
          .subscribe();
      _broadcastChannel
          ?.onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'broadcast',
              callback: (info) {
                var newRow = info.newRecord;
                String broadcastInfo = newRow['info'] ?? '';
                String userId = newRow['user_id'] ?? '';
                if (userId.isEmpty || userId == SupabaseHelper().currentUserId) {
                  broadcastMessage = broadcastInfo;
                  showBroadcast = true;
                }
              })
          .subscribe();
      _aiModelChannel
          ?.onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'ai_models',
              callback: (info) async {
                await getAiModels();
              })
          .subscribe();
      _userChannel
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

  void showUpdateDialog(ChangeSettings settings, String updateInfo, String downloadUrl, BuildContext context) {
    if (context.mounted) {
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
              final savePath = await _downloadUpdate(downloadUrl, context);
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

  Future<String> _downloadUpdate(String url, BuildContext context) async {
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
    await _myApi.downloadSth(url, file.path, onReceiveProgress: (int count, int total) {
      double progress = count / total;
      EventBusUtil().eventBus.fire(DownloadProgressEvent(progress));
      // commonPrint('下载中...${(count / total * 100).toStringAsFixed(2)}%');
    });
    if (context.mounted) {
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

  // 获取数据库的菜单数据
  Future<void> _getMenus() async {
    if (!GlobalParams.isFreeVersion) {
      List<Map<String, dynamic>> menus = await SupabaseHelper().query('menus', {'is_delete': 0});
      GlobalParams.menus = menus;
    }
  }

  Future<void> getImages() async {
    var settings = await Config.loadSettings();
    String userId = settings['user_id'] ?? '';
    if (settings['is_login'] ?? false) {
      List<Map<String, dynamic>> images =
          await SupabaseHelper().query('images', {'is_delete': 0, 'user_id': userId}, selectInfo: 'info', isOrdered: false, limitNum: 200);
      imagesList = images;
      if (imagesList.isNotEmpty) {
        int imagesLength = imagesList.length;
        Random random = Random();
        int randomNumber = random.nextInt(imagesLength);
        var imageData = jsonDecode(imagesList[randomNumber]['info']);
        topImageUrl = imageData['imageUrl'];
      }
    }
  }

  // 滚动到底部的方法
  void scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // 显示二维码对话框
  void _showQRCode(String title, String qrcodePath, ChangeSettings settings, BuildContext context) {
    String useImagePath = 'assets/images/$qrcodePath';
    List<String> images = [useImagePath];

    if (context.mounted) {
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
  void _showSponsorDialog(ChangeSettings settings, BuildContext context) {
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return SponsorDialog(
            selectedBgColor: settings.getSelectedBgColor(),
            foregroundColor: settings.getForegroundColor(),
            backgroundColor: settings.getBackgroundColor(),
            onPay: (String amount, String payMethod) {
              supportDeveloper(amount, '感谢支持', payMethod, context);
            },
          );
        },
      );
    }
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

  void supportDeveloper(String money, String packageName, String payMethod, BuildContext context) async {
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
      "notify_url": "https://oss.zxai.fun/notify",
      "return_url": "https://oss.zxai.fun/notify",
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
              if (context.mounted) {
                dealPay(response, payMethod, payName, payParams, context);
              }
            } else if (payUrl != '') {
              myLaunchUrl(Uri.parse(payUrl));
            } else {
              showHint('创建赞助订单失败,请稍后重试', showType: 3);
              dismissHint();
            }
          } else {
            if (context.mounted) {
              dealPay(response, payMethod, payName, payParams, context);
            }
            dismissHint();
          }
        } else {
          dismissHint();
          showHint('创建赞助订单失败,请稍后重试...', showType: 3);
        }
      } else {
        dismissHint();
        showHint('创建赞助订单失败,请稍后重试...', showType: 3);
        commonPrint(response.data);
      }
    } catch (e) {
      showHint('创建赞助订单失败,请稍后重试...', showType: 3);
      commonPrint(e);
      dismissHint();
    }
  }

  void dealPay(dio.Response<dynamic> response, String payMethod, String payName, Map<String, dynamic> payParams, BuildContext context) {
    String? qrcode = response.data['qrcode'];
    String? codeUrl = response.data['code_url'];
    String? tradeNo = response.data['trade_no'];
    dismissHint();
    if (codeUrl != null && codeUrl != '' && payMethod == 'alipay') {
      showPayDialog(payName, codeUrl, tradeNo, context);
      insertOrder(payParams, tradeNo);
    } else if (qrcode != null && qrcode != '') {
      showPayDialog(payName, qrcode, tradeNo, context);
      insertOrder(payParams, tradeNo);
    }
  }

  void showPayDialog(String payName, String codeUrl, String? tradeNo, BuildContext context) {
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
    await _supabaseHelper.insert('orders', payParams);
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
      var orderInfo = await _supabaseHelper.query('orders', {'trade_no': tradeNo!});
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
}
