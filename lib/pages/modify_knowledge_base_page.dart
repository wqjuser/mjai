import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:system_tray/system_tray.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/config/config.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'package:tuitu/utils/landscape_stateful_mixin.dart';
import 'package:tuitu/widgets/kb_file_item.dart';
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart';
import '../json_models/kb_file_list_data.dart';
import '../listeners/my_window_listener.dart';
import '../net/my_api.dart';
import '../utils/file_picker_manager.dart';
import '../utils/supabase_helper.dart';
import '../widgets/custom_dialog.dart';
import 'package:dio/dio.dart' as dio;

import '../widgets/window_button.dart';

class ModifyKnowledgeBasePage extends StatefulWidget {
  final String kbTitle;
  final String kbId;

  const ModifyKnowledgeBasePage({super.key, required this.kbTitle, required this.kbId});

  @override
  State<ModifyKnowledgeBasePage> createState() => _ModifyKnowledgeBasePageState();
}

class _ModifyKnowledgeBasePageState extends State<ModifyKnowledgeBasePage> with LandscapeStatefulMixin{
  var deleteSize = 175;
  late MyApi myApi;
  String appKey = '';
  String appSec = '';

  //记住用户退出应用的操作
  bool rememberChoice = true;
  final TextEditingController urlController = TextEditingController();
  final AppWindow appWindow = AppWindow();

  //动态数据包裹
  List<KBFileListData> fileListData = [];
  bool isAppIntoFullScreen = false;
  MyWindowListener? _windowListener;

  void _initializeWindowListener() {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      _windowListener = MyWindowListener(onMyWindowClose: () async {
        // 处理窗口关闭事件
        if (mounted) {
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
        }
      }, onMyWindowFocus: () {
        // 处理窗口获得焦点事件
        setState(() {});
      }, onMyWindowBlur: () {
        // 处理窗口失去焦点事件
      }, onMyWindowMaximize: () {
        setState(() {
          isAppIntoFullScreen = true;
        });
      }, onMyWindowUnmaximize: () {
        setState(() {
          isAppIntoFullScreen = false;
        });
      });
      windowManager.addListener(_windowListener!);
    }
  }

  //选择并上传文件
  Future<void> selectAndUploadFiles() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    appKey = settings['kb_app_id'] ?? '';
    appSec = settings['kb_app_sec'] ?? '';
    String userId = settings['user_id'] ?? '';
    FilePickerResult? result = await FilePickerManager().pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: ['md', 'txt', 'jpg', 'pdf', 'docx', 'xlsx', 'pptx', 'eml', 'csv'],
    );
    if (result != null) {
      DateTime now = DateTime.now();
      // 将当前时间转换为时间戳，精确到秒
      int timestamp = now.millisecondsSinceEpoch ~/ 1000;
      DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      DateFormat formatter = DateFormat('yyyy-MM-dd');
      String formatTime = formatter.format(date);
      // 创建FormData
      dio.FormData formData = dio.FormData.fromMap({'kbId': widget.kbId});
      List<File> files = result.paths.map((path) => File(path!)).toList();
      List<String> fileSizes = [];
      List<String> fileNames = [];
      if (files.isNotEmpty) {
        for (int i = 0; i < files.length; i++) {
          File file = files[i];
          String fileSize = formatFileSize(await file.length());
          String fileName = file.path.split(Platform.pathSeparator).last;
          fileSizes.add(fileSize);
          fileNames.add(fileName);
          formData.files.add(MapEntry(
            'file',
            await dio.MultipartFile.fromFile(file.path),
          ));
        }
        try {
          showHint('文件上传中...', showType: 5);
          var response = await myApi.uploadFileKB(formData);
          if (response.statusCode == 200) {
            if (response.data is String) {
              response.data = jsonDecode(response.data);
            }
            if (response.data['msg'] == 'SUCCESS') {
              showHint('文件上传成功', showType: 2);
              if (response.data['result'] is List) {
                List filesInfo = response.data['result'];
                for (var i = 0; i < filesInfo.length; i++) {
                  var fileInfo = filesInfo[i];
                  String fileSize = '';
                  for (int j = 0; j < fileNames.length; j++) {
                    if (fileNames[j] == fileInfo['fileName']) {
                      fileSize = fileSizes[j];
                      break; // 找到匹配的文件名后退出循环
                    }
                  }
                  fileListData = List.from(fileListData)
                    ..add(KBFileListData(
                      id: fileInfo['fileId'],
                      title: fileInfo['fileName'],
                      createTime: formatTime,
                      fileSize: fileSize,
                      status: fileInfo['status'],
                    ));
                }
                setState(() {});
                dismissHint();
                for (var fileInfo in filesInfo) {
                  Map<String, Object> kbFile = {
                    'user_id': userId,
                    'kb_id': widget.kbId,
                    'kb_file_id': fileInfo['fileId'],
                    'kb_file_size': fileSizes[fileNames.indexOf(fileInfo['fileName'])],
                    'kb_file_add_time': formatTime,
                    'kb_file_name': fileInfo['fileName'],
                    'kb_file_status': fileInfo['status'],
                  };
                  await SupabaseHelper().insert('kb_file', kbFile);
                }
                await SupabaseHelper().update('kb_list', {'kb_file_num': fileListData.length},
                    updateMatchInfo: {'kb_id': widget.kbId, 'user_id': userId});
              }

              while (true) {
                await Future.delayed(const Duration(seconds: 5));
                Map<String, dynamic> datas = await getAllKBFiles();
                List filesStatus = datas['filesStatus'];
                if (filesStatus.isNotEmpty) {
                  if (!filesStatus.contains('0')) {
                    break;
                  }
                } else {
                  break;
                }
              }
            }
          } else {
            commonPrint('知识库文件添加失败1,原因是${response.data['msg']}');
          }
        } catch (e) {
          commonPrint('知识库文件添加失败,原因是文件内容为空或者文件异常,请检查文件,$e');
          showHint('知识库文件添加失败,原因是文件内容为空或者文件异常,请检查文件', showType: 3);
        } finally {
          dismissHint();
        }
      }
    } else {
      commonPrint('用户取消文件选择');
    }
  }

  //获取该知识库的所有文件列表
  Future<Map<String, dynamic>> getAllKBFiles() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    appKey = settings['kb_app_id'] ?? '';
    appSec = settings['kb_app_sec'] ?? '';
    List filesStatus = [];
    Map<String, dynamic> result = {};
    Map<String, dynamic> payload = {'kbId': widget.kbId};
    try {
      final response = await myApi.fileListKB(payload);
      if (response.statusCode == 200) {
        if (response.data is String) {
          response.data = jsonDecode(response.data);
        }
        if (response.data['result'] is List) {
          result['data'] = response.data['result'];
          for (var fileStatus in response.data['result']) {
            for (var i = 0; i < fileListData.length; i++) {
              var kbFile = fileListData[i];
              if (kbFile.id == fileStatus['fileId'] && kbFile.status != fileStatus['status']) {
                fileListData[i].status = fileStatus['status'];
                setState(() {});
                String status = fileStatus['status'];
                String fileId = fileStatus['fileId'];
                await SupabaseHelper().update('kb_file', {'kb_file_status': status}, updateMatchInfo: {'kb_file_id': fileId});
              }
            }
            filesStatus.add(fileStatus['status']);
          }
        }
      } else {
        commonPrint('查询知识库文件失败,原因是${response.data['msg']}');
      }
    } catch (e) {
      commonPrint('查询知识库文件失败,原因是$e');
    } finally {
      dismissHint();
    }
    result['filesStatus'] = filesStatus;
    return result;
  }

  Future<void> showWarnDialog() async {
    if (mounted) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomDialog(
              title: '提示',
              titleColor: Colors.white,
              showConfirmButton: true,
              contentBackgroundColor: Colors.black,
              contentBackgroundOpacity: 0.5,
              description: '支持多文件上传，支持的文件格式：md、txt、pdf、jpg、docx、xlsx、pptx、eml、csv，单个文档小于30M，图片文件小于5M',
              confirmButtonText: '确认',
              descColor: Colors.white,
              useScrollContent: true,
              onConfirm: () async {
                Map<String, dynamic> settings = await Config.loadSettings();
                bool isLogin = settings['is_login'] ?? false;
                if (isLogin) {
                  selectAndUploadFiles();
                } else {
                  showHint('未登录');
                }
              },
            );
          });
    }
  }

  Future<void> addUrlDialog() async {
    urlController.text = '';
    if (mounted) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomDialog(
              title: '上传网址',
              titleColor: Colors.white,
              showConfirmButton: false,
              contentBackgroundColor: Colors.black,
              contentBackgroundOpacity: 0.5,
              description: '网址链接长度不超过5000字符，资源大小不超过30M',
              confirmButtonText: '确认',
              descColor: Colors.white,
              useScrollContent: true,
              maxWidth: 400,
              content: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.only(left: 1, top: 1, bottom: 1),
                      child: TextField(
                          controller: urlController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white, width: 1.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white, width: 1.0),
                              ),
                              hintText: '请输入网址链接',
                              hintStyle: TextStyle(color: Colors.white))),
                    )),
                    const SizedBox(
                      width: 3,
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await uploadUrl();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 176, 215, 252), // 按钮背景颜色
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5), // 圆角半径
                        ),
                      ),
                      child: const Text(
                        '上传',
                        style: TextStyle(
                          color: Color.fromARGB(255, 90, 71, 229),
                          // 文字颜色
                          fontSize: 16, // 文字大小
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 3,
                    ),
                  ],
                ),
              ),
            );
          });
    }
  }

  Future<void> uploadUrl() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    appKey = settings['kb_app_id'] ?? '';
    appSec = settings['kb_app_sec'] ?? '';
    String userId = settings['user_id'] ?? '';
    String url = urlController.text;
    if (url.isEmpty) {
      showHint('请先输入网址链接');
      return;
    }
    try {
      showHint('网址上传中...', showType: 5);
      DateTime now = DateTime.now();
      // 将当前时间转换为时间戳，精确到秒
      int timestamp = now.millisecondsSinceEpoch ~/ 1000;
      DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      DateFormat formatter = DateFormat('yyyy-MM-dd');
      String formatTime = formatter.format(date);
      Map<String, dynamic> payload = {'kbId': widget.kbId, 'url': url};
      final response = await myApi.uploadUrlKB(payload);
      if (response.statusCode == 200) {
        if (response.data is String) {
          response.data = jsonDecode(response.data);
        }
        commonPrint(response.data);
        showHint('网址上传成功', showType: 2);
        dismissHint();
        final fileInfo = response.data['result'];
        fileListData = List.from(fileListData)
          ..add(KBFileListData(
            id: fileInfo['fileId'],
            title: fileInfo['fileName'],
            createTime: formatTime,
            fileSize: '0.0KB',
            status: fileInfo['status'],
          ));
        setState(() {});
        Map<String, Object> kbFile = {
          'user_id': userId,
          'kb_id': widget.kbId,
          'kb_file_id': fileInfo['fileId'],
          'kb_file_size': '0.0KB',
          'kb_file_add_time': formatTime,
          'kb_file_name': fileInfo['fileName'],
          'kb_file_status': fileInfo['status'],
        };
        await SupabaseHelper().insert('kb_file', kbFile);
        await SupabaseHelper()
            .update('kb_list', {'kb_file_num': fileListData.length}, updateMatchInfo: {'kb_id': widget.kbId, 'user_id': userId});
        while (true) {
          await Future.delayed(const Duration(seconds: 5));
          Map<String, dynamic> datas = await getAllKBFiles();
          List filesStatus = datas['filesStatus'];
          if (filesStatus.isNotEmpty) {
            if (!filesStatus.contains('0')) {
              break;
            }
          } else {
            break;
          }
        }
      } else {
        commonPrint('网址上传失败,原因是${response.data['msg']}');
      }
    } catch (e) {
      commonPrint('网址上传失败,原因是$e');
    } finally {
      dismissHint();
    }
  }

  Future<void> getFileInfoFromSup() async {
    showHint('查询文档中...', showType: 5);
    Map<String, dynamic> settings = await Config.loadSettings();
    String userId = settings['user_id'] ?? '';
    Map<String, dynamic> datas = await getAllKBFiles();
    List webFilesInfo = datas['data'];
    List filesInfo =
        await SupabaseHelper().query('kb_file', {'user_id': userId, 'kb_id': widget.kbId, 'is_delete': false}, isOrdered: true);
    for (int i = 0; i < filesInfo.length; i++) {
      for (int j = 0; j < webFilesInfo.length; j++) {
        if (filesInfo[i]['kb_file_id'] == webFilesInfo[j]['fileId']) {
          filesInfo[i]['kb_file_status'] = webFilesInfo[j]['status'];
          continue;
        }
      }
    }
    fileListData = List.generate(filesInfo.length, (i) {
      return KBFileListData(
          fileSize: filesInfo[i]['kb_file_size'],
          status: filesInfo[i]['kb_file_status'],
          id: filesInfo[i]['kb_file_id'],
          title: filesInfo[i]['kb_file_name'],
          createTime: filesInfo[i]['kb_file_add_time']);
    });
    setState(() {});
    dismissHint();
  }

  //删除知识库的文件
  Future<void> deleteFile(int index) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    appKey = settings['kb_app_id'] ?? '';
    appSec = settings['kb_app_sec'] ?? '';
    String userId = settings['user_id'] ?? '';
    String fileId = fileListData[index].id;
    commonPrint('准备删除文件，索引: $index, 文件ID: $fileId, 文件名称: ${fileListData[index].title}');
    DateTime now = DateTime.now();
    // 将当前时间转换为时间戳，精确到秒
    int timestamp = now.millisecondsSinceEpoch ~/ 1000;
    String salt = const Uuid().v4();
    generateSha256Hash(checkInput(widget.kbId, '', appKey, salt, timestamp, appSec));
    Map<String, dynamic> payload = {
      'kbId': widget.kbId,
      'fileIds': [fileId]
    };
    try {
      var response = await myApi.deleteFileKB(payload);
      if (response.statusCode == 200) {
        if (response.data is String) {
          response.data = jsonDecode(response.data);
        }
        if (response.data['msg'] == 'SUCCESS') {
          showHint('文件删除成功', showType: 2);
          setState(() {
            fileListData.removeAt(index);
          });
          await SupabaseHelper()
              .update('kb_file', {'is_delete': true}, updateMatchInfo: {'user_id': userId, 'kb_file_id': fileId});
          await SupabaseHelper().update('kb_list', {'kb_file_num': fileListData.length},
              updateMatchInfo: {'user_id': userId, 'kb_id': widget.kbId});
        } else {
          commonPrint('文件删除失败，原因是${response.data['msg']}');
        }
      } else {
        commonPrint('文件删除失败，原因是${response.data['msg']}');
      }
    } catch (e) {
      commonPrint('文件删除失败，原因是$e');
    }
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
            color: isPrimary ? settings.getSelectedBgColor() : settings.getSelectedBgColor().withAlpha(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPrimary ? Colors.transparent : settings.getSelectedBgColor().withAlpha(0.3),
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

        try {
          await SupabaseHelper().update(
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

  //初始化
  @override
  void initState() {
    super.initState();
    myApi = MyApi();
    _initializeWindowListener();
    getFileInfoFromSup();
  }

  @override
  void dispose() {
    dismissHint();
    if (_windowListener != null) {
      windowManager.removeListener(_windowListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: (Platform.isWindows || Platform.isMacOS) ? 80 : 48, // 增加AppBar高度
        backgroundColor: settings.getAppbarColor(),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: settings.getAppbarColor(),
          ),
          child: SafeArea(
              child: Column(children: [
            if (Platform.isWindows || Platform.isMacOS) ...[
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
                              iconPath:
                                  isAppIntoFullScreen ? 'assets/images/max_window.svg' : 'assets/images/into_max_window.svg',
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
            Expanded(
                child: Row(
              children: [
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                  onPressed: () {
                    DateTime now = DateTime.now();
                    // 将当前时间转换为时间戳，精确到秒
                    int timestamp = now.millisecondsSinceEpoch ~/ 1000;
                    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
                    DateFormat formatter = DateFormat('yyyy-MM-dd');
                    String formatTime = formatter.format(date);
                    Navigator.of(context).pop({'id': widget.kbId, 'file_num': fileListData.length, 'change_time': formatTime});
                  },
                ),
                const SizedBox(width: 16),
                Text(
                  '知识库: ${widget.kbTitle}',
                  style: TextStyle(
                    color: settings.getAppbarTextColor(),
                    fontSize: 24,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Tooltip(
                      message: '上传文件',
                      child: IconButton(
                        icon: const Icon(Icons.file_upload_outlined),
                        color: Colors.white,
                        onPressed: () async {
                          showWarnDialog();
                        },
                      ),
                    ),
                    Tooltip(
                      message: '添加网址',
                      child: IconButton(
                        icon: const Icon(Icons.add_link_outlined),
                        color: Colors.white,
                        onPressed: () async {
                          addUrlDialog();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
              ],
            ))
          ])),
        ),
      ),
      body: SafeArea(
          child: Column(
        children: [
          SizedBox(
            height: 40,
            width: MediaQuery.of(context).size.width,
            child: Align(
              child: ConstrainedBox(
                constraints: const BoxConstraints.expand(), // 设置内容限制为填充父布局
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: settings.getForegroundColor(), // 边框颜色
                        width: 1.0, // 边框宽度
                      ),
                      top: BorderSide(
                        color: settings.getForegroundColor(), // 边框颜色
                        width: 1.0, // 边框宽度
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Center(
                          child: Text(
                            '文档ID',
                            style: TextStyle(
                              color: settings.getForegroundColor(),
                              shadows: [
                                Shadow(
                                  color: Colors.grey.withAlpha(128),
                                  offset: const Offset(0, 2),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1.0, // 设置线的宽度
                        height: 40.0, // 设置线的高度
                        color: settings.getForegroundColor(), // 设置线的颜色
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - deleteSize) / 5,
                        child: Center(
                          child: Text(
                            '文档名称',
                            style: TextStyle(
                              color: settings.getForegroundColor(),
                              shadows: [
                                Shadow(
                                  color: Colors.grey.withAlpha(128),
                                  offset: const Offset(0, 2),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1.0, // 设置线的宽度
                        height: 40.0, // 设置线的高度
                        color: settings.getForegroundColor(), // 设置线的颜色
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - deleteSize) / 5,
                        child: Center(
                          child: Text(
                            '文档状态(解析成功后可问答)',
                            style: TextStyle(
                              color: settings.getForegroundColor(),
                              shadows: [
                                Shadow(
                                  color: Colors.grey.withAlpha(128),
                                  offset: const Offset(0, 2),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1.0, // 设置线的宽度
                        height: 40.0, // 设置线的高度
                        color: settings.getForegroundColor(), // 设置线的颜色
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - deleteSize) / 5,
                        child: Center(
                          child: Text(
                            '文件大小',
                            style: TextStyle(
                              color: settings.getForegroundColor(),
                              shadows: [
                                Shadow(
                                  color: Colors.grey.withAlpha(128),
                                  offset: const Offset(0, 2),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1.0, // 设置线的宽度
                        height: 40.0, // 设置线的高度
                        color: settings.getForegroundColor(), // 设置线的颜色
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - deleteSize) / 5,
                        child: Center(
                          child: Text(
                            '创建日期',
                            style: TextStyle(
                              color: settings.getForegroundColor(),
                              shadows: [
                                Shadow(
                                  color: Colors.grey.withAlpha(128),
                                  offset: const Offset(0, 2),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1.0, // 设置线的宽度
                        height: 40.0, // 设置线的高度
                        color: settings.getForegroundColor(), // 设置线的颜色
                      ),
                      SizedBox(
                        width: 100,
                        child: Center(
                          child: Text(
                            '操作',
                            style: TextStyle(
                              color: settings.getForegroundColor(),
                              shadows: [
                                Shadow(
                                  color: Colors.grey.withAlpha(128),
                                  offset: const Offset(0, 2),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1.0, // 设置线的宽度
                        height: 40.0, // 设置线的高度
                        color: settings.getForegroundColor(), // 设置线的颜色
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '备注',
                            style: TextStyle(
                              color: settings.getForegroundColor(),
                              shadows: [
                                Shadow(
                                  color: Colors.grey.withAlpha(128),
                                  offset: const Offset(0, 2),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
              child: ListView.builder(
            itemCount: fileListData.length,
            itemBuilder: (context, index) {
              KBFileListData file = fileListData[index];
              return KbFileItem(
                key: ValueKey(file.id), // 为每个项目添加唯一的 key
                index: index,
                fileListData: file,
                onDelete: (index) {
                  if (mounted) {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return CustomDialog(
                            title: '提示',
                            titleColor: settings.getForegroundColor(),
                            showConfirmButton: true,
                            showCancelButton: true,
                            contentBackgroundColor: settings.getBackgroundColor(),
                            description: '删除该文件',
                            confirmButtonText: '确认',
                            cancelButtonText: '取消',
                            descColor: settings.getForegroundColor(),
                            useScrollContent: true,
                            conformButtonColor: settings.getSelectedBgColor(),
                            onCancel: () {},
                            onConfirm: () async {
                              Map<String, dynamic> settings = await Config.loadSettings();
                              bool isLogin = settings['is_login'] ?? false;
                              if (isLogin) {
                                deleteFile(index);
                              } else {
                                showHint('未登录');
                              }
                            },
                          );
                        });
                  }
                },
              );
            },
          )),
        ],
      )),
    );
  }
}
