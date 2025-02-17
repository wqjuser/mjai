import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/net/my_api.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'package:tuitu/utils/my_openai_client.dart';
import '../config/change_settings.dart';
import '../config/config.dart';
import '../config/global_params.dart';
import 'package:dio/dio.dart' as dio;

// ignore: must_be_immutable
class SecondStepView extends StatefulWidget {
  final String aiArticle;
  String selectedAiModel;
  final TextEditingController sceneController;
  final Function(String param, int useAiMode) onNextStep;
  final Function(int currentPage) onPreStep;

  SecondStepView(
      {super.key,
      required this.aiArticle,
      required this.selectedAiModel,
      required this.onNextStep,
      required this.sceneController,
      required this.onPreStep});

  @override
  State<SecondStepView> createState() => _SecondStepViewState();
}

class _SecondStepViewState extends State<SecondStepView> {
  late TextEditingController contentController;
  late TextEditingController selfPromptController;
  late TextEditingController splitController;
  String? content = '';
  String allContent = '';
  String responseText = '';
  String chatBaseUrl = '';
  String selfChatBaseUrl = '';
  late ChangeSettings changeSettings;
  late MyApi myApi;
  int _useAIMode = 1;
  bool _isSelfAIScenePrompt = false;
  final ScrollController _scrollController = ScrollController();
  bool isEditable = false;
  final box = GetStorage();
  double scenes = 1;
  String defaultPrePrompt =
      '''我给你一段文字，首先你需要将这段文字改写的更加吸引人，其次Stable Diffusion是一款利用深度学习的文生图模型，支持通过使用提示词来产生新的图像，描述要包含或省略的元素。 我在这里引入 Stable Diffusion 
    算法中的 Prompt 概念，又被称为提示符。 这里的 Prompt 通常可以用来描述图像，他由普通常见的单词构成，最好是可以在数据集来源站点找到的著名标签（比如 Danbooru)。 
    下面我将说明 Prompt 的生成步骤，这里的 Prompt 主要用于描述人物。 在 Prompt 的生成中，你需要通过提示词来描述 人物属性，主题，外表，情绪，衣服，姿势，视角，动作，背景 。 
    用单词或短语甚至自然语言的标签来描述，并不局限于我给你的单词。 然后将你想要的相似的提示词组合在一起，请使用英文半角 , 做分隔符，并将这些按从最重要到最不重要的顺序 排列。  
    人物属性中，1girl 表示你生成了一个女孩，1boy 表示你生成了一个男孩，人数可以多人。 另外注意，Prompt中不能带有-和_。可以有空格和自然语言，但不要太多，单词不能重复。 
    包含人物性别、主题、外表、情绪、衣服、姿势、视角、动作、背景，将这些按从最重要到最不重要的顺序排列,请尝试生成故事分镜的Prompt,细节越多越好。
    现在你是专业的场景分镜描述专家，你需要把你修改后的吸引人的文字分为不同的场景分镜。每个场景必须要细化，要给出人物，时间，地点，
    场景的描述，必须要细化环境描写（天气，周围有些什么等等内容），必须要细化人物描写（人物衣服，衣服样式，衣服颜色，表情，动作，头发，发色等等），
    如果多个分镜中出现的人物是同一个，请统一这个人物的衣服，发色等细节。如果分镜中出现多个人物，还必须要细化每个人物的细节。
    你回答的分镜要加入自己的一些想象，但不能脱离原文太远。你的回答请务必将每个场景的描述转换为单词，并使用多个单词描述场景，每个分镜至少6个单词，如果分镜中出现了人物,请添加人物
    数量的描述。
    你还需要分析场景分镜中各个物体的比重并且将比重按照提示的格式放在每个单词的后面。你只用回复场景分镜内容，其他的不要回复。
    例如这一段话：我和袁绍是大学的时候认识的，在一起了三年。毕业的时候袁绍说带我去他家见他爸妈。去之前袁绍说他爸妈很注重礼节。还说别让我太破费。我懂，我都懂......
    于是我提前去了我表哥顾朝澜的酒庄随手拿了几瓶红酒。临走我妈又让我再带几个LV的包包过去，他妈妈应该会喜欢的。我也没多拿就带了两个包，其中一个还是全球限量版。女人哪有不喜欢包的，
    所以我猜袁绍妈妈应该会很开心吧。
    将它分为四个场景，你可能需要这样回答我，注意这里仅仅是可能的回答：
    1. 情侣, (一个女孩和一个男孩:1.5), (女孩黑色的长发:1.2), 微笑, (白色的裙子:1.2), 非常漂亮的面庞, (女孩手挽着一个男孩:1.5), 男孩黑色的短发, (穿着灰色运动装, 
    帅气的脸庞:1.2), 走在大学校园里, 
    2. 餐馆内, 一个女孩, (黑色的长发, 白色的裙子:1.5), 坐在餐桌前, 一个男孩坐在女孩的对面, (黑色的短发, 灰色的外套:1.5), 两个人聊天, 
    3. 酒庄内, 一个女孩, 微笑, (黑色的长发, 白色的裙子:1.2),(站着:1.5), (拿着1瓶红酒:1.5), 
    4. 一个女孩, (白色的裙子, 黑色的长发:1.5),(手上拿着两个包:1.5), 站在豪华的客厅内, 
    不要拘泥于我给你示例中的权重数字，权重的范围在1到2之前的权重值。你需要按照分镜中的画面自己判断权重。注意回复中的所有标点符号请使用英文的标点符号包括逗号，不要出现句号，
    仿照例子，给出一套详细描述以下内容的prompt。直接开始给出prompt不需要用自然语言描述：请你牢记这些规则，任何时候都不要忘记。
''';
  String defaultPrePrompt2 = '''
  你能够根据文本内容自动将文本转换为不同的场景片段。我给你一段文字，需要你仔细阅读文本内容，根据文本内容将其转换为不同的文本片段，并按照序号顺序返回给我。
  例如我给你一段文字
  "黎式集团的千金小姐，我为了保护我深爱的男友，刻意隐藏了我的身家。然而，却意外遭到他母亲的不满，她嫌我家境不够富裕，甚至在我为男友做面条时，
  荷包蛋也被省略了。她更将我心爱的全球限量包包嘲弄成假货，用以讽刺我。即便男友也没有站在我这一边，反而责令我道歉。起初，我希望以普通人的身份与他亲近，
  却收获了他的疏离。好吧，我受够了虚伪，我决定坦白，我是个顶尖的富家子弟！"
  你大概需要这样回复我：
 
  1.黎式集团的千金小姐，我为了保护我深爱的男友，刻意隐藏了我的身家。
  2.然而，却意外遭到他母亲的不满，她嫌我家境不够富裕，
  3.甚至在我为男友做面条时，荷包蛋也被省略了。
  4.她更将我心爱的全球限量包包嘲弄成假货，用以讽刺我。
  5.即便男友也没有站在我这一边，反而责令我道歉。
  6.起初，我希望以普通人的身份与他亲近，却收获了他的疏离。
  7.好吧，我受够了虚伪，我决定坦白，我是个顶尖的富家子弟！
  
  具体的回复内容需要你根据文本内容来判断，并返回给我。
  ''';

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
                  widget.sceneController.text = responseText;
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
    if (_isSelfAIScenePrompt && selfPromptController.text != '') {
      defaultPrePrompt = selfPromptController.text;
    }
    try {
      String prompt = "$defaultPrePrompt\n内容是:\n $article\n必须按照我上面的要求将其转换为${scenes.toStringAsFixed(0)}个场景分镜。"
          "你不需要向我解释你转换场景个数和权重的原因，你只用回复场景分镜内容和权重，需要按照示例将内容和权重组合，分镜内容要根据文字内容来描述，"
          "不能脱离文字原本的内容太远，不要省略内容，其他的不要回复，请用中文回答，标点符号请全部使用英文标点符号";
      if (widget.selectedAiModel.startsWith('abab') || widget.selectedAiModel.startsWith('bing')) {
        Map settings = await Config.loadSettings();
        String apiKey = settings['chatSettings_apiKey'] ?? settings['chat_api_key'] ?? '';
        String baseUrl = (settings['chatSettings_apiUrl'] ?? settings['chat_api_url'] ?? '') + '/v1/chat/completions';
        Map<String, dynamic> params = {
          'model': widget.selectedAiModel,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'stream': true,
        };
        Map<String, String> headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'};
        await postStreamedData(url: baseUrl, requestBody: params, headers: headers).toList();
      } else {
        var chatStream = OpenAIClientSingleton.instance.client.createChatCompletionStream(
            request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId(widget.selectedAiModel),
          messages: [
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(
                prompt,
              ),
            ),
          ],
        ));
        chatStream.listen((streamChatCompletion) {
          content = streamChatCompletion.choices.first.delta.content;
          if (content != null) {
            allContent = allContent + content!;
          }
          if (mounted) {
            setState(() {
              responseText = allContent;
            });
            widget.sceneController.text = responseText;
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
          //TODO 这里进行逻辑判断，扣除用户的套餐余量
        }, onError: (e) {
          commonPrint('分镜失败，原因是$e');
        });
      }
      if (mounted) {
        setState(() {
          isEditable = true; // 允许编辑
        });
      }
    } on Exception catch (e) {
      setState(() {
        widget.sceneController.text = 'AI处理异常，原因是$e';
      });
    }
  }

  Future<void> aiArticle2(String article) async {
    if (_isSelfAIScenePrompt && selfPromptController.text != '') {
      defaultPrePrompt = selfPromptController.text;
    }
    try {
      String prompt = "$defaultPrePrompt2\n下面是你要处理的内容，内容是:\n$article\n\n请仿照我给你的例子，将你处理后的文本回复给我，"
          "不需要向我解释你处理的原因，只需要按照序号将内容回复给我就行，直接从序号1开始回复内容，不要回复一些废话内容，不要省略内容，其他的不要回复，请用中文回答，标点符号请全部使用英文标点符号。";
      Map<String, dynamic> settings = await Config.loadSettings();
      int useAIMode = settings['use_mode'] ?? 0;
      if (useAIMode == 0) {
        if (widget.selectedAiModel.startsWith('abab') || widget.selectedAiModel.startsWith('bing')) {
          String apiKey = settings['chatSettings_apiKey'] ?? settings['chat_api_key'] ?? '';
          String baseUrl = (settings['chatSettings_apiUrl'] ?? settings['chat_api_url'] ?? '') + '/v1/chat/completions';
          Map<String, dynamic> params = {
            'model': widget.selectedAiModel,
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
            'stream': true,
          };
          Map<String, String> headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'};
          await postStreamedData(url: baseUrl, requestBody: params, headers: headers).toList();
        } else {
          var chatStream = OpenAIClientSingleton.instance.client.createChatCompletionStream(
              request: CreateChatCompletionRequest(
            model: ChatCompletionModel.modelId(widget.selectedAiModel),
            messages: [
              ChatCompletionMessage.user(
                content: ChatCompletionUserMessageContent.string(
                  prompt,
                ),
              ),
            ],
          ));
          chatStream.listen((streamChatCompletion) {
            content = streamChatCompletion.choices.first.delta.content;
            if (content != null) {
              allContent = allContent + content!;
            }
            if (mounted) {
              setState(() {
                responseText = allContent;
              });
              widget.sceneController.text = responseText;
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
            //TODO 扣除用户套餐内容
            if (!GlobalParams.isFreeVersion || !GlobalParams.isAdminVersion) {
              //不是免费版本和管理员版本才会进行套餐扣除的处理
            }
          }, onError: (e) {
            commonPrint('分镜处理失败，原因是$e');
          });
        }
      } else if (useAIMode == 1) {
        //通义千问
        final streamData = StringBuffer();
        final Map<String, dynamic> jsonData = {};
        Map<String, dynamic> payload = {};
        payload['model'] = widget.selectedAiModel;
        payload['input'] = {
          'messages': [
            {
              'role': 'user',
              'content': '$defaultPrePrompt2\n下面是你要处理的内容，内容是:\n$article\n\n请仿照我给你的例子，将你处理后的文本回复给我，不需要向我解释你处理的原因，'
                  '只需要按照序号将内容回复给我就行，直接从序号1开始回复内容，不要回复一些废话内容，不要省略内容，其他的不要回复，请用中文回答，标点符号请全部使用英文标点符号。'
            }
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
            widget.sceneController.text = responseText;
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
      } else if (useAIMode == 2) {
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
          {
            'role': 'user',
            'content': '$defaultPrePrompt2\n下面是你要处理的内容，内容是:\n$article\n\n请仿照我给你的例子，将你处理后的文本回复给我，不需要向我解释你处理的原因，'
                '只需要按照序号将内容回复给我就行，直接从序号1开始回复内容，不要回复一些废话内容，不要省略内容，其他的不要回复，请用中文回答，标点符号请全部使用英文标点符号。'
          }
        ];
        inputs['top_p'] = 0.9;
        allContent = '';
        dio.Response response = await myApi.zpai(inputs, token, model: widget.selectedAiModel, isStream: true);
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
          if (isNumeric(content)) {
            final int? parsedValue = int.tryParse(content!);
            if (parsedValue != null && parsedValue != 1) {
              content = '\n$content';
            }
          }
          allContent = allContent + content!;
          if (mounted) {
            setState(() {
              responseText = allContent;
            });
            String resultString = responseText.replaceAll(RegExp(r'。{2,}'), '。');
            widget.sceneController.text = resultString;
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
        widget.sceneController.text = 'AI处理异常，原因是$e';
      });
    }
  }

  Future<void> loadSettings() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    bool? useSelfPrompt = settings['use_self_ai_scene_prompts'];
    String? selfPrompt = settings['self_ai_scene_prompts'];
    String? baseUrl = settings['chat_web_proxy'];
    String? useAiModel = settings['use_ai_model'];
    if (useAiModel != null) {
      widget.selectedAiModel = useAiModel;
    }
    if (baseUrl != null) {
      chatBaseUrl = baseUrl;
    }
    int? selectedAiMode = settings['ChatGPTUseMode'];
    if (selectedAiMode != null) {
    }
    if (useSelfPrompt != null) {
      if (mounted) {
        setState(() {
          _isSelfAIScenePrompt = useSelfPrompt;
          if (selfPrompt != null && selfPrompt != '') {
            selfPromptController.text = selfPrompt;
          }
        });
      }
    }
  }

  void haveChangedSettings() {
    changeSettings = Provider.of<ChangeSettings>(context);
    Map<String?, dynamic> map = changeSettings.changeValues;
    map.forEach((key, value) {
      if (key != null && value != null) {
        if (key == 'ChatGPTUseMode') {
          setState(() {
          });
        }
        if (key == 'chat_web_proxy') {
          setState(() {
            chatBaseUrl = value;
          });
        }
      }
    });
  }

  Future<void> _dealArticle() async {
    if (_useAIMode == 0) {
      aiArticle(widget.aiArticle);
    } else if (_useAIMode == 1) {
      aiArticle2(widget.aiArticle);
    } else if (_useAIMode == 2 || _useAIMode == 3) {
      String finalResult = '';
      if (_useAIMode == 3) {
        if (splitController.text.isEmpty) {
          showHint('请先输入自定义分割符号');
          return;
        }
      }
      List<String> results = _useAIMode == 2 ? widget.aiArticle.split('\n') : widget.aiArticle.split(splitController.text);
      for (int i = 0; i < results.length; i++) {
        if (i != results.length - 1) {
          finalResult += '${i + 1}.${results[i]}\n';
        } else {
          finalResult += '${i + 1}.${results[i]}';
        }
        if (mounted) {
          setState(() {
            responseText = finalResult;
          });
          widget.sceneController.text = responseText;
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
      }
    }
  }

  @override
  void initState() {
    super.initState();
    contentController = TextEditingController();
    selfPromptController = TextEditingController();
    splitController = TextEditingController();
    contentController.text = widget.aiArticle;
    myApi = MyApi();
    loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    haveChangedSettings();
    final settings = context.watch<ChangeSettings>();
    selfPromptController.text = _useAIMode == 0 ? defaultPrePrompt : defaultPrePrompt2;
    return ListView(
      children: <Widget>[
        const SizedBox(height: 6),
        TextField(
          controller: contentController,
          keyboardType: TextInputType.multiline,
          minLines: 1,
          maxLines: 10,
          readOnly: true,
          onChanged: (text) {
            contentController.text = text;
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
            labelText: '处理后的原文内容',
            labelStyle: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Theme(
                data: ThemeData(
                  unselectedWidgetColor: Colors.yellowAccent,
                ),
                child: Checkbox(
                  activeColor: settings.getSelectedBgColor(),
                  value: _isSelfAIScenePrompt,
                  onChanged: (bool? newValue) async {
                    Map<String, dynamic> settings = {
                      'use_self_ai_scene_prompts': newValue ?? false,
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
                    Map<String, dynamic> settings = {'self_ai_scene_prompts': text};
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
                    labelText: 'AI场景转换提示词',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            const Text('AI处理模式：', style: TextStyle(color: Colors.white, fontSize: 18)),
            Theme(
                data: ThemeData(
                  unselectedWidgetColor: Colors.yellowAccent,
                ),
                child: Expanded(
                  child: RadioListTile<int>(
                    activeColor: settings.getSelectedBgColor(),
                    title: const Text(
                      'AI转换',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: 1,
                    groupValue: _useAIMode,
                    onChanged: (value) async {
                      setState(() {
                        _useAIMode = value!;
                      });
                    },
                  ),
                )),
            Theme(
                data: ThemeData(
                  unselectedWidgetColor: Colors.yellowAccent,
                ),
                child: Expanded(
                  child: RadioListTile<int>(
                    activeColor: settings.getSelectedBgColor(),
                    title: const Text('指定场景数量转换', style: TextStyle(color: Colors.white)),
                    value: 0,
                    groupValue: _useAIMode,
                    onChanged: (value) async {
                      setState(() {
                        _useAIMode = value!;
                      });
                    },
                  ),
                )),
            Theme(
                data: ThemeData(
                  unselectedWidgetColor: Colors.yellowAccent,
                ),
                child: Expanded(
                  child: RadioListTile<int>(
                    activeColor: settings.getSelectedBgColor(),
                    title: const Text(
                      '使用换行转换',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: 2,
                    groupValue: _useAIMode,
                    onChanged: (value) async {
                      setState(() {
                        _useAIMode = value!;
                      });
                    },
                  ),
                )),
            Theme(
                data: ThemeData(
                  unselectedWidgetColor: Colors.yellowAccent,
                ),
                child: Expanded(
                  child: RadioListTile<int>(
                    title: const Text(
                      '自定义符号转换',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: 3,
                    groupValue: _useAIMode,
                    onChanged: (value) async {
                      setState(() {
                        _useAIMode = value!;
                      });
                    },
                  ),
                )),
            SizedBox(
              width: 150,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(settings.getSelectedBgColor()),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                ),
                onPressed: () async {
                  if (mounted) {
                    allContent = '';
                  }
                  _dealArticle();
                },
                child: const Text('开始转换场景'),
              ),
            )
          ],
        ),
        Visibility(
          visible: _useAIMode == 0,
          child: Row(
            children: <Widget>[
              Expanded(
                  child: Row(children: <Widget>[
                Text(
                  '需要转换的场景数量(${scenes.toStringAsFixed(0)})',
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
                Expanded(
                  child: Slider(
                    value: scenes,
                    min: 1,
                    max: 100,
                    divisions: 100,
                    onChanged: (value) {
                      setState(() {
                        scenes = value;
                      });
                    },
                  ),
                ),
              ])),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Visibility(
            visible: _useAIMode == 3,
            child: Column(
              children: [
                TextField(
                  controller: splitController,
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
                    labelText: '请输入自定义的分割符号',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            )),
        TextField(
          scrollController: _scrollController,
          readOnly: !isEditable,
          controller: widget.sceneController,
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
            labelText: '处理后的场景描述将显示在这里',
            labelStyle: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(settings.getSelectedBgColor()),
                    foregroundColor: WidgetStateProperty.all(Colors.white),
                  ),
                  onPressed: () async {
                    widget.onNextStep(widget.sceneController.text, _useAIMode);
                  },
                  child: const Text('下一步')),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
