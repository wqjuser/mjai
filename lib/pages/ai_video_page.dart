import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:extended_image/extended_image.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path/path.dart' as path;
import 'package:dio/dio.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:tuitu/config/config.dart';
import 'package:tuitu/config/global_params.dart';
import 'package:tuitu/json_models/video_list_data.dart';
import 'package:tuitu/net/my_api.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'package:tuitu/utils/supabase_helper.dart';
import 'package:tuitu/widgets/video_player_view.dart';
import 'package:tuitu/widgets/video_view.dart';
import '../config/change_settings.dart';
import '../utils/file_picker_manager.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/floating_action_menu.dart';

class AiVideoPage extends StatefulWidget {
  const AiVideoPage({super.key});

  @override
  State<AiVideoPage> createState() => _AiVideoPageState();
}

///AI视频界面
///
class _AiVideoPageState extends State<AiVideoPage> {
  //视频数据列表
  List<VideoListData> videosList = [];
  late MyApi myApi;

  //图片文件路径
  String imagePath = '';
  String imageEndPath = '';
  String imagePathBase64 = '';
  String imageEndPathBase64 = '';
  late VideoView videoView;
  List<MapEntry<String, dynamic>> taskList = [];
  MapEntry<String, dynamic>? currentTask;
  bool isExecuting = false;
  final TextEditingController _videoContentTextFieldController = TextEditingController();
  bool expandPrompt = true;
  final GlobalKey<VideoViewState> gridViewKey = GlobalKey<VideoViewState>();
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

  //获取自己的文件上传地址
  Future<Map<String, dynamic>> _getUploadUrl() async {
    Map<String, dynamic> resMap = {};
    try {
      Response res = await myApi.getLumaUploadImageLink();
      if (res.statusCode == 200) {
        if (res.data is String) {
          res.data = jsonDecode(res.data);
        }
        resMap['presigned_url'] = res.data['presigned_url'];
        resMap['public_url'] = res.data['public_url'];
      }
      commonPrint(resMap);
    } catch (e) {
      commonPrint('获取上传路径失败，原因是$e');
    }
    return resMap;
  }

  //luma上传图片
  Future<Map<String, dynamic>> _uploadImage(String uploadUrl, String publicUrl, {bool isEnd = false}) async {
    Map<String, dynamic> resMap = {};
    try {
      Response res;
      if (isEnd) {
        res = await myApi.lumaUploadImage(imagePath, uploadUrl);
      } else {
        res = await myApi.lumaUploadImage(imageEndPath, uploadUrl);
      }
      commonPrint(res);
      if (res.statusCode == 200) {
        resMap['public_url'] = publicUrl;
      } else {
        resMap['public_url'] = '';
      }
    } catch (e) {
      resMap['public_url'] = '';
      commonPrint('图片上传失败,原因是$e');
    }
    return resMap;
  }

  //luma创建生成视频的任务
  Future<void> _createVideo() async {
    showHint('正在创建视频生成任务，请稍后...', showType: 5);
    int canUseNum = storage.read('videosNum') ?? 0;
    if (!GlobalParams.isFreeVersion) {
      if (canUseNum <= 0) {
        showHint('您可用的视频生成次数不足，请购买套餐后再试');
        return;
      }
      bool canUse = await checkUser();
      if (!canUse) {
        showHint('账户可能已被管理员禁用，请联系管理员或者稍后重试', showType: 3);
        return;
      }
    }
    Map<String, dynamic> settings = await Config.loadSettings();
    int useLumaMode = settings['use_luma_mode'] ?? 0;
    bool isSelf = true;
    if (useLumaMode != 0) {
      isSelf = false;
    }
    if (_videoContentTextFieldController.text.isEmpty) {
      showHint('请输入视频画面描述');
      return;
    }
    final payload = {"user_prompt": _videoContentTextFieldController.text, "aspect_ratio": "16:9", "expand_prompt": expandPrompt};
    Map<String, dynamic> uploadRes = {};
    if (imagePath != '') {
      if (isSelf) {
        final res = await _getUploadUrl();
        String presignedUrl = res['presigned_url'];
        String publicUrl = res['public_url'];
        uploadRes = await _uploadImage(presignedUrl, publicUrl);
        if (uploadRes['public_url'] != null && uploadRes['public_url'] != '') {
          payload['image_url'] = uploadRes['public_url'];
        }
      } else {
        try {
          File imageFile = File(imagePath);
          String fileExtension = path.extension(imagePath);
          String imageUrl = await uploadFileToALiOss(imagePath, '', imageFile, fileType: fileExtension);
          payload['image_url'] = imageUrl;
        } catch (e) {
          showHint('图片上传失败，原因是$e', showType: 3);
        }
      }
      setState(() {
        imagePath = '';
        imagePathBase64 = '';
      });
    }
    if (imageEndPath != '') {
      if (isSelf) {
        final res = await _getUploadUrl();
        String presignedUrl = res['presigned_url'];
        String publicUrl = res['public_url'];
        uploadRes = await _uploadImage(presignedUrl, publicUrl, isEnd: true);
        if (uploadRes['public_url'] != null && uploadRes['public_url'] != '') {
          payload['image_end_url'] = uploadRes['public_url'];
        }
      } else {
        try {
          File imageFile = File(imageEndPath);
          String fileExtension = path.extension(imageEndPath);
          String imageUrl = await uploadFileToALiOss(imageEndPath, '', imageFile, fileType: fileExtension);
          payload['image_url'] = imageUrl;
        } catch (e) {
          showHint('图片上传失败，原因是$e', showType: 3);
        }
      }
      setState(() {
        imageEndPath = '';
        imageEndPathBase64 = '';
      });
    }
    try {
      final res = await myApi.lumaGenerateVideo(payload, isSelf: isSelf);
      if (res.data is String) {
        res.data = jsonDecode(res.data);
      }
      if (res.statusCode == (isSelf ? 201 : 200)) {
        dismissHint();
        setState(() {
          _videoContentTextFieldController.text = '';
        });
        Map<String, dynamic> data = {};
        if (res.data is List && isSelf) {
          if (res.data.isNotEmpty) {
            data = res.data[0];
          }
        } else {
          data = res.data;
        }
        var videoData = VideoListData(data['id'],
            prompt: data['prompt'],
            state: data['state'],
            createAt: data['created_at'] ?? getCurrentTimestamp(format: 'yyyy-MM-dd HH:mm:ss'),
            isSelf: isSelf,
            severId: data['server_id'] ?? '');
        gridViewKey.currentState?.addItem(videoData);
        setState(() {
          isFirstPageNoData = false;
        });
        Map<String, dynamic> job = {data['id']: _videoContentTextFieldController.text, 'videoData': videoData};
        createTaskQueue(job);
        showHint('视频生成任务已提交，请注意查看视频生成状态。', showType: 2);
        await storage.write('videosNum', canUseNum - 1);
        var settings = await Config.loadSettings();
        String userId = settings['user_id'] ?? '';
        Map<String, dynamic> uploadVideoData = {
          'user_id': userId,
          'video_id': videoData.videoId,
          'created_video_at': videoData.createAt,
          'is_self': videoData.isSelf,
          'prompt': videoData.prompt,
          'state': videoData.state,
          'server_id': videoData.severId,
          'video': videoData.video
        };
        await SupabaseHelper().insert('videos', uploadVideoData);
      } else {
        String msg = '创建视频失败，请稍后重试';
        if (res.statusCode == 429) {
          msg = '达到账号今日的最大可绘制数量，请明日再试';
        }
        showHint(msg);
      }
    } catch (e) {
      showHint('创建视频失败，请稍后重试', showType: 3);
      commonPrint(e);
    } finally {
      dismissHint();
    }
  }

  Future<void> _onPlayClick(VideoListData data) async {
    final settings = context.read<ChangeSettings>();
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomDialog(
            maxWidth: 900,
            title: data.prompt,
            singleLineTitle: true,
            contentBackgroundColor: settings.getBackgroundColor(),
            titleColor: settings.getForegroundColor(),
            content: VideoPlayerView(videoUrl: data.video?['upload_video_url']),
          );
        },
      );
    }
  }

  //选择图片
  Future<void> _selectPic({bool isEnd = false}) async {
    FilePickerResult? result =
        await FilePickerManager().pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'png', 'jpeg']);
    if (result != null) {
      if (isEnd) {
        String path = result.files.single.path!;
        String base64Path = await imageToBase64(path);
        setState(() {
          imageEndPath = path;
          imageEndPathBase64 = base64Path;
        });
      } else {
        String path = result.files.single.path!;
        String base64Path = await imageToBase64(path);
        setState(() {
          imagePath = path;
          imagePathBase64 = base64Path;
        });
      }
    }
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

  Future<void> _dealJobQueue(String videoId, String prompt) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    int canUseNum = storage.read('videosNum') ?? 0;
    try {
      while (true) {
        await Future.delayed(const Duration(seconds: 5));
        VideoListData videoListData = VideoListData(videoId, prompt: prompt);
        for (int i = 0; i < videosList.length; i++) {
          var videoData = videosList[i];
          if (videoData.videoId == videoId) {
            videoListData = videoData;
            break;
          }
        }
        try {
          final res = await myApi.lumaGetVideo(videoListData);
          if (res.data is String) {
            res.data = jsonDecode(res.data);
          }
          commonPrint(res.data);
          if (res.data['state'] == 'completed') {
            videoListData.video = res.data['video'];
            int index = 0;
            for (int i = 0; i < videosList.length; i++) {
              var video = videosList[i];
              if (video.videoId == videoId) {
                index = i;
                setState(() {
                  videosList[i] = videoListData;
                });
                break;
              }
            }
            String videoUrl = res.data['video']['download_url'];
            Map<String, dynamic>? thumbnailData = res.data['thumbnail'] ?? {};
            String thumbnailUrl = thumbnailData?['url'] ?? '';
            if (thumbnailUrl != '') {
              videoListData.video?['thumbnail'] = thumbnailUrl;
              videoListData.video?['upload_video_url'] = videoUrl;
              var settings = await Config.loadSettings();
              String userId = settings['user_id'] ?? '';
              Map<String, dynamic> uploadVideoData = {
                'user_id': userId,
                'video_id': videoListData.videoId,
                'created_video_at': res.data['created_at'],
                'is_self': videoListData.isSelf,
                'prompt': videoListData.prompt,
                'state': res.data['state'],
                'server_id': videoListData.severId,
                'video': videoListData.video
              };
              await SupabaseHelper().update('videos', uploadVideoData, updateMatchInfo: {'user_id': userId, 'video_id': videoId});
              gridViewKey.currentState?.refreshItem(index, videoListData);
              final response = await SupabaseHelper()
                  .runRPC('consume_user_quota', {'p_user_id': userId, 'p_quota_type': 'ai_video', 'p_amount': 1});
              if (response['code'] == 200) {
                commonPrint('消耗图片绘制额度成功');
              } else {
                commonPrint('消耗图片绘制额度失败,原因是${response['message']}');
              }
              break;
            } else {
              //这里尝试下载下来然后获取封面
              var thumbnailPath = '';
              var currentTime = getCurrentTimestamp();
              String saveVideoPath ='${settings['image_save_path']}${Platform.pathSeparator}tempVideos${Platform.pathSeparator}$currentTime.mp4';
              await myApi.downloadSth(videoUrl, saveVideoPath, onReceiveProgress: (received, total) {});
              double? videoWidth = 1360;
              double? videoHeight = 752;
              var plugin = FcNativeVideoThumbnail();
              String destFile ='${settings['image_save_path']}${Platform.pathSeparator}tempVideos${Platform.pathSeparator}$currentTime.jpg';
              try {
                final thumbnailGenerated = await plugin.getVideoThumbnail(
                    srcFile: saveVideoPath,
                    destFile: destFile,
                    width: videoWidth.toInt(),
                    height: videoHeight.toInt(),
                    // keepAspectRatio: true,
                    format: 'jpeg',
                    quality: 90);
                if (thumbnailGenerated) {
                  thumbnailPath = destFile;
                }
                if (thumbnailPath != '') {
                  File file = File(thumbnailPath);
                  File videoFile = File(saveVideoPath);
                  videoListData.video?['thumbnail'] = await uploadFileToALiOss(thumbnailPath, '', file, fileType: 'jpg');
                  //上传视频文件到阿里云
                  videoListData.video?['upload_video_url'] =
                      await uploadFileToALiOss(saveVideoPath, '', videoFile, fileType: 'mp4');
                  var settings = await Config.loadSettings();
                  String userId = settings['user_id'] ?? '';
                  Map<String, dynamic> uploadVideoData = {
                    'user_id': userId,
                    'video_id': videoListData.videoId,
                    'created_video_at': res.data['created_at'],
                    'is_self': videoListData.isSelf,
                    'prompt': videoListData.prompt,
                    'state': res.data['state'],
                    'server_id': videoListData.severId,
                    'video': videoListData.video
                  };
                  await SupabaseHelper()
                      .update('videos', uploadVideoData, updateMatchInfo: {'user_id': userId, 'video_id': videoId});
                } else {
                  commonPrint('获取视频封面失败');
                }
                gridViewKey.currentState?.refreshItem(index, videoListData);
                break;
              } catch (e) {
                commonPrint('获取视频封面失败，原因是$e');
                break;
              }
            }
          } else if (res.data['state'] == 'failed') {
            if (mounted) {
              showHint('创建视频生成任务失败，请重试....', showType: 3);
              await storage.write('videosNum', canUseNum + 1);
            }
            break;
          } else if (res.data['message'] == 'Not Found') {
            break;
          }
        } catch (e) {
          commonPrint(e);
          await storage.write('videosNum', canUseNum + 1);
          break;
        }
      }
    } catch (e) {
      commonPrint(e);
      await storage.write('videosNum', canUseNum + 1);
    } finally {
      dismissHint();
    }
  }

  Future<void> _onDownload(VideoListData data) async {
    String ct = getCurrentTimestamp();
    String? outputFile = await FilePickerManager().saveFile(
      dialogTitle: '选择视频保存路径',
      fileName: '$ct.mp4',
    );
    if (outputFile != null) {
      await myApi.downloadSth('${data.video?['upload_video_url']}', outputFile, onReceiveProgress: (progress, total) {});
      showHint('下载完成', showType: 2);
    }
  }

  Future<void> _onExtend(VideoListData data) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    int useLumaMode = settings['use_luma_mode'] ?? 0;
    bool isSelf = true;
    if (useLumaMode != 0) {
      isSelf = false;
    }
    if (data.isSelf) {
      //自己账号的视频扩展
      if (!isSelf) {
        showHint('此视频是由自有账号生成的，将尝试使用自有账号进行视频延长，若没有配置将延长失败');
      }
      //TODO 调用视频延长接口 一般不用这个了
      showHint('功能升级中,暂不可用', showType: 4);
    } else {
      //TODO 调用视频延长接口
      showHint('功能升级中,暂不可用', showType: 4);
    }
  }

  Future<void> _onDelete(VideoListData data, int index) async {
    final settings = context.read<ChangeSettings>();
    String videoId = data.videoId;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomDialog(
            title: '删除确认',
            description: '是否删除该视频？',
            titleColor: settings.getForegroundColor(),
            contentBackgroundColor: settings.getBackgroundColor(),
            descColor: settings.getForegroundColor(),
            conformButtonColor: settings.getSelectedBgColor(),
            cancelButtonText: '取消',
            confirmButtonText: '确定',
            onCancel: () {},
            onConfirm: () async {
              gridViewKey.currentState?.removeItem(index);
              if (videosList.isEmpty) {
                _refreshData();
              }
              // //这里应该修改数据库数据定义为删除
              var settings = await Config.loadSettings();
              String userId = settings['user_id'] ?? '';
              await SupabaseHelper()
                  .update('videos', {'is_delete': 1}, updateMatchInfo: {'user_id': userId, 'video_id': videoId});
            },
          );
        });
  }

  @override
  void initState() {
    super.initState();
    myApi = MyApi();
    listenStorage();
    videoView = VideoView(
      key: gridViewKey,
      videoList: videosList,
      onPlayClick: (data) => _onPlayClick(data),
      onDownload: (data) => _onDownload(data),
      onExtend: (data) => _onExtend(data),
      onDelete: (data, index) => _onDelete(data, index),
    );
    // getAllVideos();
  }

  //读取内存的键值对
  void listenStorage() {
    storage.listenKey('is_login', (value) {
      if (value) {
        setState(() {
          isFirstPageNoData = false;
        });
        getAllVideos();
      } else {
        setState(() {
          gridViewKey.currentState?.clearList();
          isFirstPageNoData = true;
        });
      }
    });
  }

  Future<void> getAllVideos({int pageNum = 0, int pageSize = 15}) async {
    var settings = await Config.loadSettings();
    String userId = settings['user_id'] ?? '';
    bool isLogin = settings['is_login'] ?? false;
    if (pageNum == 0) {
      currentDatabaseId = 10000;
    }
    if (isLogin) {
      var videos =
          await SupabaseHelper().query('videos', {'user_id': userId, 'is_delete': 0}, ltName: 'id', ltValue: currentDatabaseId);
      if (videos.length < pageSize) {
        _hasMore = false;
      }
      if (videos.isNotEmpty) {
        for (int i = 0; i < videos.length; i++) {
          var video = videos[i];
          VideoListData videoListData = VideoListData(video['video_id'],
              prompt: video['prompt'],
              state: video['state'],
              severId: video['server_id'],
              createAt: video['created_video_at'] ?? '',
              isSelf: video['is_self'],
              video: video['video']);
          gridViewKey.currentState?.addItem(videoListData, index: pageNum == 0 ? 0 : videosList.length);
        }
        currentDatabaseId = videos.last['id'];
      } else {
        if (pageNum == 0) {
          setState(() {
            isFirstPageNoData = true;
          });
        }
      }
      setState(() {});
      dismissHint();
    }
  }

  @override
  void dispose() {
    super.dispose();
    dismissHint();
    _refreshController.dispose();
  }

  Future _refreshData() async {
    Map settings = await Config.loadSettings();
    bool isLogin = settings['is_login'] ?? false;
    if (!isLogin) {
      showHint('请先登录');
      _refreshController.refreshCompleted();
      _isLoading = false;
      return;
    }
    if (_isLoading) return; // 如果正在加载，直接返回
    _isLoading = true;
    pageNum = 0;
    _hasMore = true;
    gridViewKey.currentState?.clearList();
    currentDatabaseId = 10000;
    _refreshController.resetNoData();
    await getAllVideos();
    _refreshController.refreshCompleted();
    _isLoading = false;
  }

  Future _loadMoreData() async {
    Map settings = await Config.loadSettings();
    bool isLogin = settings['is_login'] ?? false;
    if (!isLogin) {
      showHint('请先登录');
      _refreshController.refreshCompleted();
      return;
    }
    if (_isLoading) return; // 如果正在加载，直接返回
    _isLoading = true;
    if (_hasMore) {
      pageNum++;
      await getAllVideos(pageNum: pageNum);
      _refreshController.loadComplete();
    } else {
      showHint('暂无更多数据');
      _refreshController.loadNoData();
    }
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    final bool isMobile = Platform.isAndroid || Platform.isIOS;
    final children = <Widget>[
      Row(children: [
        SizedBox(
          width: 40,
          height: 40,
          child: InkWell(
            onTap: () {
              _selectPic();
            },
            child: Tooltip(
              message: '上传开始帧图片(可选)',
              child: imagePath == ''
                  ? Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: settings.getSelectedBgColor(),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: SvgPicture.asset(
                  'assets/images/upload_image.svg',
                  semanticsLabel: '上传开始帧图片',
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              )
                  : Stack(
                clipBehavior: Clip.none,
                children: [
                  Image.memory(base64Decode(imagePathBase64), width: 40, height: 40),
                  Positioned(
                    right: -8,
                    top: -8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          imagePath = '';
                          imagePathBase64 = '';
                        });
                      },
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: imagePath != '' || imageEndPath != '',
          child: Row(
            children: [
              const SizedBox(width: 10),
              SizedBox(
                width: 40,
                height: 40,
                child: InkWell(
                  onTap: () {
                    _selectPic(isEnd: true);
                  },
                  child: Tooltip(
                    message: '上传结束帧图片(可选)',
                    child: imageEndPath == ''
                        ? Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: settings.getSelectedBgColor(),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: SvgPicture.asset(
                        'assets/images/upload_image.svg',
                        semanticsLabel: '上传结束帧图片(可选)',
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                    )
                        : Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Image.memory(base64Decode(imageEndPathBase64), width: 40, height: 40),
                        Positioned(
                          right: -8,
                          top: -8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                imageEndPath = '';
                                imageEndPathBase64 = '';
                              });
                            },
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
        const SizedBox(width: 16),
      ]),

      // 根据平台使用不同的TextField容器
      if (isMobile)
        SizedBox(
          width: 260,
          child: TextField(
            style: const TextStyle(color: Colors.yellowAccent),
            controller: _videoContentTextFieldController,
            maxLines: 3,
            minLines: 1,
            decoration: const InputDecoration(
              isDense: true,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white, width: 2.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white, width: 2.0),
              ),
              labelText: '请输入要生成的视频内容',
              labelStyle: TextStyle(color: Colors.white),
            ),
          ),
        )
      else
        Expanded(
          child: TextField(
            style: const TextStyle(color: Colors.yellowAccent),
            controller: _videoContentTextFieldController,
            maxLines: 3,
            minLines: 1,
            decoration: const InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white, width: 2.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white, width: 2.0),
              ),
              labelText: '请输入要生成的视频内容',
              labelStyle: TextStyle(color: Colors.white),
            ),
          ),
        ),

      const SizedBox(width: 10),

      Row(
        children: [
          Checkbox(
            value: expandPrompt,
            onChanged: (bool? value) {
              setState(() {
                expandPrompt = value!;
              });
            },
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
          const SizedBox(width: 2),
          const Tooltip(
            message: '勾选后，会自动优化视频画面描述',
            child: Text(
              '画面描述增强',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),

      if (!isMobile) ...[
        const SizedBox(width: 10),
        ElevatedButton(
          style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(settings.getSelectedBgColor())
          ),
          onPressed: () {
            _createVideo();
          },
          child: const Text(
            '生成视频',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ]
    ];
    return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
            child: Stack(children: [
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
                              enablePullUp: true,
                              enablePullDown: true,
                              onRefresh: _refreshData,
                              onLoading: _loadMoreData,
                              child: ListView(
                                controller: _scrollController,
                                children: [videoView],
                              ),
                            )
                          : const Center(
                              child: Text(
                              '未登录或暂无数据',
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
              Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 16),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (scrollInfo is ScrollEndNotification) {
                        // 当滚动到最左边或最右边时，允许父布局滚动
                        if (scrollInfo.metrics.pixels <= 0 || scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent) {
                          return false; // 允许事件冒泡到父布局
                        }
                      }
                      return true; // 阻止事件冒泡到父布局
                    },
                    child: isMobile
                        ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: Row(children: children),
                    )
                        : Row(children: children)),
                ),
            ],
          )
        ])));
  }
}
