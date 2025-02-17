//随机图片生成界面
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:dio/dio.dart' as dio;
import 'package:extended_image/extended_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tuitu/config/global_params.dart';
import 'package:tuitu/params/foocus_create_image_inputs.dart';
import 'package:tuitu/params/fooocus_translate.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'package:tuitu/utils/my_openai_client.dart';
import 'package:tuitu/utils/supabase_helper.dart';
import 'package:tuitu/widgets/image_region_view.dart';
import 'package:tuitu/widgets/mj_settings_view.dart';
import 'package:tuitu/widgets/stacked_image_viewer.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/change_settings.dart';
import '../config/config.dart';
import '../json_models/deal_result.dart';
import '../json_models/item_model.dart';
import '../net/my_api.dart';
import '../params/prompts.dart';
import '../params/prompts_styles.dart';
import '../utils/file_picker_manager.dart';
import '../widgets/blend_image_option.dart';
import '../widgets/control_net_option.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/floating_action_menu.dart';
import '../widgets/get_image_tags.dart';
import '../widgets/image_show_view.dart';
import '../widgets/redraw_option.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import '../widgets/shorten_prompt_optiion.dart';
import '../widgets/swap_face_view.dart';

class RandomGeneratorView extends StatefulWidget {
  final bool isGallery;

  const RandomGeneratorView({super.key, required this.isGallery});

  @override
  State<StatefulWidget> createState() => _RandomGeneratorViewState();
}

class _RandomGeneratorViewState extends State<RandomGeneratorView> {
  late TextEditingController _textFieldController;
  late TextEditingController _modifyTextFieldController;
  late TextEditingController _picContentTextFieldController;
  late TextEditingController _selfScaleTextFieldController;
  List<ImageItemModel> imageBase64List = [];
  List<String> selectedImageList = [];
  final ScrollController _scrollController = ScrollController();
  late MyApi myApi;
  var isShortenVisibility = false.obs;
  List<Map<String, dynamic>> baseImages = [
    {'input_image': ''},
    {'input_image': ''}
  ];
  late StackedImageViewerController stackedImageViewerController;
  List<List<dynamic>> promptsLists = [
    prompts['camera_perspective_prompts'],
    prompts['person_prompts'],
    prompts['career_prompts'],
    prompts['facial_features_prompts'],
    prompts['light_prompts'],
    prompts['expression_prompts'],
    prompts['hair_prompts'],
    prompts['decoration_prompts'],
    prompts['hat_prompts'],
    prompts['shoes_prompts'],
    prompts['socks_prompts'],
    prompts['gesture_prompt'],
    prompts['sight_prompts'],
    prompts['environment_prompts'],
    prompts['style_prompts'],
    prompts['action_prompts'],
    prompts['actions_prompts'],
    prompts['clothes_prompts'],
    prompts['clothes_prompts2'],
  ];
  List<List<dynamic>> animePromptsLists = [
    prompts['anime_characters_prompts'],
    prompts['camera_perspective_prompts'],
    prompts['person_prompts'],
    prompts['career_prompts'],
    prompts['facial_features_prompts'],
    prompts['light_prompts'],
    prompts['expression_prompts'],
    prompts['hair_prompts'],
    prompts['decoration_prompts'],
    prompts['hat_prompts'],
    prompts['shoes_prompts'],
    prompts['socks_prompts'],
    prompts['gesture_prompt'],
    prompts['sight_prompts'],
    prompts['environment_prompts'],
    prompts['style_prompts'],
    prompts['action_prompts'],
    prompts['actions_prompts'],
    prompts['clothes_prompts'],
    prompts['clothes_prompts2'],
  ];
  final box = GetStorage();
  List<String> loraPrompts = [
    'lora:cuteGirlMix4_v10',
    'lora:koreandolllikenessV20_v20',
    'lora:taiwanDollLikeness_v20',
    'lora:japanesedolllikenessV1_v15'
  ];
  final supabase = Supabase.instance.client;
  List<double> loraWeights = [];
  String combinedLoraPromptsString = '';
  int specialIndex = 0;
  int drawEngine = 0;
  late ChangeSettings changeSettings;
  late ImageView imageView;
  List<int> _selectedIndexes = [];
  var inputImagePath = '';
  var preInputImagePath = '';
  late GlobalKey<ImageViewState> imageViewKey;
  List<MapEntry<String, dynamic>> taskList = [];
  MapEntry<String, dynamic>? currentTask;
  bool isExecuting = false;
  String mjOptions = '';
  String mjBotType = 'MID_JOURNEY';
  int publicImage = 0;
  var cuInputs = """{
  "3": {
    "inputs": {
      "seed": 174345022071993,
      "steps": 30,
      "cfg": 8,
      "sampler_name": "dpmpp_2m_sde",
      "scheduler": "karras",
      "denoise": 1,
      "model": [
        "4",
        0
      ],
      "positive": [
        "24",
        0
      ],
      "negative": [
        "25",
        0
      ],
      "latent_image": [
        "5",
        0
      ]
    },
    "class_type": "KSampler"
  },
  "4": {
    "inputs": {
      "ckpt_name": "animagineXL_v10.safetensors"
    },
    "class_type": "CheckpointLoaderSimple"
  },
  "5": {
    "inputs": {
      "width": 1024,
      "height": 1024,
      "batch_size": 1
    },
    "class_type": "EmptyLatentImage"
  },
  "24": {
    "inputs": {
      "from_translate": "auto",
      "to_translate": "en",
      "text": "一个女孩面部特写和大海背景的双重曝光,动漫风格",
      "clip": [
        "4",
        1
      ]
    },
    "class_type": "TranslateCLIPTextEncodeNode"
  },
  "25": {
    "inputs": {
      "from_translate": "auto",
      "to_translate": "en",
      "text": "低质量，错误的手，丑陋",
      "clip": [
        "4",
        1
      ]
    },
    "class_type": "TranslateCLIPTextEncodeNode"
  },
  "36": {
    "inputs": {
      "filename_prefix": "ComfyUI",
      "images": [
        "37",
        0
      ]
    },
    "class_type": "SaveImage"
  },
  "37": {
    "inputs": {
      "samples": [
        "3",
        0
      ],
      "vae": [
        "4",
        2
      ]
    },
    "class_type": "VAEDecode"
  }
}""";
  String clientId = ""; // 生成一个唯一的客户端ID
  final List<String> _controlTypes = ['All'].obs;
  final List<String> _controlModels = ['无'].obs;
  final List<String> _controlModules = ['无'].obs;
  List<Map<String, dynamic>> controlNetOptions = [];
  String swapFaceImage = "";
  Function? loginListen;
  List<String> referenceImages = ['', '']; //MJ的样式参考图
  List<String> characterImages = ['', '']; //MJ的人物参考图
  Map<String, dynamic> _mjOptions = {};
  bool _hasMore = true;
  var images = [];
  final RefreshController _refreshController = RefreshController(initialRefresh: true);
  int currentDatabaseId = 0;
  int pageNum = 0;
  bool _isLoading = false;
  double posX = -35.0; // 初始位置靠左并隐藏一半
  double posY = 300.0; // 初始Y轴位置
  double buttonSize = 50.0; // 按钮大小
  bool isHovered = false; // 鼠标是否悬停
  bool isFirstPageNoData = false;

  String randomPromptSelection(List<List<dynamic>> promptLists) {
    List<String> selectedPrompts = [];

    // 随机选择 action_prompts 或 actions_prompts 中的一个元素
    List<dynamic> actionAndActions = promptLists.sublist(promptLists.length - 4, promptLists.length - 2);
    List<dynamic> selectedActionList = actionAndActions[Random().nextInt(actionAndActions.length)];
    String selectedAction = "";
    if (selectedActionList[0] is String) {
      selectedAction = selectedActionList[Random().nextInt(selectedActionList.length)];
    } else {
      List<dynamic> selectedList = selectedActionList[Random().nextInt(selectedActionList.length)];
      selectedAction = selectedList[Random().nextInt(selectedList.length)];
    }

    // 随机选择 clothes_prompts 或 clothes_prompts2 中的一个元素
    List<dynamic> clothesAndClothes2 = promptLists.sublist(promptLists.length - 2);
    List<dynamic> selectedClothesList = clothesAndClothes2[Random().nextInt(clothesAndClothes2.length)];
    String selectedClothes = "";
    if (selectedClothesList[0] is String) {
      selectedClothes = selectedClothesList[Random().nextInt(selectedClothesList.length)];
    } else {
      List<dynamic> selectedList = selectedClothesList[Random().nextInt(selectedClothesList.length)];
      selectedClothes = selectedList[Random().nextInt(selectedList.length)];
    }

    // 其他的prompt列表
    List<List<dynamic>> otherPrompts = promptLists.sublist(0, promptLists.length - 4);

    for (var promptList in otherPrompts) {
      if (promptList[0] is List) {
        String combinedPrompts = (promptList as List<List<dynamic>>).map((subList) => subList[Random().nextInt(subList.length)]).join(", ");
        selectedPrompts.add(combinedPrompts);
      } else {
        selectedPrompts.add(promptList[Random().nextInt(promptList.length)]);
      }
    }

    // 将随机选择的 action 和 clothes 添加到结果中
    selectedPrompts.add(selectedAction);
    selectedPrompts.add(selectedClothes);

    return selectedPrompts.join(", ");
  }

  List<double> randomWeights(int numWeights,
      {double minWeight = 0.1, double maxSum = 1.0, int? specialIndex, double? specialMin, double? specialMax}) {
    while (true) {
      List<double> weights = List<double>.generate(
          numWeights - 1, (_) => double.parse((Random().nextDouble() * (maxSum - minWeight * (numWeights - 1)) + minWeight).toStringAsFixed(1)));

      if (specialIndex != null) {
        double specialWeight = double.parse((Random().nextDouble() * (specialMax! - specialMin!) + specialMin).toStringAsFixed(1));
        weights.insert(specialIndex, specialWeight);
      }

      double weightsSum = weights.reduce((a, b) => a + b);
      double lastWeight = double.parse((maxSum - weightsSum).toStringAsFixed(1));

      if (minWeight <= lastWeight && lastWeight <= maxSum) {
        weights.add(lastWeight);
        return weights;
      }
    }
  }

  Map<String, dynamic> parseArgs(String argsStr, [dynamic defaultValue]) {
    var argDict = <String, dynamic>{};
    String? argName;
    var argValues = <dynamic>[];

    if (argsStr != "") {
      for (var arg in argsStr.split(" ")) {
        if (arg.startsWith("--")) {
          if (argName != null) {
            if (argValues.length == 1) {
              argDict[argName] = argValues[0];
            } else if (argValues.length > 1) {
              argDict[argName] = argValues;
            } else {
              argDict[argName] = defaultValue;
            }
          }
          argName = arg.substring(2);
          argValues = [];
        } else {
          if (argName == null) {
            argValues.add(arg);
          } else {
            if (arg.contains(", ")) {
              var values = arg.split(", ").map((value) => value.trim()).toList();
              argValues.addAll(values);
            } else {
              argValues.add(arg);
            }
          }
        }
      }

      if (argName != null) {
        if (argValues.length == 1) {
          argDict[argName] = argValues[0];
        } else if (argValues.length > 1) {
          argDict[argName] = argValues;
        } else {
          argDict[argName] = defaultValue;
        }
      }
    }

    return argDict;
  }

  DealResult dealWithArgs(Map<String, dynamic> parsedArgs) {
    int width = 512;
    int height = 512;
    bool pm = false;
    String negativePrompt = '';
    bool isReal = false;
    bool addRandomPrompts = false;

    if (parsedArgs.isNotEmpty) {
      if (parsedArgs.containsKey('ar')) {
        var arValue = parsedArgs['ar'];
        if (arValue == '1:1') {
          width = 512;
          height = 512;
        } else if (arValue == '3:4') {
          width = 768;
          height = 1024;
        } else if (arValue == '4:3') {
          width = 1024;
          height = 768;
        } else if (arValue == '9:16') {
          width = 576;
          height = 1024;
        } else if (arValue == '16:9') {
          width = 1024;
          height = 576;
        }
      }
      if (parsedArgs.containsKey('pm')) {
        pm = true;
      }
      if (parsedArgs.containsKey('real')) {
        isReal = true;
      }
      if (parsedArgs.containsKey('arp')) {
        addRandomPrompts = true;
      }

      if (parsedArgs.containsKey('np')) {
        negativePrompt = parsedArgs['np'];
        // 去除多个逗号
        negativePrompt = negativePrompt.replaceAll(RegExp(',+'), ', ');
        // 去除多个空格
        negativePrompt = negativePrompt.replaceAll(RegExp(r'\s+'), ' ');
      }
    }

    return DealResult(
      width: width,
      height: height,
      pm: pm,
      negativePrompt: negativePrompt,
      isReal: isReal,
      addRandomPrompts: addRandomPrompts,
    );
  }

  String getPrompts(Map<String, dynamic> defaultPromptDict, String promptKeys) {
    List<String> keys = promptKeys.split('+').map((key) => '${int.parse(key)}.').toList();
    String resultStr = '';

    for (String key in keys) {
      String? dictKey = defaultPromptDict.keys.firstWhere((k) => k.startsWith(key), orElse: () => '');
      if (dictKey.isNotEmpty) {
        resultStr += '${defaultPromptDict[dictKey]}, ';
      }
    }

    resultStr = resultStr.replaceAll(RegExp(r',(?!\s)'), ', ');
    resultStr = resultStr.replaceAll(', , ', ', ');
    List<String> words = resultStr.split(', ');
    List<String> finalWords = words.toSet().toList();
    resultStr = finalWords.join(', ');
    List<String> tags = RegExp(r'<.*?>, ').allMatches(resultStr).map((match) => match.group(0)!).toList();
    resultStr = resultStr.replaceAll(RegExp(r'<.*?>, '), '');
    resultStr += tags.join('');
    return resultStr;
  }

  String moveTagsToEnd(String inputString) {
    // 使用正则表达式找到以<开头和以>结尾的字符串及其后面的逗号
    RegExp pattern = RegExp(r"<[^>]+>, ");
    List<String> tags = pattern.allMatches(inputString).map((m) => m.group(0)!).toList();

    // 检查原始字符串最后面是否有逗号
    bool hasCommaAtEnd = inputString.trimRight().endsWith(",");

    // 将找到的标签部分移除原来的字符串
    String resultString = inputString.replaceAll(pattern, "");

    // 将标签部分添加到整个字符串的末尾
    if (!hasCommaAtEnd) {
      resultString += ", ";
    }
    resultString += " ${tags.join("")}";
    // 去掉最后一个逗号
    resultString = resultString.trim();
    if (resultString.endsWith(",")) {
      resultString = resultString.substring(0, resultString.length - 1);
    }
    // 替换连续空格为一个空格
    resultString = resultString.replaceAll(RegExp(r'\s{2,}'), ' ');
    // 去除逗号前面的空格
    resultString = resultString.replaceAll(RegExp(r'\s+,'), ',');
    return resultString.trim();
  }

  Future<void> createTaskQueue(Map<String, dynamic> taskData) async {
    showHint('请稍后...', showType: 5);
    bool canUse = await checkUser();
    if (!canUse) {
      showHint('账户可能已被管理员禁用，请联系管理员或者稍后重试', showType: 3);
      return;
    }
    void executeTask(MapEntry<String, dynamic> task) async {
      currentTask = task;
      isExecuting = true;
      await _dealJobQueue(currentTask!.key, currentTask!.value, taskData: taskData);
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

  double getImageRadio(String imagePrompt) {
    double ratio = 1 / 1;
    RegExp regExp = RegExp(r'--ar (\d+:\d+)');
    Match? match = regExp.firstMatch(imagePrompt);
    if (match != null) {
      var w = double.parse(match.group(1)!.split(':')[0]);
      var h = double.parse(match.group(1)!.split(':')[1]);
      ratio = w / h;
    }
    return ratio;
  }

  Future<void> _dealJobQueue(String jobId, String prompt, {dynamic taskData}) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    var isSquare = true;
    try {
      double? ratio;
      int canDrawNum = box.read('seniorDrawNum');
      if (!prompt.contains('高档')) {
        if (!prompt.contains('--ar')) {
          ratio = taskData['radio'] ?? 1.0;
        } else {
          ratio = getImageRadio(prompt);
        }
        if (prompt.contains('方形')) {
          ratio = 1.0;
        }
        if (prompt.contains('焦点')) {
          ratio = null;
        }
        await addImageItems(ratio);
      }
      while (true) {
        dio.Response progressResponse = await myApi.selfMjDrawQuery(jobId);
        List<ImageItemModel> tempImages = [];
        List imageData = [];
        if (progressResponse.statusCode == 200) {
          if (progressResponse.data is String) {
            progressResponse.data = jsonDecode(progressResponse.data);
          }
          String? status = progressResponse.data['status'];
          if (status == '' || status == 'NOT_START' || status == 'IN_PROGRESS' || status == 'SUBMITTED' || status == 'MODAL' || status == 'SUCCESS') {
            if (progressResponse.data['progress'] == null) {
              progressResponse.data['progress'] = '0%';
            }
            if (prompt.contains('放大') || prompt.contains('高档') || prompt.contains('重做')) {
              int currentIndex = taskData['index'];
              imageBase64List[currentIndex].drawProgress = progressResponse.data['progress'];
            } else {
              for (int k = 0; k < 4; k++) {
                var imageData = imageBase64List[k];
                imageData.drawProgress = progressResponse.data['progress'];
                imageViewKey.currentState?.refreshImage(k, imageData);
              }
            }
            if (status == 'SUCCESS') {
              if (progressResponse.data['imageUrl'] != null) {
                if (prompt.contains('放大') || prompt.contains('高档') || prompt.contains('重做')) {
                  int currentIndex = taskData['index'];
                  String imageUrl = progressResponse.data['imageUrl'];
                  String useImagePath = await imageUrlToBase64(imageUrl);
                  var img = await getImageFromBase64(useImagePath);
                  var imageWidth = img.width.toDouble();
                  var imageHeight = img.height.toDouble();
                  var imageAspectRatio = imageWidth / imageHeight;
                  if (imageAspectRatio != 1.0) {
                    isSquare = false;
                  }
                  imageBase64List[currentIndex].base64Url = useImagePath;
                  String filePath = '';
                  File file = await base64ToTempFile(useImagePath);
                  if (file.existsSync()) {
                    filePath = file.path;
                  }
                  if (filePath != '') {
                    imageUrl = await uploadFileToALiOss(filePath, imageUrl, file);
                  }
                  imageBase64List[currentIndex].downloaded = false;
                  imageBase64List[currentIndex].isUpScaled = true;
                  imageBase64List[currentIndex].isSquare = isSquare;
                  imageBase64List[currentIndex].isEnlarge = true;
                  //这里重新赋值可操作按钮
                  imageBase64List[currentIndex].buttons = progressResponse.data['buttons'];
                  //这里是放大之后修改任务ID
                  imageBase64List[currentIndex].id = progressResponse.data['id'];
                  imageBase64List[currentIndex].imageUrl = GlobalParams.filesUrl + imageUrl;
                  imageViewKey.currentState?.refreshImage(currentIndex, imageBase64List[currentIndex]);
                  dismissHint();
                  var imageItemModel = imageBase64List[currentIndex];
                  imageItemModel.base64Url = '';
                  var imageInfo = jsonEncode(imageItemModel.toJson());
                  var imageKey = imageItemModel.imageKey!;
                  await SupabaseHelper().update('images', {'info': imageInfo}, updateMatchInfo: {'key': imageKey});
                  String userId = settings['user_id'];
                  await SupabaseHelper().update('user_packages', {'senior_draw': canDrawNum}, updateMatchInfo: {'user_id': userId});
                } else {
                  showHint('图片即将展示，请稍后...', showType: 2);
                  String imageUrl = progressResponse.data['imageUrl'];
                  var finalPrompt = '';
                  if (progressResponse.data['properties'] != null) {
                    finalPrompt = progressResponse.data['properties']['finalPrompt'];
                  } else {
                    finalPrompt = progressResponse.data['promptEn'];
                  }
                  List<String> base64Urls = await splitImage(imageUrl);
                  imageData.clear();
                  for (int i = 0; i < base64Urls.length; i++) {
                    tempImages.clear();
                    var userId = settings['user_id'] ?? '';
                    var createTime = DateTime.now().millisecondsSinceEpoch.toString();
                    String imageUrl = '';
                    String filePath = '';
                    File file = await base64ToTempFile(base64Urls[i]);
                    if (file.existsSync()) {
                      filePath = file.path;
                    }
                    if (filePath != '') {
                      imageUrl = await uploadFileToALiOss(filePath, imageUrl, file);
                    }
                    bool isMJV6 = finalPrompt.contains('--v 6.0');
                    bool isNijiV6 = finalPrompt.contains('--niji 6');
                    String? imageKey = imageBase64List[i].imageKey;
                    if (finalPrompt.contains('--ar')) {
                      ratio = getImageRadio(finalPrompt);
                    }
                    ImageItemModel imageItemModel = ImageItemModel(i, progressResponse.data['id'], true, false, base64Urls[i],
                        progressResponse.data['buttons'], 2, '', false, GlobalParams.filesUrl + imageUrl, false, isMJV6,
                        isSquare: isSquare,
                        isNijiV6: isNijiV6,
                        prompt: finalPrompt,
                        imageKey: imageKey,
                        isPublic: publicImage == 1,
                        imageAspectRatio: ratio,
                        drawProgress: '100%');
                    tempImages.add(imageItemModel);
                    imageViewKey.currentState?.refreshImage(i, imageItemModel);
                    _scrollToTop();
                    imageItemModel.base64Url = '';
                    var imageInfo = jsonEncode(imageItemModel.toJson());
                    Map<String, dynamic> imageMap = {
                      'create_time': createTime,
                      'user_id': userId,
                      'info': imageInfo,
                      'key': imageKey,
                      'is_public': publicImage
                    };
                    imageData.add(imageMap);
                  }
                  for (int i = imageData.length - 1; i >= 0; i--) {
                    var imageMap = imageData[i];
                    await SupabaseHelper().insert('images', imageMap);
                  }
                }
                String userId = settings['user_id'];
                //这里尝试新的逻辑
                final response =
                    await SupabaseHelper().runRPC('consume_user_quota', {'p_user_id': userId, 'p_quota_type': 'fast_drawing', 'p_amount': 1});
                if (response['code'] != 200) {
                  commonPrint('消耗失败,原因是${response['message']}');
                }
                break;
              }
            }
          } else if (status != '') {
            if (prompt.contains('放大') || prompt.contains('高档') || prompt.contains('重做')) {
              int currentIndex = taskData['index'];
              imageBase64List[currentIndex].drawProgress = '100%';
              imageViewKey.currentState?.refreshImage(currentIndex, imageBase64List[currentIndex]);
            } else {
              for (int k = 0; k < 4; k++) {
                imageViewKey.currentState?.deleteCurrent(0);
              }
            }
            showHint('mj绘图失败,原因是${progressResponse.data['failReason']}', showType: 3);
            commonPrint('mj绘图失败0,原因是${progressResponse.data['failReason']}');
            int canDrawNum = box.read('seniorDrawNum');
            box.write('seniorDrawNum', canDrawNum + 1);
            break;
          }
        } else {
          showHint('mj绘图失败,原因是${progressResponse.statusMessage}', showType: 3);
          commonPrint('mj绘图失败1,原因是${progressResponse.statusMessage}');
          int canDrawNum = box.read('seniorDrawNum');
          box.write('seniorDrawNum', canDrawNum + 1);
          if (prompt.contains('放大') || prompt.contains('高档') || prompt.contains('重做')) {
            int currentIndex = taskData['index'];
            imageBase64List[currentIndex].drawProgress = '100%';
            imageViewKey.currentState?.refreshImage(currentIndex, imageBase64List[currentIndex]);
          } else {
            for (int k = 0; k < 4; k++) {
              imageViewKey.currentState?.deleteCurrent(0);
            }
          }
          break;
        }
        dismissHint();
        await Future.delayed(const Duration(seconds: 5));
      }
    } catch (e) {
      showHint('mj绘图失败，原因是$e');
      commonPrint('mj任务队列绘图失败，原因是$e');
      int canDrawNum = box.read('seniorDrawNum');
      box.write('seniorDrawNum', canDrawNum + 1);

      if (prompt.contains('放大') || prompt.contains('高档') || prompt.contains('重做')) {
        int currentIndex = taskData['index'];
        imageBase64List[currentIndex].drawProgress = '100%';
        imageViewKey.currentState?.refreshImage(currentIndex, imageBase64List[currentIndex]);
      } else {
        for (int k = 0; k < 4; k++) {
          imageViewKey.currentState?.deleteCurrent(0);
        }
      }
    }
  }

  Future<void> _generateImage(BuildContext context,
      {bool isUpScaleRepair = false, int imagePosition = 0, bool isOnlyImg2Img = false, inputPrompt = ''}) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    if (!GlobalParams.isFreeVersion) {
      bool isLogin = settings['is_login'] ?? false;
      if (!isLogin) {
        if (context.mounted) {
          showHint('请先登录');
        }
        return;
      }
      showHint('处理中...', showType: 5);
      bool canUse = await checkUser();
      if (!canUse) {
        if (context.mounted) {
          showHint('账户可能已被管理员禁用，请联系管理员或者稍后重试');
        }
        dismissHint();
        return;
      }
      int canDrawNum = box.read('seniorDrawNum');
      if (canDrawNum <= 0) {
        if (context.mounted) {
          showHint('可用绘画次数不足，请购买套餐后再进行绘画');
        }
        dismissHint();
        return;
      }
    }
    Map<String, dynamic> defaultPromptDict = {
      "0.无": promptsStyles['None'],
      "1.基本提示(通用)": promptsStyles['default_prompts'],
      "2.基本提示(通用修手)": promptsStyles['default_prompts_fix_hands'],
      "3.基本提示(增加细节1)": promptsStyles['default_prompts_add_details_1'],
      "4.基本提示(增加细节2)": promptsStyles['default_prompts_add_details_2'],
      "5.基本提示(梦幻童话)": promptsStyles['default_prompts_fairy_tale']
    };
    int? height = settings['height'];
    int? width = settings['width'];
    int? getHeight;
    int? getWidth;
    String useImagePath = '';
    if (isUpScaleRepair && !isOnlyImg2Img) {
      useImagePath = imageBase64List[imagePosition].base64Url;
    }
    if (isOnlyImg2Img) {
      useImagePath = inputImagePath;
    }
    if (isUpScaleRepair || isOnlyImg2Img) {
      ui.Image image = await getImageFromBase64(useImagePath);
      var newImageSize = processDimensions(image.width, image.height);
      getHeight = newImageSize['height'];
      getWidth = newImageSize['width'];
    }
    bool useFaceRestore = settings['restore_face'] ?? false;
    bool useHiresFix = settings['hires_fix'] ?? false;
    bool combinedPositivePrompts = settings['is_compiled_positive_prompts'] ?? false;

    bool useSelfPositivePrompts = settings['use_self_positive_prompts'] ?? false;

    bool useSelfNegativePrompts = settings['use_self_negative_prompts'] ?? false;

    String defaultPositivePromptType = settings['default_positive_prompts_type'].toString();
    String combinedPositivePromptsTypes = settings['compiled_positive_prompts_type'];
    String defaultPositivePrompts = '';
    String defaultNegativePrompts = settings['self_negative_prompts'];
    String sdUrl = settings['sdUrl'] ?? '';
    int? imageNum = int.tryParse(_textFieldController.text);
    String? getClientId = settings['client_id'];
    if (getClientId == null) {
      final String newClientId = const Uuid().v4();
      Map<String, dynamic> saveSettings = {'client_id': newClientId};
      clientId = newClientId;
      await Config.saveSettings(saveSettings);
    } else {
      clientId = settings['client_id'];
    }
    String imageContent = inputPrompt == '' ? _picContentTextFieldController.text : inputPrompt;
    if (isUpScaleRepair) {
      imageNum = 1;
    }
    if (isOnlyImg2Img) {
      imageNum = int.tryParse(_textFieldController.text);
    }
    DealResult result = DealResult(width: width ?? 512, height: height ?? 512, pm: false, negativePrompt: "", isReal: false, addRandomPrompts: false);
    String realImageContent = "";
    if (imageContent != "") {
      int index = imageContent.indexOf("--");
      if (index != -1) {
        String argsStr = imageContent.substring(index, imageContent.length);
        Map<String, dynamic> args = parseArgs(argsStr);
        result = dealWithArgs(args);
        if (!args.containsKey('ar')) {
          result.width = width ?? 512;
          result.height = height ?? 512;
        }
        realImageContent = drawEngine == 0 ? imageContent.substring(0, index) : imageContent;
      } else {
        realImageContent = imageContent;
      }
    }
    if (drawEngine == 0) {
      if (imageNum != null && imageNum > 0) {
        for (int i = 0; i < imageNum; i++) {
          specialIndex = loraPrompts.indexOf('lora:cuteGirlMix4_v10');
          loraWeights = randomWeights(loraPrompts.length, specialIndex: specialIndex, specialMin: 0.4, specialMax: 0.6);
          combinedLoraPromptsString = loraPrompts.asMap().entries.map((entry) {
            return '<${entry.value}:${loraWeights[entry.key]}>';
          }).join(', ');
          Map<String, dynamic> requestBody = {};
          String randomPrompts = '';
          if (!combinedPositivePrompts & !useSelfPositivePrompts) {
            for (int i = 0; i < defaultPromptDict.length; i++) {
              String key = defaultPromptDict.keys.elementAt(i).toString();
              if (key.startsWith(defaultPositivePromptType)) {
                defaultPositivePrompts = defaultPromptDict.values.elementAt(i);
              }
            }
          } else if (combinedPositivePrompts & !useSelfPositivePrompts) {
            defaultPositivePrompts = getPrompts(defaultPromptDict, combinedPositivePromptsTypes);
          } else if (useSelfPositivePrompts) {
            defaultPositivePrompts = settings['self_positive_prompts'];
          }
          if (result.isReal) {
            if (useSelfNegativePrompts & defaultNegativePrompts.isNotEmpty) {
              requestBody['negative_prompt'] = defaultNegativePrompts;
            } else {
              requestBody['negative_prompt'] = prompts['real_person_negative_prompt'];
            }
            randomPrompts = randomPromptSelection(promptsLists);
            defaultPositivePrompts = '${defaultPositivePrompts}mix4, $combinedLoraPromptsString';
          } else {
            if (useSelfNegativePrompts & defaultNegativePrompts.isNotEmpty) {
              requestBody['negative_prompt'] = defaultNegativePrompts;
            } else {
              requestBody['negative_prompt'] = prompts['anime_negative_prompt'];
            }
            randomPrompts = randomPromptSelection(animePromptsLists);
          }
          if (realImageContent == "") {
            requestBody['prompt'] = "$defaultPositivePrompts, $randomPrompts";
          } else {
            if (result.addRandomPrompts) {
              if (imageContent.startsWith("--")) {
                requestBody['prompt'] = "$defaultPositivePrompts, $randomPrompts";
              } else {
                requestBody['prompt'] = "$defaultPositivePrompts, $realImageContent, $randomPrompts";
              }
            } else {
              if (imageContent.startsWith("--")) {
                requestBody['prompt'] = "$defaultPositivePrompts, ";
              } else {
                requestBody['prompt'] = "$defaultPositivePrompts, $realImageContent";
              }
            }
          }
          requestBody['restore_faces'] = useFaceRestore;
          requestBody['enable_hr'] = useHiresFix;
          requestBody['sampler_name'] = settings['Sampler'];
          if (useHiresFix) {
            requestBody['hr_scale'] = settings['hires_fix_multiple'];
            requestBody['hr_upscaler'] = settings['hires_fix_sampler'];
            requestBody['hr_second_pass_steps'] = settings['hires_fix_steps'];
            requestBody['denoising_strength'] = settings['hires_fix_amplitude'];
          }
          Map<String, dynamic> aDetailerMap = {"args": []};
          Map<String, dynamic> controlNetMap = {"args": []};
          Map<String, dynamic> alwaysOnScripts = {};
          List<Map<String, dynamic>> aDetailerMapCopies = List<Map<String, dynamic>>.from(settings['adetail_options'] ?? []);
          for (var element in aDetailerMapCopies) {
            var elementCopy = deepCopy(element);
            if (elementCopy['is_enable']) {
              elementCopy.remove('is_enable');
              if (elementCopy['ad_controlnet_model'] == '无') {
                elementCopy['ad_controlnet_model'] = 'None';
              }
              if (elementCopy['ad_controlnet_module'] == null) {
                elementCopy['ad_controlnet_module'] = 'None';
              }
              aDetailerMap['args'].add(elementCopy);
            }
          }
          bool? useADetail = settings['use_adetail'];
          if (useADetail != null && useADetail && aDetailerMapCopies.isNotEmpty) {
            alwaysOnScripts['ADetailer'] = aDetailerMap;
          }
          if (controlNetOptions.isNotEmpty) {
            controlNetMap['args'].clear();
            for (var controlNetOption in controlNetOptions) {
              Map<String, dynamic> controlNetOptionCopy = deepCopy(controlNetOption);
              if (controlNetOptionCopy['is_enable']) {
                controlNetOptionCopy.remove('is_enable');
                if (controlNetOptionCopy['module'] == '无') {
                  controlNetOptionCopy['module'] = 'none';
                }
                controlNetMap['args'].add(controlNetOptionCopy);
              }
            }
            alwaysOnScripts['controlnet'] = controlNetMap;
          }
          requestBody['alwayson_scripts'] = alwaysOnScripts;
          requestBody['steps'] = settings['steps'];
          requestBody['width'] = !isUpScaleRepair ? result.width : (getWidth ?? 512);
          requestBody['height'] = !isUpScaleRepair ? result.height : (getHeight ?? 512);
          requestBody['cfg_scale'] = 7;
          String prompt = '${moveTagsToEnd(requestBody['prompt'])} ${settings['loras']}';
          if (isUpScaleRepair) {
            requestBody['init_images'] = [useImagePath];
            requestBody['denoising_strength'] = settings['redraw_range'];
            Uint8List decodedBytes = base64Decode(useImagePath);
            img.Image image = img.decodeImage(Uint8List.fromList(decodedBytes))!;
            var imageInfo = image.textData;
            try {
              if (imageInfo != null) {
                var paramsStartIndex = imageInfo['parameters']!.indexOf('Steps');
                var promptsEndIndex = imageInfo['parameters']!.indexOf('Negative prompt');
                if (promptsEndIndex != -1) {
                  prompt = imageInfo['parameters']!.substring(0, promptsEndIndex);
                }
                if (paramsStartIndex != -1) {
                  var imageInfoMap = parseStringToMap(imageInfo['parameters']!.substring(paramsStartIndex, imageInfo['parameters']!.length));
                  var imageSeed = imageInfoMap['Seed'];
                  if (imageSeed != null) {
                    requestBody['seed'] = imageSeed;
                  } else {
                    requestBody['seed'] = -1;
                  }
                }
              }
            } catch (e) {
              commonPrint('获取图片信息异常$e');
            }
          }
          requestBody['prompt'] = prompt;
          dio.Response? response;
          try {
            showHint(isUpScaleRepair ? '图生图重绘中...' : '第${imageBase64List.length + 1}张图片生成中...', showType: 5);
            response = await (isUpScaleRepair ? myApi.sdImage2Image(sdUrl, requestBody) : myApi.sdText2Image(sdUrl, requestBody));
            if (response.statusCode == 200) {
              dismissHint();
              if (response.data['images'] is List<dynamic>) {
                for (int i = 0; i < response.data['images'].length; i++) {
                  if (isUpScaleRepair && !isOnlyImg2Img) {
                    String imageUrl = '';
                    String filePath = '';
                    File file = await base64ToTempFile(response.data['images'][i]);
                    if (file.existsSync()) {
                      filePath = file.path;
                    }
                    if (filePath != '') {
                      imageUrl = await uploadFileToALiOss(filePath, imageUrl, file);
                    }
                    imageBase64List[imagePosition].imageUrl = imageUrl;
                    imageViewKey.currentState?.refreshImage(imagePosition, imageBase64List[imagePosition]);
                    String imageKey = imageBase64List[imagePosition].imageKey!;
                    var imageInfo = jsonEncode(imageBase64List[imagePosition].toJson());
                    await SupabaseHelper().update('info', {'info': imageInfo}, updateMatchInfo: {'key': imageKey});
                  } else {
                    String imageUrl = '';
                    String filePath = '';
                    File file = await base64ToTempFile(response.data['images'][i]);
                    if (file.existsSync()) {
                      filePath = file.path;
                    }
                    if (filePath != '') {
                      imageUrl = await uploadFileToALiOss(filePath, imageUrl, file);
                    }
                    var userId = settings['user_id'] ?? '';
                    var createTime = DateTime.now().millisecondsSinceEpoch.toString();
                    ImageItemModel imageItemModel = ImageItemModel(
                        0, "0", false, false, response.data['images'][i], [], 0, '', false, GlobalParams.filesUrl + imageUrl, false, false,
                        isNijiV6: false,
                        prompt: requestBody['prompt'],
                        imageKey: '$userId-$createTime',
                        drawProgress: '100%',
                        imageAspectRatio: (requestBody['width'] / requestBody['height']).toDouble(),
                        isPublic: publicImage == 1);
                    List<ImageItemModel> imageList = [];
                    imageList.add(imageItemModel);
                    imageViewKey.currentState?.insertImageData(imageList, 0, 0, 0);
                    imageItemModel.base64Url = '';
                    var imageInfo = jsonEncode(imageItemModel.toJson());
                    Map<String, dynamic> imageMap = {
                      'create_time': createTime,
                      'user_id': userId,
                      'info': imageInfo,
                      'is_public': publicImage,
                      'key': '$userId-$createTime',
                    };
                    await SupabaseHelper().insert('images', imageMap);
                    // imageBase64List.add(imageItemModel);
                  }
                }
              }
            } else {
              dismissHint();
              if (context.mounted) {
                showHint('绘图失败，SD异常，请在设置页面查看SD配置。', showTime: 3, showPosition: 2, showType: 3);
              }
            }
            // setState(() {
            _scrollToTop();
            // });
          } catch (error) {
            dismissHint();
            commonPrint(error);
            if (context.mounted) {
              showHint('绘图失败，SD异常，请在设置页面查看SD配置。', showTime: 3, showPosition: 2, showType: 3);
            }
          }
        }
        if (imageBase64List.isNotEmpty) {
          Map<String, dynamic> settings = {
            'already_random_generate_image': true,
          };
          await Config.saveSettings(settings);
        }

        if (imageBase64List.length == imageNum) {
          dismissHint();
          if (context.mounted) {
            showHint('$imageNum张图片已全部绘制完毕，希望你能喜欢', showTime: 3, showPosition: 2, showType: 2);
          }
        }
      }
    } else {
      Map<String, dynamic> requestBody = {};
      String randomPrompts = '';
      if (!combinedPositivePrompts & !useSelfPositivePrompts) {
        for (int i = 0; i < defaultPromptDict.length; i++) {
          String key = defaultPromptDict.keys.elementAt(i).toString();
          if (key.startsWith(defaultPositivePromptType)) {
            defaultPositivePrompts = defaultPromptDict.values.elementAt(i);
          }
        }
      } else if (combinedPositivePrompts & !useSelfPositivePrompts) {
        defaultPositivePrompts = getPrompts(defaultPromptDict, combinedPositivePromptsTypes);
      } else if (useSelfPositivePrompts) {
        defaultPositivePrompts = settings['self_positive_prompts'];
      }
      if (result.isReal) {
        randomPrompts = randomPromptSelection(promptsLists);
        defaultPositivePrompts = '${defaultPositivePrompts}mix4, $combinedLoraPromptsString';
      } else {
        randomPrompts = randomPromptSelection(animePromptsLists);
      }
      if (realImageContent == "") {
        // requestBody['prompt'] = "$defaultPositivePrompts, $randomPrompts";
        requestBody['prompt'] = randomPrompts;
      } else {
        if (result.addRandomPrompts) {
          if (imageContent.startsWith("--")) {
            // requestBody['prompt'] = "$defaultPositivePrompts, $randomPrompts";
            requestBody['prompt'] = randomPrompts;
          } else {
            // requestBody['prompt'] = "$defaultPositivePrompts, $realImageContent, $randomPrompts";
            requestBody['prompt'] = "$realImageContent, $randomPrompts";
          }
        } else {
          if (imageContent.startsWith("--")) {
            // requestBody['prompt'] = "$defaultPositivePrompts, ";
            requestBody['prompt'] = "";
          } else {
            // requestBody['prompt'] = "$defaultPositivePrompts, $realImageContent";
            requestBody['prompt'] = realImageContent;
          }
        }
      }
      dio.Response response;
      if (drawEngine == 1) {
        requestBody['prompt'] = requestBody['prompt'] + mjOptions;
        int lastImageNum = imageBase64List.length;
        int drawSpeedType = settings['MJDrawSpeedType'] ?? 0;
        String token = '';
        switch (drawSpeedType) {
          case 0:
            token = settings['mj_slow_speed_token'] ?? '';
            break;
          case 1:
            token = settings['mj_fast_speed_token'] ?? '';
            break;
          case 2:
            token = settings['mj_extra_speed_token'] ?? '';
            break;
          default:
            break;
        }
        //使用知数云mj绘图
        requestBody['action'] = 'generate';
        try {
          showHint('MJ图片任务提交中...', showType: 5);
          response = await myApi.mjDraw(drawSpeedType, token, requestBody);
          if (response.statusCode == 200) {
            response.data.stream.listen((data) async {
              final decodedData = utf8.decode(data);
              final jsonData = json.decode(decodedData);
              int progress = jsonData['progress'];
              if (progress == 100) {
                showHint('图片即将展示，请稍后...', showType: 2);
                List<String> base64Urls = await splitImage(jsonData['image_url']);
                List<ImageItemModel> tempImages = [];
                for (int i = 0; i < base64Urls.length; i++) {
                  String imageUrl = '';
                  String filePath = '';
                  File file = await base64ToTempFile(base64Urls[i]);
                  if (file.existsSync()) {
                    filePath = file.path;
                  }
                  if (filePath != '') {
                    imageUrl = await uploadFileToALiOss(filePath, imageUrl, file);
                  }
                  ImageItemModel imageItemModel = ImageItemModel(i, jsonData['image_id'], true, false, base64Urls[i], jsonData['actions'], 1, '',
                      false, GlobalParams.filesUrl + imageUrl, false, false,
                      prompt: requestBody['prompt']);
                  tempImages.add(imageItemModel);
                }
                int currentImageNum = imageBase64List.length;
                if (currentImageNum != lastImageNum && currentImageNum >= 4) {
                  imageBase64List.removeRange(imageBase64List.length - 4, imageBase64List.length);
                }
                // imageBase64List.addAll(tempImages);
                imageViewKey.currentState?.insertImageData(tempImages, lastImageNum, currentImageNum, 1);
                _scrollToTop();
              }
            });
          } else {
            if (context.mounted) {
              showHint('mj绘图失败,原因是${response.statusMessage}', showType: 3);
              commonPrint('mj绘图失败1,原因是${response.statusMessage}');
            }
          }
        } catch (e) {
          if (context.mounted) {
            showHint('mj绘图失败,原因是$e', showType: 3);
            commonPrint('mj绘图失败2,原因是$e');
          }
        } finally {
          dismissHint();
        }
      } else if (drawEngine == 2) {
        requestBody['accountFilter'] = {};
        requestBody['botType'] = mjBotType;

        //自有账号mj绘图，需要先创建任务
        Map<String, dynamic> currentSettings = await Config.loadSettings();
        bool isJoinedAccountPool = currentSettings['join_account_pool'] ?? true;
        String mjAccountId = currentSettings['mj_channel_id'] ?? '';
        bool isHaveMjAccount = currentSettings['have_mj_account'] ?? true;
        bool remixAutoSubmit = currentSettings['remix_auto_submit'] ?? true;
        if (selectedImageList.isNotEmpty) {
          if (selectedImageList.first != '') {
            requestBody['base64Array'] = selectedImageList;
          } else {
            inputImagePath = '';
            preInputImagePath = '';
          }
        } else {
          inputImagePath = '';
          preInputImagePath = '';
        }
        if (!isJoinedAccountPool) {
          requestBody['accountFilter']['instanceId'] = mjAccountId;
        }
        if (remixAutoSubmit) {
          requestBody['accountFilter']['remixAutoConsidered'] = remixAutoSubmit;
        }
        if (!isHaveMjAccount) {
          if (context.mounted) {
            showHint('您未配置账号，无法使用自有账号进行绘图', showType: 3);
          }
          dismissHint();
        } else {
          int canDrawNum = box.read('seniorDrawNum');
          try {
            showHint('MJ图片任务提交中...', showType: 5);
            String referenceImageUrl1 = '';
            String referenceImageUrl2 = '';
            String characterImageUrl1 = '';
            String characterImageUrl2 = '';
            if (referenceImages[0].isNotEmpty) {
              String extension = getFileExtension(referenceImages[0]);
              referenceImageUrl1 = GlobalParams.filesUrl +
                  await uploadFileToALiOss(referenceImages[0], 'imageUrl', File(referenceImages[0]), fileType: extension, needDelete: false);
              if (referenceImages[1].isNotEmpty) {
                extension = getFileExtension(referenceImages[1]);
                referenceImageUrl2 = GlobalParams.filesUrl +
                    await uploadFileToALiOss(referenceImages[1], 'imageUrl', File(referenceImages[1]), fileType: extension, needDelete: false);
              }
              mjOptions += ' --sref $referenceImageUrl1 $referenceImageUrl2';
            }
            if (characterImages[0].isNotEmpty) {
              String extension = getFileExtension(characterImages[0]);
              characterImageUrl1 = GlobalParams.filesUrl +
                  await uploadFileToALiOss(characterImages[0], 'imageUrl', File(characterImages[0]), fileType: extension, needDelete: false);
              if (characterImages[1].isNotEmpty) {
                extension = getFileExtension(characterImages[1]);
                characterImageUrl2 = GlobalParams.filesUrl +
                    await uploadFileToALiOss(characterImages[1], 'imageUrl', File(characterImages[1]), fileType: extension, needDelete: false);
              }
              mjOptions += ' --cref $characterImageUrl1 $characterImageUrl2';
            }
            requestBody['prompt'] = requestBody['prompt'] + mjOptions;
            response = await myApi.selfMjDrawCreate(requestBody, drawSpeedType: 1);
            if (response.statusCode == 200) {
              Map<String, dynamic> data;
              if (response.data is String) {
                data = jsonDecode(response.data);
              } else {
                data = response.data;
              }
              int code = data['code'] ?? -1;
              if (code == 1) {
                if (context.mounted) {
                  showHint('MJ图片任务提交成功');
                }
                box.write('seniorDrawNum', canDrawNum - 1);
                String result = data['result'];
                Map<String, dynamic> job = {result: '${requestBody['prompt']}'};
                //如果不需要保存设置参数就清空
                if (_mjOptions['retainParameters'] == null || _mjOptions['retainParameters'] == false) {
                  _mjOptions = {};
                }
                createTaskQueue(job);
              } else {
                if (context.mounted) {
                  showHint('自有mj绘图失败,原因是${data['description']}', showType: 3);
                  commonPrint('自有mj绘图失败4,原因是${data['description']}');
                }
              }
            } else {
              if (context.mounted) {
                showHint('自有mj绘图失败,原因是${response.statusMessage}', showType: 3);
                commonPrint('自有mj绘图失败1,原因是${response.statusMessage}');
              }
            }
          } catch (e) {
            if (context.mounted) {
              showHint('自有mj绘图失败,原因是$e', showType: 3);
              commonPrint('自有mj绘图失败2,原因是$e');
            }
          } finally {
            dismissHint();
          }
        }
      } else if (drawEngine == 3) {
        if (imageNum != null && imageNum > 0) {
          for (int i = 0; i < imageNum; i++) {
            Map<String, dynamic> requestBody = {};
            String randomPrompts = '';
            if (!combinedPositivePrompts & !useSelfPositivePrompts) {
              for (int i = 0; i < defaultPromptDict.length; i++) {
                String key = defaultPromptDict.keys.elementAt(i).toString();
                if (key.startsWith(defaultPositivePromptType)) {
                  defaultPositivePrompts = defaultPromptDict.values.elementAt(i);
                }
              }
            } else if (combinedPositivePrompts & !useSelfPositivePrompts) {
              defaultPositivePrompts = getPrompts(defaultPromptDict, combinedPositivePromptsTypes);
            } else if (useSelfPositivePrompts) {
              defaultPositivePrompts = settings['self_positive_prompts'];
            }
            if (result.isReal) {
              randomPrompts = randomPromptSelection(promptsLists);
              defaultPositivePrompts = '${defaultPositivePrompts}mix4, $combinedLoraPromptsString';
            } else {
              randomPrompts = randomPromptSelection(animePromptsLists);
            }
            if (realImageContent == "") {
              requestBody['prompt'] = "$defaultPositivePrompts, $randomPrompts";
            } else {
              if (result.addRandomPrompts) {
                if (imageContent.startsWith("--")) {
                  requestBody['prompt'] = "$defaultPositivePrompts, $randomPrompts";
                } else {
                  requestBody['prompt'] = "$defaultPositivePrompts, $realImageContent, $randomPrompts";
                }
              } else {
                if (imageContent.startsWith("--")) {
                  requestBody['prompt'] = "$defaultPositivePrompts, ";
                } else {
                  requestBody['prompt'] = "$defaultPositivePrompts, $realImageContent";
                }
              }
            }
            showHint('ComfyUI绘制当前第${i + 1}张图片中...', showType: 5);
            try {
              Map<String, dynamic> savedSettings = await Config.loadSettings();
              String selectedCuWorkflow = savedSettings['select_cu_workflow'] ?? '';
              String folderPath = savedSettings['image_save_path'] ?? '';
              var seed = 0;
              if (selectedCuWorkflow != '') {
                String path = '$folderPath${Platform.pathSeparator}cu_workflows${Platform.pathSeparator}$selectedCuWorkflow';
                final prompt = await getFileContentByPath(path);
                bool found = false;
                for (var key in prompt.keys) {
                  if ((prompt[key]['class_type'] == 'TranslateCLIPTextEncodeNode' || prompt[key]['class_type'] == 'CLIPTextEncode') && !found) {
                    prompt[key]['inputs']['text'] = requestBody['prompt'];
                    found = true;
                  }
                  if (prompt[key]['class_type'] == 'KSampler') {
                    seed = Random().nextInt(4294967296);
                    prompt[key]['inputs']['seed'] = seed;
                  }
                }
                final images = await cuGetImages(prompt);

                images.forEach((key, value) async {
                  String imageUrl = '';
                  String filePath = '';
                  String base64Url = '';
                  var userId = settings['user_id'] ?? '';
                  var createTime = DateTime.now().millisecondsSinceEpoch.toString();
                  File file = await bytesToTempFile(value[0]);
                  if (file.existsSync()) {
                    filePath = file.path;
                  }

                  if (filePath != '') {
                    imageUrl = await uploadFileToALiOss(filePath, imageUrl, file);
                  }
                  base64Url = await imageUrlToBase64(GlobalParams.filesUrl + imageUrl);
                  ImageItemModel imageItemModel = ImageItemModel(
                      0, "0", false, false, base64Url, [], 3, '$seed', false, GlobalParams.filesUrl + imageUrl, false, false,
                      prompt: requestBody['prompt'], imageKey: '$userId-$createTime', isPublic: publicImage == 1);
                  List<ImageItemModel> imageList = [];
                  imageList.add(imageItemModel);
                  imageViewKey.currentState?.insertImageData(imageList, 0, 0, 0);
                  _scrollToTop();
                  imageItemModel.base64Url = '';
                  var imageInfo = jsonEncode(imageItemModel.toJson());
                  Map<String, dynamic> imageData = {'create_time': createTime, 'user_id': userId, 'info': imageInfo, 'is_public': publicImage};
                  await SupabaseHelper().insert('images', imageData);
                });
              } else {
                if (context.mounted) {
                  showHint('ComfyUI工作流未选择或不可用，请在设置中配置');
                }
              }
            } catch (e) {
              commonPrint('返回的数据2为$e');
            } finally {
              dismissHint();
            }
          }
        }
      } else if (drawEngine == 4) {
        if (imageNum != null && imageNum > 0) {
          for (int i = 0; i < imageNum; i++) {
            Map<String, dynamic> requestBody = {};
            String randomPrompts = '';
            if (!combinedPositivePrompts & !useSelfPositivePrompts) {
              for (int i = 0; i < defaultPromptDict.length; i++) {
                String key = defaultPromptDict.keys.elementAt(i).toString();
                if (key.startsWith(defaultPositivePromptType)) {
                  defaultPositivePrompts = defaultPromptDict.values.elementAt(i);
                }
              }
            } else if (combinedPositivePrompts & !useSelfPositivePrompts) {
              defaultPositivePrompts = getPrompts(defaultPromptDict, combinedPositivePromptsTypes);
            } else if (useSelfPositivePrompts) {
              defaultPositivePrompts = settings['self_positive_prompts'];
            }
            if (result.isReal) {
              randomPrompts = randomPromptSelection(promptsLists);
              defaultPositivePrompts = '${defaultPositivePrompts}mix4, $combinedLoraPromptsString';
            } else {
              randomPrompts = randomPromptSelection(animePromptsLists);
            }
            if (realImageContent == "") {
              requestBody['prompt'] = "$defaultPositivePrompts, $randomPrompts";
            } else {
              if (result.addRandomPrompts) {
                if (imageContent.startsWith("--")) {
                  requestBody['prompt'] = "$defaultPositivePrompts, $randomPrompts";
                } else {
                  requestBody['prompt'] = "$realImageContent, $randomPrompts";
                }
              } else {
                if (imageContent.startsWith("--")) {
                  requestBody['prompt'] = "$defaultPositivePrompts, ";
                } else {
                  requestBody['prompt'] = realImageContent;
                }
              }
            }
            showHint('Fooocus绘制当前第${i + 1}张图片中...', showType: 5);
            String styles = settings['fs_selected_styles'] ?? "Fooocus V2提示词智能扩展,Fooocus-杰作,Fooocus-优化增强";
            List<String> styleList = styles.split(',');
            List<String> styleListEn = [];
            for (var element in styleList) {
              fooocusTranslate.forEach((key, value) {
                if (value == element) {
                  styleListEn.add(key);
                }
              });
            }
            fooocusCreateImageInputs['style_selections'] = styleListEn;
            fooocusCreateImageInputs['prompt'] = requestBody['prompt'];
            fooocusCreateImageInputs['base_model_name'] = settings['fs_base_model'] ?? 'animagineXL_v20.safetensors';
            fooocusCreateImageInputs['require_base64'] = true;
            var fsPicHeight = settings['fs_height'] ?? 1024;
            var fsPicWidth = settings['fs_width'] ?? 1024;
            fooocusCreateImageInputs['aspect_ratios_selection'] = '$fsPicWidth*$fsPicHeight';
            var performanceSelection = settings['fs_performance_selection'] ?? '速度';
            fooocusCreateImageInputs['performance_selection'] = performanceSelection == '速度' ? 'Speed' : 'Quality';
            try {
              dio.Response response = await myApi.fsCreateImages(fooocusCreateImageInputs);
              if (response.statusCode == 200) {
                if (response.data[0]['finish_reason'] == "SUCCESS") {
                  String imageUrl = '';
                  String filePath = '';
                  String base64Url = '';
                  var userId = settings['user_id'] ?? '';
                  var createTime = DateTime.now().millisecondsSinceEpoch.toString();
                  File file = await base64ToTempFile(response.data[0]['base64']);
                  if (file.existsSync()) {
                    filePath = file.path;
                  }
                  if (filePath != '') {
                    imageUrl = await uploadFileToALiOss(filePath, imageUrl, file);
                  }
                  base64Url = await imageUrlToBase64(GlobalParams.filesUrl + imageUrl);
                  ImageItemModel imageItemModel = ImageItemModel(
                      0, "0", false, false, base64Url, [], 4, '${response.data[0]['seed']}', false, GlobalParams.filesUrl + imageUrl, false, false,
                      prompt: requestBody['prompt'], imageKey: '$userId-$createTime', isPublic: publicImage == 1);
                  List<ImageItemModel> imageList = [];
                  imageList.add(imageItemModel);
                  imageViewKey.currentState?.insertImageData(imageList, 0, 0, 0);
                  _scrollToTop();
                  imageItemModel.base64Url = '';
                  var imageInfo = jsonEncode(imageItemModel.toJson());
                  Map<String, dynamic> imageData = {'create_time': createTime, 'user_id': userId, 'info': imageInfo, 'is_public': publicImage};
                  await SupabaseHelper().insert('images', imageData);
                } else {
                  if (context.mounted) {
                    showHint('Fooocus绘图失败，原因是${response.data[0]['finish_reason']}');
                  }
                }
              } else {
                if (context.mounted) {
                  showHint('Fooocus绘图失败，原因是${response.statusMessage}');
                }
              }
            } catch (e) {
              commonPrint('Fooocus绘制异常$e');
            } finally {
              dismissHint();
            }
          }
        }
      }
    }
  }

  //sd直接调用图生图
  //输入图片的base64
  //先反推图片的tags
  //然后让用户选择重绘分类
  Future<void> sdRedraw() async {
    if (inputImagePath != preInputImagePath) {
      String inputTags = await _getTaggerTags();
      //这里弹出提示框询问用户是否需要自己加入提示词，比如说是lora等的提示词
      if (mounted) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return CustomDialog(
                title: '提示',
                titleColor: Colors.white,
                showConfirmButton: true,
                showCancelButton: true,
                contentBackgroundColor: Colors.black,
                contentBackgroundOpacity: 0.5,
                description: '图片标签反推成功，是否需要增加自定义的图片描述',
                confirmButtonText: '添加好了去生成',
                cancelButtonText: '不添加直接生成',
                descColor: Colors.white,
                useScrollContent: true,
                maxWidth: 500,
                minWidth: 380,
                onCancel: () {
                  preInputImagePath = inputImagePath;
                  _picContentTextFieldController.text = inputTags;
                  _generateImage(context, isUpScaleRepair: true, isOnlyImg2Img: true);
                },
                onConfirm: () {
                  preInputImagePath = inputImagePath;
                  _picContentTextFieldController.text = _modifyTextFieldController.text;
                  _generateImage(context, isUpScaleRepair: true, isOnlyImg2Img: true);
                },
                content: Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    style: const TextStyle(color: Colors.yellowAccent),
                    controller: _modifyTextFieldController,
                    maxLines: null,
                    // 设置为null，输入框将根据内容自动扩展到多行
                    keyboardType: TextInputType.multiline,
                    // 设置键盘类型为多行文本输入
                    decoration: const InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white, width: 2.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white, width: 2.0),
                        ),
                        labelText: '图片描述',
                        labelStyle: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            });
      }
    } else {
      _generateImage(context, isUpScaleRepair: true, isOnlyImg2Img: true);
    }
  }

  Future<String> _getTaggerTags() async {
    showHint('反推图片tag中....', showType: 5);
    String tags = '';
    Map<String, dynamic> requestBody = {};
    Map<String, dynamic> settings = await Config.loadSettings();
    String sdUrl = settings['sdUrl'] ?? '';
    requestBody['image'] = inputImagePath;
    requestBody['model'] = "wd-v1-4-moat-tagger.v2";
    requestBody['threshold'] = 0.35;
    requestBody['escape_tag'] = false;
    requestBody['add_confident_as_weight'] = false;
    try {
      dio.Response response = await myApi.getTaggerTags(sdUrl, requestBody);
      if (response.statusCode == 200) {
        Map<String, dynamic> tagsData = response.data['caption']['tag'];
        for (String key in tagsData.keys) {
          tags += '$key, ';
        }
        tags = tags.substring(0, tags.length - 2);
        _modifyTextFieldController.text = tags;
      }
      dismissHint();
    } catch (e) {
      if (mounted) {
        showHint('反推图片Tags失败，请检查sd配置。异常是$e');
      }
    }
    return tags;
  }

  void closeWebSocketConnection(WebSocketChannel? channel) {
    if (channel != null) {
      // 关闭WebSocket连接
      channel.sink.close();
    }
  }

  Future<void> _onUpScale(int currentIndex) async {
    int index = currentIndex;
    Map<String, dynamic> settings = await Config.loadSettings();
    int drawEngine = imageBase64List[index].drawEngine;
    int systemDrawEngine = settings['drawEngine'] ?? 0;
    if (drawEngine != systemDrawEngine) {
      if (mounted) {
        showHint('该图片之前不是由目前所选绘图引擎绘制的，请切换到之前的绘图引擎');
        return;
      }
    }
    dismissHint();
    if (drawEngine == 0) {
      String sdUrl = settings['sdUrl'] ?? '';
      if (index >= 0 && index <= imageBase64List.length - 1) {
        String image = imageBase64List[index].base64Url;
        if (image != '') {
          Map<String, dynamic> requestBody = {
            "resize_mode": 0,
            "show_extras_results": false,
            "gfpgan_visibility": 0,
            "codeformer_visibility": 0,
            "codeformer_weight": 0,
            "upscaling_resize": 2,
            "upscaling_resize_w": 512,
            "upscaling_resize_h": 512,
            "upscaling_crop": true,
            "upscaler_1": "R-ESRGAN 4x+ Anime6B",
            "upscaler_2": "None",
            "extras_upscaler_2_visibility": 0,
            "upscale_first": false,
            "image": image
          };
          dio.Response? response;
          try {
            showHint('图片高清放大中...', showType: 5);
            response = await myApi.sdUpScaleImage(sdUrl, requestBody);
            if (response.statusCode == 200) {
              String useImagePath = response.data['image'];
              imageBase64List[index].base64Url = useImagePath;
              String imageUrl = '';
              String filePath = '';
              File file = await base64ToTempFile(useImagePath);
              if (file.existsSync()) {
                filePath = file.path;
              }
              if (filePath != '') {
                imageUrl = await uploadFileToALiOss(filePath, imageUrl, file);
              }
              imageBase64List[index].downloaded = false;
              imageBase64List[index].imageUrl = GlobalParams.filesUrl + imageUrl;
              imageViewKey.currentState?.refreshImage(index, imageBase64List[index]);
              imageBase64List[index].base64Url = '';
              var imageKey = imageBase64List[index].imageKey!;
              var imageInfo = jsonEncode(imageBase64List[index].toJson());
              await SupabaseHelper().update('images', {'info': imageInfo}, updateMatchInfo: {'key': imageKey});
              dismissHint();
            } else {
              dismissHint();
              if (mounted) {
                showHint('高清放大失败，原因是${response.data}', showTime: 3, showType: 3);
              }
            }
          } catch (error) {
            dismissHint();
            if (mounted) {
              showHint('高清放大失败，原因是$error', showTime: 3, showType: 3);
            }
          }
        }
      }
    } else if (drawEngine == 1) {
      Map<String, dynamic> payload = {};
      int drawSpeedType = settings['MJDrawSpeedType'] ?? 0;
      String token = '';
      switch (drawSpeedType) {
        case 0:
          token = settings['mj_slow_speed_token'] ?? '';
          break;
        case 1:
          token = settings['mj_fast_speed_token'] ?? '';
          break;
        case 2:
          token = settings['mj_extra_speed_token'] ?? '';
          break;
        default:
          break;
      }
      int imageTaskPosition = imageBase64List[index].position;
      String imageId = imageBase64List[index].id;
      payload['action'] = imageBase64List[index].buttons[imageTaskPosition];
      payload['image_id'] = imageId;
      dio.Response response;
      try {
        showHint('MJ图片高清放大中...', showType: 5);
        response = await myApi.mjDraw(drawSpeedType, token, payload);
        if (response.statusCode == 200) {
          response.data.stream.listen((data) async {
            final decodedData = utf8.decode(data);
            final jsonData = json.decode(decodedData);
            if (mounted) {
              showHint('MJ高清放大绘制进度是${jsonData['progress']}%');
            }
            String base64Path = await imageUrlToBase64(jsonData['image_url']);
            imageBase64List[index].base64Url = base64Path;
            imageBase64List[index].isUpScaled = true;
            imageBase64List[index].imageUrl = jsonData['image_url'];
            imageBase64List[index].id = jsonData['image_id'];
            imageBase64List[index].buttons = jsonData['actions'];
            imageViewKey.currentState?.refreshImage(index, imageBase64List[index]);
          });
        } else {
          if (mounted) {
            showHint('MJ图片高清放大失败,原因是${response.statusMessage}', showType: 3);
          }
        }
      } catch (e) {
        if (mounted) {
          showHint('MJ图片高清放大失败,原因是$e', showType: 3);
        }
      } finally {
        dismissHint();
      }
    } else if (drawEngine == 2) {
      Map<String, dynamic> payload = {};
      int imageTaskPosition = imageBase64List[index].position;
      String imageId = imageBase64List[index].id;
      List<dynamic> buttons = imageBase64List[index].buttons;
      String customId = buttons[imageTaskPosition]['customId'];
      payload['customId'] = customId;
      payload['taskId'] = imageId;
      dio.Response response;
      try {
        showHint('MJ图片高清进行中', showType: 5);
        response = await myApi.selfMjDrawChange(payload);
        if (response.statusCode == 200) {
          if (response.data is String) {
            response.data = jsonDecode(response.data);
          }
          int code = response.data['code'] ?? -1;
          if (code == 1) {
            if (mounted) {
              showHint('图片的MJ高清任务提交成功', showType: 2);
            }
            String result = response.data['result'];
            while (true) {
              dio.Response progressResponse = await myApi.selfMjDrawQuery(result);
              if (progressResponse.statusCode == 200) {
                if (progressResponse.data is String) {
                  progressResponse.data = jsonDecode(progressResponse.data);
                }
                String status = progressResponse.data['status'];
                if (status == '' ||
                    status == 'NOT_START' ||
                    status == 'IN_PROGRESS' ||
                    status == 'SUBMITTED' ||
                    status == 'MODAL' ||
                    status == 'SUCCESS') {
                  if (progressResponse.data['progress'] == null || progressResponse.data['progress'] == '') {
                    progressResponse.data['progress'] = '0%';
                  }
                  imageBase64List[currentIndex].drawProgress = progressResponse.data['progress'];
                  imageViewKey.currentState?.refreshImage(currentIndex, imageBase64List[currentIndex]);
                  if (progressResponse.data['imageUrl'] != null && progressResponse.data['imageUrl'] != '') {
                    dismissHint();
                    String imageUrl = progressResponse.data['imageUrl'];
                    String useImagePath = await imageUrlToBase64(imageUrl);
                    ui.Image image = await getImageFromBase64(useImagePath);
                    var imageHeight = image.height.toDouble();
                    var imageWidth = image.width.toDouble();
                    var imageAspectRatio = imageWidth / imageHeight;
                    var isSquare = true;
                    if (imageAspectRatio != 1.0) {
                      isSquare = false;
                    }
                    imageBase64List[currentIndex].base64Url = useImagePath;
                    String filePath = '';
                    File file = await base64ToTempFile(useImagePath);
                    if (file.existsSync()) {
                      filePath = file.path;
                    }
                    if (filePath != '') {
                      imageUrl = await uploadFileToALiOss(filePath, imageUrl, file);
                    }
                    imageBase64List[currentIndex].downloaded = false;
                    imageBase64List[currentIndex].isUpScaled = true;
                    imageBase64List[currentIndex].isSquare = isSquare;
                    //这里重新赋值可操作按钮
                    imageBase64List[currentIndex].buttons = progressResponse.data['buttons'];
                    //这里是放大之后修改任务ID
                    imageBase64List[currentIndex].id = progressResponse.data['id'];
                    imageBase64List[currentIndex].imageUrl = GlobalParams.filesUrl + imageUrl;
                    imageBase64List[currentIndex].drawProgress = '100%';
                    imageViewKey.currentState?.refreshImage(currentIndex, imageBase64List[currentIndex]);
                    dismissHint();
                    imageBase64List[currentIndex].base64Url = '';
                    var imageKey = imageBase64List[currentIndex].imageKey!;
                    var imageInfo = jsonEncode(imageBase64List[currentIndex].toJson());
                    await SupabaseHelper().update('images', {'info': imageInfo}, updateMatchInfo: {'key': imageKey});
                    break;
                  }
                } else {
                  break;
                }
              } else {
                break;
              }
              await Future.delayed(const Duration(seconds: 5));
            }
          } else {
            if (mounted) {
              showHint('自有mj高清放大失败,原因是${response.data['description']}', showType: 3);
              commonPrint('自有mj高清放大失败0,原因是${response.data['description']}');
            }
            imageBase64List[currentIndex].drawProgress = '100%';
            imageViewKey.currentState?.refreshImage(currentIndex, imageBase64List[currentIndex]);
          }
        } else {
          if (mounted) {
            showHint('MJ图片高清放大失败,原因是${response.statusMessage}', showType: 3);
            commonPrint('MJ图片高清失败2，原因是${response.statusMessage}');
          }
          imageBase64List[currentIndex].drawProgress = '100%';
          imageViewKey.currentState?.refreshImage(currentIndex, imageBase64List[currentIndex]);
        }
      } catch (e) {
        if (mounted) {
          showHint('MJ图片高清失败，原因是$e', showType: 3);
          commonPrint('MJ图片高清失败1，原因是$e');
        }
        imageBase64List[currentIndex].drawProgress = '100%';
        imageViewKey.currentState?.refreshImage(currentIndex, imageBase64List[currentIndex]);
      } finally {
        dismissHint();
      }
    }
  }

  Future<void> _onUpScaleRepairImage(int currentIndex) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    int drawEngine = imageBase64List[currentIndex].drawEngine;
    int systemDrawEngine = settings['drawEngine'] ?? 0;
    if (drawEngine != systemDrawEngine) {
      if (mounted) {
        showHint('该图片之前不是由目前所选绘图引擎绘制的，请切换到之前的绘图引擎');
        return;
      }
    }
    if (drawEngine == 0) {
      String currentImagePath = imageBase64List[currentIndex].base64Url;
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomDialog(
              title: '图生图重绘选项',
              titleColor: Colors.white,
              cancelButtonText: '取消',
              confirmButtonText: '确认',
              contentBackgroundColor: Colors.black,
              contentBackgroundOpacity: 0.5,
              maxWidth: 400,
              content: RedrawOptionWidget(
                currentImagePath: currentImagePath,
                samplers: List<String>.from(['Euler a']),
                isUseControlNet: false,
              ),
              onCancel: () {},
              onConfirm: () async {
                _generateImage(context, isUpScaleRepair: true, imagePosition: currentIndex);
              },
            );
          },
        );
      }
    } else if (drawEngine == 1) {
      int lastImageNum = imageBase64List.length;
      Map<String, dynamic> payload = {};
      int drawSpeedType = settings['MJDrawSpeedType'] ?? 0;
      String token = '';
      switch (drawSpeedType) {
        case 0:
          token = settings['mj_slow_speed_token'] ?? '';
          break;
        case 1:
          token = settings['mj_fast_speed_token'] ?? '';
          break;
        case 2:
          token = settings['mj_extra_speed_token'] ?? '';
          break;
        default:
          break;
      }
      int imageTaskPos = imageBase64List[currentIndex].position;
      payload['action'] = imageBase64List[currentIndex].buttons[imageTaskPos + 5];
      payload['image_id'] = imageBase64List[currentIndex].id;
      dio.Response response;
      try {
        showHint('MJ图片变换中...', showType: 5);
        response = await myApi.mjDraw(drawSpeedType, token, payload);
        if (response.statusCode == 200) {
          response.data.stream.listen((data) async {
            final decodedData = utf8.decode(data);
            final jsonData = json.decode(decodedData);
            int progress = jsonData['progress'];
            if (mounted) {
              showHint('MJ变换进度是$progress%');
            }
            if (progress == 100) {
              if (mounted) {
                showHint('图片即将展示，请稍后...', showType: 2);
              }
              List<ImageItemModel> tempImages = [];
              List<String> base64Urls = await splitImage(jsonData['image_url']);
              for (int i = 0; i < base64Urls.length; i++) {
                String imageUrl = '';
                String filePath = '';
                File file = await base64ToTempFile(base64Urls[i]);
                if (file.existsSync()) {
                  filePath = file.path;
                }
                if (filePath != '') {
                  imageUrl = await uploadFileToALiOss(filePath, imageUrl, file);
                }
                ImageItemModel imageItemModel = ImageItemModel(i, jsonData['image_id'], true, false, base64Urls[i], jsonData['actions'], 1, '', false,
                    GlobalParams.filesUrl + imageUrl, false, false);
                tempImages.add(imageItemModel);
              }
              int currentImageNum = imageBase64List.length;
              if (currentImageNum != lastImageNum && currentImageNum >= 4) {
                imageBase64List.removeRange(imageBase64List.length - 4, imageBase64List.length);
              }
              // imageBase64List.addAll(tempImages);
              imageViewKey.currentState?.insertImageData(tempImages, lastImageNum, currentImageNum, 1);
              _scrollToTop();
            }
          });
        } else {
          if (mounted) {
            showHint('MJ图片变换失败,原因是${response.statusMessage}', showType: 3);
          }
        }
      } catch (e) {
        if (mounted) {
          showHint('MJ图片变换失败,原因是$e', showType: 3);
        }
      } finally {
        dismissHint();
      }
    } else if (drawEngine == 2) {
      Map<String, dynamic> payload = {};
      List<dynamic> buttons = imageBase64List[currentIndex].buttons;
      int imageTaskPos = imageBase64List[currentIndex].position;
      String imageId = imageBase64List[currentIndex].id;
      String imagePrompt = imageBase64List[currentIndex].prompt;
      double radio = getImageRadio(imagePrompt);
      String customId = buttons[imageTaskPos + 5]['customId'];
      payload['customId'] = customId;
      payload['taskId'] = imageId;
      dio.Response response;
      try {
        showHint('图片的MJ变换任务进行中', showType: 5);
        response = await myApi.selfMjDrawChange(payload);
        if (response.statusCode == 200) {
          if (response.data is String) {
            response.data = jsonDecode(response.data);
          }
          int code = response.data['code'] ?? -1;
          if (code == 1) {
            if (mounted) {
              showHint('图片的MJ变换任务提交成功');
            }
            String result = response.data['result'];
            Map<String, dynamic> job = {result: '变换任务', 'radio': radio};
            createTaskQueue(job);
          } else {
            if (mounted) {
              showHint('图片的MJ变换任务提交失败，原因是${response.data['description']}', showType: 3);
            }
          }
        }
      } catch (e) {
        if (mounted) {
          showHint('图片变换失败,原因是$e', showType: 3);
          commonPrint('图片变换失败,原因是$e');
        }
      } finally {
        dismissHint();
      }
    }
  }

  Future<void> _furtherOperations(int currentIndex, int optionId, String optionName) async {
    int drawEngine = imageBase64List[currentIndex].drawEngine;
    Map<String, dynamic> settings = await Config.loadSettings();
    int systemDrawEngine = settings['drawEngine'] ?? 0;
    String drawEngineName = drawEngine == 0
        ? 'SD'
        : drawEngine == 1
            ? 'MJ1'
            : drawEngine == 2
                ? 'MJ2'
                : drawEngine == 3
                    ? 'CU'
                    : drawEngine == 4
                        ? 'Fooocus'
                        : '未知';
    if (drawEngine != systemDrawEngine && optionId != 30 && optionId != 22) {
      if (mounted) {
        showHint('该图片之前是由$drawEngineName绘图引擎绘制的，请切换到之前的绘图引擎');
        return;
      }
    }
    if (optionId == 10 && optionName == '获取种子') {
      //获取图片种子
      _getImageSeed(currentIndex, drawEngine);
    } else if (optionId == 11 && optionName == '自选缩放') {
      if (!GlobalParams.isFreeVersion) {
        int canDrawNum = box.read('seniorDrawNum');
        if (canDrawNum <= 0) {
          if (mounted) {
            showHint('可用绘画次数不足，请购买套餐后再进行绘画');
          }
          dismissHint();
          return;
        }
      }
      //自由放大
      String taskId = imageBase64List[currentIndex].id;
      String base64Path = imageBase64List[currentIndex].imageUrl;
      dio.Response response;
      //先查询当前任务的描述词
      try {
        showHint('获取该图片参数中...', showType: 5);
        response = await myApi.selfMjDrawQuery(taskId);
        if (response.statusCode == 200) {
          String finalPrompt = '';
          if (response.data is String) {
            response.data = jsonDecode(response.data);
          }
          if (response.data['properties'] != null) {
            finalPrompt = response.data['properties']['finalPrompt'];
          } else {
            finalPrompt = response.data['promptEn'];
          }
          String base64Image = await imageUrlToBase64(base64Path);
          String imageAspectRatio = getImageAspectRatio(base64Image);
          String finalText = '';
          if (!finalPrompt.contains('--ar')) {
            finalText = '$finalPrompt --ar $imageAspectRatio --zoom 2';
          } else {
            finalText = '$finalPrompt --zoom 2';
          }
          double radio = getImageRadio(finalText);
          _selfScaleTextFieldController.text = finalText;
          Map<String, dynamic> payload = {};
          payload['taskId'] = taskId;
          List<dynamic> buttons = imageBase64List[currentIndex].buttons;
          String customId = buttons[7]['customId'];
          payload['customId'] = customId;
          dio.Response changeResponse = await myApi.selfMjDrawChange(payload);
          if (changeResponse.statusCode == 200) {
            if (changeResponse.data is String) {
              changeResponse.data = jsonDecode(changeResponse.data);
            }
            int code = changeResponse.data['code'];
            String result = changeResponse.data['result'];
            if (code == 21) {
              dismissHint();
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return CustomDialog(
                        title: '自选缩放',
                        titleColor: Colors.white,
                        showConfirmButton: true,
                        showCancelButton: true,
                        contentBackgroundColor: Colors.black,
                        contentBackgroundOpacity: 0.5,
                        description: '和mj的操作一致，需要自己指定缩放比例，请保证提示词最后包含--zoom x(x指的是缩放倍数)',
                        descColor: Colors.white,
                        useScrollContent: true,
                        maxWidth: 420,
                        minWidth: 380,
                        maxHeight: 500,
                        onCancel: () {},
                        cancelButtonText: '取消',
                        confirmButtonText: '确定',
                        onConfirm: () async {
                          if (!_selfScaleTextFieldController.text.contains('--zoom')) {
                            if (mounted) {
                              showHint('请保证图片描述里面含有缩放指令及缩放倍数，例如 --zoom 2');
                            }
                          } else {
                            Map<String, dynamic> map = {};
                            map['prompt'] = _selfScaleTextFieldController.text;
                            map['taskId'] = result;
                            dio.Response modalResponse = await myApi.selfMjModal(map);
                            if (modalResponse.statusCode == 200) {
                              if (modalResponse.data is String) {
                                modalResponse.data = jsonDecode(modalResponse.data);
                              }
                              int code = modalResponse.data['code'];
                              if (code == 1) {
                                int seniorDrawNum = box.read('seniorDrawNum');
                                box.write('seniorDrawNum', seniorDrawNum - 1);
                                String result = modalResponse.data['result'];
                                Map<String, dynamic> taskData = {result: '自选缩放', 'radio': radio};
                                createTaskQueue(taskData);
                              } else {
                                if (context.mounted) {
                                  showHint('自选缩放任务提交失败，原因是${modalResponse.data['description']}');
                                  commonPrint('自选缩放任务提交失败1，原因是${modalResponse.data['description']}');
                                }
                              }
                            } else {
                              if (context.mounted) {
                                showHint('自选缩放任务提交失败，原因是${modalResponse.statusMessage}');
                                commonPrint('自选缩放任务提交失败2，原因是${modalResponse.statusMessage}');
                              }
                            }
                          }
                        },
                        content: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: TextField(
                                    style: const TextStyle(color: Colors.yellowAccent),
                                    controller: _selfScaleTextFieldController,
                                    maxLines: 10,
                                    minLines: 1,
                                    keyboardType: TextInputType.multiline,
                                    decoration: const InputDecoration(
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.white, width: 2.0),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.white, width: 2.0),
                                        ),
                                        labelText: '图片描述',
                                        labelStyle: TextStyle(color: Colors.white))),
                              ),
                            )
                          ],
                        ));
                  },
                );
              }
            } else {
              if (mounted) {
                showHint('自选缩放任务提交失败，原因是${changeResponse.data['description']}');
                commonPrint('自选缩放任务提交失败3，原因是${changeResponse.data['description']}');
              }
            }
          } else {
            if (mounted) {
              showHint('自选缩放任务提交失败，原因是${response.statusMessage}');
              commonPrint('自选缩放任务提交失败4，原因是${response.statusMessage}');
            }
          }
        } else {
          if (mounted) {
            showHint('该图片信息查询失败无法执行操作');
          }
        }
      } catch (e) {
        if (mounted) {
          showHint('该图片信息查询失败无法执行操作');
          commonPrint('自选缩放异常，原因是$e');
        }
      } finally {
        dismissHint();
      }
    } else if (optionId == 12) {
      if (!GlobalParams.isFreeVersion) {
        int canDrawNum = box.read('seniorDrawNum');
        if (canDrawNum <= 0) {
          if (mounted) {
            showHint('可用绘画次数不足，请购买套餐后再进行绘画');
          }
          dismissHint();
          return;
        }
      }
      //局部重绘功能
      String taskId = imageBase64List[currentIndex].id;
      String base64Path = imageBase64List[currentIndex].imageUrl;
      dio.Response response;
      //先查询当前任务的描述词
      try {
        showHint('获取该图片参数中...', showType: 5);
        response = await myApi.selfMjDrawQuery(taskId);
        if (response.statusCode == 200) {
          if (response.data is String) {
            response.data = jsonDecode(response.data);
          }

          String finalPrompt = '';
          if (response.data['properties'] != null) {
            finalPrompt = response.data['properties']['finalPrompt'];
          } else {
            finalPrompt = response.data['promptEn'];
          }
          double radio = getImageRadio(finalPrompt);
          _selfScaleTextFieldController.text = finalPrompt;
          Map<String, dynamic> payload = {};
          payload['taskId'] = taskId;
          List<dynamic> buttons = imageBase64List[currentIndex].buttons;
          String customId = buttons[4]['customId'];
          payload['customId'] = customId;
          dio.Response changeResponse = await myApi.selfMjDrawChange(payload);
          if (changeResponse.statusCode == 200) {
            if (changeResponse.data is String) {
              changeResponse.data = jsonDecode(changeResponse.data);
            }
            commonPrint(changeResponse.data);
            int code = changeResponse.data['code'];
            String? result = changeResponse.data['result'];
            if (code == 21) {
              dismissHint();
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return CustomDialog(
                        title: '局部重绘',
                        titleColor: Colors.white,
                        showConfirmButton: false,
                        showCancelButton: false,
                        contentBackgroundColor: Colors.black,
                        contentBackgroundOpacity: 0.5,
                        description: '和mj的操作一致，需要自己编辑图片蒙板',
                        descColor: Colors.white,
                        useScrollContent: false,
                        maxWidth: 600,
                        minWidth: 400,
                        maxHeight: 850,
                        content: ImageRegion(
                          base64Image: base64Path,
                          imageContent: finalPrompt,
                          onConfirm: (maskBase64, regionContent) async {
                            Navigator.of(context).pop();
                            Map<String, dynamic> map = {};
                            map['prompt'] = regionContent;
                            map['taskId'] = result;
                            map['maskBase64'] = 'data:image/png;base64,$maskBase64';
                            dio.Response modalResponse = await myApi.selfMjModal(map);
                            if (modalResponse.statusCode == 200) {
                              if (modalResponse.data is String) {
                                modalResponse.data = jsonDecode(modalResponse.data);
                              }
                              int code = modalResponse.data['code'];
                              if (code == 1) {
                                int seniorDrawNum = box.read('seniorDrawNum');
                                box.write('seniorDrawNum', seniorDrawNum - 1);
                                String result = modalResponse.data['result'];
                                Map<String, dynamic> taskData = {result: '局部重绘', 'radio': radio};
                                createTaskQueue(taskData);
                              } else {
                                if (context.mounted) {
                                  showHint('局部重绘任务提交失败，原因是${modalResponse.data['description']}');
                                  commonPrint('局部重绘任务提交失败1，原因是${modalResponse.data['description']}');
                                }
                              }
                            } else {
                              if (context.mounted) {
                                showHint('局部重绘任务提交失败，原因是${modalResponse.statusMessage}');
                                commonPrint('局部重绘任务提交失败2，原因是${modalResponse.statusMessage}');
                              }
                            }
                          },
                        ));
                  },
                );
              }
            } else {
              if (mounted) {
                showHint('局部重绘任务提交失败，原因是${changeResponse.data['description']}');
                commonPrint('局部重绘任务提交失败3，原因是${changeResponse.data['description']}');
              }
            }
          } else {
            if (mounted) {
              showHint('局部重绘任务提交失败，原因是${response.statusMessage}');
              commonPrint('局部重绘任务提交失败4，原因是${response.statusMessage}');
            }
          }
        } else {
          if (mounted) {
            showHint('该图片信息查询失败无法执行操作');
          }
        }
      } catch (e) {
        if (mounted) {
          showHint('该图片信息查询失败无法执行操作');
          commonPrint('局部重绘异常，原因是$e');
        }
      } finally {
        dismissHint();
      }
    } else if (optionId == 15) {
      if (!GlobalParams.isFreeVersion) {
        int canDrawNum = box.read('seniorDrawNum');
        if (canDrawNum <= 0) {
          if (mounted) {
            showHint('可用绘画次数不足，请购买套餐后再进行绘画');
          }
          dismissHint();
          return;
        }
      }
      //换脸
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomDialog(
                title: '上传人脸源图片',
                titleColor: Colors.white,
                contentBackgroundColor: Colors.black,
                contentBackgroundOpacity: 0.5,
                description: '需要上传人脸源图片来替换当前图片人脸',
                descColor: Colors.white,
                useScrollContent: true,
                maxWidth: 600,
                minWidth: 400,
                maxHeight: 850,
                showCancelButton: false,
                showConfirmButton: false,
                content: SwapFaceView(
                  swapFaceImage: swapFaceImage,
                  onCancel: () {},
                  onConfirm: (inputSwapFaceImage) {
                    swapFaceImage = '';
                    if (inputSwapFaceImage.isNotEmpty) {
                      _swapFace(inputSwapFaceImage, currentIndex);
                    }
                    Navigator.of(context).pop();
                  },
                ));
          },
        );
      }
    } else if (optionId == 22) {
      //复制图片提示词
      String currentPrompt = imageBase64List[currentIndex].prompt;
      Clipboard.setData(ClipboardData(text: currentPrompt));
      if (mounted) {
        showHint('图片提示词已复制到剪切板，可以复制到其他地方了', showType: 4);
      }
    } else if (optionId == 30) {
      //删除当前图片
      _deleteCurrentImage(currentIndex);
    } else if (optionId == 100) {
      //效仿图片
      String imagePrompt = imageBase64List[currentIndex].prompt;
      box.write('gotoPage', 1);
      box.write('imagePrompt', imagePrompt);
    } else {
      if (drawEngine == 1) {
        int lastImageNum = imageBase64List.length;
        Map<String, dynamic> payload = {};
        int drawSpeedType = settings['MJDrawSpeedType'] ?? 0;
        String token = '';
        switch (drawSpeedType) {
          case 0:
            token = settings['mj_slow_speed_token'] ?? '';
            break;
          case 1:
            token = settings['mj_fast_speed_token'] ?? '';
            break;
          case 2:
            token = settings['mj_extra_speed_token'] ?? '';
            break;
          default:
            break;
        }
        if (optionId > 2 && optionId < 5) {
          optionId = optionId - 1;
        }
        if (optionId > 5) {
          optionId = optionId - 2;
        }
        payload['action'] = imageBase64List[currentIndex].buttons[optionId];
        payload['image_id'] = imageBase64List[currentIndex].id;
        dio.Response response;
        try {
          showHint('MJ图片$optionName中...', showType: 5);
          response = await myApi.mjDraw(drawSpeedType, token, payload);
          if (response.statusCode == 200) {
            response.data.stream.listen((data) async {
              final decodedData = utf8.decode(data);
              final jsonData = json.decode(decodedData);
              int progress = jsonData['progress'];
              if (progress == 100) {
                List<ImageItemModel> tempImages = [];
                List<String> base64Urls = await splitImage(jsonData['image_url']);
                for (int i = 0; i < base64Urls.length; i++) {
                  String imageUrl = '';
                  String filePath = '';
                  File file = await base64ToTempFile(base64Urls[i]);
                  if (file.existsSync()) {
                    filePath = file.path;
                  }
                  if (filePath != '') {
                    imageUrl = await uploadFileToALiOss(filePath, imageUrl, file);
                  }
                  ImageItemModel imageItemModel = ImageItemModel(i, jsonData['image_id'], true, false, base64Urls[i], jsonData['actions'], 1, '',
                      false, GlobalParams.filesUrl + imageUrl, false, false);
                  tempImages.add(imageItemModel);
                }
                int currentImageNum = imageBase64List.length;
                if (currentImageNum != lastImageNum && currentImageNum >= 4) {
                  imageBase64List.removeRange(imageBase64List.length - 4, imageBase64List.length);
                }
                // imageBase64List.addAll(tempImages);
                imageViewKey.currentState?.insertImageData(tempImages, lastImageNum, currentImageNum, 1);
                _scrollToTop();
              }
            });
          } else {
            if (mounted) {
              showHint('MJ图片$optionName失败,原因是${response.statusMessage}', showType: 3);
            }
          }
        } catch (e) {
          if (mounted) {
            showHint('MJ图片$optionName失败,原因是$e', showType: 3);
          }
        } finally {
          dismissHint();
        }
      } else if (drawEngine == 2) {
        if (!GlobalParams.isFreeVersion) {
          int canDrawNum = box.read('seniorDrawNum');
          if (canDrawNum <= 0) {
            if (mounted) {
              showHint('可用绘画次数不足，请购买套餐后再进行绘画');
            }
            dismissHint();
            return;
          }
        }
        Map<String, dynamic> payload = {};
        List<dynamic> buttons = imageBase64List[currentIndex].buttons;
        String imageId = imageBase64List[currentIndex].id;
        String imagePrompt = imageBase64List[currentIndex].prompt;
        double radio = getImageRadio(imagePrompt);
        String customId = '';
        if (optionId == 20) {
          customId = buttons[8]['customId'];
        } else {
          if (imageBase64List[currentIndex].isSquare) {
            customId = buttons[optionId]['customId'];
          } else {
            if (optionId >= 8) {
              //这里是因为不是正方形图片会有一个将图片变为正方形的按钮，所以后面的按钮要加1
              optionId = optionId + 1;
              customId = buttons[optionId]['customId'];
            } else {
              customId = buttons[optionId]['customId'];
            }
          }
        }
        payload['customId'] = customId;
        payload['taskId'] = imageId;
        dio.Response response;
        try {
          showHint('图片的MJ$optionName任务进行中...', showType: 5);
          response = await myApi.selfMjDrawChange(payload);
          if (response.statusCode == 200) {
            if (response.data is String) {
              response.data = jsonDecode(response.data);
            }
            int code = response.data['code'] ?? -1;
            if (code == 1) {
              if (mounted) {
                showHint('图片的MJ$optionName任务提交成功');
              }
              String result = response.data['result'];
              Map<String, dynamic> job = {result: '$optionName任务', 'index': currentIndex, 'radio': radio};
              if (!optionName.contains('高档')) {}
              int seniorDrawNum = box.read('seniorDrawNum');
              box.write('seniorDrawNum', seniorDrawNum - 1);
              createTaskQueue(job);
            } else {
              if (mounted) {
                showHint('图片的MJ$optionName任务提交失败，原因是${response.data['description']}', showType: 3);
              }
            }
          } else {
            if (mounted) {
              showHint('图片$optionName失败,原因是${response.statusMessage}', showType: 3);
              commonPrint('图片$optionName失败,原因是${response.statusMessage}');
            }
          }
        } catch (e) {
          if (mounted) {
            showHint('图片$optionName失败,原因是$e', showType: 3);
            commonPrint('图片$optionName失败,原因是$e');
          }
        } finally {
          dismissHint();
        }
      }
    }
  }

  Future<void> addImageItems(double? ratio) async {
    List<ImageItemModel> tempImages = [];
    var settings = await Config.loadSettings();
    String userId = settings['user_id'] ?? '';
    for (int i = 0; i < 4; i++) {
      String uuid = const Uuid().v4();
      tempImages.clear();
      ImageItemModel imageItemModel = ImageItemModel(i, '', true, false, '', [], 2, '', false, '', false, false,
          isSquare: false, isNijiV6: false, prompt: '', imageKey: '$userId-$uuid', isPublic: publicImage == 1, imageAspectRatio: ratio);
      tempImages.add(imageItemModel);
      imageViewKey.currentState?.insertImageData(tempImages, 0, 0, 2);
    }
    _scrollToTop();
  }

  //读取内存的键值对
  void listenStorage() {
    box.listenKey('drawEngine', (value) {
      setState(() {
        drawEngine = value;
        if (drawEngine == 0) {
          _getControlNetModels();
          _getControlNetModules();
        }
      });
    });

    box.listenKey('curPage', (value) {
      //判断当前页面是否是其他页面跳转到画廊页面
      if (widget.isGallery && value == 5) {
        imageView.imageBase64List.clear();
        readImagesFromDatabase();
      }
    });
    box.listenKey('is_login', (value) {
      if (mounted) {
        if (value) {
          setState(() {
            isFirstPageNoData = false;
          });
          //登录成功后加载数据
          readImagesFromDatabase();
        } else {
          pageNum = 0;
          imageViewKey.currentState?.clearAll();
          setState(() {
            isFirstPageNoData = true;
          });
        }
      }
    });
  }

  Future<void> _swapFace(String inputSwapFaceImage, int currentIndex) async {
    showHint('开始换脸，请稍后...', showType: 5);
    String imageUrl = imageBase64List[currentIndex].imageUrl;
    String base64Path = await imageUrlToBase64(imageUrl);
    String compressBase64Path = await compressBase64Image(base64Path);
    dio.Response response;
    inputSwapFaceImage = 'data:image/png;base64,$inputSwapFaceImage';
    compressBase64Path = 'data:image/png;base64,$compressBase64Path';
    var settings = await Config.loadSettings();
    try {
      Map<String, dynamic> payload = {};
      payload['sourceBase64'] = inputSwapFaceImage;
      payload['targetBase64'] = compressBase64Path;
      response = await myApi.swapFace(payload);
      //这个只是提交了任务而已，还需要根据任务ID获取返回值
      if (response.statusCode == 200) {
        if (response.data is String) {
          response.data = jsonDecode(response.data);
        }
        int seniorDrawNum = box.read('seniorDrawNum');
        box.write('seniorDrawNum', seniorDrawNum - 1);
        String jobId = response.data['result'];
        while (true) {
          dio.Response progressResponse = await myApi.selfMjDrawQuery(jobId);
          if (progressResponse.statusCode == 200) {
            if (progressResponse.data is String) {
              progressResponse.data = jsonDecode(progressResponse.data);
            }
            String? status = progressResponse.data['status'];
            if (status == '' ||
                status == 'NOT_START' ||
                status == 'IN_PROGRESS' ||
                status == 'SUBMITTED' ||
                status == 'MODAL' ||
                status == 'SUCCESS') {
              if (status == 'SUCCESS') {
                if (progressResponse.data['imageUrl'] != null) {
                  String imageUrl = progressResponse.data['imageUrl'];
                  imageUrl = imageUrl.replaceAll('cdn.discordapp.com', 'dc.aigc369.com');
                  String useImagePath = await imageUrlToBase64(imageUrl);
                  imageBase64List[currentIndex].base64Url = useImagePath;
                  String filePath = '';
                  File file = await base64ToTempFile(useImagePath);
                  if (file.existsSync()) {
                    filePath = file.path;
                  }
                  if (filePath != '') {
                    imageUrl = await uploadFileToALiOss(filePath, imageUrl, file);
                  }
                  imageBase64List[currentIndex].downloaded = false;
                  imageBase64List[currentIndex].isSwapFace = true;
                  imageBase64List[currentIndex].imageUrl = GlobalParams.filesUrl + imageUrl;
                  imageViewKey.currentState?.refreshImage(currentIndex, imageBase64List[currentIndex]);
                  dismissHint();
                  var imageKey = imageBase64List[currentIndex].imageKey!;
                  imageBase64List[currentIndex].base64Url = '';
                  var imageInfo = jsonEncode(imageBase64List[currentIndex].toJson());
                  await SupabaseHelper().update('images', {'info': imageInfo}, updateMatchInfo: {'key': imageKey});
                  String userId = settings['user_id'];
                  await SupabaseHelper().update('user_packages', {'senior_draw': seniorDrawNum - 1}, updateMatchInfo: {'user_id': userId});
                  break;
                }
              }
            } else if (status != '') {
              if (mounted) {
                showHint('mj绘图失败,原因是${progressResponse.data['failReason']}', showType: 3);
                commonPrint('mj绘图失败0,原因是${progressResponse.data['failReason']}');
                box.write('seniorDrawNum', seniorDrawNum);
              }
              break;
            }
          } else {
            if (mounted) {
              showHint('换脸失败,原因是${progressResponse.statusMessage}', showType: 3);
              commonPrint('换脸失败,原因是${progressResponse.statusMessage}');
              box.write('seniorDrawNum', seniorDrawNum);
            }
            break;
          }
          dismissHint();
          await Future.delayed(const Duration(seconds: 5));
        }
      } else {
        if (mounted) {
          showHint('换脸任务提交失败，请稍后重试');
        }
      }
    } catch (e) {
      if (mounted) {
        showHint('换脸任务失败，请稍后重试');
      }
    } finally {
      dismissHint();
    }
  }

  //调用GPT来优化提示词
  //GPT账号需要是plus账号才可以使用
  Future<void> _optimizationPrompts(String originPrompts) async {
    showHint('');
    bool canUse = await checkUser();
    if (!canUse) {
      if (mounted) {
        showHint('账户可能已被管理员禁用，请联系管理员或者稍后重试');
      }
      dismissHint();
      return;
    }
    //以下是设置的openai的鉴权
    //A young girl in a flowing white dress, standing by the sea at sunset. The waves gently lap at her feet, reflecting the warm glow of the setting sun. Created Using: detailed, soft-focus, golden-hour lighting, high contrast shadows, realistic texture, serene atmosphere, reflective water surface, hd quality, natural look
    // the user message that will be sent to the request.
    final userMessage = ChatCompletionMessage.user(
      content: ChatCompletionUserMessageContent.string(originPrompts),
    );
    final requestMessages = [userMessage];
    showHint('正在使用AI进行提示词优化，请稍等...', showType: 5);
    try {
      var chatCompletion = await OpenAIClientSingleton.instance.client.createChatCompletion(
          request: CreateChatCompletionRequest(
        model: const ChatCompletionModel.modelId('gpt-4-gizmo-g-tc0eHXdgb'), //这个是mj提示词生成的GPTs的id
        messages: requestMessages,
      ));
      RegExp regExp = RegExp(
        r'(/imagine prompt:.*?--v 6\.0)',
        dotAll: true,
      );
      Iterable<RegExpMatch> matches = regExp.allMatches("${chatCompletion.choices.first.message.content}");
      List<String> midjourneyCommands = matches.map((m) => m.group(0)!).toList();
      List<String> modifyCommands = [];
      for (var element in midjourneyCommands) {
        String modifyElement = element.replaceAll('/imagine prompt:', '');
        var replaceSuffixIndex = modifyElement.indexOf('--ar');
        if (replaceSuffixIndex != -1) {
          modifyElement = modifyElement.substring(0, replaceSuffixIndex);
        }
        modifyCommands.add(modifyElement);
      }
      if (mounted) {
        showHint('AI提示词优化完成', showType: 2);
        for (var i = 0; i < 1; i++) {
          var element = modifyCommands[i];
          _picContentTextFieldController.text = element;
          _generateImage(context, inputPrompt: element);
        }
      }
    } catch (e) {
      commonPrint('请求异常Error:$e');
    } finally {
      dismissHint();
    }
  }

  Future<void> _getImageSeed(int currentIndex, int drawEngine) async {
    if (drawEngine == 0) {
      // String useImagePath = imageBase64List[currentIndex].base64Url;
      String useImagePath = await imageUrlToBase64(imageBase64List[currentIndex].imageUrl);
      Uint8List decodedBytes = base64Decode(useImagePath);
      img.Image image = img.decodeImage(Uint8List.fromList(decodedBytes))!;
      var imageInfo = image.textData;
      try {
        if (imageInfo != null) {
          var paramsStartIndex = imageInfo['parameters']!.indexOf('Steps');
          if (paramsStartIndex != -1) {
            var imageInfoMap = parseStringToMap(imageInfo['parameters']!.substring(paramsStartIndex, imageInfo['parameters']!.length));
            var imageSeed = imageInfoMap['Seed'];
            if (imageSeed != null) {
              imageBase64List[currentIndex].seed = '$imageSeed';
              imageViewKey.currentState?.refreshImage(currentIndex, imageBase64List[currentIndex]);
              var imageKey = imageBase64List[currentIndex].imageKey!;
              imageBase64List[currentIndex].base64Url = '';
              var imageInfo = jsonEncode(imageBase64List[currentIndex].toJson());
              await SupabaseHelper().update('images', {'info': imageInfo}, updateMatchInfo: {'key': imageKey});
            } else {
              setState(() {
                imageBase64List[currentIndex].seed = '获取失败';
                _scrollToTop();
              });
            }
          }
        }
      } catch (e) {
        setState(() {
          imageBase64List[currentIndex].seed = '获取失败';
        });
      }
    } else if (drawEngine == 1) {
      if (mounted) {
        showHint('知数云暂不支持获取图片种子');
      }
    } else if (drawEngine == 2) {
      String imageId = imageBase64List[currentIndex].id;
      dio.Response response;
      try {
        showHint('获取图片种子中...', showType: 5);
        response = await myApi.selfMjGetImageSeed(imageId);
        if (response.statusCode == 200) {
          if (response.data is String) {
            response.data = jsonDecode(response.data);
          }
          int code = response.data['code'];
          if (code == 1) {
            var imageSeed = response.data['result'];
            imageBase64List[currentIndex].seed = '$imageSeed';
            imageViewKey.currentState?.refreshImage(currentIndex, imageBase64List[currentIndex]);
            imageBase64List[currentIndex].base64Url = '';
            var imageKey = imageBase64List[currentIndex].imageKey!;
            var imageInfo = jsonEncode(imageBase64List[currentIndex].toJson());
            await SupabaseHelper().update('images', {'info': imageInfo}, updateMatchInfo: {'key': imageKey});
          } else {
            if (mounted) {
              showHint('获取图片种子失败,原因是${response.data['description']}');
            }
          }
        } else {
          if (mounted) {
            showHint('获取图片种子失败,原因是${response.statusMessage}');
          }
        }
      } catch (e) {
        if (mounted) {
          showHint('获取图片种子失败,原因是$e');
        }
      } finally {
        dismissHint();
      }
    }
  }

  Future<void> _mjBlendImage() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    int drawEngine = settings['drawEngine'] ?? 0;
    String token = settings['zsy_blend_token'] ?? '';
    List<Map<String, dynamic>> images = [
      {'input_image': ''},
      {'input_image': ''}
    ];
    Map<String, dynamic> payload = {};
    if ((drawEngine == 2 || drawEngine == 1) && mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomDialog(
              title: null,
              titleColor: Colors.white,
              showConfirmButton: false,
              showCancelButton: false,
              contentBackgroundColor: Colors.black,
              contentBackgroundOpacity: 0.5,
              description: null,
              descColor: Colors.white,
              useScrollContent: false,
              maxWidth: 420,
              minWidth: 380,
              minHeight: 300,
              maxHeight: drawEngine == 2 ? 600 : 560,
              content: BlendImageOption(
                base64Images: images,
                drawEngine: drawEngine,
                canAddOrDelete: drawEngine == 2,
                onConfirm: (options) async {
                  Navigator.of(context).pop();
                  double radio = 1.0;
                  if (drawEngine == 2) {
                    String dimensions = options.last['imageProportion'];
                    if (dimensions == '方形纵横比(1:1)') {
                      dimensions = 'SQUARE';
                      radio = 1.0;
                    } else if (dimensions == '纵向纵横比(2:3)') {
                      dimensions = 'PORTRAIT';
                      radio = 3 / 2;
                    } else if (dimensions == '横向纵横比(3:2)') {
                      dimensions = 'LANDSCAPE';
                      radio = 2 / 3;
                    }
                    payload['dimensions'] = dimensions;
                    List<String> base64Array = [];
                    for (var i = 0; i < options.length - 1; i++) {
                      String base64Path = await compressBase64Image(options[i]['input_image']);
                      base64Path = 'data:image/png;base64,$base64Path';
                      base64Array.add(base64Path);
                    }
                    payload['base64Array'] = base64Array;
                    dio.Response response;
                    try {
                      response = await myApi.selfMjBlend(payload);
                      if (response.statusCode == 200) {
                        if (response.data is String) {
                          response.data = jsonDecode(response.data);
                        }
                        int code = response.data['code'];
                        if (code == 1) {
                          String result = response.data['result'];
                          Map<String, dynamic> job = {result: '融图任务', 'radio': radio};
                          createTaskQueue(job);
                        } else {
                          if (context.mounted) {
                            showHint('MJ融图任务提交失败,原因是${response.data['description']}');
                            commonPrint('MJ融图任务提交失败,原因是${response.data['description']}');
                          }
                        }
                      } else {
                        if (context.mounted) {
                          showHint('MJ融图任务提交失败,原因是${response.statusMessage}');
                          commonPrint('MJ融图任务提交失败,原因是${response.statusMessage}');
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showHint('MJ融图任务提交失败,原因是$e');
                        commonPrint('MJ融图任务提交失败,原因是$e');
                      }
                    }
                  } else {
                    int lastImageNum = imageBase64List.length;
                    Map<String, dynamic> payload = {};
                    for (int i = 0; i < options.length; i++) {
                      payload['image_url$i+1'] = options[i]['input_image'];
                    }
                    dio.Response response;
                    try {
                      showHint('知数云MJ融图中...', showType: 5);
                      response = await myApi.mjBlend(token, payload);
                      if (response.statusCode == 200) {
                        response.data.stream.listen((data) async {
                          final decodedData = utf8.decode(data);
                          final jsonData = json.decode(decodedData);
                          int progress = jsonData['progress'];
                          if (mounted) {
                            showHint('MJ融图的绘制进度是$progress%');
                          }
                          if (progress == 100) {
                            List<String> base64Urls = await splitImage(jsonData['image_url']);
                            List<ImageItemModel> tempImages = [];
                            for (int i = 0; i < base64Urls.length; i++) {
                              String imageUrl = '';
                              String filePath = '';
                              File file = await base64ToTempFile(base64Urls[i]);
                              if (file.existsSync()) {
                                filePath = file.path;
                              }
                              if (filePath != '') {
                                imageUrl = await uploadFileToALiOss(filePath, imageUrl, file);
                              }
                              ImageItemModel imageItemModel = ImageItemModel(i, jsonData['image_id'], true, false, base64Urls[i], jsonData['actions'],
                                  1, '', false, GlobalParams.filesUrl + imageUrl, false, false);
                              tempImages.add(imageItemModel);
                            }
                            int currentImageNum = imageBase64List.length;
                            if (currentImageNum != lastImageNum && currentImageNum >= 4) {
                              imageBase64List.removeRange(imageBase64List.length - 4, imageBase64List.length);
                            }
                            // imageBase64List.addAll(tempImages);
                            imageViewKey.currentState?.insertImageData(tempImages, lastImageNum, currentImageNum, 1);
                            _scrollToTop();
                          }
                        });
                      } else {
                        if (context.mounted) {
                          showHint('mj绘图失败,原因是${response.statusMessage}', showType: 3);
                          commonPrint('mj绘图失败1,原因是${response.statusMessage}');
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showHint('知数云MJ融图失败，原因是$e');
                      }
                    }
                  }
                },
              ));
        },
      );
    }
  }

  Future<void> _mjShortenPrompt(String content) async {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomDialog(
              title: null,
              titleColor: Colors.white,
              showConfirmButton: false,
              showCancelButton: false,
              contentBackgroundColor: Colors.black,
              contentBackgroundOpacity: 0.5,
              description: null,
              descColor: Colors.white,
              useScrollContent: false,
              maxWidth: 420,
              minWidth: 380,
              minHeight: 300,
              maxHeight: 600,
              content: ShortenPromptOption(
                originalPrompt: content,
                onConfirm: (newPrompt) {
                  Navigator.of(context).pop();
                  _picContentTextFieldController.text = newPrompt;
                },
              ));
        },
      );
    }
  }

  Future<void> loadSettings() async {
    myApi = MyApi();
    Map<String, dynamic> settings = await Config.loadSettings();
    if (mounted) {
      setState(() {
        drawEngine = settings['drawEngine'] ?? 0;
        if (drawEngine == 0) {
          _getControlNetModels();
          _getControlNetModules();
        }
      });
    }
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<void> haveChangedSettings() async {
    changeSettings = Provider.of<ChangeSettings>(context);
    Map<String?, dynamic> map = changeSettings.changeValues;
    map.forEach((key, value) async {
      if (key != null && value != null) {
        if (key == 'drawEngine') {
          setState(() {
            drawEngine = value;
            _getControlNetModels();
            _getControlNetModules();
          });
        }
      }
    });
  }

  Future<void> _getControlNetModels() async {
    String url;
    Map<String, dynamic> settings = await Config.loadSettings();
    url = settings['sdUrl'] ?? "";
    if (url != "") {
      try {
        dio.Response response = await myApi.getSDControlNetModels(url);
        if (response.statusCode == 200) {
          List<dynamic>? models = response.data['model_list'];
          if (models != null && models.isNotEmpty) {
            for (String model in models) {
              if (!_controlModels.contains(model)) {
                _controlModels.add(model);
              }
            }
          }
        } else {
          if (mounted) {
            showHint('获取controlNet模型失败，请检查sd相关设置', showType: 3);
          }
        }
      } catch (e) {
        commonPrint('获取controlNet模型失败，原因是$e');
      }
    }

    // _initSettings();
    // setState(() {});
  }

  Future<void> _getControlNetModules() async {
    String url;
    Map<String, dynamic> settings = await Config.loadSettings();
    url = settings['sdUrl'] ?? "";
    if (url != "") {
      try {
        dio.Response response = await myApi.getSDControlNetModules(url);
        if (response.statusCode == 200) {
          List<dynamic>? models = response.data['module_list'];
          if (models != null && models.isNotEmpty) {
            for (String model in models) {
              if (!_controlModules.contains(model)) {
                _controlModules.add(model);
              }
            }
          }
        } else {
          if (mounted) {
            showHint('获取controlNet预处理器失败，请检查sd相关设置', showType: 3);
          }
        }
      } catch (e) {
        commonPrint('获取controlNet预处理器失败，原因是$e');
      }
    }
    // setState(() {});
  }

  Future<void> _showSet() async {
    final changeSettings = context.read<ChangeSettings>();
    if (mounted) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomDialog(
                title: null,
                titleColor: changeSettings.getForegroundColor(),
                showConfirmButton: false,
                showCancelButton: false,
                contentBackgroundColor: changeSettings.getBackgroundColor(),
                useScrollContent: false,
                maxWidth: 500,
                minWidth: 380,
                minHeight: 300,
                maxHeight: (Platform.isWindows || Platform.isMacOS) ? 720 : 520,
                content: drawEngine == 0
                    ? ControlNetOptionWidget(
                        controlModels: _controlModels,
                        controlModules: _controlModules,
                        controlTypes: _controlTypes,
                        controlNetOptions: controlNetOptions,
                        canAddOrDelete: true,
                        onConfirm: (options) {
                          controlNetOptions = options;
                          Navigator.of(context).pop();
                        },
                      )
                    : MidjourneySettingsView(
                        options: _mjOptions,
                        onConfirm: (finalOptions) {
                          _mjOptions = finalOptions;
                          finalOptions.forEach((key, value) {
                            if (key == 'MID_JOURNEY' || key == 'NIJI_JOURNEY') {
                              mjBotType = key;
                              mjOptions = value;
                            }
                            if (key == 'characterImages') {
                              characterImages = value;
                            }
                            if (key == 'referenceImages') {
                              referenceImages = value;
                            }
                          });
                        },
                      ));
          });
    }
  }

  Future<void> _downloadAll() async {
    if (imageBase64List.isNotEmpty) {
      showHint('开始保存图片,保存完成后会有提示');
      if (_selectedIndexes.isNotEmpty) {
        for (var index in _selectedIndexes) {
          String imageUrl = imageBase64List[index].imageUrl;
          await saveImageToDirectory('', context, isShowHint: false, imageUrl: imageUrl);
          imageBase64List[index].downloaded = true;
          imageViewKey.currentState?.refreshImage(index, imageBase64List[index]);
        }
        imageViewKey.currentState?.exitSelectionMode();
      } else {
        for (var i = 0; i < imageBase64List.length; i++) {
          if (!imageBase64List[i].downloaded) {
            String imageUrl = imageBase64List[i].imageUrl;
            await saveImageToDirectory(imageBase64List[i].base64Url, context, isShowHint: false, imageUrl: imageUrl);
            imageBase64List[i].downloaded = true;
            imageViewKey.currentState?.refreshImage(i, imageBase64List[i]);
          }
        }
      }
      showHint('图片保存完成', showType: 2);
    } else {
      if (mounted) {
        showHint('此页面没有可保存的图片');
      }
    }
  }

  void _clearAll() {
    final settings = context.read<ChangeSettings>();
    if (mounted) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomDialog(
                title: _selectedIndexes.isEmpty ? '清空提示' : '删除提示',
                titleColor: settings.getForegroundColor(),
                showConfirmButton: true,
                showCancelButton: true,
                confirmButtonText: '确认',
                cancelButtonText: '取消',
                conformButtonColor: settings.getSelectedBgColor(),
                contentBackgroundColor: settings.getBackgroundColor(),
                contentBackgroundOpacity: 0.5,
                description: _selectedIndexes.isEmpty ? '确认清空所有图片吗?\n注意：这里的清空不会删除云端数据，只是此次展示删除' : '确认删除选中的图片吗? 注意这里的删除会在云端数据中标记这些图片已删除。',
                descColor: settings.getForegroundColor(),
                useScrollContent: false,
                onConfirm: () async {
                  if (_selectedIndexes.isEmpty) {
                    imageBase64List.clear();
                    imageViewKey.currentState?.clearAll();
                  } else {
                    List<String> needDeleteKeys = [];
                    for (var currentIndex in _selectedIndexes) {
                      var imageKey = imageBase64List[currentIndex].imageKey!;
                      needDeleteKeys.add(imageKey);
                    }
                    imageViewKey.currentState?.deleteSelectedItems();
                    _selectedIndexes.clear();
                    for (var imageKey in needDeleteKeys) {
                      await SupabaseHelper().update('images', {'is_delete': 1}, updateMatchInfo: {'key': imageKey});
                    }
                  }
                },
                onCancel: () {});
          });
    }
  }

  Future<void> _deleteCurrentImage(int currentIndex) async {
    if (mounted) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            final settings = context.watch<ChangeSettings>();
            return CustomDialog(
                title: '删除提示',
                titleColor: settings.getForegroundColor(),
                showConfirmButton: true,
                showCancelButton: true,
                confirmButtonText: '确认',
                cancelButtonText: '取消',
                contentBackgroundColor: settings.getBackgroundColor(),
                description: '确认删除此图片吗? 注意这里的删除会在云端数据中标记此图片已删除。',
                descColor: settings.getForegroundColor(),
                useScrollContent: false,
                conformButtonColor: settings.getSelectedBgColor(),
                onConfirm: () async {
                  var imageKey = imageBase64List[currentIndex].imageKey!;
                  imageViewKey.currentState?.deleteCurrent(currentIndex);
                  await SupabaseHelper().update('images', {'is_delete': 1}, updateMatchInfo: {'key': imageKey});
                },
                onCancel: () {});
          });
    }
  }

  Future<void> _selectPic() async {
    // if (drawEngine == 1) {
    FilePickerResult? result = await FilePickerManager().pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'png', 'jpeg']);

    if (result != null) {
      inputImagePath = await imageToBase64(result.files.single.path!);
      if (drawEngine == 1 || drawEngine == 0) {
        selectedImageList.clear();
        selectedImageList.add('data:image/png;base64,$inputImagePath');
        controlNetOptions = [];
        setState(() {});
      } else if (drawEngine == 2) {
        selectedImageList.remove('');
        if (selectedImageList.length < 3) {
          inputImagePath = await compressBase64Image(inputImagePath);
          selectedImageList.add('data:image/png;base64,$inputImagePath');
          controlNetOptions = [];
          setState(() {});
        } else {
          if (mounted) {
            showHint('底图请不要超过三张，如需上传其他请先删除之前的');
          }
        }
      }
    }
  }

  void _onImageClick(int index) async {
    FocusScope.of(context).unfocus();
    final settings = context.read<ChangeSettings>();
    int currentIndex = imageBase64List.indexWhere((element) => element.imageUrl == imageBase64List[index].imageUrl);
    if (mounted) {
      showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return Stack(
              children: [
                ExtendedImageGesturePageView.builder(
                  itemBuilder: (BuildContext context, int index) {
                    var item = imageBase64List[index].imageUrl;
                    Widget image = ExtendedImage.network(
                      item,
                      fit: BoxFit.contain,
                      mode: ExtendedImageMode.gesture,
                      initGestureConfigHandler: (state) {
                        return GestureConfig(
                          inPageView: true,
                          initialScale: 0.5,
                          minScale: 0.4,
                          maxScale: 1.0,
                          animationMaxScale: 1.0,
                          initialAlignment: InitialAlignment.center,
                        );
                      },
                    );
                    image = Container(
                      padding: const EdgeInsets.all(5.0),
                      child: image,
                    );
                    if (index == currentIndex) {
                      return Hero(
                        tag: item + index.toString(),
                        child: image,
                      );
                    } else {
                      return image;
                    }
                  },
                  itemCount: imageBase64List.length,
                  onPageChanged: (int index) {
                    currentIndex = index;
                  },
                  controller: ExtendedPageController(
                    initialPage: currentIndex,
                  ),
                  scrollDirection: Axis.horizontal,
                ),
                Positioned(
                  bottom: 20,
                  right: 0,
                  left: 0,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(128),
                            shape: BoxShape.circle,
                          ),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            child: const Icon(
                              Icons.close,
                              size: 30,
                              color: Colors.white,
                            ),
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(128),
                            shape: BoxShape.circle,
                          ),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            child: const Icon(
                              Icons.download,
                              size: 30,
                              color: Colors.white,
                            ),
                            onTap: () async {
                              var imageUrl = imageBase64List[currentIndex].imageUrl;
                              String extension = imageUrl.split('.').last;
                              String currentTime = getCurrentTimestamp();
                              String? outputFile = await FilePickerManager().saveFile(
                                dialogTitle: '选择文件保存位置',
                                fileName: '$currentTime.$extension',
                              );
                              if (outputFile != null) {
                                await myApi.downloadSth(imageUrl, outputFile, onReceiveProgress: (progress, total) {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (getRealDarkMode(settings))
                  IgnorePointer(
                      child: Container(
                    color: Colors.black.withAlpha(128),
                  ))
              ],
            );
          });
    }
  }

  @override
  void initState() {
    super.initState();
    _textFieldController = TextEditingController(text: "1");
    _modifyTextFieldController = TextEditingController();
    _picContentTextFieldController = TextEditingController();
    _selfScaleTextFieldController = TextEditingController();
    imageViewKey = GlobalKey<ImageViewState>();
    stackedImageViewerController = StackedImageViewerController();
    imageView = ImageView(
      key: imageViewKey,
      imageBase64List: imageBase64List,
      context: context,
      onUpScale: (index) => _onUpScale(index),
      onUpScaleRepair: (index) => _onUpScaleRepairImage(index),
      furtherOperations: (index, id, name) => _furtherOperations(index, id, name),
      isInGallery: widget.isGallery,
      onImageClick: (index) => _onImageClick(index),
      onSelectionChange: (selectedIndexes) {
        setState(() {
          _selectedIndexes = selectedIndexes;
        });
      },
    );
    loadSettings();
    listenStorage();
  }

  Future<void> readImagesFromDatabase({int pageNum = 0, int pageSize = 20}) async {
    try {
      // showLoading('正在读取图片');
      Map<String, dynamic> settings = await Config.loadSettings();
      String userId = settings['user_id'] ?? '';
      var isLogin = settings['is_login'] ?? false;
      if (pageNum == 0) {
        currentDatabaseId = 10000;
      }
      var matchMap = widget.isGallery ? {'is_public': 1, 'is_delete': 0} : {'user_id': userId, 'is_delete': 0};
      var data = await SupabaseHelper().query(
        'images',
        matchMap,
        limitNum: pageSize,
        ltName: 'id',
        ltValue: currentDatabaseId,
      );
      images.clear();
      // commonPrint(data);
      if (!widget.isGallery) {
        if (isLogin) {
          for (int i = 0; i < data.length; i++) {
            images.add(data[i]['info']);
          }
          // images = await SupabaseHelper().query('images', {'user_id': userId, 'is_delete': 0},
          //     limitNum: pageSize, ltName: 'id', ltValue: currentDatabaseId, selectInfo: 'info');
        }
      } else {
        for (int i = 0; i < data.length; i++) {
          images.add(data[i]['info']);
        }
      }

      if (images.isNotEmpty) {
        if (images.length < pageSize) {
          _hasMore = false;
        }
        // commonPrint(imageBase64List.length);
        for (var i = 0; i < images.length; i++) {
          // var image = jsonDecode(images[i]['info']);
          var image = jsonDecode(images[i]);
          if (widget.isGallery) {
            image['isPublic'] = true;
          } else {
            image['isPublic'] = false;
          }
          ImageItemModel imageItemModel = ImageItemModel.fromJson(image);
          List<ImageItemModel> imagesList = [];
          imagesList.add(imageItemModel);
          imageViewKey.currentState?.insertImageData(imagesList, imageBase64List.length, 0, imageItemModel.drawEngine);
        }
        currentDatabaseId = data.last['id'];
      } else {
        if (pageNum == 0) {
          imageViewKey.currentState?.clearAll();
          setState(() {
            isFirstPageNoData = true;
          });
        }
      }
    } catch (e) {
      commonPrint('在线图片读取失败，原因是$e');
      dismissHint();
    } finally {
      dismissHint();
    }
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(milliseconds: 400), () {
        if (imageBase64List.isNotEmpty) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  void removeImage() {
    setState(() {
      inputImagePath = '';
      controlNetOptions = [];
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    Map settings = await Config.loadSettings();
    bool isLogin = settings['is_login'] ?? false;
    if (!isLogin) {
      if (mounted) {
        showHint('请先登录');
      }
      _refreshController.refreshCompleted();
      setState(() {
        isFirstPageNoData = true;
      });
      return;
    }
    if (_isLoading) return; // 如果正在加载，直接返回
    _isLoading = true;
    // setState(() {
    imageBase64List.clear();
    imageViewKey.currentState?.clearAll();
    pageNum = 0;
    _hasMore = true;
    _refreshController.resetNoData();
    await readImagesFromDatabase();
    _refreshController.refreshCompleted();
    _isLoading = false; // 重新解锁
    // });
  }

  Future<void> _loadMore() async {
    Map settings = await Config.loadSettings();
    bool isLogin = settings['is_login'] ?? false;
    if (!isLogin) {
      if (mounted) {
        showHint('请先登录');
      }
      return;
    }
    if (_isLoading) return; // 如果正在加载，直接返回
    _isLoading = true;
    if (_hasMore) {
      pageNum = pageNum + 1;
      await readImagesFromDatabase(pageNum: pageNum);
      _refreshController.loadComplete();
      _isLoading = false; // 重新解锁
    } else {
      if (mounted) {
        showHint('暂无更多数据');
      }
      _refreshController.loadNoData();
      _isLoading = false; // 重新解锁
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChangeSettings>(builder: (context, settings, child) {
      settings.changeValues.forEach((key, value) {
        if (value != null) {
          if (key == 'drawEngine') {
            drawEngine = value;
            if (drawEngine == 0) {
              _getControlNetModels();
              _getControlNetModules();
            }
          }
        }
      });
      return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
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
                  filter: ui.ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
              Column(
                children: <Widget>[
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand, // 添加这个
                      children: [
                        Padding(
                            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                            child: SmartRefresher(
                              controller: _refreshController,
                              onRefresh: _refresh,
                              onLoading: _loadMore,
                              enablePullUp: true,
                              enablePullDown: true,
                              child: ListView(
                                controller: _scrollController,
                                children: [imageView],
                              ),
                            )),
                        Visibility(
                            visible: isFirstPageNoData,
                            child: const Center(
                                child: Text(
                              '未登录或者暂无数据',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ))),
                        // 浮动按钮
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
                              await _loadMore();
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
                    ),
                  ),
                  Visibility(
                    visible: !widget.isGallery,
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8, right: 8),
                          child: Row(children: <Widget>[
                            Visibility(
                              visible: drawEngine == 0 || drawEngine == 2,
                              child: Row(children: [
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: InkWell(
                                    onTap: _selectPic,
                                    child: Tooltip(
                                        message: '上传输入图片',
                                        child: inputImagePath == ''
                                            ? Container(
                                                width: 40,
                                                height: 40,
                                                padding: const EdgeInsets.all(8.0),
                                                decoration: BoxDecoration(
                                                  color: settings.getSelectedBgColor(),
                                                  borderRadius: BorderRadius.circular(20.0),
                                                ),
                                                child: SvgPicture.asset('assets/images/upload_image.svg',
                                                    colorFilter: ColorFilter.mode(settings.getCardTextColor(), BlendMode.srcIn),
                                                    semanticsLabel: '上传输入图片'),
                                              )
                                            : StackedImageViewer(
                                                imageSources: selectedImageList,
                                                controller: stackedImageViewerController,
                                                onPressed: _selectPic,
                                                onImageLongPressed: (image) {
                                                  if (mounted) {
                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext context) {
                                                        return CustomDialog(
                                                          title: '反推图片标签',
                                                          titleColor: settings.getForegroundColor(),
                                                          showConfirmButton: false,
                                                          showCancelButton: false,
                                                          contentBackgroundColor: settings.getBackgroundColor(),
                                                          description: null,
                                                          maxWidth: 420,
                                                          minWidth: 380,
                                                          content: GetImageTagsWidget(
                                                            interrogators: const [],
                                                            base64Image: image,
                                                            drawEngine: drawEngine,
                                                            imageUrl: '',
                                                            onTaggerClicked: (String tagger) {
                                                              setState(() {
                                                                _picContentTextFieldController.text = tagger;
                                                              });
                                                            },
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  }
                                                },
                                              )),
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ]),
                            ),
                            Visibility(
                              visible: drawEngine == 0 || drawEngine == 3 || drawEngine == 4,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 90,
                                    child: TextField(
                                      style: const TextStyle(color: Colors.yellowAccent),
                                      controller: _textFieldController,
                                      decoration: const InputDecoration(
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.white, width: 2.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.white, width: 2.0),
                                          ),
                                          labelText: '作图数量',
                                          labelStyle: TextStyle(color: Colors.white)),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                              ),
                            ),
                            Expanded(
                              child: KeyboardListener(
                                focusNode: FocusNode(),
                                onKeyEvent: (event) async {
                                  if (event is KeyDownEvent) {
                                    if (event.logicalKey == LogicalKeyboardKey.enter) {
                                      if (HardwareKeyboard.instance.isShiftPressed) {
                                        // Shift + Enter，插入换行符
                                        final currentText = _picContentTextFieldController.text;
                                        final selection = _picContentTextFieldController.selection;
                                        final newText = currentText.replaceRange(
                                          selection.start,
                                          selection.end,
                                          '\n',
                                        );
                                        _picContentTextFieldController.value = TextEditingValue(
                                          text: newText,
                                          selection: TextSelection.collapsed(
                                            offset: selection.start + 1,
                                          ),
                                        );
                                      } else {
                                        // 普通回车，触发提交
                                        await onGenerate(context);
                                      }
                                    }
                                  }
                                },
                                child: InkWell(
                                  onDoubleTap: () {
                                    if ((drawEngine == 2 || drawEngine == 1)) {
                                      _mjBlendImage();
                                    }
                                  },
                                  child: TextField(
                                    style: const TextStyle(color: Colors.yellowAccent),
                                    controller: _picContentTextFieldController,
                                    maxLines: 3,
                                    minLines: 1,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (value) {
                                      if (Platform.isAndroid || Platform.isIOS) {
                                        onGenerate(context);
                                      }
                                    },
                                    onChanged: (content) {
                                      if (content.length > 10 && drawEngine == 2) {
                                        isShortenVisibility.value = true;
                                      } else {
                                        isShortenVisibility.value = false;
                                      }
                                    },
                                    inputFormatters: [
                                      TextInputFormatter.withFunction((oldValue, newValue) {
                                        // 阻止直接输入换行符，除非是通过我们的Shift+Enter逻辑
                                        if (newValue.text.length > oldValue.text.length) {
                                          final addedChar = newValue.text.substring(oldValue.text.length);
                                          if (addedChar == '\n') {
                                            return oldValue;
                                          }
                                        }
                                        return newValue;
                                      }),
                                    ],
                                    decoration: const InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white, width: 2.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white, width: 2.0),
                                      ),
                                      labelText: '请输入要绘制的图片内容，留空图片将完全随机',
                                      labelStyle: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (Platform.isWindows || Platform.isMacOS) ...[
                              Row(
                                children: [
                                  Checkbox(
                                    value: publicImage == 1,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        publicImage = value == true ? 1 : 0;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 2),
                                  const Tooltip(
                                    message: '勾选后，图片也会显示在画廊中',
                                    child: Text(
                                      '图片公开',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              Obx(() => Visibility(
                                  visible: isShortenVisibility.value && drawEngine != 0 && drawEngine != 3 && drawEngine != 4,
                                  child: Row(
                                    children: [
                                      ElevatedButton(
                                          style: ButtonStyle(backgroundColor: WidgetStateProperty.all(settings.getSelectedBgColor())),
                                          onPressed: () async {
                                            _mjShortenPrompt(_picContentTextFieldController.text);
                                          },
                                          child: Text('MJ优化提示词', style: TextStyle(color: settings.getCardTextColor()))),
                                      const SizedBox(width: 10),
                                      ElevatedButton(
                                          style: ButtonStyle(backgroundColor: WidgetStateProperty.all(settings.getSelectedBgColor())),
                                          onPressed: () async {
                                            _optimizationPrompts(_picContentTextFieldController.text);
                                          },
                                          child: Text('AI优化并生成', style: TextStyle(color: settings.getCardTextColor()))),
                                      const SizedBox(width: 10),
                                    ],
                                  ))),
                              ElevatedButton(
                                  style: ButtonStyle(backgroundColor: WidgetStateProperty.all(settings.getSelectedBgColor())),
                                  onPressed: () async {
                                    await onGenerate(context);
                                  },
                                  child: Text(
                                    '直接作图',
                                    style: TextStyle(color: settings.getCardTextColor()),
                                  )),
                              Visibility(
                                  visible: drawEngine == 0,
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: InkWell(
                                          onTap: _showSet,
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
                                              child: SvgPicture.asset('assets/images/tb-app.svg',
                                                  colorFilter: ColorFilter.mode(settings.getCardTextColor(), BlendMode.srcIn),
                                                  semanticsLabel: '控制选项'),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                  )),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: InkWell(
                                  onTap: () async {
                                    _downloadAll();
                                  },
                                  child: Tooltip(
                                    message: _selectedIndexes.isEmpty ? '保存当前列表的全部图片' : '保存选中图片',
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        color: settings.getSelectedBgColor(),
                                        borderRadius: BorderRadius.circular(20.0),
                                      ),
                                      child: SvgPicture.asset('assets/images/save_all.svg',
                                          colorFilter: ColorFilter.mode(settings.getCardTextColor(), BlendMode.srcIn), semanticsLabel: '保存全部图片'),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: InkWell(
                                  onTap: () {
                                    _clearAll();
                                  },
                                  child: Tooltip(
                                    message: _selectedIndexes.isEmpty ? '清空当前列表全部图片' : '删除选中图片',
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        color: settings.getSelectedBgColor(),
                                        borderRadius: BorderRadius.circular(20.0),
                                      ),
                                      child: SvgPicture.asset('assets/images/clear.svg',
                                          colorFilter: ColorFilter.mode(settings.getCardTextColor(), BlendMode.srcIn), semanticsLabel: '清空全部图片'),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            Visibility(
                              visible: drawEngine != 0 && drawEngine != 3 && drawEngine != 4,
                              child: Row(
                                children: [
                                  const SizedBox(width: 5),
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: InkWell(
                                      onTap: _showSet,
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
                                          child: SvgPicture.asset('assets/images/tb-app.svg',
                                              colorFilter: ColorFilter.mode(settings.getCardTextColor(), BlendMode.srcIn), semanticsLabel: '控制选项'),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          )));
    });
  }

  Future<void> onGenerate(BuildContext context) async {
    if (selectedImageList.isNotEmpty) {
      if (selectedImageList.first == '') {
        inputImagePath = '';
        preInputImagePath = '';
      }
    } else {
      inputImagePath = '';
      preInputImagePath = '';
    }
    if (inputImagePath != '' && drawEngine == 0) {
      await sdRedraw();
    } else {
      await _generateImage(context);
    }
  }
}
