import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:dio/dio.dart' as dio;
import 'package:extended_image/extended_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/config/global_params.dart';
import '../config/config.dart';
import '../json_models/control_net_unit.dart';
import '../json_models/deal_result.dart';
import '../json_models/item_model.dart';
import '../net/my_api.dart';
import '../params/prompts.dart';
import '../params/prompts_styles.dart';
import '../utils/common_methods.dart';
import '../utils/file_picker_manager.dart';
import '../widgets/control_net_option.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/image_show_view.dart';
import '../widgets/redraw_option.dart';

class AIArtImagesView extends StatefulWidget {
  const AIArtImagesView({super.key});

  @override
  State<AIArtImagesView> createState() => _AIArtImagesViewState();
}

class _AIArtImagesViewState extends State<AIArtImagesView> {
  late TextEditingController _textFieldController;
  late TextEditingController _picContentTextFieldController;
  List<ImageItemModel> imageBase64List = [];
  List<String> imageBase64ParameterList = [];
  final ScrollController _scrollController = ScrollController();
  late MyApi myApi;
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
  List<String> loraPrompts = [
    'lora:cuteGirlMix4_v10',
    'lora:koreandolllikenessV20_v20',
    'lora:taiwanDollLikeness_v20',
    'lora:japanesedolllikenessV1_v15'
  ];
  List<double> loraWeights = [];
  String combinedLoraPromptsString = '';
  int specialIndex = 0;
  final List<String> _controlTypes = ['All'].obs;
  final List<String> _controlModels = ['无'].obs;
  final List<String> _controlModules = ['无'].obs;
  String imagePath = '';
  List<Map<String, dynamic>> controlNetOptions = [];
  late ImageView imageView;
  late GlobalKey<ImageViewState> imageViewKey;

  Future<void> _getControlNetModels() async {
    String url;
    Map<String, dynamic> settings = await Config.loadSettings();
    url = settings['sdUrl'] ?? '';
    try {
      dio.Response response = await myApi.getSDControlNetModels(url);
      if (response.statusCode == 200) {
        List<dynamic>? models = response.data['model_list'];
        if (models != null && models.isNotEmpty) {
          for (String model in models) {
            if (!_controlModels.contains(model)) {
              if (model.contains('brightness') || model.contains('qrcode_monster') || model.contains('QRPattern')) {
                _controlModels.add(model);
              }
            }
          }
        }
      } else {
        showHint('获取controlNet模型失败，请检查sd相关设置', showType: 3);
      }
    } catch (e) {
      commonPrint('获取controlNet模型失败，原因是$e');
    }
    // _initSettings();
    setState(() {});
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
          showHint('获取controlNet预处理器失败，请检查sd相关设置', showType: 3);
        }
      } catch (e) {
        commonPrint('获取controlNet预处理器失败，原因是$e');
      }
    }
    // setState(() {});
  }

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
        String combinedPrompts =
            (promptList as List<List<dynamic>>).map((subList) => subList[Random().nextInt(subList.length)]).join(", ");
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
      List<double> weights = List<double>.generate(numWeights - 1,
          (_) => double.parse((Random().nextDouble() * (maxSum - minWeight * (numWeights - 1)) + minWeight).toStringAsFixed(1)));

      if (specialIndex != null) {
        double specialWeight =
            double.parse((Random().nextDouble() * (specialMax! - specialMin!) + specialMin).toStringAsFixed(1));
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

  Future<void> _downloadAll() async {
    if (imageBase64List.isNotEmpty) {
      showHint('开始保存图片,保存完成后会有提示', showType: 5);
      for (var i = 0; i < imageBase64List.length; i++) {
        if (!imageBase64List[i].downloaded) {
          await saveImageToDirectory(imageBase64List[i].base64Url, context, isShowHint: false);
          imageBase64List[i].downloaded = true;
        }
      }
      showHint('图片保存完成', showType: 2);
    } else {
      showHint('此页面没有可保存的图片', showType: 3);
    }
  }

  Future<void> initData() async {
    final savedSettings = await Config.loadSettings();
    String sdUrl = savedSettings['sdUrl'] ?? '';
    if (sdUrl.isNotEmpty) {
      _getControlNetModels();
      _getControlNetModules();
    }
  }

  @override
  void initState() {
    _textFieldController = TextEditingController(text: "1");
    _picContentTextFieldController = TextEditingController();
    myApi = MyApi();
    imageViewKey = GlobalKey<ImageViewState>();
    imageView = ImageView(
      key: imageViewKey,
      imageBase64List: imageBase64List,
      context: context,
      onUpScale: (index) => _onUpScale(index),
      onUpScaleRepair: (index) => _onUpScaleRepairImage(index),
      furtherOperations: _furtherOperations,
      onSelectionChange: (selectedIndexes) {
        // 处理选中项变化
        commonPrint('选中的图片索引: $selectedIndexes');
      },
    );
    showHint('此功能目前需要配置Stable diffusion API地址，请先配置，否则无法使用，后续功能将会升级。');
    initData();
    super.initState();
  }

  Future<void> _selectPic() async {
    FilePickerResult? result =
        await FilePickerManager().pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'png', 'jpeg']);
    if (result != null) {
      imagePath = result.files.single.path!;
      _initSettings();
    }
  }

  void _initSettings() async {
    controlNetOptions = List<Map<String, dynamic>>.from([]);
    ControlNetUnit controlNetUnit1 = ControlNetUnit();
    ControlNetUnit controlNetUnit2 = ControlNetUnit();
    ControlNetUnit controlNetUnit3 = ControlNetUnit();
    controlNetUnit1.model = _controlModels[2];
    controlNetUnit2.model = _controlModels[1];
    controlNetUnit3.model = _controlModels[3];
    controlNetUnit2.guidanceStart = 0.2;
    controlNetUnit2.guidanceEnd = 0.8;
    controlNetUnit2.weight = 0.4;
    controlNetUnit3.isEnable = false;
    var controlNetUnit1Json = controlNetUnit1.toJson();
    var controlNetUnit2Json = controlNetUnit2.toJson();
    var controlNetUnit3Json = controlNetUnit3.toJson();
    if (imagePath != '') {
      String base64Path = await imageToBase64(imagePath);
      controlNetUnit1Json['input_image'] = base64Path;
      controlNetUnit2Json['input_image'] = base64Path;
      controlNetUnit3Json['input_image'] = base64Path;
    }
    controlNetOptions.add(controlNetUnit1Json);
    controlNetOptions.add(controlNetUnit2Json);
    controlNetOptions.add(controlNetUnit3Json);
  }

  void _showSet() async {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomDialog(
            title: null,
            showConfirmButton: false,
            showCancelButton: false,
            contentBackgroundColor: Colors.black,
            contentBackgroundOpacity: 0.5,
            description: null,
            useScrollContent: false,
            maxWidth: 420,
            minWidth: 380,
            minHeight: 500,
            content: ControlNetOptionWidget(
              controlModels: _controlModels,
              controlModules: _controlModules,
              controlTypes: _controlTypes,
              controlNetOptions: controlNetOptions,
              canAddOrDelete: false,
              onConfirm: (options) {
                controlNetOptions = options;
                Navigator.of(context).pop();
              },
            ),
          );
        },
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(milliseconds: 400), () {
        _scrollController.animateTo(
          0,
          // _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    });
  }

  Future<void> createImage(BuildContext context, {bool isUpScaleRepair = false, int imagePosition = 0}) async {
    Map<String, dynamic> defaultPromptDict = {
      "0.无": promptsStyles['None'],
      "1.基本提示(通用)": promptsStyles['default_prompts'],
      "2.基本提示(通用修手)": promptsStyles['default_prompts_fix_hands'],
      "3.基本提示(增加细节1)": promptsStyles['default_prompts_add_details_1'],
      "4.基本提示(增加细节2)": promptsStyles['default_prompts_add_details_2'],
      "5.基本提示(梦幻童话)": promptsStyles['default_prompts_fairy_tale']
    };
    String useImagePath = '';
    if (isUpScaleRepair) {
      useImagePath = imageBase64List[imagePosition].base64Url;
    }
    Map<String, dynamic> settings = await Config.loadSettings();
    bool useFaceRestore = settings['restore_face'];
    bool useHiresFix = settings['hires_fix'];
    bool combinedPositivePrompts = settings['is_compiled_positive_prompts'];
    bool useSelfPositivePrompts = settings['use_self_positive_prompts'];
    bool useSelfNegativePrompts = settings['use_self_negative_prompts'];
    String defaultPositivePromptType = settings['default_positive_prompts_type'].toString();
    String combinedPositivePromptsTypes = settings['compiled_positive_prompts_type'];
    String defaultPositivePrompts = '';
    String defaultNegativePrompts = settings['self_negative_prompts'];
    String sdUrl = settings['sdUrl'] ?? '';
    int? imageNum = int.tryParse(_textFieldController.text);
    if (isUpScaleRepair) {
      imageNum = 1;
    }
    String imageContent = _picContentTextFieldController.text;
    int? height = settings['height'];
    int? width = settings['width'];
    DealResult result = DealResult(
        width: width ?? 512, height: height ?? 512, pm: false, negativePrompt: "", isReal: false, addRandomPrompts: false);

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
        realImageContent = imageContent.substring(0, index);
      } else {
        realImageContent = imageContent;
      }
    }
    if (imageNum != null && imageNum > 0) {
      // imageBase64List.clear();
      imageBase64ParameterList.clear();
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
        requestBody['steps'] = settings['steps'];
        requestBody['width'] = !isUpScaleRepair ? result.width : (settings['newWidth'] ?? 512);
        requestBody['height'] = !isUpScaleRepair ? result.height : (settings['newHeight'] ?? 512);
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
                var imageInfoMap =
                    parseStringToMap(imageInfo['parameters']!.substring(paramsStartIndex, imageInfo['parameters']!.length));
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
        imageBase64ParameterList.add("(${requestBody['prompt']})");
        Map<String, dynamic> controlNetMap = {"args": []};
        Map<String, dynamic> aDetailerMap = {"args": []};
        Map<String, dynamic> alwaysOnScripts = {};
        List<Map<String, dynamic>> aDetailerMapCopies = List<Map<String, dynamic>>.from(settings['adetail_options'] ?? []);
        for (var element in aDetailerMapCopies) {
          if (element['is_enable'] != null && element['is_enable']) {
            element.remove('is_enable');
            if (element['ad_controlnet_model'] == '无') {
              element['ad_controlnet_model'] = 'None';
            }
            if (element['ad_controlnet_module'] == null) {
              element['ad_controlnet_module'] = 'None';
            }
            aDetailerMap['args'].add(element);
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
        dio.Response? response;
        try {
          showHint(isUpScaleRepair ? '图片重绘中...' : '第${imageBase64List.length + 1}张图片生成中...', showType: 5);
          response = await (isUpScaleRepair ? myApi.sdImage2Image(sdUrl, requestBody) : myApi.sdText2Image(sdUrl, requestBody));
          if (response.statusCode == 200) {
            dismissHint();
            if (response.data['images'] is List<dynamic>) {
              // for (int i = 0; i < response.data['images'].length; i++) {
              var firstImage = response.data['images'][0];
              if (isUpScaleRepair) {
                imageBase64List[imagePosition].base64Url = firstImage;
                // response.data['images'][i];
                imageViewKey.currentState?.refreshImage(imagePosition, imageBase64List[imagePosition]);
              } else {
                String imageUrl = '';
                String filePath = '';
                File file = await base64ToTempFile(firstImage);
                // await base64ToTempFile(response.data['images'][i]);
                if (file.existsSync()) {
                  filePath = file.path;
                }
                if (filePath != '') {
                  imageUrl = await uploadFileToALiOss(filePath, imageUrl, file);
                }
                ImageItemModel imageItemModel = ImageItemModel(0, "id", false, false, response.data['images'][0], [], 0, '',
                    false, GlobalParams.filesUrl + imageUrl, false, false,
                    isSquare: true);
                List<ImageItemModel> imageList = [];
                imageList.add(imageItemModel);
                imageViewKey.currentState?.insertImageData(imageList, 0, 0, 0);
                // imageBase64List.add(imageItemModel);
              }
            }
            // }
          } else {
            dismissHint();
            showHint('绘图失败，SD异常，请在设置页面查看SD配置。', showTime: 300, showPosition: 2, showType: 3);
          }
          setState(() {
            _scrollToBottom();
          });
        } catch (error) {
          dismissHint();
          showHint('绘图失败，SD异常，请在设置页面查看SD配置。', showTime: 300, showPosition: 2, showType: 3);
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
        showHint('$imageNum张图片已全部绘制完毕，希望你能喜欢', showTime: 3, showPosition: 2, showType: 2);
      }
    }
  }

  Future<void> _onUpScale(int currentIndex) async {
    dismissHint();
    int index = currentIndex;
    Map<String, dynamic> settings = await Config.loadSettings();
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
            dismissHint();
          } else {
            dismissHint();
            showHint('高清放大失败，原因是${response.data}', showTime: 3, showType: 3);
          }
        } catch (error) {
          dismissHint();
          showHint('高清放大失败，原因是$error', showTime: 3, showType: 3);
        }
      } else {
        EasyLoading.show(status: '没有已选中图片，跳过高清放大...');
      }
    }
  }

  Future<void> _furtherOperations(int currentIndex, int optionId, String optionName) async {
    int drawEngine = imageBase64List[currentIndex].drawEngine;
    Map<String, dynamic> settings = await Config.loadSettings();
    int systemDrawEngine = settings['drawEngine'] ?? 0;
    if (drawEngine != systemDrawEngine) {
      if (mounted) {
        showHint('该图片之前不是由目前所选绘图引擎绘制的，请切换到之前的绘图引擎');
        return;
      }
    }
    if (optionId == 10) {
      _getImageSeed(currentIndex, drawEngine);
    }
  }

  Future<void> _getImageSeed(int currentIndex, int drawEngine) async {
    if (drawEngine == 0) {
      String useImagePath = imageBase64List[currentIndex].base64Url;
      Uint8List decodedBytes = base64Decode(useImagePath);
      img.Image image = img.decodeImage(Uint8List.fromList(decodedBytes))!;
      var imageInfo = image.textData;
      try {
        if (imageInfo != null) {
          var paramsStartIndex = imageInfo['parameters']!.indexOf('Steps');
          if (paramsStartIndex != -1) {
            var imageInfoMap =
                parseStringToMap(imageInfo['parameters']!.substring(paramsStartIndex, imageInfo['parameters']!.length));
            var imageSeed = imageInfoMap['Seed'];
            if (imageSeed != null) {
              // setState(() {
              imageBase64List[currentIndex].seed = '$imageSeed';
              imageViewKey.currentState?.refreshImage(currentIndex, imageBase64List[currentIndex]);
              //   _scrollToBottom();
              // });
            } else {
              setState(() {
                imageBase64List[currentIndex].seed = '获取失败';
                _scrollToBottom();
              });
            }
          }
        }
      } catch (e) {
        setState(() {
          imageBase64List[currentIndex].seed = '获取失败';
        });
      }
    }
  }

  Future<void> _onUpScaleRepairImage(int currentIndex) async {
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
              createImage(context, isUpScaleRepair: true, imagePosition: currentIndex);
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return Stack(children: [
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
      Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                children: <Widget>[imageView],
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Row(children: <Widget>[
              SizedBox(
                width: 40,
                height: 40,
                child: InkWell(
                  onTap: _selectPic,
                  child: Tooltip(
                    message: '上传图片',
                    child: Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: settings.getSelectedBgColor(),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: SvgPicture.asset('assets/images/upload_image.svg',
                          colorFilter: ColorFilter.mode(settings.getCardTextColor(), BlendMode.srcIn), semanticsLabel: '上传输入图片'),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
              Expanded(
                child: TextField(
                    style: const TextStyle(color: Colors.yellowAccent),
                    controller: _picContentTextFieldController,
                    decoration: const InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white, width: 2.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white, width: 2.0),
                        ),
                        labelText: '请输入要绘制的图片内容，留空图片将完全随机',
                        labelStyle: TextStyle(color: Colors.white))),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                  style: ButtonStyle(backgroundColor: WidgetStateProperty.all(settings.getSelectedBgColor())),
                  onPressed: () async {
                    if (imagePath == '') {
                      showHint('请先点击左侧上传底图', showType: 3);
                    } else {
                      await createImage(context);
                    }
                  },
                  child: const Text(
                    '开始作图',
                    style: TextStyle(color: Colors.white),
                  )),
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
                          colorFilter: ColorFilter.mode(settings.getCardTextColor(), BlendMode.srcIn), semanticsLabel: '控制选项'),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 40,
                height: 40,
                child: InkWell(
                  onTap: () async {
                    _downloadAll();
                  },
                  child: Tooltip(
                    message: '保存全部图片',
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
            ]),
            const SizedBox(
              height: 16,
            ),
          ],
        ),
      )
    ]);
  }
}
