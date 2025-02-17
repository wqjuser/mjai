import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flash/flash_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/config/global_params.dart';
import 'package:tuitu/net/my_api.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'package:tuitu/utils/supabase_helper.dart';
import 'package:tuitu/widgets/input_with_tags.dart';
import 'package:tuitu/widgets/music_player_view.dart';
import '../config/config.dart';
import '../json_models/music_response_entity.dart';
import '../utils/file_picker_manager.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/floating_action_menu.dart';
import '../widgets/music_view.dart';
import '../widgets/video_player_view.dart';

class AiMusicPage extends StatefulWidget {
  const AiMusicPage({super.key});

  @override
  State<AiMusicPage> createState() => _AiMusicPageState();
}

class _AiMusicPageState extends State<AiMusicPage> {
  final TextEditingController _musicContentController = TextEditingController();
  final TextEditingController _musicTitleController = TextEditingController();
  bool isSimpleMode = true;
  bool isOnlyMusic = false;
  late MyApi myApi;
  List<MapEntry<String, dynamic>> taskList = [];
  MapEntry<String, dynamic>? currentTask;
  bool isExecuting = false;
  String tags = '';
  List<MusicResponseClips> musicList = []; // 音乐数据列表
  final GlobalKey<MusicViewState> musicViewKey = GlobalKey<MusicViewState>();
  final storage = GetStorage();
  final RefreshController _refreshController = RefreshController(initialRefresh: true);
  int currentDatabaseId = 0;
  int pageNum = 0;
  final ScrollController _scrollController = ScrollController();
  bool _hasMore = true;
  bool _isLoading = false;
  double posX = -35.0; // 初始位置靠左并隐藏一半
  double posY = 300.0; // 初始Y轴位置
  double buttonSize = 50.0; // 按钮大小
  bool isHovered = false; // 鼠标是否悬停
  bool isFirstPageNoData = false;

  @override
  void initState() {
    super.initState();
    myApi = MyApi();
    listenStorage();
  }

  //读取内存的键值对
  void listenStorage() {
    storage.listenKey('is_login', (value) {
      if (value) {
        setState(() {
          isFirstPageNoData = false;
        });
        getAllMusics();
      } else {
        setState(() {
          musicList.clear();
          isFirstPageNoData = true;
        });
      }
    });
  }

  Future<void> showSet() async {
    final changeSettings = context.read<ChangeSettings>();
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomDialog(
            title: '音乐标签选择',
            titleColor: changeSettings.getForegroundColor(),
            contentBackgroundColor: changeSettings.getBackgroundColor(),
            descColor: changeSettings.getForegroundColor(),
            content: InputWithTags(
              onSure: (selectedTags) {
                Navigator.of(context).pop();
                tags = selectedTags;
              },
            ),
          );
        },
      );
    }
  }

  //提交生成音乐的任务
  Future<void> generateMusic() async {
    showHint('创建音乐生成任务中...', showType: 5);
    int canUseNum = storage.read('musicsNum') ?? 0;
    if (!GlobalParams.isFreeVersion) {
      if (canUseNum <= 0) {
        showHint('您可用的音乐生成次数不足，请购买套餐后再试');
        return;
      }
      bool canUse = await checkUser();
      if (!canUse) {
        showHint('账户可能已被管理员禁用，请联系管理员或者稍后重试');
        return;
      }
    }
    var settings = await Config.loadSettings();
    String userId = settings['user_id'] ?? '';
    Map<String, dynamic> payload = {};
    payload['mv'] = 'chirp-v3-5';
    payload['prompt'] = _musicContentController.text;
    payload['make_instrumental'] = isOnlyMusic;
    if (!isSimpleMode) {
      payload['title'] = _musicTitleController.text;
      payload['tags'] = tags;
    }
    try {
      MusicResponseEntity? response = await myApi.sunoGenerateMusic(payload);
      if (response != null) {
        dismissHint();
        commonPrint(response);
        var clips = response.clips;
        if (clips != null && clips.isNotEmpty) {
          String clipsIds = '';
          for (int i = 0; i < clips.length; i++) {
            if (i != clips.length - 1) {
              clipsIds += '${clips[i].id!},';
            } else {
              clipsIds += clips[i].id!;
            }
          }
          Map<String, dynamic> job = {clipsIds: _musicContentController.text};
          createTaskQueue(job);
          showHint('音乐生成任务已提交，请注意查看音乐生成状态。', showType: 2);
          await storage.write('musicsNum', canUseNum - 2);
          String currentTimestamp = getCurrentTimestamp();
          for (int i = 0; i < clips.length; i++) {
            MusicResponseClips clip = clips[i];
            musicViewKey.currentState?.addItem(clip);
            var musicData = {
              'music_id': clip.id,
              'info': jsonEncode(clip),
              'user_id': userId,
              'create_time': currentTimestamp,
              'key': '$userId-${clip.id}'
            };
            await SupabaseHelper().insert('musics', musicData);
          }
        }
      } else {
        dismissHint();
        commonPrint('音乐生成任务创建失败,请稍后重试.');
      }
    } catch (e) {
      dismissHint();
      commonPrint('音乐生成任务创建失败,原因是$e');
    } finally {}
  }

  //提交生成歌词任务
  Future<void> generateLyrics() async {
    showHint('正在为您生成歌词请稍后...', showType: 5);
    Map<String, dynamic> payload = {};
    payload['prompt'] = _musicContentController.text;
    try {
      Response response = await myApi.sunoGenerateLyrics(payload);
      if (response.statusCode == 200) {
        if (response.data is String) {
          response.data = jsonDecode(response.data);
        }
        String clipId = response.data['data']['task_id'];
        while (true) {
          await Future.delayed(const Duration(seconds: 5));
          Map music = await getLyrics(clipId);
          if (music['lyrics'] != '') {
            setState(() {
              _musicContentController.text = music['lyrics'];
              _musicTitleController.text = music['title'];
            });
            dismissHint();
            break;
          }
        }
      } else {
        dismissHint();
        commonPrint('歌词生成任务提交失败原因是$response');
      }
    } catch (e) {
      dismissHint();
      commonPrint('歌词生成任务提交失败原因是$e');
      showHint('歌词生成任务提交失败,请稍后重试.', showType: 3);
    } finally {}
  }

  //获取歌词
  Future<Map<String, dynamic>> getLyrics(String id) async {
    Map<String, dynamic> music = {};
    String lyrics = '';
    String title = '';
    music['lyrics'] = lyrics;
    music['title'] = title;
    try {
      Response response = await myApi.sunoGetLyrics(id);
      if (response.statusCode == 200) {
        if (response.data is String) {
          response.data = jsonDecode(response.data);
        }
        if (response.data['data']['status'] == 'completed') {
          lyrics = response.data['data']['text'];
          title = response.data['data']['title'];
          music['lyrics'] = lyrics;
          music['title'] = title;
        }
      } else {
        commonPrint('歌词生成失败原因是$response');
      }
    } catch (e) {
      commonPrint('歌词生成失败原因是$e');
      showHint('歌词生成失败,请稍后重试.', showType: 3);
    }
    return music;
  }

  Future<void> createTaskQueue(Map<String, dynamic> taskData) async {
    void executeTask(MapEntry<String, dynamic> task) async {
      currentTask = task;
      isExecuting = true;
      await _dealJobQueue(currentTask!.key, currentTask!.value);
      commonPrint('任务 ${currentTask!.key} 执行完成');
      currentTask = null;
      isExecuting = false;
      // 继续执行下一个任务
      if (taskList.isNotEmpty) {
        final nextTask = taskList.removeAt(0);
        executeTask(nextTask);
      }
    }

    void addTask(MapEntry<String, dynamic> task) {
      taskList.add(task);
      // 如果当前没有任务在执行，立即执行新任务
      if (!isExecuting) {
        final nextTask = taskList.removeAt(0);
        executeTask(nextTask);
      }
    }

    // 使用addTask方法来添加任务
    addTask(MapEntry<String, dynamic>(taskData.keys.first, taskData.values.first));
  }

  Future<void> _dealJobQueue(String clipIds, String prompt) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String userId = settings['user_id'] ?? '';
    int canUseNum = storage.read('musicsNum') ?? 0;
    try {
      while (true) {
        await Future.delayed(const Duration(seconds: 15));
        Response response = await myApi.sunoGetMusic(clipIds);
        if (response.statusCode == 200) {
          var result = response.data;
          if (result['clips'] != null && result['clips'].isNotEmpty) {
            int totalNum = 0;
            for (int i = 0; i < result['clips'].length; i++) {
              if (result['clips'][i]['status'] == 'complete') {
                totalNum = totalNum + 1;
              }
            }
            if (totalNum == 2) {
              commonPrint(result);
              //因为音乐每次生成两个，所以这里刷新前两个
              MusicResponseClips clip1 = MusicResponseClips.fromJson(result['clips'][0]);
              MusicResponseClips clip2 = MusicResponseClips.fromJson(result['clips'][1]);
              musicViewKey.currentState?.refreshItem(0, clip1);
              musicViewKey.currentState?.refreshItem(1, clip2);
              for (int i = 0; i < result['clips'].length; i++) {
                //下面是更新数据库数据
                String clip = jsonEncode(result['clips'][i]);
                String musicId = result['clips'][i]['id'];
                await SupabaseHelper().update('musics', {'info': clip}, updateMatchInfo: {'music_id': musicId});
              }
              final response = await SupabaseHelper()
                  .runRPC('consume_user_quota', {'p_user_id': userId, 'p_quota_type': 'ai_music', 'p_amount': 1});
              if (response['code'] == 200) {
                commonPrint('消耗图片绘制额度成功');
              } else {
                commonPrint('消耗图片绘制额度失败,原因是${response['message']}');
              }
              break;
            }
          }
        } else {
          commonPrint(response);
          await storage.write('musicsNum', canUseNum + 2);
          break;
        }
      }
    } catch (e) {
      await storage.write('musicsNum', canUseNum + 2);
      commonPrint(e);
    } finally {
      dismissHint();
    }
  }

  Future<void> getAllMusics({int pageNum = 0, int pageSize = 15}) async {
    var settings = await Config.loadSettings();
    String userId = settings['user_id'] ?? '';
    bool isLogin = settings['is_login'] ?? false;
    if (pageNum == 0) {
      currentDatabaseId = 10000;
    }
    if (isLogin) {
      var musics = await SupabaseHelper()
          .query('musics', {'user_id': userId, 'is_delete': 0}, isOrdered: false, ltName: 'id', ltValue: currentDatabaseId);
      if (musics.length < pageSize) {
        _hasMore = false;
      }
      if (musics.isNotEmpty) {
        for (var music in musics) {
          MusicResponseClips musicData = MusicResponseClips.fromJson(jsonDecode(music['info']));
          musicViewKey.currentState?.addItem(musicData, index: pageNum == 0 ? 0 : musicList.length);
        }
        currentDatabaseId = musics.last['id'];
      } else {
        if (pageNum == 0) {
          isFirstPageNoData = true;
        }
      }
      setState(() {});
      dismissHint();
    }
  }

  void _onPlayClick(MusicResponseClips musicData) {
    final settings = context.read<ChangeSettings>();
    // 播放音乐的逻辑
    if (context.mounted) {
      context.showFlash(
        barrierColor: Colors.black54,
        barrierDismissible: true,
        builder: (context, controller) => FadeTransition(
          opacity: controller.controller,
          child: AlertDialog(
            backgroundColor: settings.getBackgroundColor(),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              side: BorderSide(),
            ),
            contentPadding: const EdgeInsets.only(left: 24.0, top: 16.0, right: 24.0, bottom: 16.0),
            title: Text(
              '播放选项',
              style: TextStyle(color: !getRealDarkMode(settings) ? Colors.black : settings.getSelectedBgColor()),
            ),
            content: Text(
              "选择播放类别? ",
              style: TextStyle(color: !getRealDarkMode(settings) ? Colors.black : settings.getSelectedBgColor()),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  controller.dismiss();
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return CustomDialog(
                          maxWidth: 400,
                          contentBackgroundColor: settings.getBackgroundColor(),
                          titleColor: settings.getForegroundColor(),
                          title: musicData.title == '' ? '无标题' : musicData.title,
                          content: MusicPlayerWidget(musicData: musicData),
                        );
                      },
                    );
                  }
                },
                child: Text(
                  '音乐',
                  style: TextStyle(color: settings.getSelectedBgColor()),
                ),
              ),
              TextButton(
                onPressed: () async {
                  controller.dismiss();
                  commonPrint(musicData.videoUrl!);
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return CustomDialog(
                          minWidth: 400,
                          maxWidth: 400,
                          contentBackgroundColor: settings.getBackgroundColor(),
                          titleColor: settings.getForegroundColor(),
                          title: musicData.title == '' ? '无标题' : musicData.title,
                          content: VideoPlayerView(
                            videoUrl: musicData.videoUrl!,
                            aspectRatio: 2.0 / 3.0,
                          ),
                        );
                      },
                    );
                  }
                },
                child: Text(
                  '视频',
                  style: TextStyle(color: settings.getSelectedBgColor()),
                ),
              ),
              TextButton(
                onPressed: () async {
                  controller.dismiss();
                },
                child: Text(
                  '取消',
                  style: TextStyle(color: settings.getSelectedBgColor()),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _onDownload(MusicResponseClips musicData) {
    final settings = context.read<ChangeSettings>();
    // 下载音乐的逻辑
    if (context.mounted) {
      context.showFlash(
        barrierColor: Colors.black54,
        barrierDismissible: true,
        builder: (context, controller) => FadeTransition(
          opacity: controller.controller,
          child: AlertDialog(
            backgroundColor: settings.getBackgroundColor(),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              side: BorderSide(),
            ),
            contentPadding: const EdgeInsets.only(left: 24.0, top: 16.0, right: 24.0, bottom: 16.0),
            title: Text(
              '下载选项',
              style: TextStyle(color: !getRealDarkMode(settings) ? Colors.black : settings.getSelectedBgColor()),
            ),
            content: Text(
              "选择下载类别? ",
              style: TextStyle(color: !getRealDarkMode(settings) ? Colors.black : settings.getSelectedBgColor()),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  controller.dismiss();
                  String ct = getCurrentTimestamp();
                  String? outputFile = await FilePickerManager().saveFile(
                    dialogTitle: '选择音乐保存路径',
                    fileName: '$ct.mp3',
                  );
                  if (outputFile != null) {
                    await myApi.downloadSth('${musicData.audioUrl}', outputFile, onReceiveProgress: (progress, total) {});
                    showHint('下载完成', showType: 2);
                  }
                },
                child: Text(
                  '音乐',
                  style: TextStyle(color: settings.getSelectedBgColor()),
                ),
              ),
              TextButton(
                onPressed: () async {
                  controller.dismiss();
                  String ct = getCurrentTimestamp();
                  String? outputFile = await FilePickerManager().saveFile(
                    dialogTitle: '选择视频保存路径',
                    fileName: '$ct.mp4',
                  );
                  if (outputFile != null) {
                    await myApi.downloadSth('${musicData.videoUrl}', outputFile, onReceiveProgress: (progress, total) {});
                    showHint('下载完成', showType: 2);
                  }
                },
                child: Text(
                  '视频',
                  style: TextStyle(color: settings.getSelectedBgColor()),
                ),
              ),
              TextButton(
                onPressed: () async {
                  controller.dismiss();
                },
                child: Text(
                  '取消',
                  style: TextStyle(color: settings.getSelectedBgColor()),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _onExtend(MusicResponseClips musicData) {
    //TODO 扩展音乐的逻辑
    showHint('功能升级中,暂不可用', showType: 4);
  }

  Future<void> _onDelete(MusicResponseClips musicData, int index) async {
    String musicId = musicData.id!;
    final settings = context.read<ChangeSettings>();
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomDialog(
            title: '删除确认',
            description: '是否删除该音乐？',
            titleColor: settings.getForegroundColor(),
            contentBackgroundColor: settings.getBackgroundColor(),
            descColor: settings.getForegroundColor(),
            conformButtonColor: settings.getSelectedBgColor(),
            cancelButtonText: '取消',
            confirmButtonText: '确定',
            onCancel: () {},
            onConfirm: () async {
              musicViewKey.currentState?.removeItem(index);
              if (musicList.isEmpty) {
                _refreshData();
              }
              // //这里应该修改数据库数据定义为删除
              var settings = await Config.loadSettings();
              String userId = settings['user_id'] ?? '';
              await SupabaseHelper()
                  .update('musics', {'is_delete': 1}, updateMatchInfo: {'user_id': userId, 'music_id': musicId});
            },
          );
        });
  }

  Future _refreshData() async {
    Map settings = await Config.loadSettings();
    bool isLogin = settings['is_login'] ?? false;
    if (!isLogin) {
      showHint('请先登录');
      _refreshController.refreshCompleted();
      return;
    }
    if (_isLoading) return; // 如果正在加载，直接返回
    _isLoading = true;
    _hasMore = true;
    pageNum = 0;
    musicViewKey.currentState?.clearList();
    await getAllMusics();
    _refreshController.refreshCompleted();
    _refreshController.resetNoData();
    _isLoading = false;
  }

  Future _loadMoreData() async {
    Map settings = await Config.loadSettings();
    bool isLogin = settings['is_login'] ?? false;
    if (!isLogin) {
      showHint('请先登录');
      return;
    }
    if (_isLoading) return; // 如果正在加载，直接返回
    _isLoading = true;
    if (_hasMore) {
      pageNum++;
      await getAllMusics(pageNum: pageNum);
      _refreshController.loadComplete();
    } else {
      showHint('暂无更多数据');
      _refreshController.loadNoData();
    }
    _isLoading = false;
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  // 提取复用的模式选择组件
  Widget _buildModeSelection({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required ChangeSettings settings,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: settings.getSelectedBgColor(),
            checkColor: Colors.white,
            side: WidgetStateBorderSide.resolveWith(
              (states) {
                if (states.contains(WidgetState.selected)) {
                  return BorderSide(color: settings.getSelectedBgColor(), width: 2);
                }
                return const BorderSide(color: Colors.white, width: 2);
              },
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    final isDesktop = Platform.isWindows || Platform.isMacOS;
    final children = <Widget>[
      // 歌词/描述输入框
      if (isDesktop)
        Expanded(
          child: InkWell(
            child: TextField(
              style: const TextStyle(color: Colors.yellowAccent),
              controller: _musicContentController,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2.0),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2.0),
                ),
                labelText: isSimpleMode ? '描述您想要的歌曲的风格,想表达的含义等' : '请输入歌词',
                labelStyle: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        )
      else
        SizedBox(
          width: 300,
          child: InkWell(
            child: TextField(
              style: const TextStyle(color: Colors.yellowAccent),
              controller: _musicContentController,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                isDense: true,
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2.0),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2.0),
                ),
                labelText: isSimpleMode ? '描述您想要的歌曲的风格,想表达的含义等' : '请输入歌词',
                labelStyle: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),

      const SizedBox(width: 6),

      const Text(
        '创作模式:',
        style: TextStyle(color: Colors.white),
      ),
      const SizedBox(width: 3),

      // 简易模式和专业模式选择部分
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeSelection(
            label: '简易模式',
            value: isSimpleMode,
            onChanged: (value) => setState(() => isSimpleMode = value!),
            settings: settings,
          ),
          _buildModeSelection(
            label: '专业模式',
            value: !isSimpleMode,
            onChanged: (value) => setState(() => isSimpleMode = !value!),
            settings: settings,
          ),
        ],
      ),

      const SizedBox(width: 6),

      // 歌曲标题输入框（专业模式）
      if (!isSimpleMode) ...[
        SizedBox(
          width: 200,
          child: InkWell(
            child: TextField(
              style: const TextStyle(color: Colors.yellowAccent),
              controller: _musicTitleController,
              maxLines: 3,
              minLines: 1,
              decoration:  InputDecoration(
                isDense: !isDesktop,
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2.0),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2.0),
                ),
                labelText: '20字以内的歌曲标题',
                labelStyle: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
      ],

      // 纯音乐选择
      _buildModeSelection(
        label: '纯音乐',
        value: isOnlyMusic,
        onChanged: (value) => setState(() => isOnlyMusic = value!),
        settings: settings,
      ),

      const SizedBox(width: 6),

      // 控制选项按钮（专业模式）
      if (!isSimpleMode)
        SizedBox(
          width: 40,
          height: 40,
          child: InkWell(
            onTap: () async {
              await showSet();
            },
            child: Tooltip(
              message: '控制选项',
              child: Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: settings.getSelectedBgColor(),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: SvgPicture.asset(
                  'assets/images/tb-app.svg',
                  semanticsLabel: '控制选项',
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
            ),
          ),
        ),

      const SizedBox(width: 10),

      // 生成按钮
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(settings.getSelectedBgColor())),
            onPressed: () async {
              await generateLyrics();
            },
            child: const Text(
              '生成歌词',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(settings.getSelectedBgColor())),
            onPressed: () async {
              await generateMusic();
            },
            child: const Text(
              '创作音乐',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ];

    return SafeArea(
        child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              children: [
                // 背景图片
                Positioned.fill(
                  child: ExtendedImage.asset(
                    'assets/images/drawer_top_bg.png',
                    fit: BoxFit.cover,
                  ),
                ),
                // 毛玻璃效果只应用于内容区域
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Expanded(
                        child: Stack(
                      children: [
                        Padding(
                            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                            child: !isFirstPageNoData
                                ? SmartRefresher(
                                    controller: _refreshController,
                                    enablePullDown: true,
                                    enablePullUp: Platform.isMacOS,
                                    onRefresh: _refreshData,
                                    onLoading: _loadMoreData,
                                    child: ListView(
                                      controller: _scrollController,
                                      children: [
                                        MusicView(
                                          key: musicViewKey,
                                          musicList: musicList,
                                          onPlayClick: _onPlayClick,
                                          onDownload: _onDownload,
                                          onExtend: _onExtend,
                                          onDelete: _onDelete,
                                        )
                                      ],
                                    ),
                                  )
                                : const Center(
                                    child: Text(
                                    '未登录或者暂无数据',
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ))),
                        // 添加贴边按钮
                        FloatingActionMenu(
                          onRefresh: () {
                            _refreshController.requestRefresh();
                          },
                          onLoadMore: () async {
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                            if (_hasMore) {
                              await _loadMoreData();
                              _scrollController.animateTo(
                                _scrollController.offset + 200,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            } else {
                              showHint('暂无更多数据');
                            }
                          },
                          onToTop: () {
                            _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                          },
                        ),
                      ],
                    )),
                    // Expanded(child: Container()),
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 16),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollInfo is ScrollEndNotification) {
                            if (scrollInfo.metrics.pixels <= 0 ||
                                scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent) {
                              return false;
                            }
                          }
                          return true;
                        },
                        child: LayoutBuilder(
                          builder: (BuildContext context, BoxConstraints constraints) {
                            // 根据宽度判断是否为桌面端
                            return !isDesktop
                                ? SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const ClampingScrollPhysics(),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: children),
                                  )
                                : Row(children: children);
                          },
                        ),
                      ),
                    )
                  ],
                )
              ],
            )));
  }
}
