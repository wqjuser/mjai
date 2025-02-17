import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/config/global_params.dart';
import 'package:tuitu/net/my_api.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'package:tuitu/utils/my_openai_client.dart';
import 'package:tuitu/widgets/common_dropdown.dart';
import 'package:flutter_azure_tts/flutter_azure_tts.dart';
import '../config/config.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/voice_text_option.dart';
import 'package:dio/dio.dart' as dio;

// 文章图片生成器的第一步界面
class FirstStepView extends StatefulWidget {
  final TextEditingController responseController;
  final TextEditingController articleController;
  final Function(String param) onNextStep;
  final Function() goToThirdStep;

  const FirstStepView(
      {super.key,
      required this.responseController,
      required this.onNextStep,
      required this.articleController,
      required this.goToThirdStep});

  @override
  State<FirstStepView> createState() => _FirstStepViewState();
}

// 这里是主界面内容
class _FirstStepViewState extends State<FirstStepView> {
  int _aiSelectedMode = 0;
  int _useAiMode = 0;
  List<String> articleTypes = ['原文', '玄幻', '爽文', '科幻', '仙侠', '修真', '甜宠', '悬疑', '都市', '恐怖', '穿越']; //重写文章类别
  String reWritePrompt = '';
  String aiType = '你是最好的小说家，擅长写出能够非常吸引人的小说内容';
  String selectedType = '原文';
  String selectedAiModel = '暂无可用模型';
  String chatBaseUrl = '';
  String selfChatBaseUrl = '';
  String openAIKey = '';
  List<String> aiModelIds = ['暂无可用模型'].obs;
  String responseText = '';
  bool isEditable = false;
  String? content = '';
  String allContent = '';
  late TextEditingController articleController;
  late TextEditingController responseController;
  final ScrollController _scrollController = ScrollController();
  late TextEditingController selfPromptController;
  late TextEditingController _novelTitleTextFieldController;
  late ChangeSettings changeSettings;
  String selectedVoice = '';
  String selectedVoiceAue = '';
  String selectedVoiceEmotion = '';
  String selectedVoiceRole = '';
  String selfAiOptimizationPrompts = '';
  List<String> voices = [''];
  List<String> voicesAue = [''];
  List<String> voicesEmotions = [''];
  List<String> voicesRoles = [''];
  bool isVisitable_1 = false;
  bool isVisitable_2 = false;
  bool isVisitable_3 = false;
  bool _isSelfAIScenePrompt = false;
  Map<String, dynamic> envDatas = {};
  String draftContent = '';
  late MyApi myApi;
  final box = GetStorage();

  Future<void> loadSettings() async {
    Map<String, dynamic> azureInitialized = {
      'azure_initialized': false,
    };
    await Config.saveSettings(azureInitialized);
    Map<String, dynamic> settings = await Config.loadSettings();
    int? aiSelectedMode = settings['ChatGPTUseMode'];
    String? baseUrl = settings['chat_web_proxy'];
    _useAiMode = settings['use_mode'] ?? 0;
    bool? isSelfOptimizationPrompts = settings['use_self_ai_optimization_prompts'];
    String? selfOptimizationPrompts = settings['self_ai_optimization_prompts'];
    if (isSelfOptimizationPrompts != null) {
      setState(() {
        _isSelfAIScenePrompt = isSelfOptimizationPrompts;
      });
    }
    if (selfOptimizationPrompts != null && selfOptimizationPrompts != '') {
      setState(() {
        selfAiOptimizationPrompts = selfOptimizationPrompts;
      });
    }
    if (baseUrl != null) {
      chatBaseUrl = baseUrl;
    }
    if (aiSelectedMode != null) {
      _aiSelectedMode = aiSelectedMode;
    }
    envDatas = settings;
    try {
      var speechKey = envDatas['azure_voice_speech_key'];
      var serviceRegion = "eastus";
      if (speechKey != null && speechKey != "") {
        bool? isInitialized = envDatas['azure_initialized'];
        if (isInitialized != null && !isInitialized) {
          AzureTts.init(subscriptionKey: speechKey, region: serviceRegion, withLogs: true);
        }
        Map<String, dynamic> azureInitialized = {
          'azure_initialized': true,
        };
        await Config.saveSettings(azureInitialized);
      }
    } catch (e) {
      showHint('$e', showPosition: 2, showType: 3);
      Map<String, dynamic> azureInitialized = {
        'azure_initialized': false,
      };
      await Config.saveSettings(azureInitialized);
    }

    await getAIModelList(settings, true);
    Map<String, dynamic> saveSettings = {'current_novel_folder': '', 'current_novel_title': ''};
    await Config.saveSettings(saveSettings);
  }

  Future<void> getAIModelList(Map<String, dynamic> settings, bool needRefresh) async {
    if (_aiSelectedMode == 0 && _useAiMode == 0) {
      //获取当前key可用模型列表
      try {
        var models = GlobalParams.aiModels;
        aiModelIds.clear();
        aiModelIds.add('暂无可用模型');
        if (models.isNotEmpty) {
          for (var value in models) {
            if (!value['model_id'].startsWith('m') && !value['model_id'].startsWith('s')) {
              if (!aiModelIds.contains(value['model_name'])) {
                aiModelIds.add(value['model_name']);
              }
            }
          }
          Map<String, dynamic> useAiModel = {
            'use_ai_model': findModelIdByName(aiModelIds[1]),
          };
          await Config.saveSettings(useAiModel);
          if (needRefresh && mounted) {
            setState(() {
              selectedAiModel = aiModelIds[1];
            });
          } else {
            selectedAiModel = aiModelIds[1];
          }
          aiModelIds.remove('暂无可用模型');
        } else {
          commonPrint('获取到可用模型个数为0');
        }
      } on Exception catch (e) {
        showHint('获取AI模型失败，原因是$e', showPosition: 2, showType: 3);
      }
    } else if (_useAiMode == 1) {
      aiModelIds.clear();
      aiModelIds.add('qwen-7b-chat');
      aiModelIds.add('qwen-14b-chat');
      setState(() {
        selectedAiModel = aiModelIds[0];
      });
    } else if (_useAiMode == 2) {
      aiModelIds.clear();
      aiModelIds.add('chatglm_pro');
      aiModelIds.add('chatglm_std');
      aiModelIds.add('chatglm_lite');
      setState(() {
        selectedAiModel = aiModelIds[0];
      });
    }
  }

  // 这里是为了某些中转AI返回的结构体不标准进行的手动解析
  Stream<String> postStreamedData({
    required String url,
    required Map<String, dynamic> requestBody,
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
                  setState(() {
                    responseText = allContent;
                  });
                  responseController.text = responseText;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // 在下一帧中滚动到最后一行
                    final maxScrollExtent = _scrollController.position.maxScrollExtent;
                    _scrollController.animateTo(
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

  Future<void> aiArticle(String article) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    int useAiMode = settings['use_mode'] ?? 0;
    if (_aiSelectedMode == 1 && chatBaseUrl == '') {
      showHint('使用web模式的Ai，但未配置web代理地址，无法使用该功能，请在设置中配置代理地址', showPosition: 2, showType: 3);
      return;
    }
    if (_isSelfAIScenePrompt && selfAiOptimizationPrompts != '') {
      if (selectedType == '原文') {
        aiType = '$selfAiOptimizationPrompts,现在需要你将小说优化';
      } else {
        aiType = '$selfAiOptimizationPrompts,现在需要你将$selectedType类型的小说优化';
      }
    }
    String realModelId = findModelIdByName(selectedAiModel);
    try {
      if (useAiMode == 0) {
        //chatGPT
        if (selectedAiModel.startsWith('Mini') || selectedAiModel.startsWith('微软') || selectedAiModel.startsWith('讯飞')) {
          String apiKey = settings['chatSettings_apiKey'] ?? settings['chat_api_key'] ?? '';
          String baseUrl = (settings['chatSettings_apiUrl'] ?? settings['chat_api_url'] ?? '') + '/v1/chat/completions';
          Map<String, dynamic> params = {
            'model': realModelId,
            'messages': [
              {'role': 'user', 'content': '$aiType,接下来我给你一段文字,请你帮忙重写,你要尽可能的重写,尽量改变原文的描述,但是不要改变原文的故事情节,变的更加吸引人阅读,内容是:\n $article'}
            ],
            'stream': true,
          };
          Map<String, String> headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'};
          await postStreamedData(url: baseUrl, requestBody: params, headers: headers).toList();
        } else {
          var message = ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.string(
                "$aiType,接下来我给你一段文字,请你帮忙重写,你要尽可能的重写,尽量改变原文的描述,但是不要改变原文的故事情节,变的更加吸引人阅读,内容是:\n $article"),
          );
          final stream = OpenAIClientSingleton.instance.client.createChatCompletionStream(
            request: CreateChatCompletionRequest(
              model: ChatCompletionModel.modelId(realModelId),
              messages: [
                message,
              ],
            ),
          );
          stream.listen((streamChatCompletion) {
            content = streamChatCompletion.choices.first.delta.content;
            if (content != null) {
              allContent = allContent + content!;
            }
            if (mounted) {
              setState(() {
                responseText = allContent;
              });
              responseController.text = responseText;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // 在下一帧中滚动到最后一行
                final maxScrollExtent = _scrollController.position.maxScrollExtent;
                _scrollController.animateTo(
                  maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              });
            }
          }, onDone: () {
            if (!GlobalParams.isFreeVersion || !GlobalParams.isAdminVersion) {
              //不是免费版本和管理员版本才会进行套餐扣除的处理
              int commonChatNum = box.read('commonChatNum');
              int seniorChatNum = box.read('seniorChatNum');
              if (selectedAiModel.contains('gpt-4')) {
                //TODO 这里其实应该还需要其他模型
                seniorChatNum = seniorChatNum - 1;
                box.write('seniorChatNum', seniorChatNum);
                //TODO 这里进行数据库的数据处理
              } else {
                commonChatNum = commonChatNum - 1;
                box.write('commonChatNum', commonChatNum);
                //TODO 这里进行数据库的数据处理
              }
            }
          }, onError: (e) {
            commonPrint('重写小说文本内容失败，原因是$e');
            showHint('重写小说文本内容失败，原因是$e', showType: 3);
          });
        }
      } else if (useAiMode == 1) {
        //通义千问
        final streamData = StringBuffer();
        final Map<String, dynamic> jsonData = {};
        Map<String, dynamic> payload = {};
        payload['model'] = selectedAiModel;
        payload['input'] = {
          'messages': [
            {'role': 'system', 'content': aiType},
            {'role': 'user', 'content': '接下来我给你一段文字,请你帮忙重写,你要尽可能的重写,尽量改变原文的描述,但是不要改变原文的故事情节,变的更加吸引人阅读,内容是:\n $article'}
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
            setState(() {
              responseText = allContent;
            });
            responseController.text = responseText;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // 在下一帧中滚动到最后一行
              final maxScrollExtent = _scrollController.position.maxScrollExtent;
              _scrollController.animateTo(
                maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            });
          }
        });
      } else if (useAiMode == 2) {
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
          {'role': 'user', 'content': '$aiType,接下来我给你一段文字,请你帮忙重写,你要尽可能的重写,尽量改变原文的描述,但是不要改变原文的故事情节,变的更加吸引人阅读,内容是:\n $article'}
        ];
        inputs['top_p'] = 0.9;
        allContent = '';
        dio.Response response = await myApi.zpai(inputs, token, model: selectedAiModel, isStream: true);
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
            setState(() {
              responseText = allContent;
            });
            String resultString = responseText.replaceAll(RegExp(r'。{2,}'), '。');
            responseController.text = resultString;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // 在下一帧中滚动到最后一行
              final maxScrollExtent = _scrollController.position.maxScrollExtent;
              _scrollController.animateTo(
                maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            });
          }
        });
      }
      if (mounted) {
        setState(() {
          isEditable = true; // 允许编辑
        });
      }
    } on Exception catch (e) {
      setState(() {
        responseController.text = 'AI处理异常，原因是$e';
      });
    }
  }

  Future<void> haveChangedSettings() async {
    changeSettings = Provider.of<ChangeSettings>(context);
    Map<String?, dynamic> map = changeSettings.changeValues;
    map.forEach((key, value) async {
      if (key != null && value != null) {
        if (key == 'ChatGPTUseMode') {
          _aiSelectedMode = value;
          Map<String, dynamic> settings = await Config.loadSettings();
          String? preAIKey = settings['pre_ai_key'];
          String? currentAIKey = settings['chat_api_key'];
          if (preAIKey == null || preAIKey != currentAIKey) {
            await getAIModelList(settings, false);
            Map<String, dynamic> setPreAIKey = {
              'pre_ai_key': currentAIKey,
            };
            await Config.saveSettings(setPreAIKey);
          }
        }
        if (key == 'chat_web_proxy') {
          chatBaseUrl = value;
        }
        if (key == 'use_mode') {
          if (_useAiMode != value) {
            Map<String, dynamic> settings = await Config.loadSettings();
            _useAiMode = value;
            _aiSelectedMode = value;
            if (_useAiMode == 0) {
              aiModelIds.clear();
              String? currentAIKey = settings['chat_api_key'];
              await getAIModelList(settings, true);
              Map<String, dynamic> setPreAIKey = {
                'pre_ai_key': currentAIKey,
              };
              await Config.saveSettings(setPreAIKey);
            } else if (_useAiMode == 1) {
              aiModelIds.clear();
              aiModelIds.add('qwen-7b-chat');
              aiModelIds.add('qwen-14b-chat');
              setState(() {
                selectedAiModel = aiModelIds[0];
              });
            } else if (_useAiMode == 2) {
              aiModelIds.clear();
              aiModelIds.add('chatglm_pro');
              aiModelIds.add('chatglm_std');
              aiModelIds.add('chatglm_lite');
              setState(() {
                selectedAiModel = aiModelIds[0];
              });
            }
          }
        }
      }
    });
  }

  void onChangeArticleType(String type) {
    selectedType = type;
    if (type == '原文') {
      aiType = '你是最好的小说家，擅长写出能够非常吸引人的小说内容';
    } else {
      aiType = '你是最好的$type类型的小说家，擅长写出能够非常吸引人的$type小说内容';
    }
  }

  void onChangeAIType(String type) async {
    selectedAiModel = type;
    Map<String, dynamic> useAiModel = {
      'use_ai_model': findModelIdByName(type),
    };
    await Config.saveSettings(useAiModel);
  }

  Future<void> createNovelFolder() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String defaultFolder = settings['image_save_path'];
    String fullPath = '$defaultFolder${Platform.pathSeparator}${_novelTitleTextFieldController.text}';
    await commonCreateDirectory('$defaultFolder${Platform.pathSeparator}${_novelTitleTextFieldController.text}');
    Map<String, dynamic> saveSettings = {
      'current_novel_folder': fullPath,
      'current_novel_title': _novelTitleTextFieldController.text
    };
    await Config.saveSettings(saveSettings);
  }

  @override
  void initState() {
    articleController = widget.articleController;
    responseController = widget.responseController;
    responseController.text = allContent;
    selfPromptController = TextEditingController();
    _novelTitleTextFieldController = TextEditingController();
    myApi = MyApi();
    loadSettings();
    super.initState();
  }

  Future<void> listenStorage() async {
    box.listenKey('is_login', (value) async {
      if (value) {
        final settings = await Config.loadSettings();
        getAIModelList(settings, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    haveChangedSettings();
    final settings = context.watch<ChangeSettings>();
    return ListView(
      children: <Widget>[
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            Expanded(
                child: GestureDetector(
              child: TextField(
                controller: _novelTitleTextFieldController,
                style: const TextStyle(color: Colors.yellowAccent),
                decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 2.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 2.0),
                    ),
                    labelText: '请输入文章标题，暂不支持中文，请使用拼音或英文代替',
                    labelStyle: TextStyle(color: Colors.white)),
              ),
            )),
            const SizedBox(width: 16),
            ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(settings.getSelectedBgColor()),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                ),
                onPressed: () async {
                  int type = 2;
                  if (_novelTitleTextFieldController.text.isNotEmpty) {
                    if (containsChinese(_novelTitleTextFieldController.text)) {
                      type = 3;
                      draftContent = '小说标题暂不支持中文';
                    } else {
                      await createNovelFolder();
                      draftContent = '以该文章命名的文件夹创建成功';
                    }
                  } else {
                    type = 3;
                    draftContent = '文章标题为空，不能创建以该文章标题命名的文件夹';
                  }
                  showHint(draftContent, showType: type);
                },
                child: const Text('设置'))
          ],
        ),
        const SizedBox(height: 10),
        TextField(
            controller: articleController,
            maxLines: 10,
            minLines: 1,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(color: Colors.yellowAccent),
            decoration: const InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2.0),
                ),
                labelText: '请输入原文',
                labelStyle: TextStyle(color: Colors.white))),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Theme(
                data: ThemeData(
                  unselectedWidgetColor: Colors.yellowAccent,
                ),
                child: Checkbox(
                  value: _isSelfAIScenePrompt,
                  onChanged: (bool? newValue) async {
                    Map<String, dynamic> settings = {
                      'use_self_ai_optimization_prompts': newValue ?? false,
                    };
                    await Config.saveSettings(settings);
                    setState(() {
                      _isSelfAIScenePrompt = newValue ?? false;
                    });
                  },
                )),
            const SizedBox(width: 2),
            const Text(
              '自行输入AI场景转换提示词',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(width: 10),
            Visibility(
              visible: _isSelfAIScenePrompt,
              child: Expanded(
                child: TextField(
                  controller: selfPromptController,
                  onChanged: (text) async {
                    Map<String, dynamic> settings = {'self_ai_optimization_prompts': text};
                    await Config.saveSettings(settings);
                  },
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
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 2.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 2.0),
                    ),
                    labelText: 'AI优化提示词',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            const Text(
              '推文类别:',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CommonDropdownWidget(
                dropdownData: articleTypes,
                selectedValue: selectedType,
                onChangeValue: onChangeArticleType,
              ),
            ),
            Visibility(
              visible: _aiSelectedMode == 0,
              child: Expanded(
                child: Row(
                  children: <Widget>[
                    const SizedBox(width: 10),
                    const Text(
                      'AI模型:',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: CommonDropdownWidget(
                      dropdownData: aiModelIds,
                      selectedValue: selectedAiModel,
                      onChangeValue: onChangeAIType,
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(settings.getSelectedBgColor()),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                ),
                onPressed: () async {
                  if (articleController.text == '') {
                    showHint('请先输入原文再点击开始重写', showType: 3);
                  } else {
                    allContent = '';
                    aiArticle(articleController.text);
                  }
                },
                child: const Text('开始重写'))
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          scrollController: _scrollController,
          readOnly: !isEditable,
          controller: responseController,
          maxLines: 10,
          minLines: 1,
          keyboardType: TextInputType.multiline,
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
          decoration: const InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white, width: 2.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white, width: 2.0),
            ),
            labelText: 'AI处理后的内容将显示在这里',
            labelStyle: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: <Widget>[
          Expanded(
            child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(settings.getSelectedBgColor()),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                ),
                onPressed: () async {
                  if (responseController.text != "" || articleController.text != "") {
                    List<String> scenes = [];
                    String scene = responseController.text != '' ? responseController.text : articleController.text;
                    scenes.add(scene);
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
                                scenes: scenes,
                                isBatch: false,
                                title: '生成配音设置',
                                index: 0,
                                onVoice: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          );
                        },
                      );
                    }
                  } else {
                    showHint('请输入原文或使用AI对原文进行处理', showType: 3);
                  }
                },
                child: const Text('文本转音频')),
          ),
          const SizedBox(
            width: 16,
          ),
          Expanded(
            child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(settings.getSelectedBgColor()),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                ),
                onPressed: () async {
                  if (_novelTitleTextFieldController.text.isNotEmpty) {
                    if (containsChinese(_novelTitleTextFieldController.text)) {
                      showHint('小说标题暂不支持中文', showType: 3);
                    } else {
                      await createNovelFolder();
                      widget.onNextStep(selectedAiModel);
                    }
                  }
                },
                child: const Text('下一步')),
          ),
          const SizedBox(
            width: 16,
          ),
          Expanded(
            child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(settings.getSelectedBgColor()),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                ),
                onPressed: () async {
                  widget.goToThirdStep();
                },
                child: const Text('有历史记录?直接进入第三步')),
          ),
        ]),
        const SizedBox(
          height: 16,
        )
      ],
    );
  }
}
