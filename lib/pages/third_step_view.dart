import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dio/dio.dart' as dio;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/global_params.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'package:tuitu/utils/my_openai_client.dart';
import 'package:tuitu/utils/screen_resolution_singleton.dart';
import 'package:tuitu/widgets/add_character_preset_widget.dart';
import 'package:tuitu/widgets/after_detail_option.dart';
import 'package:tuitu/widgets/auto_save_option.dart';
import 'package:tuitu/widgets/control_net_option.dart';
import 'package:tuitu/widgets/custom_carousel.dart';
import 'package:tuitu/widgets/custom_dialog.dart';
import 'package:tuitu/widgets/get_image_tags.dart';
import 'package:tuitu/widgets/image_manipulation_item.dart';
import 'package:http/http.dart' as http;
import 'package:tuitu/widgets/voice_text_option.dart';
import '../config/change_settings.dart';
import '../config/config.dart';
import '../draft_sample_files/attachment_pc_common.dart';
import '../draft_sample_files/draft_agency_config.dart';
import '../draft_sample_files/draft_content.dart';
import '../draft_sample_files/draft_meta_info.dart';
import '../net/my_api.dart';
import '../params/preset_character.dart';
import '../params/prompts.dart';
import '../params/prompts_styles.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import '../utils/auto_task_manager.dart';
import '../utils/file_picker_manager.dart';
import '../widgets/my_keep_alive_wrapper.dart';
import '../widgets/common_dropdown.dart';
import '../widgets/mj_settings_view.dart';
import '../widgets/redraw_option.dart';

class ThirdStepView extends StatefulWidget {
  final String scenes;
  final int useAiMode;
  final bool? isDirectlyInto;
  final String? novelTitle;

  const ThirdStepView({super.key, required this.scenes, required this.useAiMode, this.isDirectlyInto = false, this.novelTitle = ''});

  @override
  State<ThirdStepView> createState() => _ThirdStepViewState();
}

class _ThirdStepViewState extends State<ThirdStepView> {
  String inputScenes = '';
  final manager = AutoTaskManager();
  double _everySceneImages = 2;
  List<String> lines = [];
  List<String> contentList = [];
  List<dynamic> items = [].obs;
  String chatBaseUrl = '';
  String _useAiModel = '';
  String? content = '';
  String allContent = '';
  String responseText = '';
  bool isEditable = false;
  bool isAutoSave = false;
  int interval = 5;
  String _baiduTransAppId = '';
  String _baiduTransKey = '';
  String _deeplTransKey = '';
  String selfChatBaseUrl = '';
  String mjOptions = '';
  List<String> referenceImages = ['', '']; //MJ的样式参考图
  List<String> characterImages = ['', '']; //MJ的人物参考图
  // ignore: non_constant_identifier_names
  Map<String, dynamic> MjOptions = {};
  String mjBotType = 'MID_JOURNEY';
  late MyApi myApi;
  late Future<void> oneKeyAIScene;
  late Future<void> oneKeyTransScene;
  late Future<void> oneKeyDealScene;
  late Future<void> oneKeyGenerateImage;
  late Future<void> oneKeyUpScale;
  late ChangeSettings changeSettings;
  List<String> imageBase64ParameterList = [];
  List<String> imageChangeTypes = ['0.无', '1.从上到下', '2.从下到上', '3.从左到右', '4.从右到左', '5.自动判断'];
  CancellationToken oneKeyAISceneToken = CancellationToken();
  CancellationToken oneKeyTransSceneToken = CancellationToken();
  CancellationToken oneKeyDealSceneToken = CancellationToken();
  CancellationToken oneKeyGenerateImageToken = CancellationToken();
  CancellationToken oneKeyUpScaleToken = CancellationToken();
  bool isSaving = false;
  int _imageHeight = 1;
  int _imageWidth = 1;
  var drawEngine = 0;
  Timer? _debounce;
  TextEditingController addCharactersPresetTitleController = TextEditingController();
  TextEditingController addCharactersPresetContentController = TextEditingController();
  TextEditingController addSceneContentController = TextEditingController();
  TextEditingController oneKeyStartSceneNumController = TextEditingController(text: '1');
  TextEditingController everySceneImageNumController = TextEditingController(text: '2');
  late List<String> readCharacterPresets;
  int selectModifyCharacterPresetsPosition = 0;
  late List<String> readCharacterPresetDescriptions;
  String _selectedHistoryTitle = '';
  String defaultPrePrompt = '''
  StableDiffusion是一款利用深度学习的文生图模型，支持通过使用提示词来产生新的图像，描述要包含或省略的元素。
  我在这里引入StableDiffusion算法中的Prompt概念，又被称为提示符。
  下面的prompt是用来指导AI绘画模型创作图像的。它们包含了图像的各种细节，如人物的外观、背景、颜色和光线效果，以及图像的主题和风格。这些prompt的格式经常包含括号内的加权数字，用于指定某些细节的重要性或强调。例如，"(杰作:1.5)"表示作品质量是非常重要的，多个括号也有类似作用。此外，如果使用中括号，如"{蓝色 头发:白色 
  头发:0.3}"，这代表将蓝发和白发加以融合，蓝发占比为0.3。
  以下是用prompt帮助AI模型生成图像的例子:杰作, (最佳画质), 高精细, 超精细, 冷艳, 单人,(1个女孩),(细致的眼睛),(闪耀着金色光芒的眼睛), (长长的肝色头发), 无表情, (长袖), (蓬松袖), (白色翅膀), 闪耀光环, (重金属:1.2), (金属饰品), 交叉花边鞋(链条), (白色羽绒服:1.2)
  仿照例子，给出一套详细描述以下内容的提示词。用中文描述，但是标点符号用英文的，直接开始给出中文提示词不需要用自然语言描述:
  ''';
  final List<String> _controlTypes = ['All'].obs;
  final List<String> _controlModels = ['无'].obs;
  final List<String> _controlModules = ['无'].obs;
  final List<String> _samplers = ['Euler a'].obs;
  List<Map<String, dynamic>> jobs = [];
  List<MapEntry<String, dynamic>> taskList = [];
  MapEntry<String, dynamic>? currentTask;
  bool isExecuting = false;
  String? screenSize = ScreenResolutionSingleton.instance.screenResolution;
  var deleteSize = 175;
  String? novelTitle;
  final box = GetStorage();

  Future<void> _getSamplers(String url) async {
    try {
      dio.Response response = await myApi.getSDSamplers(url);
      if (response.statusCode == 200) {
        for (int i = 0; i < response.data.length; i++) {
          if (!_samplers.contains(response.data[i]['name'])) {
            _samplers.add(response.data[i]['name']);
          }
        }
      } else {
        commonPrint('获取采样器列表失败，错误是${response.statusMessage}');
      }
    } catch (error) {
      commonPrint('获取模型采样器失败，错误是$error');
    }
    setState(() {});
  }

  Future<void> _getControlNetModels(String url) async {
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
          showHint('获取controlNet模型失败，请检查sd相关设置');
        }
      }
    } catch (e) {
      commonPrint('获取controlNet模型失败，原因是$e');
    }
    setState(() {});
  }

  Future<void> _getControlNetModules(String url) async {
    try {
      dio.Response response = await myApi.getSDControlNetModules(url);
      if (response.statusCode == 200) {
        List<dynamic>? modules = response.data['module_list'];
        if (modules != null && modules.isNotEmpty) {
          for (String module in modules) {
            if (module == 'none') {
              module = '无';
            }
            if (!_controlModules.contains(module)) {
              _controlModules.add(module);
            }
          }
        }
      } else {
        if (mounted) {
          showHint('获取controlNet预处理器失败，请检查sd相关设置');
        }
      }
    } catch (e) {
      commonPrint('获取controlNet预处理器失败，原因是$e');
    }
    setState(() {});
  }

  Future<void> _getControlNetControlTypes(String url) async {
    try {
      dio.Response response = await myApi.getSDControlNetControlTypes(url);
      if (response.statusCode == 200) {
        Map<String, dynamic>? controlTypes = response.data['control_types'];
        if (controlTypes != null) {
          List<String> controlTypeKeys = controlTypes.keys.toList();
          for (String controlTypeKey in controlTypeKeys) {
            if (!_controlTypes.contains(controlTypeKey)) {
              _controlTypes.add(controlTypeKey);
            }
          }
        }
      } else {
        if (mounted) {
          showHint('获取controlNet控制类型失败，请检查sd相关设置');
        }
      }
    } catch (e) {
      commonPrint('获取controlNet控制类型失败，原因是$e');
    }
    setState(() {});
  }

  // 这里是为了某些中转AI返回的结构体不标准进行的手动解析
  Stream<String> postStreamedData({
    required String url,
    required Map<String, dynamic> requestBody,
    required TextEditingController aiSceneController,
    required ScrollController scrollController,
    Map<String, String>? headers,
  }) async* {
    final controller = StreamController<String>();
    final dio.Dio myDio = dio.Dio();
    try {
      // 发起POST请求，设置返回类型为流
      dio.Response<dio.ResponseBody> response = await myDio.post<dio.ResponseBody>(
        url,
        data: jsonEncode(requestBody), // 发送POST请求体
        options: dio.Options(
          responseType: dio.ResponseType.stream, // 设置为流式响应
          headers: headers ??
              {
                'Content-Type': 'application/json', // 默认请求头为JSON
              },
        ),
      );

      // 监听数据流
      response.data!.stream
          .map((Uint8List data) => data.toList()) // 将 Uint8List 转换为 List<int>
          .transform(utf8.decoder) // 解码为字符串
          .transform(const LineSplitter()) // 按行分割
          .listen(
        (data) {
          // 如果数据以 "data: " 开头，去掉前缀
          if (data.startsWith("data: ")) {
            data = data.substring(6).trim(); // 去掉 "data: " 前缀并修剪空白
          }
          // 如果处理后的数据为空，则跳过
          if (data.isEmpty) {
            return;
          }

          if (data == "[DONE]") {
            // 当接收到[DONE]时，表示流结束
            controller.close(); // 关闭流
            return;
          }

          try {
            // 解析JSON数据
            var jsonData = jsonDecode(data);

            // 只处理delta部分
            if (jsonData['choices'][0]['delta'] != null) {
              var content = jsonData['choices'][0]['delta']['content'];

              // 如果delta中的content存在并且非空，将其累积到StringBuffer中
              if (content != null && content.isNotEmpty) {
                if (content != null) {
                  allContent = allContent + content!;
                }
                if (mounted) {
                  responseText = allContent;
                  aiSceneController.text = responseText;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // 在下一帧中滚动到最后一行
                    final maxScrollExtent = scrollController.position.maxScrollExtent;
                    scrollController.animateTo(
                      maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  });
                }
                controller.add(content); // 添加拼接后的内容到流中
              }
            }
          } catch (e) {
            commonPrint("JSON解析错误: $e");
            controller.addError(e); // 如果JSON解析错误，加入流的错误处理
          }
        },
        onError: (error) {
          commonPrint("流发生错误: $error");
          controller.addError(error); // 传递错误到流中
          controller.close(); // 关闭流
        },
        onDone: () async {
          controller.close(); // 关闭流
        },
        cancelOnError: true, // 遇到错误时取消流
      );
    } catch (e) {
      commonPrint("请求发生错误: $e");
      controller.addError(e);
      controller.close();
    }

    yield* controller.stream; // 将流控制器中的流返回
  }

  Future<void> _aiScene(String currentIndex) async {
    await loadSettings();
    int index = int.parse(currentIndex) - 1;
    if (index >= 0 && index <= items.length - 1) {
      String article = '';
      if (items[index].selfSceneController.text != '') {
        article = items[index].selfSceneController.text;
      } else {
        article = items[index].prompt;
      }
      TextEditingController aiSceneController = items[index].aiSceneController;
      ScrollController scrollController = items[index].scrollController;
      try {
        allContent = '';
        Map<String, dynamic> settings = await Config.loadSettings();
        int useAIMode = settings['use_mode'] ?? 0;
        if (useAIMode == 0) {
          if (_useAiModel.startsWith('abab') || _useAiModel.startsWith('bing')) {
            String apiKey = settings['chatSettings_apiKey'] ?? settings['chat_api_key'] ?? '';
            String baseUrl = (settings['chatSettings_apiUrl'] ?? settings['chat_api_url'] ?? '') + '/v1/chat/completions';
            Map<String, dynamic> params = {
              'model': _useAiModel,
              'messages': [
                {'role': 'user', 'content': '$defaultPrePrompt\n内容是:\n $article\n'}
              ],
              'stream': true,
            };
            Map<String, String> headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'};
            await postStreamedData(
                    url: baseUrl, requestBody: params, aiSceneController: aiSceneController, scrollController: scrollController, headers: headers)
                .toList();
          } else {
            final chatStream = OpenAIClientSingleton.instance.client.createChatCompletionStream(
                request: CreateChatCompletionRequest(
              model: ChatCompletionModel.modelId(_useAiModel),
              messages: [
                ChatCompletionMessage.user(
                  content: ChatCompletionUserMessageContent.string('$defaultPrePrompt\n内容是:\n $article\n'),
                )
              ],
            ));
            chatStream.listen((streamChatCompletion) {
              content = streamChatCompletion.choices.first.delta.content;
              if (content != null) {
                allContent = allContent + content!;
              }
              if (mounted) {
                responseText = allContent;
                aiSceneController.text = responseText;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // 在下一帧中滚动到最后一行
                  final maxScrollExtent = scrollController.position.maxScrollExtent;
                  scrollController.animateTo(
                    maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                });
              }
            }, onDone: () {
              // 监听完成事件，例如关闭加载动画等
            }, onError: (error) {
              // 监听错误事件，例如显示错误消息等
              commonPrint('AI生成失败，错误是$error');
            });
          }
        } else if (useAIMode == 1) {
          //通义千问
          final streamData = StringBuffer();
          final Map<String, dynamic> jsonData = {};
          Map<String, dynamic> payload = {};
          payload['model'] = _useAiModel;
          payload['input'] = {
            'messages': [
              {'role': 'user', 'content': '$defaultPrePrompt\n内容是:\n $article\n'}
            ]
          };
          payload['parameters'] = {'top_p': 0.9, 'result_format': 'message', 'seed': Random().nextInt(65536)};
          dio.Response response = await myApi.tyqwAI(payload, isStream: true);
          response.data.stream.listen((data) {
            // 在这里处理接收到的数据流
            streamData.write(utf8.decode(data));
            final jsonString = streamData.toString();
            // 使用正则表达式来提取键值对
            final pattern = RegExp(r'(\w+):(.+?)($|\n)');
            final matches = pattern.allMatches(jsonString);
            for (final match in matches) {
              final key = match.group(1)?.trim();
              final value = match.group(2)?.trim();
              if (key != null && value != null) {
                if (key == 'data') {
                  jsonData.addAll(jsonDecode(value));
                }
              }
            }
            content = jsonData['output']['choices'][0]['message']['content'];
            allContent = content!;
            if (mounted) {
              responseText = allContent;
              aiSceneController.text = responseText;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // 在下一帧中滚动到最后一行
                final maxScrollExtent = scrollController.position.maxScrollExtent;
                scrollController.animateTo(
                  maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              });
            }
          });
        } else if (useAIMode == 2) {
          //智谱AI
          final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
          final oneWeekLater = DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch;
          String apiId = (settings['zpai_api_key'] ?? '').split('.')[0];
          String secretKey = (settings['zpai_api_key'] ?? '').split('.')[1];
          Map<String, dynamic> payload = {'api_key': apiId, 'exp': oneWeekLater, 'timestamp': currentTimestamp};
          final jwt = JWT(payload, header: GlobalParams.zpaiHeaders);
          final token = jwt.sign(SecretKey(secretKey));
          final streamData = StringBuffer();
          Map<String, dynamic> inputs = {};
          inputs['prompt'] = [
            {'role': 'user', 'content': '$defaultPrePrompt\n内容是:\n $article\n'}
          ];
          inputs['top_p'] = 0.9;
          allContent = '';
          dio.Response response = await myApi.zpai(inputs, token, model: _useAiModel, isStream: true);
          response.data.stream.listen((data) {
            // 在这里处理接收到的数据流
            streamData.write(utf8.decode(data));
            final jsonString = streamData.toString();
            // 使用正则表达式来提取键值对
            final pattern = RegExp(r'(\w+):(.+?)($|\n)');
            final matches = pattern.allMatches(jsonString);
            for (final match in matches) {
              final key = match.group(1)?.trim();
              final value = match.group(2)?.trim();
              if (key != null && value != null) {
                if (key == 'data') {
                  content = value;
                }
              }
            }
            allContent = allContent + content!;
            if (mounted) {
              responseText = allContent;
              String resultString = responseText.replaceAll(RegExp(r'。{2,}'), '。');
              aiSceneController.text = resultString;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // 在下一帧中滚动到最后一行
                final maxScrollExtent = scrollController.position.maxScrollExtent;
                scrollController.animateTo(
                  maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              });
            }
          });
        }
      } on Exception catch (e) {
        setState(() {
          aiSceneController.text = 'AI处理异常，原因是$e';
        });
      }
    }
  }

  Future<void> _oneKeyAiScene(CancellationToken token) async {
    int startNum = int.parse(oneKeyStartSceneNumController.text);
    for (int i = startNum - 1; i < items.length; i++) {
      if (token.isCancelled) {
        continue;
      }
      showHint('正在推理第${i + 1}个场景', showType: 5);
      await _aiScene('${i + 1}');
      await Future.delayed(const Duration(seconds: 20));
      dismissHint();
    }
    setState(() {
      token.isCancelled = false;
      token.isStarted = false;
    });
  }

  Future<void> _oneKeyTransScene(CancellationToken token) async {
    int startNum = int.parse(oneKeyStartSceneNumController.text);
    for (int i = startNum - 1; i < items.length; i++) {
      if (token.isCancelled) {
        continue;
      }
      showHint('正在翻译第${i + 1}个场景...', showType: 5);
      await _transScene('${i + 1}');
      await Future.delayed(const Duration(seconds: 10));
      dismissHint();
    }
    setState(() {
      token.isCancelled = false;
      token.isStarted = false;
    });
  }

  Future<void> _oneKeyDeal(CancellationToken token) async {
    int startNum = int.parse(oneKeyStartSceneNumController.text);
    for (int i = startNum - 1; i < items.length; i++) {
      if (token.isCancelled) {
        continue;
      }
      showHint('正在处理第${i + 1}个场景，包括推理、翻译、生图', showType: 5);
      await _aiScene('${i + 1}');
      await Future.delayed(const Duration(seconds: 10));
      await _transScene('${i + 1}');
      await Future.delayed(const Duration(seconds: 2));
      await _generateImage('${i + 1}');
      dismissHint();
    }
    setState(() {
      token.isCancelled = false;
      token.isStarted = false;
    });
  }

  Future<void> _oneKeyGenerateImage(CancellationToken token) async {
    int startNum = int.parse(oneKeyStartSceneNumController.text);
    for (int i = startNum - 1; i < items.length; i++) {
      if (token.isCancelled) {
        continue;
      }
      await _generateImage('${i + 1}');
    }
    setState(() {
      token.isCancelled = false;
      token.isStarted = false;
    });
  }

  Future<void> _oneKeyUpScale(CancellationToken token) async {
    int startNum = int.parse(oneKeyStartSceneNumController.text);
    for (int i = startNum - 1; i < items.length; i++) {
      if (token.isCancelled) {
        continue;
      }
      await _onUpScale('${i + 1}');
    }
    setState(() {
      token.isCancelled = false;
      token.isStarted = false;
    });
  }

  Future<void> _transScene(String currentIndex) async {
    await loadSettings();
    int index = int.parse(currentIndex) - 1;
    if (index >= 0 && index <= items.length - 1) {
      String article = '';
      String aiSceneText = items[index].aiSceneController.text;
      String selfSceneText = items[index].selfSceneController.text;
      String prompt = items[index].prompt;
      if (selfSceneText != '') {
        article = selfSceneText;
      } else if (aiSceneText != '') {
        article = aiSceneText;
      } else {
        article = prompt;
      }
      TextEditingController transSceneController = items[index].transSceneController;
      String? transResponseText = '';
      ScrollController scrollControllerTrans = items[index].scrollControllerTrans;
      if (_deeplTransKey != '') {
        transResponseText = await _deeplTranslateText(_deeplTransKey, article);
        if (transResponseText == null) {
          transResponseText = 'deepl翻译失败';
          if (_baiduTransAppId != '' && _baiduTransKey != '') {
            transResponseText = await _baiduTranslate(article, 'zh', 'en', _baiduTransAppId, _baiduTransKey);
          } else {
            if (mounted) {
              showHint('请先在设置页面配置翻译的相关内容');
            }
          }
        }
      } else if (_baiduTransAppId != '' && _baiduTransKey != '') {
        transResponseText = await _baiduTranslate(article, 'zh', 'en', _baiduTransAppId, _baiduTransKey);
      } else {
        if (mounted) {
          showHint('请先在设置页面配置翻译的相关内容');
        }
      }
      transSceneController.text = '';
      if (mounted) {
        if (transResponseText != null) {
          setState(() {
            transSceneController.text = transResponseText!;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // 在下一帧中滚动到最后一行
              final maxScrollExtent = scrollControllerTrans.position.maxScrollExtent;
              scrollControllerTrans.animateTo(
                maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            });
          });
        } else {
          showHint('翻译失败，请稍后重试');
        }
      }
    }
  }

  Future<void> _voiceScene(String currentIndex) async {
    List<String> scenes = [];
    int index = int.parse(currentIndex) - 1;
    if (index >= 0 && index <= items.length - 1) {
      String scene = items[index].prompt;
      scenes.add(scene);
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomDialog(
              title: null,
              showCancelButton: false,
              showConfirmButton: false,
              description: null,
              maxWidth: 920,
              minHeight: 300,
              contentBackgroundColor: Colors.black,
              contentBackgroundOpacity: 0.5,
              content: Padding(
                padding: const EdgeInsets.all(10),
                child: VoiceTextOption(
                  scenes: scenes,
                  isBatch: false,
                  title: '单个配音设置',
                  isDirectlyInto: widget.isDirectlyInto,
                  novelTitle: novelTitle,
                  index: index,
                  onVoice: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            );
          },
        );
      }
    }
  }

  Future<void> _oneKeyVoiceScene() async {
    int startNum = int.parse(oneKeyStartSceneNumController.text);
    List<String> finalContentList = [];
    for (var item in items) {
      finalContentList.add(item.prompt);
    }
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomDialog(
            title: null,
            showCancelButton: false,
            description: null,
            maxWidth: 920,
            minHeight: 300,
            contentBackgroundColor: Colors.black,
            contentBackgroundOpacity: 0.5,
            content: Padding(
              padding: const EdgeInsets.all(10),
              child: VoiceTextOption(
                scenes: finalContentList,
                isBatch: true,
                start: startNum - 1,
                isDirectlyInto: widget.isDirectlyInto,
                novelTitle: novelTitle,
                title: '批量配音设置',
                onVoice: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          );
        },
      );
    }
  }

  Future<String?> _deeplTranslateText(String apiKey, String text, {String targetLang = 'EN-US'}) async {
    final deeplUrl = Uri.parse('https://api-free.deepl.com/v2/translate');
    final Map<String, String> params = {
      'auth_key': apiKey,
      'text': text,
      'source_lang': 'ZH',
      'target_lang': targetLang,
    };
    final response = await http.post(deeplUrl, body: params);
    if (response.statusCode == 200) {
      final Map<String, dynamic> result = json.decode(utf8.decode(response.bodyBytes));
      final translatedText = result['translations'][0]['text'];
      return translatedText;
    } else {
      commonPrint('deepl翻译失败，失败返回值是${response.statusCode}');
      return null;
    }
  }

  Future<String?> _baiduTranslate(String query, String fromLang, String toLang, String appid, String secretKey) async {
    String translatedText = "";
    int salt = Random().nextInt(32768) + 32768;
    String signStr = appid + query + salt.toString() + secretKey;
    String sign = md5.convert(utf8.encode(signStr)).toString();
    String url = 'https://fanyi-api.baidu.com/api/trans/vip/translate?q=$query&from=$fromLang&to=$toLang'
        '&appid=$appid&salt=$salt&sign=$sign';
    http.Response resp = await http.get(Uri.parse(url));
    if (resp.statusCode == 200) {
      Map<String, dynamic> result = json.decode(resp.body);
      List<dynamic> transResult = result['trans_result'];
      for (int i = 0; i < transResult.length; i++) {
        translatedText += transResult[i]['dst'];
        if (i != transResult.length - 1) {
          translatedText += '\n';
        }
      }
    } else {
      translatedText = '百度翻译失败';
    }
    return translatedText;
  }

  String _getPrompts(Map<String, dynamic> defaultPromptDict, String promptKeys) {
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

  Future<void> _dealJobQueue(String jobId, int index) async {
    String currentIndex = (index + 1).toString();
    List<String> imageBase64List = items[index].imageBase64List;
    List<String> imageUrlList = items[index].imageUrlList;
    try {
      while (true) {
        dio.Response progressResponse = await myApi.selfMjDrawQuery(jobId);
        if (progressResponse.statusCode == 200) {
          if (progressResponse.data is String) {
            progressResponse.data = jsonDecode(progressResponse.data);
          }
          String? status = progressResponse.data['status'];
          if (status == '' || status == 'NOT_START' || status == 'IN_PROGRESS' || status == 'SUBMITTED' || status == 'MODAL' || status == 'SUCCESS') {
            if (mounted) {
              showHint('第$currentIndex个场景的图片的MJ绘制进度是${progressResponse.data['progress'] ?? "0%"}');
            }
            if (status == 'SUCCESS') {
              if (progressResponse.data['imageUrl'] != null) {
                if (mounted) {
                  showHint('图片即将展示，请稍后...');
                }
                imageBase64List.clear();
                imageUrlList.clear();
                String imageUrl = progressResponse.data['imageUrl'];
                imageUrl = imageUrl.replaceAll('cdn.discordapp.com', 'dc.aigc369.com');
                List<String> base64List = await splitImage(imageUrl);
                for (var element in base64List) {
                  imageBase64List.add(element);
                  String imageUrl = '';
                  String filePath = '';
                  File file = await base64ToTempFile(element);
                  if (file.existsSync()) {
                    filePath = file.path;
                  }
                  if (filePath != '') {
                    imageUrl = await uploadFileToALiOss(filePath, imageUrl, file);
                  }
                  imageUrlList.add(GlobalParams.filesUrl + imageUrl);
                }
                setState(() {
                  items[index].imageBase64List = imageBase64List;
                  items[index].imageUrlList = imageUrlList;
                  items[index].actions3 = List<dynamic>.from(progressResponse.data['buttons']);
                  items[index].useImagePath = '';
                  items[index].imagesDownloadStatus = [0, 0, 0, 0];
                  items[index].imageId = progressResponse.data['id'];
                  items[index].taskId = progressResponse.data['id'];
                  items[index].isAlreadyVariation = false;
                  items[index].isAlreadyUpScale = false;
                  items[index].isAlreadyUpScaleRepair = false;
                  items[index].isSingleImageDownloaded = false;
                });
                if (status == 'SUCCESS') {
                  break;
                }
              }
            }
          } else {
            if (mounted) {
              showHint('自有mj绘图失败,原因是${progressResponse.statusMessage}', showType: 3);
              commonPrint('自有mj绘图失败0,原因是${progressResponse.statusMessage}');
            }
            break;
          }
        } else {
          if (mounted) {
            showHint('第$currentIndex个场景的图片MJ绘制失败，原因是${progressResponse.statusMessage}', showType: 3);
            commonPrint('第$currentIndex个场景的图片MJ绘制失败，原因是${progressResponse.statusMessage}');
          }
          break;
        }
        dismissHint();
        await Future.delayed(const Duration(seconds: 5));
      }
    } catch (e) {
      if (mounted) {
        showHint('第$currentIndex个场景的图片MJ绘制失败，原因是$e');
        commonPrint('第$currentIndex个场景的图片MJ绘制失败，原因是$e');
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
      commonPrint('MJ绘图任务${task.key}添加成功');
      // 如果当前没有任务在执行，立即执行新任务
      if (!isExecuting) {
        final nextTask = taskList.removeAt(0);
        executeTask(nextTask);
      }
    }

    // 使用addTask方法来添加任务
    addTask(MapEntry<String, dynamic>(taskData.keys.first, taskData.values.first));
  }

  Future<void> _generateImage(String currentIndex, {bool isUpScaleRepair = false, bool singleUpScale = false}) async {
    int index = int.parse(currentIndex) - 1;
    Map<String, dynamic> settings = await Config.loadSettings();
    drawEngine = settings['drawEngine'] ?? 0;
    TextEditingController transSceneController = items[index].transSceneController;
    List<String> imageBase64List = items[index].imageBase64List;
    List<String> imageUrlList = items[index].imageUrlList;
    String characterPreset = items[index].characterPreset;
    String currentUsedImagePath = items[index].useImagePath;
    String characterPresetDesc = '';
    List<String> newCharacterPresets = await _getCharacterPresets();
    List<String> newCharacterPresetsDescriptions = await _getCharacterPresetsDescriptions();
    for (int i = 0; i < newCharacterPresets.length; i++) {
      if (characterPreset == newCharacterPresets[i]) {
        characterPresetDesc = newCharacterPresetsDescriptions[i];
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
    bool? useFaceRestore = settings['restore_face'];
    bool useHiresFix = settings['hires_fix'];
    bool combinedPositivePrompts = settings['is_compiled_positive_prompts'];
    bool useSelfPositivePrompts = settings['use_self_positive_prompts'];
    bool useSelfNegativePrompts = settings['use_self_negative_prompts'];
    String defaultPositivePromptType = settings['default_positive_prompts_type'].toString();
    String combinedPositivePromptsTypes = settings['compiled_positive_prompts_type'];
    String defaultPositivePrompts = '';
    String defaultNegativePrompts = settings['self_negative_prompts'];
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

    if (index >= 0 && index <= items.length - 1) {
      items[index].key.currentState?.changeDrawEngine(drawEngine);
      setState(() {
        items[index].drawEngine = drawEngine;
      });
      if (drawEngine == 0) {
        //使用SD绘图
        if (!isUpScaleRepair && !singleUpScale) {
          items[index].imagesDownloadStatus = [0, 0, 0, 0];
        }
        String sdUrl = settings['sdUrl'] ?? '';
        double? imageNum = settings['every_scene_images'].toDouble();
        int everySceneImageNum = imageNum?.truncate() ?? 4;
        if (isUpScaleRepair) {
          everySceneImageNum = 1;
        }
        String imageContent = transSceneController.text;
        if (!isUpScaleRepair) {
          imageBase64List.clear();
          imageBase64ParameterList.clear();
          imageUrlList.clear();
        }
        for (int i = 0; i < everySceneImageNum; i++) {
          Map<String, dynamic> requestBody = {};
          if (!combinedPositivePrompts & !useSelfPositivePrompts) {
            for (int i = 0; i < defaultPromptDict.length; i++) {
              String key = defaultPromptDict.keys.elementAt(i).toString();
              if (key.startsWith(defaultPositivePromptType)) {
                defaultPositivePrompts = defaultPromptDict.values.elementAt(i);
              }
            }
          } else if (combinedPositivePrompts & !useSelfPositivePrompts) {
            defaultPositivePrompts = _getPrompts(defaultPromptDict, combinedPositivePromptsTypes);
          } else if (useSelfPositivePrompts) {
            defaultPositivePrompts = settings['self_positive_prompts'];
          }
          if (useSelfNegativePrompts & defaultNegativePrompts.isNotEmpty) {
            requestBody['negative_prompt'] = defaultNegativePrompts;
          } else {
            requestBody['negative_prompt'] = prompts['anime_negative_prompt'];
          }
          if (characterPresetDesc != '') {
            requestBody['prompt'] = "$defaultPositivePrompts($imageContent:1.5), $characterPresetDesc";
          } else {
            requestBody['prompt'] = "$defaultPositivePrompts($imageContent)";
          }
          requestBody['restore_faces'] = useFaceRestore;
          requestBody['enable_hr'] = useHiresFix;
          if (useHiresFix || singleUpScale) {
            requestBody['hr_scale'] = settings['hires_fix_multiple'];
            requestBody['hr_upscaler'] = settings['hires_fix_sampler'];
            requestBody['hr_second_pass_steps'] = settings['hires_fix_steps'];
            requestBody['denoising_strength'] = settings['hires_fix_amplitude'];
          }
          requestBody['steps'] = settings['steps'];
          requestBody['width'] = !isUpScaleRepair ? settings['width'] : (settings['newWidth'] ?? 1024);
          requestBody['height'] = !isUpScaleRepair ? settings['height'] : (settings['newHeight'] ?? 1024);
          requestBody['cfg_scale'] = 7;
          requestBody['sampler_name'] = settings['Sampler'];
          Map<String, dynamic> controlNetMap = {"args": []};
          Map<String, dynamic> aDetailerMap = {"args": []};
          Map<String, dynamic> alwaysOnScripts = {};
          if (items[index].aDetailsOptions.length > 0) {
            aDetailerMap['args'].clear();
            for (var aDetailsOption in items[index].aDetailsOptions) {
              Map<String, dynamic> aDetailerMapCopy = deepCopy(aDetailsOption);
              if (aDetailerMapCopy['is_enable']) {
                aDetailerMapCopy.remove('is_enable');
                if (aDetailerMapCopy['ad_controlnet_model'] == '无') {
                  aDetailerMapCopy['ad_controlnet_model'] = 'None';
                }
                aDetailerMap['args'].add(aDetailerMapCopy);
              }
            }
            alwaysOnScripts['ADetailer'] = aDetailerMap;
          }
          if (items[index].controlNetOptions.length > 0) {
            controlNetMap['args'].clear();
            for (var controlNetOption in items[index].controlNetOptions) {
              Map<String, dynamic> controlNetOptionCopy = deepCopy(controlNetOption);
              if (controlNetOptionCopy['is_enable']) {
                controlNetOptionCopy.remove('is_enable');
                if (controlNetOptionCopy['module'] == '无') {
                  controlNetOptionCopy['module'] = 'none';
                }
                if (isUpScaleRepair) {
                  controlNetOptionCopy.remove('input_image');
                }
                controlNetMap['args'].add(controlNetOptionCopy);
              }
            }
            var settings = await Config.loadSettings();
            bool isImg2imgUseControlNet = settings['is_img2img_use_control_net'];
            if (isUpScaleRepair) {
              if (isImg2imgUseControlNet) {
                alwaysOnScripts['controlnet'] = controlNetMap;
              }
            } else {
              alwaysOnScripts['controlnet'] = controlNetMap;
            }
          }
          if (isUpScaleRepair) {
            requestBody['init_images'] = [currentUsedImagePath];
            requestBody['denoising_strength'] = settings['redraw_range'];
            Uint8List decodedBytes = base64Decode(currentUsedImagePath);
            img.Image image = img.decodeImage(Uint8List.fromList(decodedBytes))!;
            var imageInfo = image.textData;
            try {
              if (imageInfo != null) {
                var paramsStartIndex = imageInfo['parameters']!.indexOf('Steps');
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
          imageBase64ParameterList.add("(${requestBody['prompt']})");
          requestBody['alwayson_scripts'] = alwaysOnScripts;
          dio.Response? response;
          try {
            showHint(!isUpScaleRepair ? '第$currentIndex个场景的第${i + 1}张图片生成中...' : '第$currentIndex个场景的已选中图片重绘中...', showType: 5);
            response = !isUpScaleRepair ? await myApi.sdText2Image(sdUrl, requestBody) : await myApi.sdImage2Image(sdUrl, requestBody);
            if (response.statusCode == 200) {
              if (response.data['images'] is List<dynamic>) {
                if (isUpScaleRepair) {
                  String imageUrl = '';
                  String filePath = '';
                  File file = await base64ToTempFile(response.data['images'][0]);
                  if (file.existsSync()) {
                    filePath = file.path;
                  }
                  if (filePath != '') {
                    imageUrl = await uploadFileToALiOss(filePath, imageUrl, file);
                  }
                  setState(() {
                    items[index].useImagePath = GlobalParams.filesUrl + imageUrl;
                    items[index].isAlreadyUpScaleRepair = true;
                    items[index].isAlreadyUpScale = false;
                    items[index].isSingleImageDownloaded = false;
                  });
                } else {
                  for (int i = 0; i < response.data['images'].length; i++) {
                    imageBase64List.add(response.data['images'][i]);
                    String imageUrl = '';
                    String filePath = '';
                    File file = await base64ToTempFile(response.data['images'][i]);
                    if (file.existsSync()) {
                      filePath = file.path;
                    }
                    if (filePath != '') {
                      imageUrl = await uploadFileToALiOss(filePath, imageUrl, file);
                    }
                    imageUrlList.add(GlobalParams.filesUrl + imageUrl);
                  }
                  setState(() {
                    items[index].imageBase64List = imageBase64List;
                    items[index].imageUrlList = imageUrlList;
                  });
                }
              }
            } else {
              if (mounted) {
                showHint('绘图失败，SD异常，请在设置页面查看SD配置。', showTime: 3);
              }
            }
          } catch (error) {
            if (mounted) {
              showHint('绘图失败，SD异常，请在设置页面查看SD配置。', showTime: 3);
              commonPrint('异常原因是$error}');
            }
          } finally {
            dismissHint();
          }
        }
        if (imageBase64List.length == imageNum) {
          dismissHint();
        }
      } else {
        String imageContent = transSceneController.text;
        Map<String, dynamic> payload = <String, dynamic>{};
        if (!combinedPositivePrompts & !useSelfPositivePrompts) {
          for (int i = 0; i < defaultPromptDict.length; i++) {
            String key = defaultPromptDict.keys.elementAt(i).toString();
            if (key.startsWith(defaultPositivePromptType)) {
              defaultPositivePrompts = defaultPromptDict.values.elementAt(i);
            }
          }
        } else if (combinedPositivePrompts & !useSelfPositivePrompts) {
          defaultPositivePrompts = _getPrompts(defaultPromptDict, combinedPositivePromptsTypes);
        } else if (useSelfPositivePrompts) {
          defaultPositivePrompts = settings['self_positive_prompts'];
        }
        if (characterPresetDesc != '') {
          payload['prompt'] = "$imageContent, $characterPresetDesc";
        } else {
          payload['prompt'] = imageContent;
        }
        dio.Response response;
        if (drawEngine == 1) {
          //使用知数云mj绘图
          payload['action'] = 'generate';
          try {
            payload['prompt'] = payload['prompt'] + mjOptions;
            showHint('第$currentIndex个场景的图片生成中...', showType: 5);
            response = await myApi.mjDraw(drawSpeedType, token, payload);
            if (response.statusCode == 200) {
              response.data.stream.listen((data) async {
                imageBase64List.clear();
                final decodedData = utf8.decode(data);
                final jsonData = json.decode(decodedData);
                int progress = jsonData['progress'];
                if (mounted) {
                  showHint('第$currentIndex个场景的图片的MJ绘制进度是$progress%');
                }
                if (progress == 100) {
                  if (mounted) {
                    showHint('图片即将展示，请稍后...');
                  }
                  List<String> base64List = await splitImage(jsonData['image_url']);
                  for (var element in base64List) {
                    imageBase64List.add(element);
                    String imageUrl = '';
                    String filePath = '';
                    File file = await base64ToTempFile(element);
                    if (file.existsSync()) {
                      filePath = file.path;
                    }
                    if (filePath != '') {
                      imageUrl = await uploadFileToALiOss(filePath, imageUrl, file);
                    }
                    imageUrlList.add(GlobalParams.filesUrl + imageUrl);
                  }
                  setState(() {
                    items[index].imageBase64List = imageBase64List;
                    items[index].imageUrlList = imageUrlList;
                    items[index].actions = List<String>.from(jsonData['actions']);
                    items[index].imageId = jsonData['image_id'];
                    items[index].taskId = jsonData['task_id'];
                  });
                }
              });
            } else {
              if (mounted) {
                showHint('mj绘图失败1,原因是${response.statusMessage}', showType: 3);
                commonPrint('mj绘图失败1,原因是${response.statusMessage}');
              }
            }
          } catch (e) {
            if (mounted) {
              showHint('mj绘图失败2,原因是$e', showType: 3);
              commonPrint('mj绘图失败2,原因是$e');
            }
          } finally {
            dismissHint();
          }
        } else if (drawEngine == 2) {
          //自有账号mj绘图，需要先创建任务
          payload['botType'] = mjBotType;
          payload['accountFilter'] = {};
          Map<String, dynamic> currentSettings = await Config.loadSettings();
          bool isJoinedAccountPool = currentSettings['join_account_pool'] ?? false;
          String mjAccountId = currentSettings['mj_channel_id'] ?? '';
          bool isHaveMjAccount = currentSettings['have_mj_account'] ?? false;
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
          payload['prompt'] = payload['prompt'] + mjOptions;
          if (!isJoinedAccountPool) {
            payload['accountFilter']['instanceId'] = mjAccountId;
          }
          if (!isHaveMjAccount) {
            if (mounted) {
              showHint('您未配置账号，无法使用自有账号进行绘图', showType: 3);
            }
          } else {
            try {
              showHint('第$currentIndex个场景的图片生成中...', showType: 5);
              response = await myApi.selfMjDrawCreate(payload);
              if (response.statusCode == 200) {
                if (response.data is String) {
                  response.data = jsonDecode(response.data);
                }
                int code = response.data['code'] ?? -1;
                if (code == 1) {
                  if (mounted) {
                    showHint('第$currentIndex个场景的图片的MJ绘图任务提交成功');
                  }
                  String result = response.data['result'];
                  Map<String, dynamic> taskData = {result: index};
                  createTaskQueue(taskData);
                } else {
                  if (mounted) {
                    showHint('自有mj绘图失败0,原因是${response.data['description']}', showType: 3);
                    commonPrint('自有mj绘图失败0,原因是${response.data['description']}');
                  }
                }
              } else {
                if (mounted) {
                  showHint('自有mj绘图失败1,原因是${response.statusMessage}', showType: 3);
                  commonPrint('自有mj绘图失败1,原因是${response.statusMessage}');
                }
              }
            } catch (e) {
              if (mounted) {
                showHint('自有mj绘图失败2,原因是$e', showType: 3);
                commonPrint('自有mj绘图失败2,原因是$e');
              }
            } finally {
              dismissHint();
            }
          }
        } else if (drawEngine == 3) {
          //TODO 增加Comfyui绘图逻辑
        } else if (drawEngine == 4) {
          //TODO 增加Fooocus绘图逻辑
        }
      }
    }
  }

  Future<void> loadSettings() async {
    myApi = MyApi();
    Map<String, dynamic> settings = await Config.loadSettings();
    String? baseUrl = settings['chat_web_proxy'];
    String? useAiModel = settings['use_ai_model'];
    String? baiduTransAppId = settings['baidu_trans_app_id'];
    String? baiduTransKey = settings['baidu_trans_app_key'];
    String? deeplTransKey = settings['deepl_api_key'];
    double? everySceneImages = settings['every_scene_images'].toDouble();
    setState(() {
      drawEngine = settings['drawEngine'] ?? 0;
    });
    if (everySceneImages != null) {
      setState(() {
        _everySceneImages = everySceneImages;
        everySceneImageNumController.text = '${_everySceneImages.toInt()}';
      });
    }
    if (baiduTransAppId != null) {
      _baiduTransAppId = baiduTransAppId;
    }
    if (baiduTransKey != null) {
      _baiduTransKey = baiduTransKey;
    }
    if (deeplTransKey != null) {
      _deeplTransKey = deeplTransKey;
    }
    if (baseUrl != null) {
      chatBaseUrl = baseUrl;
    }
    int? selectedAiMode = settings['ChatGPTUseMode'];
    if (selectedAiMode != null) {}
    if (useAiModel != null) {
      _useAiModel = useAiModel;
    }
  }

  void _mergeDown(String currentIndex) {
    int index = int.parse(currentIndex) - 1;
    if (index >= 0 && index < items.length - 1) {
      String currentPrompt = items[index].prompt;
      String nextPrompt = items[index + 1].prompt;
      String mergedPrompt = '$currentPrompt $nextPrompt';
      // 更新下一个项目的索引和合并后的提示
      String updatedIndex = (int.parse(items[index + 1].key) - 1).toString();
      items[index + 1].key = updatedIndex;
      items[index + 1].prompt = mergedPrompt;
      //先清空下一项的列表数据
      items[index + 1].aiSceneController.clear();
      items[index + 1].selfSceneController.clear();
      items[index + 1].transSceneController.clear();
      items[index + 1].contentController.text = mergedPrompt;
      items[index + 1].imageBase64List.clear();
      items[index + 1].imageUrlList.clear();

      // 更新下一个项目的属性
      items[index + 1].aiSceneController = items[index + 1].aiSceneController;
      items[index + 1].selfSceneController = items[index + 1].selfSceneController;
      items[index + 1].transSceneController = items[index + 1].transSceneController;
      items[index + 1].contentController = items[index + 1].contentController;
      items[index + 1].imageBase64List = items[index + 1].imageBase64List;
      items[index + 1].useImagePath = '';
      items[index + 1].isAlreadyUpScale = false;
      items[index + 1].isAlreadyUpScaleRepair = false;
      items[index + 1].characterPreset = presetCharacter['character_list'][0];
      items[index + 1].imageChangeType = imageChangeTypes.last;
      items[index + 1].isSingleImageDownloaded = false;
      items[index + 1].imagesDownloadStatus = [0, 0, 0, 0];
      items[index + 1].actions = List<String>.from([]);
      items[index + 1].actions2 = List<String>.from([]);
      items[index + 1].taskId = '';
      items[index + 1].imageId = '';
      items[index + 1].selectedImagePosition = -1;
      // 更新剩下的项目的序号
      for (int i = index + 2; i < items.length; i++) {
        setState(() {
          items[i].key = (int.parse(items[i].key) - 1).toString();
        });
      }
      setState(() {
        items.removeAt(index);
      });
    }
  }

  void _addDown(String currentIndex, String prompt) async {
    int index = int.parse(currentIndex) - 1;
    if (index >= 0 && index <= items.length - 1) {
      GlobalKey<ImageManipulationItemState> itemKey = GlobalKey();
      ImageManipulationItem item = ImageManipulationItem(
          key: itemKey,
          index: (index + 2).toString(),
          prompt: prompt,
          actions: List<String>.from([]),
          actions2: List<String>.from([]),
          actions3: List<dynamic>.from([]),
          actions4: List<dynamic>.from([]),
          imageUrlList: List<String>.from([]),
          allScenes: contentList.length + 1,
          onMergeDown: (index) => _mergeDown(index),
          drawEngine: drawEngine,
          onMergeUp: (index) => _mergeUp(index),
          onAddDown: (index) => _addItem(index, 1),
          onAddUp: (index) => _addItem(index, 0),
          onDelete: (index) => _deleteItem(index),
          aiScene: (index) => _aiScene(index),
          transScene: (index) => _transScene(index),
          sceneToImage: (index) => _generateImage(index),
          aiSceneController: TextEditingController(),
          selfSceneController: TextEditingController(),
          transSceneController: TextEditingController(),
          contentController: TextEditingController(text: prompt),
          onChangeUseFix: (index) => _changeUseFix(index),
          onUseControlNet: (index) => onUseControlNet(index),
          onReasoningTagsTapped: (index) => onReasoningTags(index),
          scrollController: ScrollController(),
          controlNetOptions: List<Map<String, dynamic>>.from([]),
          aDetailsOptions: List<Map<String, dynamic>>.from([]),
          scrollControllerTrans: ScrollController(),
          imageBase64List: List<String>.from([]),
          imagesDownloadStatus: List<int>.from([0, 0, 0, 0]),
          isSingleImageDownloaded: false,
          onSingleImageSaveTapped: (index) => _saveSingleImage(index),
          isAlreadyUpScale: false,
          isAlreadyUpScaleRepair: false,
          useFix: true,
          useControlnet: false,
          onImageTapped: (index, pos, paths) => _onImageTapped(index, pos, paths),
          onImageSaveTapped: (index, pos, paths) => _onImageSaveTapped(index, pos, paths),
          useImagePath: '',
          onTypeChanged: (index, type) => _onTypeChanged(index, type),
          onPresetsChanged: (index, type) => _onPresetChanged(index, type),
          imageChangeType: imageChangeTypes.last,
          characterPreset: presetCharacter['character_list'][0],
          onUpScale: (index) => _onUpScale(index),
          onVariation: (index, {type = 0}) => _onVariation(index, type: type),
          onUpScaleRepair: (index) => _onUpScaleRepairImage(index),
          onSingleImageTapped: (index) => _onSingleImageTapped(index),
          onVoiceTapped: (index) => _voiceScene(index),
          useAiMode: widget.useAiMode,
          characterPresets: await _getCharacterPresets(),
          onSelectCustom: (index, type) => _onSelectCustom(index, type),
          onContentChanged: (index, content) => _contentChanged(index, content),
          onSelectImage: (index) => _onSelectImage(index),
          useImageUrl: '');
      // 更新插入位置之后的项目的序号
      for (int i = index + 1; i < items.length; i++) {
        setState(() {
          items[i].key = (int.parse(items[i].key) + 1).toString();
        });
      }
      setState(() {
        items.insert(index + 1, item); // 在指定位置后插入新的项目
      });
    }
  }

  void _mergeUp(String currentIndex) {
    int index = int.parse(currentIndex) - 1;
    if (index > 0 && index < items.length) {
      String currentPrompt = items[index].prompt;
      String prevPrompt = items[index - 1].prompt;
      String mergedPrompt = '$prevPrompt $currentPrompt';
      items[index - 1].prompt = mergedPrompt;
      //先清空上一项的列表数据
      items[index - 1].aiSceneController.clear();
      items[index - 1].selfSceneController.clear();
      items[index - 1].transSceneController.clear();
      items[index - 1].contentController.text = mergedPrompt;
      items[index - 1].imageBase64List.clear();
      items[index - 1].imageUrlList.clear();
      // 更新上一个项目的属性
      items[index - 1].aiSceneController = items[index - 1].aiSceneController;
      items[index - 1].selfSceneController = items[index - 1].selfSceneController;
      items[index - 1].transSceneController = items[index - 1].transSceneController;
      items[index - 1].contentController = items[index - 1].contentController;
      items[index - 1].imageBase64List = items[index - 1].imageBase64List;
      items[index - 1].useImagePath = '';
      items[index - 1].isAlreadyUpScale = false;
      items[index - 1].isAlreadyUpScaleRepair = false;
      items[index - 1].isSingleImageDownloaded = false;
      items[index - 1].imagesDownloadStatus = [0, 0, 0, 0];
      items[index - 1].characterPreset = presetCharacter['character_list'][0];
      items[index - 1].imageChangeType = imageChangeTypes.last;
      items[index - 1].actions = List<String>.from([]);
      items[index - 1].actions2 = List<String>.from([]);
      items[index - 1].taskId = '';
      items[index - 1].imageId = '';
      items[index - 1].selectedImagePosition = -1;
      // 更新剩下的项目的序号
      for (int i = index; i < items.length; i++) {
        setState(() {
          items[i].key = (int.parse(items[i].key) - 1).toString();
        });
      }
      //移除当前item
      setState(() {
        items.removeAt(index);
      });
    }
  }

  void _addUp(String currentIndex, String prompt) async {
    int index = int.parse(currentIndex) - 1;
    if (index >= 0 && index <= items.length) {
      GlobalKey<ImageManipulationItemState> itemKey = GlobalKey();
      ImageManipulationItem item = ImageManipulationItem(
          key: itemKey,
          index: currentIndex,
          prompt: prompt,
          drawEngine: drawEngine,
          actions: List<String>.from([]),
          actions2: List<String>.from([]),
          actions3: List<dynamic>.from([]),
          actions4: List<dynamic>.from([]),
          imageUrlList: List<String>.from([]),
          allScenes: contentList.length + 1,
          onMergeDown: (index) => _mergeDown(index),
          onMergeUp: (index) => _mergeUp(index),
          onAddDown: (index) => _addItem(index, 1),
          onAddUp: (index) => _addItem(index, 0),
          onDelete: (index) => _deleteItem(index),
          aiScene: (index) => _aiScene(index),
          onReasoningTagsTapped: (index) => onReasoningTags(index),
          controlNetOptions: List<Map<String, dynamic>>.from([]),
          aDetailsOptions: List<Map<String, dynamic>>.from([]),
          transScene: (index) => _transScene(index),
          sceneToImage: (index) => _generateImage(index),
          onChangeUseFix: (index) => _changeUseFix(index),
          onUseControlNet: (index) => onUseControlNet(index),
          aiSceneController: TextEditingController(),
          selfSceneController: TextEditingController(),
          transSceneController: TextEditingController(),
          contentController: TextEditingController(text: prompt),
          scrollController: ScrollController(),
          scrollControllerTrans: ScrollController(),
          imageBase64List: List<String>.from([]),
          imagesDownloadStatus: List<int>.from([0, 0, 0, 0]),
          isSingleImageDownloaded: false,
          onSingleImageSaveTapped: (index) => _saveSingleImage(index),
          isAlreadyUpScale: false,
          isAlreadyUpScaleRepair: false,
          useFix: true,
          useControlnet: false,
          onImageTapped: (index, pos, paths) => _onImageTapped(index, pos, paths),
          onImageSaveTapped: (index, pos, paths) => _onImageSaveTapped(index, pos, paths),
          onContentChanged: (index, content) => _contentChanged(index, content),
          useImagePath: '',
          onTypeChanged: (index, type) => _onTypeChanged(index, type),
          onPresetsChanged: (index, type) => _onPresetChanged(index, type),
          imageChangeType: imageChangeTypes.last,
          characterPreset: presetCharacter['character_list'][0],
          onUpScale: (index) => _onUpScale(index),
          onVariation: (index, {type = 0}) => _onVariation(index, type: type),
          onUpScaleRepair: (index) => _onUpScaleRepairImage(index),
          onSingleImageTapped: (index) => _onSingleImageTapped(index),
          onVoiceTapped: (index) => _voiceScene(index),
          useAiMode: widget.useAiMode,
          characterPresets: await _getCharacterPresets(),
          onSelectCustom: (index, type) => _onSelectCustom(index, type),
          onSelectImage: (index) => _onSelectImage(index),
          useImageUrl: '');
      // 更新剩下的项目的序号
      for (int i = index; i < items.length; i++) {
        setState(() {
          items[i].key = (int.parse(items[i].key) + 1).toString();
        });
      }
      setState(() {
        items.insert(index, item);
      });
    }
  }

  Future<void> _saveImageToDirectory(int sceneNum, String base64Image) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String defaultFolder = settings['current_novel_folder'];
    String saveDate = '';
    try {
      if (widget.isDirectlyInto!) {
        saveDate = novelTitle!.split('_')[1];
      } else {
        saveDate = currentDayStr();
      }
      String saveDirectory = "$defaultFolder${Platform.pathSeparator}images${Platform.pathSeparator}$saveDate";
      Directory directory = Directory(saveDirectory);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      Uint8List bytes = base64Decode(base64Image);
      String fullPath = path.join(saveDirectory, 'scene${sceneNum + 1}.png');
      File file = File(fullPath);
      await file.writeAsBytes(bytes);
    } catch (e) {
      if (mounted) {
        showHint('第$sceneNum个场景的图片下载并处理失败，原因是$e');
      }
    }
  }

  // 保存当前进度
  Future<void> _saveCurrentSchedule() async {
    if (mounted) {
      showHint('开始保存当前进度');
    }
    Map<String, dynamic> settings = await Config.loadSettings();
    String? appDefaultSaveFolder = settings['image_save_path'];
    String currentNovelTitle = '';
    String saveDate = '';
    if (widget.isDirectlyInto != null && widget.isDirectlyInto!) {
      currentNovelTitle = novelTitle!.split('_')[0];
      saveDate = novelTitle!.split('_')[1];
    } else {
      currentNovelTitle = settings['current_novel_title'];
      saveDate = currentDayStr();
    }
    if (appDefaultSaveFolder != null && appDefaultSaveFolder != '') {
      String historySavePath = '';
      if (appDefaultSaveFolder.endsWith('/') || appDefaultSaveFolder.endsWith('\\')) {
        historySavePath = '${appDefaultSaveFolder.substring(0, appDefaultSaveFolder.length - 1)}${Platform.pathSeparator}history';
      } else {
        historySavePath = '$appDefaultSaveFolder${Platform.pathSeparator}history';
      }
      String currentSavePath = '$historySavePath${Platform.pathSeparator}$currentNovelTitle${Platform.pathSeparator}$saveDate';
      await commonCreateDirectory(currentSavePath);
      String historyFilePath = '$currentSavePath${Platform.pathSeparator}history.json';
      await getFileByPath(historyFilePath);
      Map<String, dynamic> defaultContents = {'contents': []};
      await modifyFileContentByPath(defaultContents, historyFilePath);
      List<dynamic> contentList = [];
      for (int i = 0; i < items.length; i++) {
        Map<String, dynamic> content = {};
        content['index'] = items[i].index;
        content['prompt'] = items[i].prompt;
        content['useImagePath'] = items[i].useImagePath;
        content['imageChangeType'] = items[i].imageChangeType;
        content['characterPreset'] = items[i].characterPreset;
        content['allScenes'] = items[i].allScenes;
        content['isAlreadyUpScale'] = items[i].isAlreadyUpScale;
        content['isAlreadyUpScaleRepair'] = items[i].isAlreadyUpScaleRepair;
        content['imagesDownloadStatus'] = items[i].imagesDownloadStatus;
        content['isSingleImageDownloaded'] = items[i].isSingleImageDownloaded;
        // content['imageBase64List'] = items[i].imageBase64List;
        content['imageUrlList'] = items[i].imageUrlList;
        content['controlNetOptions'] = items[i].controlNetOptions;
        content['aDetailsOptions'] = items[i].aDetailsOptions;
        content['useAiMode'] = items[i].useAiMode;
        content['useFix'] = items[i].useFix;
        content['drawEngine'] = items[i].drawEngine;
        content['useControlnet'] = items[i].useControlnet;
        content['aiSceneText'] = items[i].aiSceneController.text;
        content['transSceneText'] = items[i].transSceneController.text;
        content['actions'] = items[i].actions ?? [];
        content['actions2'] = items[i].actions2 ?? [];
        content['actions3'] = items[i].actions3 ?? [];
        content['actions4'] = items[i].actions4 ?? [];
        content['taskId'] = items[i].taskId;
        content['imageId'] = items[i].imageId;
        content['selectedImagePosition'] = items[i].selectedImagePosition;
        content['operatedImageId'] = items[i].operatedImageId ?? '';
        content['useImageUrl'] = items[i].useImageUrl ?? '';
        contentList.add(content);
      }
      Map<String, dynamic> fileContent = await getFileContentByPath(historyFilePath);
      fileContent['contents'] = contentList;
      await modifyFileContentByPath(fileContent, '$currentSavePath${Platform.pathSeparator}history.json', needOriginalContent: false);
      if (mounted) {
        showHint('当前进度保存完成', showType: 2);
      }
    } else {
      if (mounted) {
        showHint('当前进度保存失败，原因是默认文件保存目录为空，请在设置中配置默认保存路径', showType: 3);
      }
    }
  }

  // 加载历史项目
  Future<void> _loadHistoryProgram() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String historyPath = '${settings['image_save_path']}${Platform.pathSeparator}history';
    final directory = Directory(historyPath);
    if (directory.existsSync()) {
      final folderCount = countSubFolders(historyPath);
      if (folderCount > 0) {
        try {
          List<String> historyTitles = getSubdirectories(historyPath);

          if (historyTitles.isNotEmpty) {
            if (mounted) {
              setState(() {
                _selectedHistoryTitle = historyTitles[0];
              });
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return CustomDialog(
                    title: '选择一个历史记录',
                    titleColor: Colors.white,
                    description: null,
                    maxWidth: 500,
                    confirmButtonText: '确认',
                    cancelButtonText: '取消',
                    contentBackgroundColor: Colors.black,
                    contentBackgroundOpacity: 0.5,
                    content: Padding(
                        padding: const EdgeInsets.all(10),
                        child: CommonDropdownWidget(
                            selectedValue: _selectedHistoryTitle,
                            dropdownData: historyTitles,
                            onChangeValue: (historyTitle) {
                              setState(() {
                                _selectedHistoryTitle = historyTitle;
                              });
                            })),
                    onCancel: () {},
                    onConfirm: () {
                      novelTitle = _selectedHistoryTitle;
                      readHistoryInfo();
                    },
                  );
                },
              );
            }
          } else {
            if (mounted) {
              showHint('未发现存在历史记录');
            }
          }
        } catch (e) {
          commonPrint('An error occurred: $e');
        }
      } else {
        if (mounted) {
          showHint('未发现存在历史记录');
        }
      }
    } else {
      if (mounted) {
        showHint('未发现存在历史记录');
      }
    }
  }

  // 清除历史项目
  Future<void> _deleteHistoryProgram() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String historyPath = '${settings['image_save_path']}${Platform.pathSeparator}history';
    final directory = Directory(historyPath);
    if (directory.existsSync()) {
      final folderCount = countSubFolders(historyPath);
      if (folderCount > 0) {
        try {
          List<String> historyTitles = getSubdirectories(historyPath);

          if (historyTitles.isNotEmpty) {
            if (mounted) {
              setState(() {
                _selectedHistoryTitle = historyTitles[0];
              });
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return CustomDialog(
                    title: '选择一个历史记录',
                    titleColor: Colors.white,
                    description: null,
                    maxWidth: 500,
                    confirmButtonText: '确认',
                    cancelButtonText: '取消',
                    contentBackgroundColor: Colors.black,
                    contentBackgroundOpacity: 0.5,
                    content: Padding(
                        padding: const EdgeInsets.all(10),
                        child: CommonDropdownWidget(
                            selectedValue: _selectedHistoryTitle,
                            dropdownData: historyTitles,
                            onChangeValue: (historyTitle) {
                              setState(() {
                                _selectedHistoryTitle = historyTitle;
                              });
                            })),
                    onCancel: () {},
                    onConfirm: () async {
                      Map<String, dynamic> settings = await Config.loadSettings();
                      String defaultPath = settings['image_save_path'];
                      String historyJsonPath = '$defaultPath${Platform.pathSeparator}history${Platform.pathSeparator}${novelTitle!.split('_')[0]}';
                      await deleteFolder(historyJsonPath);
                      if (context.mounted) {
                        showHint('删除成功');
                      }
                    },
                  );
                },
              );
            }
          } else {
            if (mounted) {
              showHint('未发现存在历史记录');
            }
          }
        } catch (e) {
          commonPrint('An error occurred: $e');
        }
      } else {
        if (mounted) {
          showHint('未发现存在历史记录');
        }
      }
    } else {
      if (mounted) {
        showHint('未发现存在历史记录');
      }
    }
  }

  void _onImageTapped(String currentIndex, int position, List<String> images) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    int? imageHeight = settings['height'];
    int? imageWidth = settings['width'];
    if (imageHeight != null && imageWidth != null) {
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;
    }
    int index = int.parse(currentIndex) - 1;
    int selectedIndex = position;
    String useImagePath = images[position];
    if (mounted) {
      final changeSettings = context.read<ChangeSettings>();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomDialog(
            title: null,
            showCancelButton: false,
            description: null,
            contentBackgroundColor: changeSettings.getBackgroundColor(),
            // 设置透明度，值在0.0到1.0之间
            maxWidth: 800,
            confirmButtonText: '选择此图片为场景图',
            conformButtonColor: changeSettings.getSelectedBgColor(),
            content: Padding(
                padding: const EdgeInsets.all(16),
                child: CustomCarousel(
                  currentIndex: position,
                  imagePaths: images,
                  autoScroll: false,
                  aspectRatio: _imageWidth / _imageHeight,
                  onPageChangedCallback: (int scrollIndex, String imagePath) {
                    useImagePath = imagePath;
                    selectedIndex = scrollIndex;
                  },
                  onImageDoubleTap: (int doubleClickIndex) {
                    Navigator.of(context).pop();
                    useImagePath = images[doubleClickIndex];
                    setState(() {
                      items[index].useImagePath = useImagePath;
                      items[index].isAlreadyUpScale = false;
                      items[index].isAlreadyUpScaleRepair = false;
                      items[index].isSingleImageDownloaded = false;
                      items[index].selectedImagePosition = doubleClickIndex;
                    });
                  },
                )),
            onConfirm: () {
              setState(() {
                items[index].useImagePath = useImagePath;
                items[index].isAlreadyUpScale = false;
                items[index].isAlreadyUpScaleRepair = false;
                items[index].isSingleImageDownloaded = false;
                items[index].selectedImagePosition = selectedIndex;
              });
            },
          );
        },
      );
    }
  }

  void _onSingleImageTapped(String currentIndex) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    int? imageHeight = settings['height'];
    int? imageWidth = settings['width'];
    if (imageHeight != null && imageWidth != null) {
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;
    }
    int index = int.parse(currentIndex) - 1;
    String useImagePath = items[index].useImagePath;
    List<String> images = [useImagePath];
    if (mounted) {
      final changeSettings = context.read<ChangeSettings>();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomDialog(
            title: null,
            showCancelButton: false,
            showConfirmButton: false,
            description: null,
            maxWidth: 800,
            contentBackgroundColor: changeSettings.getBackgroundColor(),
            content: Padding(
                padding: const EdgeInsets.all(16),
                child: CustomCarousel(
                  currentIndex: 0,
                  imagePaths: images,
                  autoScroll: false,
                  isNeedIndicator: false,
                  aspectRatio: _imageWidth / _imageHeight,
                  onPageChangedCallback: (int index, String imagePath) {
                    useImagePath = imagePath;
                  },
                )),
          );
        },
      );
    }
  }

  Future<int> getAudioDuration(String filePath) async {
    int? duration = 0;
    AudioPlayer audioPlayer = AudioPlayer();
    var thisDuration = await audioPlayer.setFilePath(filePath);
    if (thisDuration != null) {
      duration = thisDuration.inMicroseconds;
    }
    return duration;
  }

  Future<List<Map<String, dynamic>>> generateCanvasJson(int imageNumber) async {
    List<Map<String, dynamic>> canvases = [];
    Map<String, dynamic> jsonData = {
      "album_image": "",
      "blur": 0.0,
      "color": "",
      "id": "",
      "image": "",
      "image_id": "",
      "image_name": "",
      "source_platform": 0,
      "team_id": "",
      "type": "canvas_color"
    };

    for (int i = 0; i < imageNumber; i++) {
      Map<String, dynamic> canvas = deepCopy(jsonData);
      canvas["id"] = generateDraftId(true);
      canvases.add(canvas);
    }
    return canvases;
  }

  Future<Map<String, dynamic>> generateVideoJson(int duration, String filePath, int height, int width) async {
    String materialName = filePath.split(Platform.pathSeparator).last;
    String id = generateDraftId(true);

    Map<String, dynamic> jsonData = {
      "audio_fade": null,
      "cartoon_path": "",
      "category_id": "",
      "category_name": "local",
      "check_flag": 63487,
      "crop": {
        "lower_left_x": 0.0,
        "lower_left_y": 1.0,
        "lower_right_x": 1.0,
        "lower_right_y": 1.0,
        "upper_left_x": 0.0,
        "upper_left_y": 0.0,
        "upper_right_x": 1.0,
        "upper_right_y": 0.0
      },
      "crop_ratio": "free",
      "crop_scale": 1.0,
      "duration": 10800000000,
      "extra_type_option": 0,
      "formula_id": "",
      "freeze": null,
      "gameplay": null,
      "has_audio": false,
      "height": height,
      "id": id,
      "intensifies_audio_path": "",
      "intensifies_path": "",
      "is_ai_generate_content": false,
      "is_unified_beauty_mode": false,
      "local_id": "",
      "local_material_id": "",
      "material_id": "",
      "material_name": materialName,
      "material_url": "",
      "matting": {"flag": 0, "has_use_quick_brush": false, "has_use_quick_eraser": false, "interactiveTime": [], "path": "", "strokes": []},
      "media_path": "",
      "object_locked": null,
      "origin_material_id": "",
      "path": filePath,
      "picture_from": "none",
      "picture_set_category_id": "",
      "picture_set_category_name": "",
      "request_id": "",
      "reverse_intensifies_path": "",
      "reverse_path": "",
      "source_platform": 0,
      "stable": null,
      "team_id": "",
      "type": "photo",
      "video_algorithm": {"algorithms": [], "deflicker": null, "motion_blur_config": null, "noise_reduction": null, "path": "", "time_range": null},
      "width": width
    };

    return jsonData;
  }

  Future<Map<String, dynamic>> generateAudiosJson() async {
    Map<String, dynamic> jsonData = {
      "app_id": 0,
      "category_id": "local",
      "category_name": "local_music",
      "check_flag": 1,
      "duration": 108083333,
      "effect_id": "",
      "formula_id": "",
      "id": "",
      "intensifies_path": "",
      "local_material_id": "",
      "music_id": "",
      "name": "",
      "path": "",
      "request_id": "",
      "resource_id": "",
      "source_platform": 0,
      "team_id": "",
      "text_id": "",
      "tone_category_id": "",
      "tone_category_name": "",
      "tone_effect_id": "",
      "tone_effect_name": "",
      "tone_speaker": "",
      "tone_type": "",
      "type": "extract_music",
      "video_id": "",
      "wave_points": []
    };

    return jsonData;
  }

  Future<Map<String, dynamic>> generateAudioJson(int duration, String filePath, String extraInfo) async {
    Map<String, dynamic> jsonData = {
      "create_time": 0,
      "duration": duration,
      "extra_info": extraInfo,
      "file_Path": filePath,
      "height": 0,
      "id": generateDraftId(true),
      "import_time": DateTime.now().millisecondsSinceEpoch,
      "import_time_ms": -1,
      "item_source": 1,
      "md5": "",
      "metatype": "none",
      "roughcut_time_range": {"duration": -1, "start": -1},
      "sub_time_range": {"duration": -1, "start": -1},
      "type": 1,
      "width": 0
    };

    return jsonData;
  }

  Future<Map<String, dynamic>> generateTracksAudioJson(List<String> voiceFiles, List<String> voiceMaterialIds, List<int> voiceDurations) async {
    Map<String, dynamic> jsonData = {
      "attribute": 0,
      "flag": 0,
      "id": generateDraftId(true),
      "segments": await generateSegmentsAudioJson(voiceFiles, voiceMaterialIds, voiceDurations),
      "type": "audio"
    };
    return jsonData;
  }

  Future<List<Map<String, dynamic>>> generateSegmentsAudioJson(
      List<String> voiceFiles, List<String> voiceMaterialIds, List<int> voiceDurations) async {
    List<Map<String, dynamic>> segments = [];
    List<String> extraMaterialRefs = [generateDraftId(true), generateDraftId(true), generateDraftId(true)];

    Map<String, dynamic> jsonData = {
      "cartoon": false,
      "clip": null,
      "common_keyframes": [],
      "enable_adjust": false,
      "enable_color_curves": true,
      "enable_color_wheels": true,
      "enable_lut": false,
      "enable_smart_color_adjust": false,
      "extra_material_refs": extraMaterialRefs,
      "group_id": "",
      "hdr_settings": null,
      "id": generateDraftId(true),
      "intensifies_audio": false,
      "is_placeholder": false,
      "is_tone_modify": false,
      "keyframe_refs": [],
      "last_nonzero_volume": 1.0,
      "material_id": generateDraftId(true),
      "render_index": 0,
      "reverse": false,
      "source_timerange": {"duration": 8150000, "start": 0},
      "speed": 1.0,
      "target_timerange": {"duration": 8150000, "start": 0},
      "template_id": "",
      "template_scene": "default",
      "track_attribute": 0,
      "track_render_index": 0,
      "uniform_scale": null,
      "visible": true,
      "volume": 1.0
    };

    int accumulatedDuration = 0;
    for (int i = 0; i < voiceFiles.length; i++) {
      Map<String, dynamic> segment = deepCopy(jsonData); // 创建新的 Map 实例
      String id = generateDraftId(true);
      segment['id'] = id;
      segment['material_id'] = voiceMaterialIds[i];
      segment['extra_material_refs'] = List<String>.from(extraMaterialRefs.map((ref) => generateDraftId(true))); // 创建新的 List 实例
      segment['source_timerange'] = {
        "duration": voiceDurations[i],
        "start": 0,
      };
      segment['target_timerange'] = {
        "duration": voiceDurations[i],
        "start": accumulatedDuration,
      };
      segments.add(segment);
      accumulatedDuration += voiceDurations[i];
    }

    return segments;
  }

  Future<Map<String, dynamic>> generateTracksImageJson(int imagesNumber, bool applyAll, int keyFramesType, List<int> keyFramesTypes,
      List<String> imagePaths, List<String> videosIds, List<int> voiceDurations) async {
    Map<String, dynamic> jsonData = {
      "attribute": 0,
      "flag": 0,
      "id": generateDraftId(true),
      "segments": await generateSegmentsImageJson(imagesNumber, applyAll, keyFramesType, keyFramesTypes, imagePaths, videosIds, voiceDurations),
      "type": "video"
    };
    return jsonData;
  }

  Future<List<Map<String, dynamic>>> generateSegmentsImageJson(int imagesNumber, bool applyAll, int keyFramesType, List<int> keyFramesTypes,
      List<String> imagePaths, List<String> videosIds, List<int> voiceDurations) async {
    List<Map<String, dynamic>> segments = List.filled(imagesNumber, {});
    Map<String, dynamic> jsonData = {
      "cartoon": false,
      "clip": {
        "alpha": 1.0,
        "flip": {"horizontal": false, "vertical": false},
        "rotation": 0.0,
        "scale": {"x": 1.33, "y": 1.33},
        "transform": {"x": 0.0, "y": 0.0}
      },
      "common_keyframes": List.filled(2, {}),
      "enable_adjust": true,
      "enable_color_curves": true,
      "enable_color_wheels": true,
      "enable_lut": true,
      "enable_smart_color_adjust": false,
      "extra_material_refs": List.filled(3, ''),
      "group_id": "",
      "hdr_settings": {"intensity": 1.0, "mode": 1, "nits": 1000},
      "id": "",
      "intensifies_audio": false,
      "is_placeholder": false,
      "is_tone_modify": false,
      "keyframe_refs": [],
      "last_nonzero_volume": 1.0,
      "material_id": "",
      "render_index": 0,
      "reverse": false,
      "source_timerange": {"duration": 3000000, "start": 0},
      "speed": 1.0,
      "target_timerange": {"duration": 3000000, "start": 0},
      "template_id": "",
      "template_scene": "default",
      "track_attribute": 0,
      "track_render_index": 0,
      "uniform_scale": {"on": true, "value": 1.0},
      "visible": true,
      "volume": 1.0
    };
    int preFrameType = 0;
    for (int i = 0; i < imagesNumber; i++) {
      late double scaleX, scaleY, transformX, transformY, values0, values1;
      Map<String, dynamic> segment = deepCopy(jsonData);
      segment['id'] = generateDraftId(true);
      segment['material_id'] = videosIds[i];
      int frameType = keyFramesTypes[i];
      int width = 512, height = 512;
      final image = img.decodeImage(File(imagePaths[i]).readAsBytesSync());
      if (image != null) {
        width = image.width;
        height = image.height;
      }
      for (int k = 0; k < 3; k++) {
        segment['extra_material_refs'][k] = generateDraftId(true);
      }
      Map<String, dynamic> commonKeyframesJson_1 = await generateCommonKeyframesJson();
      Map<String, dynamic> commonKeyframesJson_2 = await generateCommonKeyframesJson();

      commonKeyframesJson_1['id'] = generateDraftId(true);
      commonKeyframesJson_1['keyframe_list'][0]['id'] = generateDraftId(true);
      commonKeyframesJson_1['keyframe_list'][1]['id'] = generateDraftId(true);
      commonKeyframesJson_2['property_type'] = 'KFTypePositionY';
      commonKeyframesJson_2['id'] = generateDraftId(true);
      commonKeyframesJson_2['keyframe_list'][0]['id'] = generateDraftId(true);
      commonKeyframesJson_2['keyframe_list'][1]['id'] = generateDraftId(true);
      if (voiceDurations.length == imagesNumber) {
        segment['source_timerange']['duration'] = voiceDurations[i];
        segment['target_timerange']['duration'] = voiceDurations[i];
        commonKeyframesJson_1['keyframe_list'][1]['time_offset'] = voiceDurations[i];
        commonKeyframesJson_2['keyframe_list'][1]['time_offset'] = voiceDurations[i];
      }
      void updateKeyframes(scaleX, scaleY, transformX, transformY, values0, values1) {
        segment['clip']['scale']['x'] = scaleX;
        segment['clip']['scale']['y'] = scaleY;
        segment['clip']['transform']['x'] = transformX;
        segment['clip']['transform']['y'] = transformY;
        commonKeyframesJson_2['keyframe_list'][0]['values'][0] = values0;
        commonKeyframesJson_2['keyframe_list'][1]['values'][0] = values1;
        segment['common_keyframes'][0] = commonKeyframesJson_1;
        segment['common_keyframes'][1] = commonKeyframesJson_2;
      }

      Map<String, List<double>> scaleValues = {
        "1:1": [1.33, 1.33],
        "9:16": [2.368755676657584, 2.368755676657584],
        "16:9": [1.3342422176778004, 1.3342422176778004],
      };
      Map<int, List<double>> transformValues = {
        1: [0, 0.33, -0.33, 0.33],
        2: [0, -0.33, 0.33, -0.33],
        3: [-0.33424221767780027, 0, 0.3342422176778004, -0.3342422176778004],
        4: [0.33424221767780027, 0, -0.3342422176778004, 0.3342422176778004],
      };
      int imagePortion() {
        var tolerance = 1e-6;
        if (width == height) {
          return 0;
        } else if ((width * 9 / 16 - height).abs() < tolerance) {
          return 1;
        } else if ((width * 16 / 9 - height).abs() < tolerance) {
          return 2;
        }
        return 3;
      }

      if (frameType == 0) {
        if (imagePortion() == 0) {
          segment['clip']['scale']['x'] = 1.33;
          segment['clip']['scale']['y'] = 1.33;
        } else if (imagePortion() == 1) {
          segment['clip']['scale']['x'] = 2.368755676657584;
          segment['clip']['scale']['y'] = 2.368755676657584;
        } else if (imagePortion() == 2) {
          segment['clip']['scale']['x'] = 1.3342422176778004;
          segment['clip']['scale']['y'] = 1.3342422176778004;
        }
      } else if (frameType == 1 || frameType == 2 || frameType == 3 || frameType == 4) {
        String aspectRatio = "1:1";
        if (imagePortion() == 0) {
          aspectRatio = "1:1";
        } else if (imagePortion() == 1) {
          aspectRatio = "9:16";
        } else if (imagePortion() == 2) {
          aspectRatio = "16:9";
        }
        if (scaleValues.containsKey(aspectRatio)) {
          scaleX = scaleValues[aspectRatio]![0];
          scaleY = scaleValues[aspectRatio]![1];
        } else {
          commonPrint("第{i}张图片比例未知，无法处理。");
          continue;
        }
        if (transformValues.containsKey(frameType)) {
          transformX = transformValues[frameType]![0];
          transformY = transformValues[frameType]![1];
          values0 = transformValues[frameType]![2];
          values1 = transformValues[frameType]![3];
        }
        if ((aspectRatio == "1:1") && (frameType == 3 || frameType == 4)) {
          if (mounted) {
            showHint("第$i张图片比例为1:1,这种比例目前不支持从左到右或者从右到左的关键帧，自动转换为从上到下或者从下到上");
          }
        }
        if ((aspectRatio == "16:9") && (frameType == 1 || frameType == 2)) {
          if (mounted) {
            showHint("第$i张图片比例为16:9,这种比例目前不支持从上到下或者从下到上的关键帧，自动转换为从左到右或者从右到左");
          }
        }
        if ((aspectRatio == "9:16") && (frameType == 3 || frameType == 4)) {
          if (mounted) {
            showHint("第$i张图片比例为9:16,这种比例目前不支持从左到右或者从右到左的关键帧，自动转换为从上到下或者从下到上");
          }
        }
        updateKeyframes(scaleX, scaleY, transformX, transformY, values0, values1);
      } else if (frameType == 5) {
        int updateKeyframesAndReturnTransformKey(String scaleKey, int transformKey) {
          var scaleX = scaleValues[scaleKey]![0];
          var scaleY = scaleValues[scaleKey]![1];
          var transformX = transformValues[transformKey]![0];
          var transformY = transformValues[transformKey]![1];
          var values0 = transformValues[transformKey]![2];
          var values1 = transformValues[transformKey]![3];
          updateKeyframes(scaleX, scaleY, transformX, transformY, values0, values1);
          return transformKey;
        }

        List<List<dynamic>> conditionsAndKeys = [
          [imagePortion() == 0, "1:1"],
          [imagePortion() == 1, "9:16"],
          [imagePortion() == 2, "16:9"],
        ];
        for (int n = 0; n < conditionsAndKeys.length; n++) {
          bool condition = conditionsAndKeys[n][0];
          String scaleKey = conditionsAndKeys[n][1];
          if (condition) {
            if (preFrameType == 0) {
              preFrameType = updateKeyframesAndReturnTransformKey(scaleKey, 1);
            } else if ((preFrameType == 1 || preFrameType == 4) && scaleKey != '16:9') {
              preFrameType = updateKeyframesAndReturnTransformKey(scaleKey, 2);
            } else if ((preFrameType == 2 || preFrameType == 3) && scaleKey != '16:9') {
              preFrameType = updateKeyframesAndReturnTransformKey(scaleKey, 1);
            } else if ((preFrameType == 1 || preFrameType == 3) && scaleKey != '16:9') {
              preFrameType = updateKeyframesAndReturnTransformKey(scaleKey, 4);
            } else if ((preFrameType == 2 || preFrameType == 4) && scaleKey != '16:9') {
              preFrameType = updateKeyframesAndReturnTransformKey(scaleKey, 3);
            }
            break;
          }
        }
      }
      segments[i] = segment;
    }
    return segments;
  }

  Future<Map<String, dynamic>> generateCommonKeyframesJson() async {
    return {
      "id": "",
      "keyframe_list": [
        {
          "curveType": "Line",
          "graphID": "",
          "id": "",
          "left_control": {"x": 0.0, "y": 0.0},
          "right_control": {"x": 0.0, "y": 0.0},
          "time_offset": 0,
          "values": [0.0]
        },
        {
          "curveType": "Line",
          "graphID": "",
          "id": "",
          "left_control": {"x": 0.0, "y": 0.0},
          "right_control": {"x": 0.0, "y": 0.0},
          "time_offset": 3000000,
          "values": [0.0]
        }
      ],
      "property_type": "KFTypePositionX"
    };
  }

  void _saveDraft() async {
    showHint('本次草稿一共需要下载并处理${items.length}张图片，请耐心等待...', showType: 5);
    // 去除了自动保存图片的功能，这里需要先批量保存图片,大量图片的时候会比较慢
    try {
      for (int i = 0; i < items.length; i++) {
        if (mounted) {
          showHint('正在下载并处理第${i + 1}张图片');
        }
        String usedImagePath = await imageUrlToBase64(items[i].useImagePath);
        if (usedImagePath != '') {
          _saveImageToDirectory(i, usedImagePath);
        }
      }
      showHint('正在生成草稿文件，请稍等...', showType: 5);
      Map<String, dynamic> settings = await Config.loadSettings();
      String? novelTitle = settings['current_novel_title'];
      String? jyDraftFolder = settings['jy_draft_save_path'];
      String? currentNovelFolder = settings['current_novel_folder'];
      DateTime currentDate = DateTime.now();
      String formatDate = DateFormat('yyyyMMdd').format(currentDate);
      if (jyDraftFolder == null || jyDraftFolder == '') {
        if (mounted) {
          showHint('请先在设置页面填写剪映草稿保存路径', showTime: 5, showPosition: 2);
        }
        dismissHint();
        return;
      }
      if (currentNovelFolder == null || currentNovelFolder == '') {
        if (mounted) {
          showHint('当前小说文件夹为空，无法合成草稿');
        }
        return;
      } else {
        String saveDate = '';
        if (widget.isDirectlyInto!) {
          saveDate = novelTitle!.split('_')[1];
        } else {
          saveDate = currentDayStr();
        }
        novelTitle ??= currentDayStr();
        await commonCreateDirectory('$jyDraftFolder${Platform.pathSeparator}${novelTitle}_${currentDayStr()}');
        String currentDraftFolder = '$jyDraftFolder${Platform.pathSeparator}${novelTitle}_${currentDayStr()}';
        String attachmentPcCommonJsonStr = jsonEncode(attachmentPcCommon);
        String draftAgencyConfigJsonStr = jsonEncode(draftAgencyConfig);
        String draftContentJsonStr = jsonEncode(draftContent);
        String draftMetaInfoJsonStr = jsonEncode(draftMetaInfo);
        File('$currentDraftFolder/attachment_pc_common.json').writeAsStringSync(attachmentPcCommonJsonStr);
        File('$currentDraftFolder/draft_agency_config.json').writeAsStringSync(draftAgencyConfigJsonStr);
        File('$currentDraftFolder/draft_content.json').writeAsStringSync(draftContentJsonStr);
        File('$currentDraftFolder/draft_meta_info.json').writeAsStringSync(draftMetaInfoJsonStr);
        Map<String, dynamic> contentData = await getFileContentByPath('$currentDraftFolder${Platform.pathSeparator}draft_content.json');
        Map<String, dynamic> metaInfoData = await getFileContentByPath('$currentDraftFolder${Platform.pathSeparator}draft_meta_info.json');
        List<String> allSelectedImages =
            await getAllFilePaths('$currentNovelFolder${Platform.pathSeparator}images${Platform.pathSeparator}$saveDate');
        List<String> allVoices = await getAllFilePaths('$currentNovelFolder${Platform.pathSeparator}audio${Platform.pathSeparator}$saveDate');
        await cropAndSaveImage(allSelectedImages[0], '$jyDraftFolder${Platform.pathSeparator}${novelTitle}_${currentDayStr()}');
        metaInfoData['draft_fold_path'] = currentDraftFolder;
        metaInfoData['draft_id'] = generateDraftId(true);
        metaInfoData['draft_name'] = path.basename(currentDraftFolder);
        metaInfoData['draft_removable_storage_device'] = splitDrive(currentDraftFolder)[0];
        metaInfoData['tm_draft_create'] = getTimestamp();
        metaInfoData['tm_draft_modified'] = getTimestamp();
        metaInfoData['draft_materials'][0]['value'] = List.filled(allSelectedImages.length, {});
        List<int> metaInfoDurations = [];
        metaInfoData['draft_materials'][1]['value'] = List.filled(allSelectedImages.length, {});
        if (allVoices.isNotEmpty) {
          for (int i = 0; i < allVoices.length; i++) {
            int audioDuration = await getAudioDuration(allVoices[i]);
            metaInfoData['draft_materials'][1]['value'][i] = await generateAudioJson(audioDuration, allVoices[i], '提取音频$formatDate-${i + 1}');
          }
        }
        for (int i = 0; i < allSelectedImages.length; i++) {
          final image = img.decodeImage(File(allSelectedImages[i]).readAsBytesSync());
          if (image != null) {
            if (allSelectedImages.length == allVoices.length) {
              int audioDuration = await getAudioDuration(allVoices[i]);
              metaInfoDurations.add(audioDuration);
              metaInfoData['draft_materials'][0]['value'][i] =
                  await generatePhotoJson(audioDuration, allSelectedImages[i], image.height, image.width);
            } else {
              if (mounted) {
                showHint('图片数量和音频数量不匹配无法自动调整图片切换时长', showPosition: 2);
              }
              metaInfoData['draft_materials'][0]['value'][i] = await generatePhotoJson(3000000, allSelectedImages[i], image.height, image.width);
            }
          }
        }
        if (allVoices.length == allSelectedImages.length) {
          int totalDuration = 0;
          for (int i = 0; i < allVoices.length; i++) {
            int audioDuration = await getAudioDuration(allVoices[i]);
            totalDuration += audioDuration;
            metaInfoDurations.add(audioDuration);
          }
          metaInfoData['tm_duration'] = totalDuration;
        } else {
          metaInfoData['tm_duration'] = 3000000 * allSelectedImages.length;
        }
        contentData['tracks'] = List.filled(1, {});
        List<String> voiceMaterialIds = [];
        List<int> contentVoiceDurations = [];
        if (allSelectedImages.length == allVoices.length) {
          contentData['tracks'] = List.filled(2, {});
          contentData['materials']['audios'] = List.filled(allSelectedImages.length, {});
          int totalDuration = 0;
          for (int i = 0; i < allSelectedImages.length; i++) {
            Map<String, dynamic> audioJson = await generateAudiosJson();
            int audioDuration = await getAudioDuration(allVoices[i]);
            contentVoiceDurations.add(audioDuration);
            audioJson['id'] = generateDraftId(true);
            audioJson['duration'] = audioDuration;
            audioJson['music_id'] = generateDraftId(false);
            audioJson['name'] = '提取音频$formatDate-${i + 1}';
            audioJson['path'] = allVoices[i];
            voiceMaterialIds.add(audioJson['id']);
            contentData['materials']['audios'][i] = audioJson;
            totalDuration += audioDuration;
          }
          contentData['duration'] = totalDuration;
          contentData['tracks'][1] = await generateTracksAudioJson(allVoices, voiceMaterialIds, contentVoiceDurations);
        } else {
          contentData['duration'] = 3000000 * allSelectedImages.length;
        }
        contentData['canvas_config']['ratio'] = '4:3';
        contentData['id'] = generateDraftId(true);
        contentData['last_modified_platform']['device_id'] = getDeviceId();
        contentData['last_modified_platform']['hard_disk_id'] = await getHardDiskId();
        contentData['last_modified_platform']['mac_address'] = await getMacAddress();
        contentData['last_modified_platform']['os'] = getOS();
        contentData['last_modified_platform']['os_version'] = await getOSVersion();
        contentData['platform']['device_id'] = getDeviceId();
        contentData['platform']['hard_disk_id'] = await getHardDiskId();
        contentData['platform']['mac_address'] = await getMacAddress();
        contentData['platform']['os'] = getOS();
        contentData['platform']['os_version'] = await getOSVersion();
        contentData['materials']['canvases'] = await generateCanvasJson(allSelectedImages.length);
        contentData['materials']['videos'] = List.filled(allSelectedImages.length, {});
        contentData['materials']['sound_channel_mappings'] = List.filled(allSelectedImages.length, {});
        contentData['materials']['speeds'] = List.filled(allSelectedImages.length, {});
        Map<String, dynamic> soundChannelMappingJson = {"audio_channel_mapping": 0, "id": "", "is_config_open": false, "type": ""};
        Map<String, dynamic> speedJson = {"curve_speed": null, "id": "", "mode": 0, "speed": 1.0, "type": "speed"};
        List<String> videosIds = [];
        for (int i = 0; i < allSelectedImages.length; i++) {
          soundChannelMappingJson['id'] = generateDraftId(true);
          speedJson['id'] = generateDraftId(true);
          final image = img.decodeImage(File(allSelectedImages[i]).readAsBytesSync());
          if (image != null) {
            contentData['materials']['videos'][i] = await generateVideoJson(0, allSelectedImages[i], image.height, image.width);
          }
          contentData['materials']['sound_channel_mappings'][i] = soundChannelMappingJson;
          contentData['materials']['speeds'][i] = speedJson;
          videosIds.add(contentData['materials']['videos'][i]['id']);
        }
        List<int> imageKeyFrames = [];
        for (var i = 0; i < items.length; i++) {
          String imageChangeType = items[i].imageChangeType;
          int type = int.tryParse(imageChangeType.split('.')[0]) ?? 5;
          imageKeyFrames.add(type);
        }
        contentData['tracks'][0] =
            await generateTracksImageJson(allSelectedImages.length, false, 0, imageKeyFrames, allSelectedImages, videosIds, contentVoiceDurations);
        await modifyFileContentByPath(metaInfoData, '$currentDraftFolder${Platform.pathSeparator}draft_meta_info.json');
        await modifyFileContentByPath(contentData, '$currentDraftFolder${Platform.pathSeparator}draft_content.json');
      }
      showHint('剪映草稿合成完毕', showType: 2);
      await Future.delayed(const Duration(seconds: 1));
      dismissHint();
    } catch (e) {
      if (mounted) {
        showHint('合成草稿失败，原因是未知错误', showType: 3);
      }
      commonPrint('合成草稿失败,原因是未知错误$e');
      dismissHint();
    }
  }

  Future<Map<String, dynamic>> generatePhotoJson(int duration, String filePath, int height, int width) async {
    String extraInfo = path.basename(filePath);
    int createTime = DateTime.now().millisecondsSinceEpoch;
    int importTime = createTime;
    int importTimeMs = createTime * 1000000;

    Map<String, dynamic> jsonMap = {
      "create_time": createTime,
      "duration": duration,
      "extra_info": extraInfo,
      "file_Path": filePath,
      "height": height,
      "id": generateDraftId(false),
      "import_time": importTime,
      "import_time_ms": importTimeMs,
      "item_source": 1,
      "metetype": "photo",
      "roughcut_time_range": {"duration": -1, "start": -1},
      "sub_time_range": {"duration": -1, "start": -1},
      "type": 0,
      "width": width
    };
    return jsonMap;
  }

  //合成剪映草稿封面图
  Future<void> cropAndSaveImage(String imageFilePath, String targetFolderPath, {String targetFileName = 'draft_cover.jpg'}) async {
    final image = img.decodeImage(File(imageFilePath).readAsBytesSync())!;
    final width = image.width;
    final height = image.height;
    final aspectRatio = width / height;
    late int cropWidth, cropHeight, left, top;
    if (aspectRatio == 1) {
      cropWidth = cropHeight = width < height ? width : height;
      left = ((width - cropWidth) / 2).round();
      top = ((height - cropHeight) / 2).round();
    } else if (aspectRatio > 1) {
      cropWidth = 720;
      cropHeight = (720 / 16 * 9).round();
      left = ((width - cropWidth) / 2).round();
      top = ((height - cropHeight) / 2).round();
    } else {
      cropWidth = (720 / 16 * 9).round();
      cropHeight = 720;
      left = ((width - cropWidth) / 2).round();
      top = ((height - cropHeight) / 2).round();
    }

    final croppedImage = img.copyCrop(image, x: left, y: top, width: cropWidth, height: cropHeight);

    Directory(targetFolderPath).createSync(recursive: true);
    final targetFilePath = File('$targetFolderPath/$targetFileName');
    targetFilePath.writeAsBytesSync(img.encodeJpg(croppedImage));
  }

  //图片变换
  Future<void> _onVariation(String currentIndex, {int type = 0}) async {
    dismissHint();
    Map<String, dynamic> settings = await Config.loadSettings();
    drawEngine = settings['drawEngine'] ?? 0;
    int index = int.parse(currentIndex) - 1;
    if (index >= 0 && index <= items.length - 1) {
      String imageId = items[index].imageId;
      String operatedImageId = items[index].operatedImageId;
      int usePosition = items[index].selectedImagePosition;
      List<String> imageBase64List = items[index].imageBase64List;
      List<String> imageUrlList = items[index].imageUrlList;
      Map<String, dynamic> payload = {};
      if (drawEngine == 1) {
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
        if (type == 0) {
          payload['action'] = items[index].actions[usePosition + 4];
          payload['image_id'] = imageId;
        } else {
          payload['action'] = items[index].actions2[type - 1];
          payload['image_id'] = operatedImageId;
        }
        dio.Response response;
        try {
          showHint('第$currentIndex场景的已选中图片变换中...', showType: 5);
          response = await myApi.mjDraw(drawSpeedType, token, payload);
          if (response.statusCode == 200) {
            dismissHint();
            response.data.stream.listen((data) async {
              final decodedData = utf8.decode(data);
              final jsonData = json.decode(decodedData);
              int progress = jsonData['progress'];
              if (mounted) {
                showHint('第$currentIndex个场景的图片的MJ变换绘制进度是$progress%', showType: 5);
              }
              if (progress == 100) {
                if (mounted) {
                  showHint('图片即将展示，请稍后...');
                }
                imageBase64List.clear();
                imageUrlList.clear();
                List<String> base64List = await splitImage(jsonData['image_url']);
                for (var element in base64List) {
                  imageBase64List.add(element);
                  String imageUrl = '';
                  String filePath = '';
                  File file = await base64ToTempFile(element);
                  if (file.existsSync()) {
                    filePath = file.path;
                  }
                  if (filePath != '') {
                    imageUrl = await uploadFileToALiOss(filePath, imageUrl, file);
                  }
                  imageUrlList.add(GlobalParams.filesUrl + imageUrl);
                }
                setState(() {
                  items[index].imageBase64List = imageBase64List;
                  items[index].imageUrlList = imageUrlList;
                  items[index].actions = List<String>.from(jsonData['actions']);
                  items[index].imageId = jsonData['image_id'];
                  items[index].taskId = jsonData['task_id'];
                  items[index].useImagePath = '';
                  items[index].isAlreadyVariation = false;
                  items[index].isAlreadyUpScale = false;
                  items[index].isAlreadyUpScaleRepair = false;
                  items[index].isSingleImageDownloaded = false;
                });
              }
            });
          } else {
            if (mounted) {
              showHint('MJ图片变换失败1,原因是${response.statusMessage}', showType: 3);
            }
          }
        } catch (e) {
          if (mounted) {
            showHint('MJ图片变换失败2,原因是$e', showType: 3);
          }
        } finally {
          dismissHint();
        }
      } else {
        List<dynamic> buttons = items[index].actions3;
        List<dynamic> buttons2 = items[index].actions4;
        if (type == 0) {
          String customId = buttons[usePosition + 5]['customId'];
          payload['customId'] = customId;
          payload['taskId'] = imageId;
        } else {
          String customId = buttons2[type]['customId'];
          payload['customId'] = customId;
          payload['taskId'] = operatedImageId;
        }
        dio.Response response;
        try {
          showHint('第$currentIndex场景的已选中图片变换中...', showType: 5);
          response = await myApi.selfMjDrawChange(payload);
          if (response.statusCode == 200) {
            if (response.data is String) {
              response.data = jsonDecode(response.data);
            }
            int code = response.data['code'] ?? -1;
            if (code == 1) {
              if (mounted) {
                showHint('第$currentIndex个场景的图片的MJ变换任务提交成功');
              }
              String result = response.data['result'];
              Map<String, dynamic> jobData = {result: index};
              createTaskQueue(jobData);
            } else {
              if (mounted) {
                showHint('第$currentIndex个场景的图片的MJ变换任务提交失败，原因是${response.data['description']}');
              }
            }
          } else {
            if (mounted) {
              showHint('自有MJ图片变换失败,原因是${response.statusMessage}', showType: 3);
            }
          }
        } catch (e) {
          if (mounted) {
            showHint('自有MJ图片变换失败,原因是$e', showType: 3);
          }
        } finally {
          dismissHint();
        }
      }
    }
  }

  Future<void> _onUpScale(String currentIndex) async {
    dismissHint();
    Map<String, dynamic> settings = await Config.loadSettings();
    drawEngine = settings['drawEngine'] ?? 0;
    int index = int.parse(currentIndex) - 1;
    if (index >= 0 && index <= items.length - 1) {
      String image = items[index].useImagePath;
      bool isAlreadyUpScale = items[index].isAlreadyUpScale;
      if (!isAlreadyUpScale) {
        if (drawEngine == 0) {
          String sdUrl = settings['sdUrl'] ?? '';
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
              showHint('第$currentIndex场景的已选中图片高清放大中...', showType: 5);
              response = await myApi.sdUpScaleImage(sdUrl, requestBody);
              if (response.statusCode == 200) {
                // String useImagePath = response.data['image'];
                String imageUrl = '';
                String filePath = '';
                File file = await base64ToTempFile(response.data['image']);
                if (file.existsSync()) {
                  filePath = file.path;
                }
                if (filePath != '') {
                  imageUrl = await uploadFileToALiOss(filePath, imageUrl, file);
                }
                setState(() {
                  items[index].useImagePath = GlobalParams.filesUrl + imageUrl;
                  items[index].isAlreadyUpScale = true;
                  items[index].isAlreadyUpScaleRepair = false;
                  items[index].isSingleImageDownloaded = false;
                });
              } else {
                if (mounted) {
                  showHint('高清放大失败，原因是${response.data}', showTime: 3);
                }
                commonPrint('高清放大失败1，原因是${response.data}');
              }
            } catch (error) {
              if (mounted) {
                showHint('高清放大失败，原因是$error', showTime: 3);
              }
              commonPrint('高清放大失败2，原因是$error');
            } finally {
              dismissHint();
            }
          } else {
            if (mounted) {
              showHint('第$currentIndex场景没有已选中图片，跳过高清放大...');
            }
          }
        } else {
          Map<String, dynamic> payload = {};
          if (image != '') {
            String imageId = items[index].imageId;
            int usePosition = items[index].selectedImagePosition;
            List<dynamic> buttons = items[index].actions3;
            if (drawEngine == 1) {
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
              payload['action'] = items[index].actions[usePosition];
              payload['image_id'] = imageId;
              dio.Response response;
              try {
                showHint('第$currentIndex场景的已选中图片高清放大中...', showType: 5);
                response = await myApi.mjDraw(drawSpeedType, token, payload);
                if (response.statusCode == 200) {
                  response.data.stream.listen((data) async {
                    final decodedData = utf8.decode(data);
                    final jsonData = json.decode(decodedData);
                    if (mounted) {
                      showHint('第$currentIndex个场景的图片的MJ高清放大绘制进度是${jsonData['progress']}%');
                    }
                    String base64Path = await imageUrlToBase64(jsonData['image_url']);
                    setState(() {
                      items[index].useImagePath = base64Path;
                      items[index].operatedImageId = jsonData['image_id'];
                      items[index].actions2 = List<String>.from(jsonData['actions']);
                      items[index].isAlreadyUpScale = true;
                      items[index].isAlreadyUpScaleRepair = false;
                      items[index].isSingleImageDownloaded = false;
                    });
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
              String customId = buttons[usePosition]['customId'];
              payload['customId'] = customId;
              payload['taskId'] = imageId;
              dio.Response response;
              try {
                showHint('第$currentIndex场景的已选中图片高清放大中...', showType: 5);
                response = await myApi.selfMjDrawChange(payload);
                if (response.statusCode == 200) {
                  if (response.data is String) {
                    response.data = jsonDecode(response.data);
                  }
                  int code = response.data['code'] ?? -1;
                  if (code == 1) {
                    if (mounted) {
                      showHint('第$currentIndex个场景的图片的MJ高清任务提交成功');
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
                          if (mounted) {
                            showHint('第$currentIndex个场景的图片的MJ高清进度是${progressResponse.data['progress'] ?? "0%"}');
                          }
                          if (progressResponse.data['imageUrl'] != null) {
                            String imageUrl = progressResponse.data['imageUrl'];
                            imageUrl = imageUrl.replaceAll('cdn.discordapp.com', 'dc.aigc369.com');
                            setState(() {
                              items[index].useImagePath = imageUrl;
                              items[index].operatedImageId = progressResponse.data['id'];
                              items[index].actions2 = List<String>.from([]);
                              items[index].actions4 = List<dynamic>.from(progressResponse.data['buttons']);
                              items[index].isAlreadyUpScale = true;
                              items[index].isAlreadyUpScaleRepair = false;
                              items[index].isSingleImageDownloaded = false;
                            });
                            if (status == 'SUCCESS') {
                              break;
                            }
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
                    if (code == 21) {
                      String imageUrl = response.data['properties']['imageUrl'];
                      imageUrl = imageUrl.replaceAll('cdn.discordapp.com', 'dc.aigc369.com');
                      String base64Path = await imageUrlToBase64(imageUrl);
                      setState(() {
                        items[index].useImagePath = base64Path;
                        items[index].operatedImageId = response.data['result'];
                        items[index].actions2 = List<String>.from([]);
                        items[index].isAlreadyUpScale = true;
                        items[index].isAlreadyUpScaleRepair = false;
                        items[index].isSingleImageDownloaded = false;
                      });
                    } else {
                      if (mounted) {
                        showHint('自有mj绘图失败,原因是${response.data['description']}', showType: 3);
                        commonPrint('自有mj绘图失败0,原因是${response.data['description']}');
                      }
                    }
                  }
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
            }
          } else {
            if (mounted) {
              showHint('第$currentIndex场景没有已选中图片，跳过高清放大...');
            }
          }
        }
      } else {
        if (mounted) {
          showHint('已高清放大，无需再次高清放大');
        }
      }
    }
  }

  void _onTypeChanged(String currentIndex, String type) {
    int index = int.parse(currentIndex) - 1;
    if (index >= 0 && index <= items.length - 1) {
      setState(() {
        items[index].imageChangeType = type;
      });
    }
  }

  void _onPresetChanged(String currentIndex, String type) {
    if (currentIndex == '') {
      currentIndex = '1';
    }
    int index = int.parse(currentIndex) - 1;
    if (index >= 0 && index <= items.length - 1) {
      setState(() {
        items[index].characterPreset = type;
      });
    }
    String cutType;
    int dotIndex = type.indexOf('.');
    if (dotIndex != -1) {
      cutType = type.substring(dotIndex + 1, type.length);
    } else {
      cutType = type;
    }
    for (int i = 0; i < items.length; i++) {
      if (items[i].prompt.contains(cutType)) {
        setState(() {
          items[i].characterPreset = type;
        });
      }
    }
  }

  //修改预设
  void _onSelectCustom(String currentIndex, String type, {bool isModify = false}) {
    selectModifyCharacterPresetsPosition = 0;
    setState(() {
      addCharactersPresetTitleController.clear();
      addCharactersPresetContentController.clear();
    });
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomDialog(
            title: isModify ? '修改人物预设' : '添加人物预设',
            titleColor: Colors.white,
            cancelButtonText: '取消',
            confirmButtonText: '确认',
            contentBackgroundColor: Colors.black,
            contentBackgroundOpacity: 0.5,
            description: null,
            maxWidth: 360,
            isConformClose: false,
            content: Padding(
                padding: const EdgeInsets.all(5),
                child: AddCharacterPreset(
                    titleController: addCharactersPresetTitleController,
                    contentController: addCharactersPresetContentController,
                    isModify: isModify,
                    onClearCharacterPresets: clearCharacterPresets,
                    onChangedCharacterPresetsPosition: (index) => changeCharacterPresetsPosition(index),
                    onDeleteCharacterPresets: (index) => deleteCharacterPresets(index))),
            onCancel: () {},
            onConfirm: () async {
              if (addCharactersPresetTitleController.text == '') {
                if (mounted) {
                  showHint('请输入预设标题');
                }
              } else if (addCharactersPresetContentController.text == '' && addCharactersPresetTitleController.text != '0.无') {
                if (mounted) {
                  showHint('请输入预设描述');
                }
              } else {
                Map<String, dynamic> characterPresets = await Config.loadSettings(type: 2);
                List<dynamic> characterPresetsTitles = characterPresets['character_list'];
                List<dynamic> characterPresetsContents = characterPresets['character_prompts'];
                if (!isModify) {
                  characterPresetsTitles.insert(
                      characterPresetsTitles.length - 1, '${characterPresetsTitles.length - 1}.${addCharactersPresetTitleController.text}');
                  characterPresetsContents.add(addCharactersPresetContentController.text);
                  var newCharacterPresets = {'character_list': characterPresetsTitles, 'character_prompts': characterPresetsContents};
                  await Config.saveSettings(newCharacterPresets, type: 2);
                  for (var i = 0; i < items.length; i++) {
                    items[i].key.currentState?.updateCharacterPresets(List<String>.from(characterPresetsTitles));
                  }
                  if (context.mounted) {
                    _onPresetChanged(currentIndex, characterPresetsTitles[characterPresetsTitles.length - 2]);
                    Navigator.of(context).pop();
                    showHint('人物预设保存成功');
                  }
                } else {
                  if (selectModifyCharacterPresetsPosition == 0) {
                    if (context.mounted) {
                      showHint('预设"0.无"不能修改');
                    }
                  } else {
                    List<String> oldCharacterPresetsTitles = List<String>.from(characterPresetsTitles);
                    characterPresetsTitles[selectModifyCharacterPresetsPosition] = addCharactersPresetTitleController.text;
                    characterPresetsContents[selectModifyCharacterPresetsPosition] = addCharactersPresetContentController.text;
                    var newCharacterPresets = {'character_list': characterPresetsTitles, 'character_prompts': characterPresetsContents};
                    await Config.saveSettings(newCharacterPresets, type: 2);
                    for (var i = 0; i < items.length; i++) {
                      items[i].key.currentState?.updateCharacterPresets(List<String>.from(characterPresetsTitles));
                      setState(() {
                        items[i].characterPresets = List<String>.from(characterPresetsTitles);
                      });
                    }
                    for (var i = 0; i < items.length; i++) {
                      if (oldCharacterPresetsTitles[selectModifyCharacterPresetsPosition] == items[i].characterPreset) {
                        items[i].characterPreset = addCharactersPresetTitleController.text;
                      }
                    }
                    if (context.mounted) {
                      _onPresetChanged(currentIndex, characterPresetsTitles[characterPresetsTitles.length - 2]);
                      Navigator.of(context).pop();
                      showHint('人物预设修改成功');
                    }
                  }
                }
              }
            },
          );
        },
      );
    }
  }

  //聚合向下插入和向上插入的方法
  void _addItem(String currentIndex, int type) {
    addSceneContentController.clear();
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomDialog(
            title: type == 0 ? '向上插入场景' : '向下插入场景',
            titleColor: Colors.white,
            cancelButtonText: '取消',
            confirmButtonText: '确认',
            contentBackgroundColor: Colors.black,
            contentBackgroundOpacity: 0.5,
            description: null,
            maxWidth: 360,
            content: Padding(
                padding: const EdgeInsets.all(5),
                child: AutoSizeTextField(
                  controller: addSceneContentController,
                  minLines: 1,
                  maxLines: 3,
                  onChanged: (content) {
                    addSceneContentController.text = content;
                  },
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(color: Colors.yellowAccent),
                  decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 2.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 2.0),
                      ),
                      labelText: '请输入场景描述',
                      labelStyle: TextStyle(color: Colors.white)),
                )),
            onCancel: () {},
            onConfirm: () async {
              String scenePrompt = addSceneContentController.text;
              if (scenePrompt == '') {
                showHint('请输入场景描述');
              } else {
                type == 0 ? _addUp(currentIndex, scenePrompt) : _addDown(currentIndex, scenePrompt);
              }
            },
          );
        },
      );
    }
  }

  void _deleteItem(String currentIndex) {
    int index = int.parse(currentIndex) - 1;
    if (index >= 0 && index <= items.length) {
      // 更新剩下的项目的序号
      for (int i = index; i < items.length; i++) {
        setState(() {
          items[i].key = (int.parse(items[i].key) - 1).toString();
        });
      }
      setState(() {
        items.removeAt(index);
      });
    }
  }

  Future<void> _saveSingleImage(String currentIndex) async {
    int index = int.parse(currentIndex) - 1;
    if (index >= 0 && index < items.length) {
      String base64Image = await imageUrlToBase64(items[index].useImagePath);
      String? outputFile = await FilePicker.platform
          .saveFile(dialogTitle: '将图片保存在:', fileName: '${currentDayStr(needTime: true)}.png', allowedExtensions: ['jpeg', 'jpg', 'png']);
      if (outputFile != null) {
        Uint8List bytes = base64Decode(base64Image);
        File file = File(outputFile);
        await file.writeAsBytes(bytes);
        setState(() {
          items[index].isSingleImageDownloaded = true;
        });
      }
    }
  }

  void _onImageSaveTapped(String currentIndex, int position, List<String> images) async {
    int index = int.parse(currentIndex) - 1;
    if (index >= 0 && index < items.length) {
      String? outputFile = await FilePicker.platform
          .saveFile(dialogTitle: '将图片保存在:', fileName: '${currentDayStr(needTime: true)}.png', allowedExtensions: ['jpeg', 'jpg', 'png']);
      String base64Image = await imageUrlToBase64(images[position]);
      List<int> imagesDownloadStatus = items[index].imagesDownloadStatus;
      if (outputFile != null) {
        Uint8List bytes = base64Decode(base64Image);
        File file = File(outputFile);
        await file.writeAsBytes(bytes);
        imagesDownloadStatus[position] = 1;
        setState(() {
          items[index].imagesDownloadStatus = imagesDownloadStatus;
        });
      }
    }
  }

  Future<List<String>> _getCharacterPresets() async {
    Map<String, dynamic> savedCharacterPresets = await Config.loadSettings(type: 2);
    readCharacterPresets = List<String>.from(savedCharacterPresets['character_list']);
    return readCharacterPresets;
  }

  Future<List<String>> _getCharacterPresetsDescriptions() async {
    Map<String, dynamic> savedCharacterPresets = await Config.loadSettings(type: 2);
    readCharacterPresetDescriptions = List<String>.from(savedCharacterPresets['character_prompts']);
    return readCharacterPresetDescriptions;
  }

  //用户手动上传图片
  Future<void> _onSelectImage(String currentIndex) async {
    FilePickerResult? result = await FilePickerManager().pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'png', 'jpeg']);
    if (result != null) {
      String imagePath = result.files.single.path ?? '';
      String imageUrl = '';
      if (imagePath != '') {
        showHint('图片上传中...', showType: 5);
        try {
          File file = File(imagePath);
          String uploadImageFile = await uploadFileToALiOss(imagePath, '', file, needDelete: false);
          imageUrl = uploadImageFile;
        } catch (e) {
          if (mounted) {
            showHint('图片上传失败，原因是$e');
          }
        } finally {
          dismissHint();
        }
      }
      int index = int.parse(currentIndex) - 1;
      if (index >= 0 && index <= items.length - 1) {
        setState(() {
          items[index].useImagePath = GlobalParams.filesUrl + imageUrl;
          items[index].isAlreadyUpScale = false;
          items[index].isAlreadyUpScaleRepair = false;
          items[index].isSingleImageDownloaded = false;
        });
      }
    }
  }

  Future<void> _onUpScaleRepairImage(String currentIndex) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    int index = int.parse(currentIndex) - 1;
    String currentImagePath = items[index].useImagePath;
    int currentDrawEngine = items[index].drawEngine;
    int systemDrawEngine = settings['drawEngine'];
    if (currentDrawEngine != systemDrawEngine) {
      if (mounted) {
        showHint('当前图片之前使用的绘图引擎与当前选择的绘图引擎不一致，将使用当前的绘图引擎绘图');
      }
      currentDrawEngine = systemDrawEngine;
    }
    if (currentDrawEngine == 0) {
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
                isUseControlNet: items[index].useControlnet,
              ),
              onCancel: () {},
              onConfirm: () async {
                _generateImage(currentIndex, isUpScaleRepair: true);
              },
            );
          },
        );
      }
    } else {
      if (mounted) {
        showHint('当前绘图引擎为MJ，MJ的图生图功能需要阅读说明书了解如何使用');
      }
    }
  }

  Future<void> _contentChanged(String currentIndex, String content) async {
    int index = int.parse(currentIndex) - 1;
    if (index >= 0 && index < items.length) {
      setState(() {
        items[index].prompt = content;
      });
    }
  }

  void initView() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String? sdUrl = settings['sdUrl'];
    drawEngine = settings['drawEngine'] ?? 0;
    if (widget.isDirectlyInto!) {
      String defaultPath = settings['image_save_path'];
      Map<String, dynamic> changeSettings = {
        'current_novel_title': novelTitle!.split('_')[0],
        'current_novel_folder': '$defaultPath${Platform.pathSeparator}${novelTitle!.split('_')[0]}'
      };
      await Config.saveSettings(changeSettings);
      readHistoryInfo();
    } else {
      for (int i = 0; i < contentList.length; i++) {
        GlobalKey<ImageManipulationItemState> itemKey = GlobalKey();
        ImageManipulationItem item = ImageManipulationItem(
            key: itemKey,
            index: (i + 1).toString(),
            prompt: contentList[i],
            actions: List<String>.from([]),
            actions2: List<String>.from([]),
            actions3: List<dynamic>.from([]),
            actions4: List<dynamic>.from([]),
            imageUrlList: List<String>.from([]),
            drawEngine: drawEngine,
            allScenes: contentList.length,
            controlNetOptions: List<Map<String, dynamic>>.from([]),
            aDetailsOptions: List<Map<String, dynamic>>.from([]),
            onMergeDown: (index) => _mergeDown(index),
            onReasoningTagsTapped: (index) => onReasoningTags(index),
            onContentChanged: (index, content) => _contentChanged(index, content),
            onMergeUp: (index) => _mergeUp(index),
            onAddDown: (index) => _addItem(index, 1),
            onUseControlNet: (index) => onUseControlNet(index),
            onAddUp: (index) => _addItem(index, 0),
            onDelete: (index) => _deleteItem(index),
            aiScene: (index) => _aiScene(index),
            transScene: (index) => _transScene(index),
            sceneToImage: (index) => _generateImage(index),
            onChangeUseFix: (index) => _changeUseFix(index),
            aiSceneController: TextEditingController(),
            selfSceneController: TextEditingController(),
            transSceneController: TextEditingController(),
            contentController: TextEditingController(text: contentList[i]),
            scrollController: ScrollController(),
            scrollControllerTrans: ScrollController(),
            imageBase64List: List<String>.from([]),
            imagesDownloadStatus: List<int>.from([0, 0, 0, 0]),
            isSingleImageDownloaded: false,
            onSingleImageSaveTapped: (index) => _saveSingleImage(index),
            isAlreadyUpScale: false,
            isAlreadyUpScaleRepair: false,
            useFix: false,
            useControlnet: false,
            onImageTapped: (index, pos, paths) => _onImageTapped(index, pos, paths),
            onImageSaveTapped: (index, pos, paths) => _onImageSaveTapped(index, pos, paths),
            useImagePath: '',
            onTypeChanged: (index, type) => _onTypeChanged(index, type),
            onPresetsChanged: (index, type) => _onPresetChanged(index, type),
            imageChangeType: imageChangeTypes.last,
            characterPreset: presetCharacter['character_list'][0],
            onUpScale: (index) => _onUpScale(index),
            onVariation: (index, {type = 0}) => _onVariation(index, type: type),
            onUpScaleRepair: (index) => _onUpScaleRepairImage(index),
            onSingleImageTapped: (index) => _onSingleImageTapped(index),
            onVoiceTapped: (index) => _voiceScene(index),
            useAiMode: widget.useAiMode,
            characterPresets: await _getCharacterPresets(),
            onSelectCustom: (index, type) => _onSelectCustom(index, type),
            onSelectImage: (index) => _onSelectImage(index),
            useImageUrl: '');
        items.add(item);
      }
    }
    if (sdUrl != null && sdUrl != '' && drawEngine == 0) {
      _getControlNetModels(sdUrl);
      _getControlNetModules(sdUrl);
      _getControlNetControlTypes(sdUrl);
      _getSamplers(sdUrl);
      //TODO 这里是获取提示词组的方法，考虑加入指导用户的提示词组
      // _getGroupTags(sdUrl);
    }
  }

  void readHistoryInfo() async {
    showHint('历史记录数据加载中...', showType: 5);
    Map<String, dynamic> settings = await Config.loadSettings();
    String? defaultPath = settings['image_save_path'];
    String historyJsonPath =
        '$defaultPath${Platform.pathSeparator}history${Platform.pathSeparator}${novelTitle!.split('_')[0]}${Platform.pathSeparator}${novelTitle!.split('_')[1]}${Platform.pathSeparator}history.json';
    Map<String, dynamic> historyJsonContent = await getFileContentByPath(historyJsonPath);
    List<Map<String, dynamic>> historyContents = List<Map<String, dynamic>>.from(historyJsonContent['contents']);
    Map<String, dynamic> characterPresets = await Config.loadSettings(type: 2);
    List<dynamic> characterPresetsTitles = characterPresets['character_list'];
    items.clear();
    for (int i = 0; i < historyContents.length; i++) {
      GlobalKey<ImageManipulationItemState> itemKey = GlobalKey();
      ImageManipulationItem item = ImageManipulationItem(
        key: itemKey,
        index: historyContents[i]['index'],
        prompt: historyContents[i]['prompt'],
        allScenes: historyContents[i]['allScenes'],
        controlNetOptions: List<Map<String, dynamic>>.from(historyContents[i]['controlNetOptions']),
        aDetailsOptions: List<Map<String, dynamic>>.from(historyContents[i]['aDetailsOptions']),
        onMergeDown: (index) => _mergeDown(index),
        onMergeUp: (index) => _mergeUp(index),
        onAddDown: (index) => _addItem(index, 1),
        onReasoningTagsTapped: (index) => onReasoningTags(index),
        onAddUp: (index) => _addItem(index, 0),
        onDelete: (index) => _deleteItem(index),
        aiScene: (index) => _aiScene(index),
        transScene: (index) => _transScene(index),
        sceneToImage: (index) => _generateImage(index),
        onChangeUseFix: (index) => _changeUseFix(index),
        onUseControlNet: (index) => onUseControlNet(index),
        onContentChanged: (index, content) => _contentChanged(index, content),
        aiSceneController: TextEditingController(text: historyContents[i]['aiSceneText']),
        selfSceneController: TextEditingController(),
        transSceneController: TextEditingController(text: historyContents[i]['transSceneText']),
        contentController: TextEditingController(text: historyContents[i]['prompt']),
        scrollController: ScrollController(),
        scrollControllerTrans: ScrollController(),
        imageBase64List: List<String>.from(historyContents[i]['imageBase64List'] ?? []),
        imageUrlList: List<String>.from(historyContents[i]['imageUrlList'] ?? []),
        isAlreadyUpScale: historyContents[i]['isAlreadyUpScale'] ?? false,
        isAlreadyUpScaleRepair: historyContents[i]['isAlreadyUpScaleRepair'] ?? false,
        imagesDownloadStatus: List<int>.from([0, 0, 0, 0]),
        isSingleImageDownloaded: historyContents[i]['isSingleImageDownloaded'] ?? false,
        onSingleImageSaveTapped: (index) => _saveSingleImage(index),
        onImageTapped: (index, pos, paths) => _onImageTapped(index, pos, paths),
        onImageSaveTapped: (index, pos, paths) => _onImageSaveTapped(index, pos, paths),
        useImagePath: historyContents[i]['useImagePath'],
        onTypeChanged: (index, type) => _onTypeChanged(index, type),
        onPresetsChanged: (index, type) => _onPresetChanged(index, type),
        imageChangeType: historyContents[i]['imageChangeType'],
        characterPreset: historyContents[i]['characterPreset'],
        onUpScale: (index) => _onUpScale(index),
        onVariation: (index, {type = 0}) => _onVariation(index, type: type),
        onUpScaleRepair: (index) => _onUpScaleRepairImage(index),
        onSingleImageTapped: (index) => _onSingleImageTapped(index),
        onVoiceTapped: (index) => _voiceScene(index),
        useAiMode: historyContents[i]['useAiMode'],
        useFix: historyContents[i]['useFix'],
        actions: List<String>.from(historyContents[i]['actions'] ?? []),
        actions2: List<String>.from(historyContents[i]['actions2'] ?? []),
        actions3: List<dynamic>.from(historyContents[i]['actions3'] ?? []),
        actions4: List<dynamic>.from(historyContents[i]['actions4'] ?? []),
        drawEngine: historyContents[i]['drawEngine'] ?? 0,
        useControlnet: historyContents[i]['useControlnet'],
        characterPresets: List<String>.from(characterPresetsTitles),
        onSelectCustom: (index, type) => _onSelectCustom(index, type),
        onSelectImage: (index) => _onSelectImage(index),
        imageId: historyContents[i]['imageId'] ?? '',
        taskId: historyContents[i]['taskId'] ?? '',
        useImageUrl: historyContents[i]['useImageUrl'] ?? '',
        selectedImagePosition: historyContents[i]['selectedImagePosition'] ?? -1,
        operatedImageId: historyContents[i]['operatedImageId'] ?? '',
      );
      items.add(item);
    }
    setState(() {});
    dismissHint();
  }

  void clearCharacterPresets() async {
    Navigator.of(context).pop();
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomDialog(
            title: '!!!警告!!!',
            titleColor: Colors.yellowAccent,
            cancelButtonText: '取消',
            confirmButtonText: '确认',
            contentBackgroundColor: Colors.black,
            contentBackgroundOpacity: 0.5,
            description: '清空预设后需要重新添加预设，确认清空吗',
            maxWidth: 360,
            content: null,
            onCancel: () {},
            onConfirm: () async {
              Map<String, dynamic> characterPresets = await Config.loadSettings(type: 2);
              List<dynamic> characterPresetsTitles = characterPresets['character_list'];
              List<dynamic> characterPresetsContents = characterPresets['character_prompts'];
              characterPresetsTitles.clear();
              characterPresetsContents.clear();
              characterPresetsTitles.add('0.无');
              characterPresetsTitles.add('自定义');
              characterPresetsContents.add('');
              var newCharacterPresets = {'character_list': characterPresetsTitles, 'character_prompts': characterPresetsContents};
              await Config.saveSettings(newCharacterPresets, type: 2);
              for (var i = 0; i < items.length; i++) {
                items[i].key.currentState?.updateCharacterPresets(List<String>.from(characterPresetsTitles));
              }
              for (var i = 0; i < items.length; i++) {
                setState(() {
                  items[i].characterPreset = characterPresetsTitles[0];
                });
              }
              if (context.mounted) {
                showHint('人物预设清空成功');
              }
            },
          );
        },
      );
    }
  }

  void deleteCharacterPresets(int position) async {
    Map<String, dynamic> characterPresets = await Config.loadSettings(type: 2);
    List<dynamic> characterPresetsTitles = characterPresets['character_list'];
    List<dynamic> characterPresetsContents = characterPresets['character_prompts'];
    for (var i = 0; i < items.length; i++) {
      if (items[i].characterPreset == characterPresetsTitles[selectModifyCharacterPresetsPosition]) {
        setState(() {
          items[i].characterPreset = '0.无';
        });
      }
    }
    characterPresetsTitles.removeAt(position);
    characterPresetsContents.removeAt(position);
    var newCharacterPresets = {'character_list': characterPresetsTitles, 'character_prompts': characterPresetsContents};
    await Config.saveSettings(newCharacterPresets, type: 2);
    for (var i = 0; i < items.length; i++) {
      items[i].key.currentState?.updateCharacterPresets(List<String>.from(characterPresetsTitles));
      setState(() {
        items[i].characterPresets = List<String>.from(characterPresetsTitles);
      });
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void changeCharacterPresetsPosition(int position) async {
    selectModifyCharacterPresetsPosition = position;
  }

  void _changeUseFix(String currentIndex) {
    if (drawEngine != 0) {
      showHint('您当前选择的是midjourney绘画引擎，无法使用ADetail');
    } else {
      int index = int.parse(currentIndex) - 1;
      if (index >= 0 && index < items.length) {
        List<Map<String, dynamic>> itemAfterDetailOptions = items[index].aDetailsOptions;
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
                  maxWidth: 550,
                  minWidth: 400,
                  minHeight: 100,
                  content: AfterDetailOption(
                    afterDetailOptions: itemAfterDetailOptions,
                    sdSamplers: _samplers,
                    onConfirm: (options) {
                      bool isUseADetail = false;
                      for (var option in options) {
                        if (option['is_enable']) {
                          isUseADetail = true;
                          break;
                        }
                      }
                      setState(() {
                        items[index].aDetailsOptions = options;
                        items[index].useFix = isUseADetail;
                      });
                    },
                  ));
            },
          );
        }
      }
    }
  }

  void onUseControlNet(String currentIndex) async {
    if (drawEngine != 0) {
      showHint('您当前选择的是midjourney绘画引擎，无法使用ControlNet');
    } else {
      int index = int.parse(currentIndex) - 1;
      if (index >= 0 && index <= items.length - 1) {
        List<Map<String, dynamic>> controlNetOptions = items[index].controlNetOptions ?? [];
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
                  onConfirm: (options) {
                    bool isUseControlNet = false;
                    for (var option in options) {
                      if (option['is_enable']) {
                        isUseControlNet = true;
                        break;
                      }
                    }
                    setState(() {
                      items[index].useControlnet = isUseControlNet;
                      items[index].controlNetOptions = options;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              );
            },
          );
        }
      }
    }
  }

  void onReasoningTags(String currentIndex) async {
    final sets = context.read<ChangeSettings>();
    Map<String, dynamic> settings = await Config.loadSettings();
    int index = int.parse(currentIndex) - 1;
    if (index >= 0 && index <= items.length - 1) {
      String currentUseImagePath = items[index].useImagePath;
      int currentDrawEngine = items[index].drawEngine ?? 0;
      int systemDrawEngine = settings['drawEngine'] ?? 0;
      if (systemDrawEngine != currentDrawEngine) {
        currentDrawEngine = systemDrawEngine;
      }
      String currentUseImageUrl = '';
      List<String> interrogators = [''];
      if (currentDrawEngine == 0) {
        interrogators = await getTaggerInterrogators();
      }
      if (currentDrawEngine == 1) {
        currentUseImageUrl = items[index].useImageUrl ?? '';
      }
      currentUseImagePath = await imageUrlToBase64(items[index].useImagePath);
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomDialog(
              title: '反推图片标签',
              titleColor: sets.getForegroundColor(),
              showConfirmButton: false,
              showCancelButton: false,
              contentBackgroundColor: sets.getBackgroundColor(),
              description: null,
              maxWidth: 420,
              minWidth: 380,
              content: GetImageTagsWidget(
                  interrogators: interrogators, base64Image: currentUseImagePath, drawEngine: currentDrawEngine, imageUrl: currentUseImageUrl),
            );
          },
        );
      }
    }
  }

  Future<void> haveChangedSettings() async {
    changeSettings = Provider.of<ChangeSettings>(context);
    Map<String?, dynamic> map = changeSettings.changeValues;
    map.forEach((key, value) async {
      if (key != null && value != null) {
        if (key == 'drawEngine') {
          setState(() {
            drawEngine = value;
          });
        }
      }
    });
  }

  Future<void> _showSet() async {
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
              maxWidth: 500,
              minWidth: 380,
              minHeight: 300,
              maxHeight: 720,
              content: MidjourneySettingsView(
                options: MjOptions,
                intoType: 1,
                onConfirm: (finalOptions) {
                  MjOptions = finalOptions;
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
              ),
            );
          });
    }
  }

  @override
  void initState() {
    inputScenes = widget.scenes;
    novelTitle = widget.novelTitle;
    inputScenes = removeMultipleEmptyLines(inputScenes, 0);
    lines = inputScenes.split('\n');
    for (String line in lines) {
      final index = line.indexOf('.');
      if (index != -1) {
        contentList.add(line.substring(index + 1));
      }
    }
    loadSettings();
    initView();
    listenKey();
    super.initState();
  }

  void listenKey() async {
    box.listenKey('drawEngine', (value) {
      setState(() {
        drawEngine = value;
      });
    });
  }

  @override
  void didChangeDependencies() {
    var ratio = MediaQuery.of(context).devicePixelRatio;
    deleteSize = (((screenSize == '4K')
                ? 120
                : (screenSize == '2K')
                    ? 150
                    : (screenSize == '1080p')
                        ? 180
                        : 210) *
            (ratio < 2 ? 2 : ratio))
        .toInt();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    taskList.clear();
    manager.cancelAutoTask();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    haveChangedSettings();
    final settings = context.watch<ChangeSettings>();
    return Stack(children: [
      Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: 105,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      backgroundColor: settings.getSelectedBgColor(),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      _onSelectCustom('', '', isModify: true);
                    },
                    child: const Text('修改预设')),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 105,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      backgroundColor: settings.getSelectedBgColor(),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (!oneKeyAISceneToken.isStarted) {
                        oneKeyAIScene = _oneKeyAiScene(oneKeyAISceneToken);
                        setState(() {
                          oneKeyAISceneToken.isStarted = true;
                        });
                      } else {
                        oneKeyAISceneToken.cancel();
                        setState(() {
                          oneKeyAISceneToken.isStarted = false;
                        });
                        if (mounted) {
                          showHint('取消了一键推理');
                        }
                        dismissHint();
                      }
                    },
                    child: Text(!oneKeyAISceneToken.isStarted ? '一键推理' : '取消推理')),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 105,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      backgroundColor: settings.getSelectedBgColor(),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (!oneKeyTransSceneToken.isStarted) {
                        oneKeyTransScene = _oneKeyTransScene(oneKeyTransSceneToken);
                        setState(() {
                          oneKeyTransSceneToken.isStarted = true;
                        });
                      } else {
                        oneKeyTransSceneToken.cancel();
                        setState(() {
                          oneKeyTransSceneToken.isStarted = false;
                        });
                        if (mounted) {
                          showHint('取消了一键翻译');
                        }
                        dismissHint();
                      }
                    },
                    child: Text(!oneKeyTransSceneToken.isStarted ? '一键翻译' : '取消翻译')),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 105,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      backgroundColor: settings.getSelectedBgColor(),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (!oneKeyGenerateImageToken.isStarted) {
                        oneKeyGenerateImage = _oneKeyGenerateImage(oneKeyGenerateImageToken);
                        setState(() {
                          oneKeyGenerateImageToken.isStarted = true;
                        });
                      } else {
                        oneKeyGenerateImageToken.cancel();
                        setState(() {
                          oneKeyGenerateImageToken.isStarted = false;
                        });
                        if (mounted) {
                          showHint('取消了一键生图');
                        }
                        dismissHint();
                      }
                    },
                    child: Text(!oneKeyGenerateImageToken.isStarted ? '一键生图' : '取消生图')),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 105,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      backgroundColor: settings.getSelectedBgColor(),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (!oneKeyDealSceneToken.isStarted) {
                        oneKeyDealScene = _oneKeyDeal(oneKeyDealSceneToken);
                        setState(() {
                          oneKeyDealSceneToken.isStarted = true;
                        });
                      } else {
                        oneKeyDealSceneToken.cancel();
                        setState(() {
                          oneKeyDealSceneToken.isStarted = false;
                        });
                        if (mounted) {
                          showHint('取消了一键处理');
                        }
                        dismissHint();
                      }
                    },
                    child: Text(!oneKeyDealSceneToken.isStarted ? '一键处理' : '取消处理')),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 105,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      backgroundColor: settings.getSelectedBgColor(),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (!oneKeyUpScaleToken.isStarted) {
                        oneKeyUpScale = _oneKeyUpScale(oneKeyUpScaleToken);
                        setState(() {
                          oneKeyUpScaleToken.isStarted = true;
                        });
                      } else {
                        oneKeyUpScaleToken.cancel();
                        setState(() {
                          oneKeyUpScaleToken.isStarted = false;
                        });
                        if (mounted) {
                          showHint('取消了一键高清');
                        }
                        dismissHint();
                      }
                    },
                    child: Text(!oneKeyUpScaleToken.isStarted ? '一键高清' : '取消高清')),
              ),
              Visibility(
                  visible: widget.useAiMode == 1,
                  child: Row(
                    children: [
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 105,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(8),
                              backgroundColor: settings.getSelectedBgColor(),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              _oneKeyVoiceScene();
                            },
                            child: const Text('一键配音')),
                      ),
                    ],
                  )),
              const SizedBox(width: 6),
              Visibility(
                  visible: drawEngine != 0,
                  child: Row(children: [
                    SizedBox(
                      width: 105,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(8),
                            backgroundColor: settings.getSelectedBgColor(),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            _showSet();
                          },
                          child: const Text('MJ绘图选项')),
                    ),
                    const SizedBox(width: 6),
                  ])),
              SizedBox(
                width: 105,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      backgroundColor: settings.getSelectedBgColor(),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      _saveDraft();
                    },
                    child: const Text('合成草稿')),
              ),
              const SizedBox(width: 6),
              Container(
                  padding: const EdgeInsets.only(left: 8, right: 8, top: 6, bottom: 6),
                  decoration: BoxDecoration(
                    color: settings.getSelectedBgColor(),
                    borderRadius: BorderRadius.circular(20.0), // 6像素的圆角
                  ),
                  child: Row(
                    children: [
                      const Text('一键起始为第', style: TextStyle(color: Colors.white)),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: Colors.white, // 边框颜色
                            width: 1.0, // 边框宽度
                          ), // 6像素的圆角
                        ),
                        child: AutoSizeTextField(
                          fullwidth: false,
                          minFontSize: 14,
                          scrollPadding: EdgeInsets.zero,
                          onChanged: (content) {
                            if (_debounce != null) {
                              _debounce!.cancel();
                            }
                            _debounce = Timer(const Duration(milliseconds: 500), () {
                              if (content.isEmpty) {
                                oneKeyStartSceneNumController.text = '1';
                                if (mounted) {
                                  showHint('所有的一键操作的起始场景不能为空,已为您设置为最小值1');
                                }
                              } else if (int.parse(content.trim()) <= 0) {
                                oneKeyStartSceneNumController.text = '1';
                                if (mounted) {
                                  showHint('所有的一键操作的起始场景最小值为1,已为您设置为最小值1');
                                }
                              } else if (int.parse(content.trim()) >= items.length) {
                                oneKeyStartSceneNumController.text = '${items.length}';
                                if (mounted) {
                                  showHint('所有的一键操作的起始场景最大值为当前的场景最大值${items.length},已为您设置为最大值${items.length}');
                                }
                              }
                            });
                          },
                          textAlign: TextAlign.right,
                          keyboardType: TextInputType.number,
                          controller: oneKeyStartSceneNumController,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly, // 限制只能输入数字
                          ],
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.only(bottom: 4),
                            isCollapsed: true,
                          ),
                        ),
                      ),
                      const Text('个场景', style: TextStyle(color: Colors.white)),
                    ],
                  )),
              Visibility(
                  visible: drawEngine == 0,
                  child: Row(
                    children: [
                      const SizedBox(width: 6),
                      Container(
                          padding: const EdgeInsets.only(left: 8, right: 8, top: 6, bottom: 6),
                          decoration: BoxDecoration(
                            color: settings.getSelectedBgColor(),
                            borderRadius: BorderRadius.circular(20.0), // 6像素的圆角
                          ),
                          child: Row(
                            children: [
                              const Text('每个场景图片为', style: TextStyle(color: Colors.white)),
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4.0),
                                  border: Border.all(
                                    color: Colors.white, // 边框颜色
                                    width: 1.0, // 边框宽度
                                  ), // 6像素的圆角
                                ),
                                child: AutoSizeTextField(
                                  fullwidth: false,
                                  minFontSize: 14,
                                  scrollPadding: EdgeInsets.zero,
                                  onChanged: (content) {
                                    if (_debounce != null) {
                                      _debounce!.cancel();
                                    }
                                    _debounce = Timer(const Duration(milliseconds: 500), () {
                                      if (content.isEmpty) {
                                        Config.saveSettings({
                                          'every_scene_images': 1,
                                        });
                                        _everySceneImages = 1;
                                        everySceneImageNumController.text = '1';
                                        if (mounted) {
                                          showHint('每个场景的图片数量不能为空,已为您设置为最小值1');
                                        }
                                      } else if (int.parse(content.trim()) <= 0) {
                                        Config.saveSettings({
                                          'every_scene_images': 1,
                                        });
                                        _everySceneImages = 1;
                                        everySceneImageNumController.text = '1';
                                        if (mounted) {
                                          showHint('每个场景的图片数量最小值为1,已为您设置为最小值1');
                                        }
                                      } else if (int.parse(content.trim()) > 4) {
                                        Config.saveSettings({
                                          'every_scene_images': 4,
                                        });
                                        _everySceneImages = 4;
                                        everySceneImageNumController.text = '4';
                                        if (mounted) {
                                          showHint('每个场景的图片数量最大值为4,已为您设置为最大值4');
                                        }
                                      } else {
                                        Config.saveSettings({
                                          'every_scene_images': double.parse(content.trim()),
                                        });
                                        _everySceneImages = double.parse(content.trim());
                                      }
                                    });
                                  },
                                  textAlign: TextAlign.right,
                                  keyboardType: TextInputType.number,
                                  controller: everySceneImageNumController,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly,
                                    // 限制只能输入数字
                                  ],
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.only(bottom: 4),
                                    isCollapsed: true,
                                  ),
                                ),
                              ),
                              const Text('张', style: TextStyle(color: Colors.white)),
                            ],
                          ))
                    ],
                  ))
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            width: MediaQuery.of(context).size.width,
            child: Align(
              child: ConstrainedBox(
                constraints: const BoxConstraints.expand(), // 设置内容限制为填充父布局
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: GlobalParams.themeColor,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Center(
                          child: Text(
                            '序号',
                            style: TextStyle(
                              color: Colors.yellowAccent,
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
                        color: GlobalParams.themeColor, // 设置线的颜色
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - deleteSize) / 5,
                        child: Center(
                          child: Text(
                            '场景描述',
                            style: TextStyle(
                              color: Colors.yellowAccent,
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
                        color: GlobalParams.themeColor, // 设置线的颜色
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - deleteSize) / 4,
                        child: Center(
                          child: Text(
                            '场景处理',
                            style: TextStyle(
                              color: Colors.yellowAccent,
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
                        color: GlobalParams.themeColor, // 设置线的颜色
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - deleteSize) / 4,
                        child: Center(
                          child: Text(
                            '生成图片',
                            style: TextStyle(
                              color: Colors.yellowAccent,
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
                        color: GlobalParams.themeColor, // 设置线的颜色
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - deleteSize) / 4,
                        child: Center(
                          child: Text(
                            '选择图片',
                            style: TextStyle(
                              color: Colors.yellowAccent,
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
                        color: GlobalParams.themeColor, // 设置线的颜色
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '图片关键帧动画',
                            style: TextStyle(
                              color: Colors.yellowAccent,
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
          Obx(() => Expanded(
                  child: ListView.builder(
                shrinkWrap: true, // 设置这个属性
                physics: const ClampingScrollPhysics(), // 设置所需的滚动效果
                itemCount: items.length,
                itemBuilder: (BuildContext context, int index) {
                  return MyKeepAliveWrapper(
                      child: ImageManipulationItem(
                    key: items[index].key,
                    index: items[index].index,
                    prompt: items[index].prompt,
                    allScenes: items.length,
                    actions: items[index].actions,
                    actions2: items[index].actions2,
                    actions3: items[index].actions3,
                    actions4: items[index].actions4,
                    imageUrlList: items[index].imageUrlList,
                    onReasoningTagsTapped: items[index].onReasoningTagsTapped,
                    controlNetOptions: items[index].controlNetOptions,
                    aDetailsOptions: items[index].aDetailsOptions,
                    onMergeDown: items[index].onMergeDown,
                    onMergeUp: items[index].onMergeUp,
                    drawEngine: items[index].drawEngine,
                    onAddUp: items[index].onAddUp,
                    onAddDown: items[index].onAddDown,
                    onDelete: items[index].onDelete,
                    aiScene: items[index].aiScene,
                    transScene: items[index].transScene,
                    sceneToImage: items[index].sceneToImage,
                    aiSceneController: items[index].aiSceneController,
                    selfSceneController: items[index].selfSceneController,
                    transSceneController: items[index].transSceneController,
                    contentController: items[index].contentController,
                    onChangeUseFix: items[index].onChangeUseFix,
                    onUseControlNet: items[index].onUseControlNet,
                    scrollController: items[index].scrollController,
                    useFix: items[index].useFix,
                    useControlnet: items[index].useControlnet,
                    scrollControllerTrans: items[index].scrollControllerTrans,
                    imageBase64List: items[index].imageBase64List,
                    onImageTapped: items[index].onImageTapped,
                    onImageSaveTapped: items[index].onImageSaveTapped,
                    useImagePath: items[index].useImagePath,
                    onTypeChanged: items[index].onTypeChanged,
                    onPresetsChanged: items[index].onPresetsChanged,
                    imageChangeType: items[index].imageChangeType,
                    characterPreset: items[index].characterPreset,
                    imagesDownloadStatus: items[index].imagesDownloadStatus,
                    isSingleImageDownloaded: items[index].isSingleImageDownloaded,
                    onSingleImageSaveTapped: items[index].onSingleImageSaveTapped,
                    onUpScale: items[index].onUpScale,
                    onVariation: items[index].onVariation,
                    onUpScaleRepair: items[index].onUpScaleRepair,
                    onSingleImageTapped: items[index].onSingleImageTapped,
                    isAlreadyUpScale: items[index].isAlreadyUpScale,
                    isAlreadyUpScaleRepair: items[index].isAlreadyUpScaleRepair,
                    onVoiceTapped: items[index].onVoiceTapped,
                    onContentChanged: items[index].onContentChanged,
                    useAiMode: items[index].useAiMode,
                    onSelectCustom: items[index].onSelectCustom,
                    characterPresets: items[index].characterPresets,
                    onSelectImage: items[index].onSelectImage,
                    useImageUrl: items[index].useImageUrl,
                  ));
                },
              ))),
          // ListView(),
        ],
      ),
      Positioned(
          bottom: 16,
          right: 16,
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  _saveCurrentSchedule();
                  if (isAutoSave) {
                    manager.startAutoTask(
                      interval: Duration(minutes: interval),
                      autoStart: true,
                      initialTimestamp: DateTime.now().millisecondsSinceEpoch,
                      customTaskCallback: (currentTimestamp) {
                        _saveCurrentSchedule();
                      },
                    );
                  }
                },
                onDoubleTap: () {
                  //双击启用自动保存
                  if (mounted) {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return CustomDialog(
                            titleColor: Colors.white,
                            title: '启用自动保存',
                            showCancelButton: false,
                            showConfirmButton: false,
                            contentBackgroundOpacity: 0.5,
                            contentBackgroundColor: Colors.black,
                            content: AutoSaveOption(
                              interval: interval,
                              isAutoSave: isAutoSave,
                              onConfirm: (outInterval, outIsAutoSave) {
                                if (outIsAutoSave) {
                                  manager.startAutoTask(
                                    interval: Duration(minutes: outInterval),
                                    autoStart: true,
                                    initialTimestamp: DateTime.now().millisecondsSinceEpoch,
                                    customTaskCallback: (currentTimestamp) {
                                      _saveCurrentSchedule();
                                    },
                                  );
                                } else {
                                  manager.cancelAutoTask();
                                }
                                setState(() {
                                  interval = outInterval;
                                  isAutoSave = outIsAutoSave;
                                });
                              },
                            ),
                          );
                        });
                  }
                },
                child: Tooltip(
                  message: !isAutoSave ? '自动保存未启用，单击保存当前进度，双击打开自动保存设置' : '自动保存已启用，亦可单击保存当前进度，双击打开自动保存设置',
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: settings.getSelectedBgColor(),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Icon(Icons.save, color: !isAutoSave ? Colors.white : Colors.blue),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  _loadHistoryProgram();
                },
                child: Tooltip(
                  message: '加载历史项目',
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: settings.getSelectedBgColor(),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: const Icon(Icons.history, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  _deleteHistoryProgram();
                },
                child: Tooltip(
                  message: '删除历史项目',
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: settings.getSelectedBgColor(),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                ),
              ),
            ],
          ))
    ]);
  }
}
