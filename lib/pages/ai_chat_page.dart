import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:dio/dio.dart' as dio;
import 'package:extended_image/extended_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/global_params.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'package:tuitu/utils/my_openai_client.dart';
import 'package:tuitu/utils/supabase_helper.dart';
import 'package:tuitu/widgets/chat_item_view.dart';
import 'package:tuitu/widgets/chat_settings.dart';
import 'package:tuitu/widgets/file_display_widget.dart';
import 'package:tuitu/widgets/image_preview_widget.dart';
import 'package:uuid/uuid.dart';
import '../config/change_settings.dart';
import '../config/config.dart';
import '../json_models/chat_list_data.dart';
import '../json_models/chat_message.dart';
import '../json_models/question_data.dart';
import '../json_models/text_segment.dart';
import '../json_models/uploading_file.dart';
import '../net/my_api.dart';
import '../net/api_exception.dart';
import '../net/handle_chat_request.dart';
import '../utils/encryption_utils.dart';
import '../utils/file_picker_manager.dart';
import '../utils/native_communication.dart';
import '../widgets/chat_controls.dart';
import '../widgets/chat_list_view.dart';
import '../widgets/clipboardl_listener_widget.dart';
import '../widgets/custom_dialog.dart';
import 'package:path/path.dart' as path;
import '../widgets/drag_drop_widget.dart';
import '../widgets/file_viewer_widget.dart';
import '../widgets/shareable_message_list.dart';
import '../widgets/user_info_dialog_widget.dart';

/// AI聊天界面
class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class ChatService {
  final StreamController<ChatMessage> _messageController = StreamController<ChatMessage>.broadcast();

  Stream<ChatMessage> get messageStream => _messageController.stream;

  void dispose() {
    _messageController.close();
  }
}

class _AIChatPageState extends State<AIChatPage> {
  // 使用ValueNotifier包裹聊天列表数据
  final ValueNotifier<List<ChatListData>> _chatListNotifier = ValueNotifier([]);
  final List<GlobalKey> _chatTitleKeys = [];
  final Map<int, bool> _hovering = {};
  int _selectedIndex = 0; // 用于跟踪当前选中项的索引
  late ChatService chatService;
  List<ChatMessage> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _leftScrollController = ScrollController();
  late Map<String, dynamic> settings;
  int randomSeed = 0;
  late MyApi myApi;
  final random = math.Random();
  String createTime = '';
  String useAIModel = '自动选择';
  String useImageSize = '1024x1024';
  String videoSize = '不指定';
  String videoDuration = '5';
  String videoFPS = '30';
  String videoImagePath = '';
  bool aiSound = false;
  bool enableNet = false;
  bool enableChatContext = true;
  bool justCleanContext = false;
  bool autoGenerateTitle = true;
  bool isHovering1 = false;
  bool isHovering2 = false;
  bool isHovering3 = false;
  bool isHovering4 = false;
  bool isHovering5 = false;
  bool isHovering6 = false;
  bool isHovering7 = false;
  bool isLogin = false;
  String fileContent = '';
  String fileName = '';
  String urlContent = '';
  bool alwaysShowModelName = false;
  final box = GetStorage();
  int maxTokens = 2048;
  double tem = 0.6;
  double tp = 1.0;
  double pp = 0.0;
  double fp = 0.0;
  Map<String, dynamic> curChatSet = {};
  bool isAnswering = false;
  MapEntry<String, dynamic>? currentTask;
  bool isExecuting = false;
  List<MapEntry<String, dynamic>> taskList = [];
  int tempInt = 0;
  final GlobalKey<ChatListViewState> _chatListKey = GlobalKey<ChatListViewState>();
  final List<GlobalKey> _keys = [];
  bool isOnBottom = false;
  bool canAutoScroll = true;
  bool hasFileUploaded = false;
  String defaultAIResponseLanguage = '自动选择';
  int chatMessagesStartIndex = 0;
  double _leftPanelWidth = 270.0; // 初始宽度为270
  // 存储所有上传的文件
  List<UploadingFile> allUploadedFiles = [];
  List<UploadingFile> tempFiles = [];
  String currentTitle = '';
  final GlobalKey _textFieldKey = GlobalKey();
  Map<String, dynamic> userChatAvailableInfo = {};
  bool isUserScrollUp = false;
  int currentChatTokens = 0;
  bool canUseTokens = false;
  bool canUseChatNum = false;
  int isSeniorChat = 0;
  int canUsedTokens = 0;
  int canUsedSeniorChatNum = 0;
  int canUsedCommonChatNum = 0;
  int canUsedSeniorDrawNum = 0;
  String pastedContent = '';
  final List<QuestionData> _questionList = [];
  final List<TextSegment> _textSegments = [];

  // 控制多选模式的状态
  bool _isMultiSelectMode = false;

  // 存储被选中的项的索引
  final Set<int> _selectedItems = {};

  // 搜索关键词
  String _searchKeyword = '';

  // 搜索框控制器
  final TextEditingController _searchController = TextEditingController();

  // 用于追踪是否全选的变量
  bool _isAllSelected = false;

  //对话的流式请求
  StreamSubscription<dynamic>? _chatStreamSubscription;

  //搜索防抖
  Timer? _searchDebounce;

  Set<String> _searchMatchedCreateTimes = {};

  bool _enableDrop = true;

  //是否使用加密
  bool _useEncrypt = true;

  //消息体加密key
  String _encryptKey = '';

  //是否处于搜索状态
  bool _isSearching = false;

  //截图相关属性
  bool _isCapturing = false;

  //截图时是否关闭窗口
  bool _closeWindowWhenCapturing = false;

  bool _showLeftPanel = true;

  Future<void> _addNewChat(String title) async {
    currentTitle = title;
    String curChatSetStr = await _getChatSettings();
    await getSettingsData(needRefreshModel: true);
    String userId = settings['user_id'] ?? '';
    bool isLogin = settings['is_login'] ?? false;
    //增加用户时候登录判断，只有登录用户才能对话
    if (!isLogin) {
      showHint('请先登录', showType: 3);
      return;
    }
    isOnBottom = true;
    chatMessagesStartIndex = 0;
    tempFiles.clear();
    createTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    try {
      randomSeed = random.nextInt(1 << 32);
      //这里是新建了一个空的聊天内容,有一个默认提示词
      ChatMessage defaultHintMessage = ChatMessage(
          text: '我今天能帮你做什么呢？',
          isSentByMe: false,
          model: '魔镜AI',
          sendTime: createTime,
          userName: '魔镜AI',
          isPrivate: _useEncrypt,
          encryptKey: _encryptKey);
      messages.clear();
      messages.add(defaultHintMessage);
      // 将消息数组序列化为JSON字符串
      String messagesJson = jsonEncode(messages.map((m) => m.toJson()).toList());
      var onlyOneChatMessage = [defaultHintMessage];
      var chats = onlyOneChatMessage;
      messages.clear();
      _keys.clear();
      setState(() {
        messages.addAll(chats);
        for (int i = 0; i < messages.length; i++) {
          _keys.add(GlobalKey());
        }
      });
      _selectedIndex = 0;
      _chatTitleKeys.insert(0, GlobalKey());
      // 更新ValueNotifier
      _chatListNotifier.value = List.from(_chatListNotifier.value)
        ..insert(0,
            ChatListData(id: DateTime.now().millisecondsSinceEpoch, title: title, createTime: createTime, modelName: useAIModel, messagesCount: 0));
      _scrollToBottom();
      if (_leftScrollController.hasClients) {
        _leftScrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
      setState(() {});
      await SupabaseHelper().insert('chat_list', {
        'title': title,
        'createTime': createTime,
        'isChangedTitle': 0,
        'user_id': userId,
        'is_delete': 0,
        'modelName': useAIModel,
        'messagesCount': 0,
        'isSelected': true
      });
      await SupabaseHelper().insert('chat_contents', {
        'title': currentTitle,
        'createTime': createTime,
        'content': messagesJson,
        'useAIModel': useAIModel,
        'chatSettings': curChatSetStr,
        'user_id': userId,
        'is_delete': 0,
        'key': const Uuid().v4(),
      });
    } catch (e) {
      commonPrint('新建聊天失败，异常是$e');
    }
  }

  Future<void> _captureScreen() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);
    if (_closeWindowWhenCapturing) {
      await box.write('capture_close_window', true);
    }
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      String? capturedPath = await NativeCommunication.startScreenshot();
      if (_closeWindowWhenCapturing) {
        await box.write('capture_close_window', false);
      }
      if (capturedPath != null && capturedPath.isNotEmpty) {
        // 处理截图路径
        String fileName = path.basename(capturedPath);
        //截图完成后自动上传
        var captureImage = PlatformFile(name: fileName, size: 0, path: capturedPath);
        var captureImageFile = UploadingFile(
            key: GlobalKey().toString(),
            file: captureImage,
            content: pastedContent,
            isPrivate: _useEncrypt,
            encryptKey: _encryptKey,
            isUploaded: false);
        setState(() {
          hasFileUploaded = false;
          allUploadedFiles.add(captureImageFile);
        });
        await uploadSingleFile(captureImageFile, captureImageFile.key, needDelete: true);
        setState(() {
          hasFileUploaded = checkUploadFileStatus();
        });
      } else {
        commonPrint('截图取消或失败');
      }
    } catch (e) {
      commonPrint('Failed to capture screen: $e');
    } finally {
      setState(() => _isCapturing = false);
    }
  }

  Future<String> _getChatSettings({Map<String, dynamic>? inputSettings}) async {
    final bool isMobile = Platform.isAndroid || Platform.isIOS;
    if (inputSettings != null) {
      settings = inputSettings;
    } else {
      settings = await Config.loadSettings();
    }
    String chatSettingsStr = '';
    Map<String, dynamic> chatSettings = {};
    useAIModel = chatSettings['chatSettings_defaultModel'] = settings['chatSettings_defaultModel'] ?? '自动选择';
    useImageSize = chatSettings['chatSettings_defaultImageSize'] = settings['chatSettings_defaultImageSize'] ?? '1024x1024';
    defaultAIResponseLanguage = chatSettings['chatSettings_defaultLanguage'] = settings['chatSettings_defaultLanguage'] ?? '自动选择';
    chatSettings['chatSettings_defaultGenerateTitleModel'] = settings['chatSettings_defaultGenerateTitleModel'] ?? '自动选择';
    alwaysShowModelName = isMobile ? false : chatSettings['chatSettings_alwaysShowModelName'] = settings['chatSettings_alwaysShowModelName'] ?? false;
    autoGenerateTitle = chatSettings['chatSettings_autoGenerateTitle'] = settings['chatSettings_autoGenerateTitle'] ?? true;
    enableNet = chatSettings['chatSettings_enableNet'] = settings['chatSettings_enableNet'] ?? false;
    _encryptKey = chatSettings['chatSettings_privateModeKey'] = settings['chatSettings_privateModeKey'] ?? '';
    _closeWindowWhenCapturing = chatSettings['chatSettings_captureCloseWindow'] = settings['chatSettings_captureCloseWindow'] ?? false;
    chatSettings['chatSettings_useNetUrl'] = settings['chatSettings_useNetUrl'] ?? '';
    chatSettings['chatSettings_netSearch'] = settings['chatSettings_netSearch'] ?? '5.0';
    chatSettings['chatSettings_apiUrl'] = settings['chatSettings_apiUrl'] ?? '';
    chatSettings['chatSettings_apiKey'] = settings['chatSettings_apiKey'] ?? '';
    chatSettings['chatSettings_userAddModels'] = settings['chatSettings_userAddModels'] ?? [];
    tem = chatSettings['chatSettings_tem'] = settings['chatSettings_tem'] ?? 0.6;
    tp = chatSettings['chatSettings_top_p'] = settings['chatSettings_top_p'] ?? 1.0;
    pp = chatSettings['chatSettings_pp'] = settings['chatSettings_pp'] ?? 0.0;
    fp = chatSettings['chatSettings_fp'] = settings['chatSettings_fp'] ?? 0.0;
    enableChatContext = chatSettings['chatSettings_enableChatContext'] = settings['chatSettings_enableChatContext'] ?? true;
    chatSettings['chatSettings_withContextValue'] = settings['chatSettings_withContextValue'] ?? 5.0;
    chatSettings['chatSettings_maxTokens'] = settings['chatSettings_maxTokens'] ?? '2048';
    _useEncrypt = chatSettings['chatSettings_enablePrivateMode'] = settings['chatSettings_enablePrivateMode'] ?? true;
    maxTokens = int.parse(settings['chatSettings_maxTokens'] ?? '2048');
    chatSettingsStr = jsonEncode(chatSettings);
    curChatSet = chatSettings;
    return chatSettingsStr;
  }

  Future<void> _deleteChat(int chatId, String createTime) async {
    try {
      for (int i = 0; i < _chatListNotifier.value.length; i++) {
        var chat = _chatListNotifier.value[i];
        if (chat.createTime == createTime) {
          _chatTitleKeys.removeAt(i);
        }
      }
      var settings = await Config.loadSettings();
      String userId = settings['user_id'] ?? '';
      await SupabaseHelper().update('chat_list', {'is_delete': 1}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
      await SupabaseHelper().update('chat_contents', {'is_delete': 1}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
    } catch (e) {
      commonPrint('聊天删除失败，原因是$e');
    }
  }

  // 聊天设置
  Future<void> _setChat({isSingleChat = false, isSingleChatSet = false, isGlobalChatSet = true, ChangeSettings? settings}) async {
    final bool isMobile = Platform.isAndroid || Platform.isIOS;
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomDialog(
            title: null,
            showConfirmButton: false,
            showCancelButton: false,
            description: null,
            maxWidth: 600,
            minWidth: 400,
            minHeight: 50,
            contentBackgroundColor: settings!.getBackgroundColor(),
            content: Padding(
              padding: EdgeInsets.all(isMobile ? 0 : 10),
              child: ChatSettings(
                isSingleChat: isSingleChat,
                isSingleChatSet: isSingleChatSet,
                isGlobalChatSet: isGlobalChatSet,
                currentSettings: (isSingleChat || isSingleChatSet) ? curChatSet : null,
                onConfirm: isSingleChat
                    ? (modelName) {
                        Navigator.of(context).pop();
                        showHint('当前聊天模型已更改为：$modelName', showType: 2, showTime: 500);
                        box.write('chatSettings_defaultModel', modelName);
                      }
                    : null,
                onConfirmSingleChatSet: isSingleChatSet ? (settings) {} : null,
                modelName: isSingleChat ? useAIModel : null,
              ),
            ),
          );
        },
      );
    }
  }

  // 读取聊天列表历史，这里使用supabase
  Future<void> _readChatListHistory() async {
    showHint('读取聊天列表中...', showType: 5);
    try {
      settings = await Config.loadSettings();
      String userId = settings['user_id'] ?? '';
      final List<Map<String, dynamic>> maps = await SupabaseHelper().query('chat_list', {'is_delete': 0, 'user_id': userId}, isOrdered: false);
      if (maps.isNotEmpty) {
        for (int i = 0; i < maps.length; i++) {
          _chatTitleKeys.add(GlobalKey());
        }
      }
      _chatListNotifier.value = List.generate(maps.length, (i) {
        return ChatListData(
          id: maps[i]['id'],
          title: maps[i]['title'],
          createTime: maps[i]['createTime'],
          modelName: maps[i]['modelName'] ?? '',
          messagesCount: maps[i]['messagesCount'] ?? 0,
          isSelected: maps[i]['isSelected'] ?? false,
        );
      });
      if (_chatListNotifier.value.isNotEmpty) {
        createTime = _chatListNotifier.value[0].createTime;
        for (int k = 0; k < _chatListNotifier.value.length; k++) {
          var chat = _chatListNotifier.value[k];
          if (chat.isSelected) {
            createTime = chat.createTime;
            _selectedIndex = k;
            setState(() {
              _scrollToIndex(k);
            });
            break;
          }
        }
        final chats = await _readChatContentHistory(createTime);
        _keys.clear();
        setState(() {
          messages = chats;
        });
        for (int i = 0; i < messages.length; i++) {
          _keys.add(GlobalKey());
        }
        _scrollToBottom();
      } else {
        _addNewChat('新的聊天');
      }
    } catch (e) {
      commonPrint('读取聊天列表异常，错误是$e');
    } finally {
      dismissHint();
    }
  }

  void _scrollToIndex(int index) {
    final context = _chatTitleKeys[index].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
      );
    } else {
      //无法通过获取context，尝试滚动到指定位置
      const itemHeight = 66.0; // 每个项的高度
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_leftScrollController.hasClients) {
          return;
        }
        _leftScrollController.animateTo(
          (index) * itemHeight,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  // 滚动到底部的方法
  void _scrollToBottom({bool isReadHistory = false, bool isAutoScroll = false}) {
    _chatListKey.currentState?.scrollToBottom();
    setState(() {
      isOnBottom = true;
    });
  }

  Future<void> _addMessageToChat(String text, {bool isFinal = false}) async {
    if (messages.isEmpty || messages.last.isSentByMe) {
      String sendTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      messages.add(
          ChatMessage(isSentByMe: false, text: '思考中，请稍后...', model: useAIModel, sendTime: sendTime, isPrivate: _useEncrypt, encryptKey: _encryptKey));
      _keys.add(GlobalKey());
      setState(() {}); // 立即显示"思考中"的消息
    }

    final lastMessage = messages.last;
    if (lastMessage.text == '思考中，请稍后...') {
      lastMessage.text = ''; // 清除"思考中"的文本
      lastMessage.fullText = ''; // 确保 fullText 也被清除
      setState(() {}); // 立即更新 UI 以移除"思考中"的文本
    }

    if (!isFinal) {
      lastMessage.fullText = preprocessMarkdown((lastMessage.fullText ?? '') + text);
      _animateTyping(lastMessage);
    } else {
      lastMessage.text = preprocessMarkdown(lastMessage.fullText ?? '');
      lastMessage.fullText = preprocessMarkdown(lastMessage.text + text); // 确保 fullText 与最终文本一致
      _animateTyping(lastMessage); // 确保最终文本被显示
    }
    setState(() {});
  }

  void _animateTyping(ChatMessage message) {
    if (message.animationTimer != null) {
      message.animationTimer!.cancel();
    }

    int currentLength = message.text.length;
    int targetLength = message.fullText?.length ?? 0;

    message.animationTimer = Timer.periodic(const Duration(milliseconds: 3), (timer) {
      if (currentLength < targetLength) {
        currentLength += 1;
        // 查找最近的单词边界
        while (currentLength < targetLength && !RegExp(r'\s').hasMatch(message.fullText![currentLength - 1])) {
          currentLength++;
        }
        message.text = preprocessMarkdown(message.fullText!.substring(0, currentLength));
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> changeChatTitle() async {
    var settings = await Config.loadSettings();
    bool isChangedTitle = false;
    var queryData = await SupabaseHelper().query('chat_list', {'createTime': createTime});
    if (queryData.isNotEmpty) {
      var firstData = queryData[0];
      isChangedTitle = (firstData['isChangedTitle']! as int) != 0;
    }
    if (messages.length >= 9 && !isChangedTitle) {
      List<ChatCompletionMessage> currentMessagesNew = [];
      for (var element in messages) {
        if (element.isSentByMe) {
          final userMessageNew = ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.string(
              element.text,
            ),
          );
          currentMessagesNew.add(userMessageNew);
        } else {
          final aiMessageNew = ChatCompletionMessage.assistant(
            content: element.text,
          );
          currentMessagesNew.add(aiMessageNew);
        }
      }
      const userMessageNew = ChatCompletionMessage.user(
        content: ChatCompletionUserMessageContent.string(
          '请根据上述聊天，总结一下聊天标题，标题控制在10个字以内，你直接回复xxxxxx，xxxxxx是指标题，请牢记回复格式，不要回复其他内容。',
        ),
      );
      // currentMessages.add(userMessage);
      currentMessagesNew.add(userMessageNew);
      String useModel = settings['chatSettings_defaultGenerateTitleModel'] ?? '自动选择';
      if (useModel == '自动选择') {
        useModel = 'gpt-3.5-turbo';
      }
      final res = await OpenAIClientSingleton.instance.client.createChatCompletion(
        request: CreateChatCompletionRequest(
            model: ChatCompletionModel.modelId(useModel), messages: currentMessagesNew, temperature: 0.6, maxTokens: 2048),
      );
      currentTitle = '${res.choices.first.message.content}';
      for (var element in _chatListNotifier.value) {
        if (element.createTime == createTime) {
          element.title = currentTitle;
        }
      }
      setState(() {});
      String userId = settings['user_id'] ?? '';
      await SupabaseHelper()
          .update('chat_list', {'title': currentTitle, 'isChangedTitle': 1}, updateMatchInfo: {'user_id': userId, 'createTime': createTime});
      await SupabaseHelper().update('chat_contents', {'title': currentTitle}, updateMatchInfo: {'user_id': userId, 'createTime': createTime});
    }
  }

  String preprocessMarkdown(String data) {
    // 1. 恢复转义的美元符号为非转义的美元符号
    String processedData = data.replaceAll(r'\$', r'$');

    // 2. 将方括号替换为块级公式表示的美元符号 ($$)
    processedData = processedData.replaceAll('\\[', r'$$');
    processedData = processedData.replaceAll('\\]', r'$$');

    // 3. 将小括号替换为行内公式表示的美元符号 ($)
    processedData = processedData.replaceAll('\\(', r'$');
    processedData = processedData.replaceAll('\\)', r'$');
    // 4. 动态替换不兼容的 LaTeX 表达式 (\sqrt[n]{...} -> |...|^{1/n})
    final sqrtRegex = RegExp(r'\\sqrt\[(.*?)\]\{(.*?)\}');
    processedData = processedData.replaceAllMapped(sqrtRegex, (match) {
      String index = match.group(1)!; // 根号的指数部分
      String content = match.group(2)!; // 根号内的内容
      return '|$content|^{1/$index}';
    });
    return processedData;
  }

  //如果文件内容超过了2000行就截取前2000行,如果只有一行就截取前10000个字符
  String processString(String input) {
    // 按换行符拆分字符串
    List<String> lines = input.split('\n');

    // 判断是否只有一行
    if (lines.length == 1) {
      // 如果只有一行，截取前10000个字符
      return input.length > 01000 ? input.substring(0, 10000) : input;
    }

    // 判断行数是否超过2000
    if (lines.length > 2000) {
      // 截取前2000行
      lines = lines.sublist(0, 2000);
    }

    // 重新组合成字符串
    return lines.join('\n');
  }

  String replaceUrlsInText(String text) {
    // 定义一个正则表达式来匹配网址
    RegExp urlPattern = RegExp(r'(http|https)://[a-zA-Z0-9\-.]+\.[a-zA-Z]{2,3}(:[0-9]{1,5})?(/[a-zA-Z0-9\-%_/]*)?');

    // 使用 replaceAllMapped 来查找并替换 URL
    String replacedText = text.replaceAllMapped(urlPattern, (match) {
      String urlInText = match.group(0)!; // 获取匹配到的 URL
      return '[$urlInText]($urlInText)'; // 替换为指定格式
    });

    return replacedText;
  }

  //发送消息并接收回复
  void _sendMessage(String text, {bool isRetry = false}) async {
    canUsedTokens = box.read('tokens') ?? 0;
    canUsedSeniorChatNum = box.read('seniorChatNum') ?? 0;
    canUsedCommonChatNum = box.read('commonChatNum') ?? 0;
    canUsedSeniorDrawNum = box.read('seniorDrawNum') ?? 0;
    if (useAIModel == '自动选择') {
      useAIModel = 'gpt-3.5-turbo';
      if (text.contains('画')) {
        String mjUrl = settings['mj_api_url'] ?? '';
        String mjKey = settings['mj_api_secret'] ?? '';
        if (mjUrl != '' && mjKey != '') {
          useAIModel = 'MJ绘画';
        } else {
          useAIModel = 'gpt-4-all';
        }
      }
      if (tempFiles.isNotEmpty) {
        useAIModel = 'gpt-4o';
      }
    }
    if (tempFiles.isNotEmpty) {
      if (useAIModel.contains('o1-mini') || useAIModel.contains('o1-preview')) {
        isAnswering = false;
        showHint('当前模型不支持附件，请选择其他模型。');
        return;
      }
    }
    if (text.trimRight().isEmpty && tempFiles.isEmpty && !isRetry) {
      _controller.clear();
      isAnswering = false;
      return;
    }
    isAnswering = true;
    await getSettingsData();
    String userName = settings['user_name'] ?? '';
    List<ChatCompletionMessage> currentMessagesNew = [];
    List<ChatCompletionMessageContentPart> currentMessagesPartsNew = [];
    String curChatSetStr = jsonEncode(curChatSet);
    setState(() {
      if (!isRetry) {
        allUploadedFiles.clear();
        String sendTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
        List<UploadingFile> chatFiles = List.from(tempFiles);
        messages.add(ChatMessage(
            text: text,
            isSentByMe: true,
            model: useAIModel,
            sendTime: sendTime,
            files: chatFiles,
            userName: userName,
            isPrivate: _useEncrypt,
            encryptKey: _encryptKey));
        _chatListNotifier.value[_selectedIndex].messagesCount = messages.length - 1;
        _keys.add(GlobalKey());
        String messagesJson = jsonEncode([messages.last.toJson()]);
        String userId = settings['user_id'] ?? '';
        SupabaseHelper().update('chat_list', {'messagesCount': messages.length - 1}, updateMatchInfo: {'user_id': userId, 'createTime': createTime});
        SupabaseHelper().insert('chat_contents', {
          'title': currentTitle,
          'createTime': createTime,
          'content': messagesJson,
          'useAIModel': useAIModel,
          'chatSettings': curChatSetStr,
          'user_id': userId,
          'is_delete': 0,
          'key': const Uuid().v4(),
        });
      }
      _addMessageToChat('思考中，请稍后...', isFinal: true);
      _controller.clear();
      _scrollToBottom();
    });
    var chatMessages = List.from(messages.sublist(chatMessagesStartIndex));
    String urlInText = '';
    // 定义一个正则表达式来匹配网址
    RegExp urlPattern = RegExp(r'(http|https)://[a-zA-Z0-9\-.]+\.[a-zA-Z]{2,3}(:[0-9]{1,5})?(/[a-zA-Z0-9\-%_/]*)?');
    // 使用正则表达式查找匹配项
    Iterable<RegExpMatch> matches = urlPattern.allMatches(text);
    if (matches.isNotEmpty) {
      for (var match in matches) {
        urlInText = match.group(0)!;
      }
    }
    if (urlInText != '') {
      if (text.contains('总结')) {
        try {
          dio.Response response = await myApi.getUrlContent(urlInText);
          if (response.statusCode == 200) {
            urlContent = response.data;
            String sumTextPrompt = '我需要对网站内容进行总结，总结输出包括以下三个部分：\n📖 一句话总结\n🔑 关键要点,用数字序号列出3-5个文章的核心内容\n🏷 标签: #xx #xx'
                '\n请使用emoji让你的表达更生动。';
            text = '$sumTextPrompt\n网址内容是\n$urlContent';
          }
        } catch (e) {
          commonPrint("网页内容获取失败${e.toString()}");
        }
      }
    } else if (enableNet && !useAIModel.contains('联网')) {
      String currentTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      String preText = 'You will play the role of an AI Q&A assistant, where your knowledge base is not offline, but can be '
          'networked in real time, and you can provide real-time networked information with links to networked '
          'search sources.\nCurrent time: $currentTime\nReal-time internet search results\n';
      try {
        dio.Response response = await myApi.getSearchResult(text);
        if (response.statusCode == 200) {
          List<Map<String, dynamic>> searchResults = List<Map<String, dynamic>>.from(response.data);
          for (var element in searchResults) {
            preText += '${element['title']}(${element['href']})${element['body']}\n';
          }
        }
      } catch (e) {
        commonPrint("搜索失败$e");
      }
      final systemMessageNew = ChatCompletionMessage.system(content: preText);
      currentMessagesNew.add(systemMessageNew);
    }
    String language = '';
    if (defaultAIResponseLanguage != '自动选择') {
      language = '\n请使用$defaultAIResponseLanguage来回答，语言回答要求不需要做出回复';
    }
    var fileMessages = {};
    if (enableChatContext && !justCleanContext) {
      //携带上下文
      int contextNum = int.tryParse(settings['chatSettings_withContextValue']?.toString() ?? '4') ?? 4;
      var lastMessages = chatMessages.length - 3 >= contextNum
          ? chatMessages.sublist(chatMessages.length - 3 - contextNum, chatMessages.length - 2)
          : chatMessages.length == 2
              ? chatMessages.sublist(1, chatMessages.length - 1)
              : chatMessages.sublist(1, chatMessages.length - 2);

      for (var element in lastMessages) {
        String fileUrls = '';
        if (element.isSentByMe) {
          List<ChatCompletionMessageContentPart> currentMessagesPartsNew = [];
          String text = element.text;
          if (element.files != null && element.files!.isNotEmpty) {
            for (var file in element.files!) {
              if (file.file.name.startsWith('复制')) {
                fileUrls += '${file.content}\n';
              } else {
                String fileName = path.basename(file.file.path!);
                String fileContent = file.content ?? '';
                String fileUrl = file.fileUrl;
                String lowerFileContent = fileContent.toLowerCase();
                fileContent = processString(fileContent);
                if (lowerFileContent.endsWith('jpg') || lowerFileContent.endsWith('jpeg') || lowerFileContent.endsWith('png')) {
                  if (useAIModel.contains('逆向') ||
                      useAIModel.contains('4o') ||
                      useAIModel.contains('Mini') ||
                      useAIModel.contains('claude') ||
                      useAIModel.contains('智谱AI免费') ||
                      useAIModel.contains('带思考')) {
                    final userMessageNew =
                        ChatCompletionMessageContentPart.image(imageUrl: ChatCompletionMessageImageUrl(url: fileUrl == '' ? fileContent : fileUrl));
                    currentMessagesPartsNew.add(userMessageNew);
                  } else {
                    fileUrls += '文件$fileName的在线路径是 $fileContent\n';
                  }
                } else {
                  if (!useAIModel.contains('逆向')) {
                    fileContent = 'The file name is $fileName\n Part of this file content is :\n$fileContent\n';
                  } else {
                    fileContent = '';
                  }
                  fileUrls += '文件$fileName的在线路径是 $fileUrl \n$fileContent';
                }
              }
            }
          }
          final userMessageNew = ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.parts([
              ChatCompletionMessageContentPart.text(
                text: removeExtraSpaces(fileUrls + text),
              ),
              ...currentMessagesPartsNew,
            ]),
          );
          currentMessagesNew.add(userMessageNew);
        } else {
          final aiMessageNew = ChatCompletionMessage.assistant(content: element.text);
          currentMessagesNew.add(aiMessageNew);
        }
      }
      fileMessages = putFilesIntoChat(currentMessagesPartsNew, currentMessagesNew);
    } else {
      fileMessages = putFilesIntoChat(currentMessagesPartsNew, currentMessagesNew);
    }
    final userMessageNew = ChatCompletionMessage.user(
      content: ChatCompletionUserMessageContent.parts([
        ChatCompletionMessageContentPart.text(
          text: removeExtraSpaces('${fileMessages['fileUrls']}\n$language\n$text'),
        ),
        ...fileMessages['currentMessagesPartsNew'],
      ]),
    );
    currentMessagesNew.add(userMessageNew);
    String realModelId = findModelIdByName(useAIModel);
    if (useAIModel != 'MJ绘画') {
      if (realModelId == 'cogview-3-flash') {
        //这里是智谱AI的相关操作
        var configs = await Config.loadSettings();
        try {
          showHint('正在绘图,请稍后...', showType: 5);
          var generateImageResponse = await myApi.zhipuGenerateImage(
              {
                'model': realModelId,
                'prompt': text,
                'size': useImageSize,
              },
              dio.Options(headers: {
                'Authorization': 'Bearer ${configs['zpai_api_key'] ?? ''}',
              }));
          if (generateImageResponse.statusCode == 200) {
            List<dynamic> imageData = generateImageResponse.data['data'] ?? [];
            if (imageData.isNotEmpty) {
              String imageUrl = imageData[0]['url'];
              String useImagePath = await imageUrlToBase64(imageUrl);
              String filePath = '';
              File file = await base64ToTempFile(useImagePath);
              if (file.existsSync()) {
                filePath = file.path;
              }
              if (filePath != '') {
                imageUrl = await uploadFileToALiOss(filePath, imageUrl, file);
              }
              String messageText = '智谱AI免费绘图完成\n\n ![$text](${GlobalParams.filesUrl + imageUrl}) \n\n';
              _addMessageToChat(messageText);
              _scrollToBottom();
              dismissHint();
              await finishChat();
            }
          } else {
            commonPrint(generateImageResponse);
            _addMessageToChat('智谱AI绘图失败');
            commonPrint('智谱AI绘图失败');
            dismissHint();
            await finishChat();
          }
        } catch (e) {
          _addMessageToChat('智谱AI绘图失败');
          commonPrint('智谱AI绘图失败,$e');
          dismissHint();
          await finishChat();
        }
      } else if (realModelId == 'cogvideox-flash') {
        generateVideoByZhipu(text, realModelId);
      } else {
        //计算tokens
        if (canUsedTokens > 0) {
          currentChatTokens = await countCurrentChatTokens(currentMessagesNew, realModelId);
        }
        isSeniorChat = isSeniorModel(useAIModel);
        userChatAvailableInfo = await checkChatAvailability(
            isSeniorChat, canUsedSeniorChatNum, canUsedCommonChatNum, canUsedTokens, currentChatTokens, canUseChatNum, canUseTokens);
        if (!GlobalParams.isAdminVersion && !GlobalParams.isFreeVersion) {
          bool canChat = userChatAvailableInfo['canChat'];
          if (!canChat) {
            await finishChat();
            return;
          }
        }
        if (useAIModel.startsWith('Mini') ||
            useAIModel.startsWith('微软') ||
            useAIModel.startsWith('讯飞') ||
            useAIModel.startsWith('通义') ||
            useAIModel.startsWith('月') ||
            useAIModel.contains('免费对话') ||
            useAIModel.contains('R1') ||
            (useAIModel.contains('逆向') && !useAIModel.contains('满血'))) {
          Map settings = await Config.loadSettings();
          String apiKey = settings['chatSettings_apiKey'] ?? settings['chat_api_key'] ?? '';
          String urlPrefix = settings['chatSettings_apiUrl'] ?? '';
          String setsUrlPrefix = settings['chatSettings_apiUrl'] ?? '';
          String baseUrl = '${urlPrefix.isEmpty ? setsUrlPrefix.isEmpty ? '' : setsUrlPrefix : urlPrefix}/v1/chat/completions';
          List<Map<String, dynamic>>? thisMessages = [];
          for (int j = 0; j < currentMessagesNew.length - 1; j++) {
            if (currentMessagesNew[j].content is ChatCompletionMessageContentParts) {
              var thisMessage = currentMessagesNew[j].toJson();
              var thisMessageContent = (currentMessagesNew[j].content as ChatCompletionMessageContentParts).toJson();
              thisMessages.add({"role": thisMessage['role'], "content": thisMessageContent['value'][0]['text']});
            } else {
              thisMessages.add(currentMessagesNew[j].toJson());
            }
          }
          var thisLastMessage = (currentMessagesNew[currentMessagesNew.length - 1].content as ChatCompletionMessageContentParts).toJson();
          if (thisLastMessage['value'] != null && thisLastMessage['value'] is List) {
            if (thisLastMessage['value'].length == 1) {
              thisMessages.add({"role": "user", "content": thisLastMessage['value'][0]['text']});
            } else if (thisLastMessage['value'].length >= 1) {
              thisMessages.add({"role": "user", "content": thisLastMessage['value']});
            }
          }
          bool useTools = false;
          bool isOModel = (realModelId.startsWith('o1') || realModelId.startsWith('o3')) && (!useAIModel.contains('all'));
          bool isR1Model = realModelId.contains('reasoner');
          if (isR1Model) {
            if (thisMessages.length > 1) {
              if (thisMessages[0]['role']=='assistant') {
                thisMessages.removeAt(0);
              }
            }
          }
          Map<String, dynamic> params = {'model': realModelId, 'messages': thisMessages, 'stream': true};
          if (!isOModel || !isR1Model) {
            params['temperature'] = isOModel ? 0 : tem;
            params['top_p'] = isOModel ? 1 : tp;
          }
          if (realModelId != 'glm-4-flash') {
            params['presence_penalty'] = isOModel ? 0 : pp;
            params['frequency_penalty'] = isOModel ? 0 : fp;
          }

          if (enableNet) {
            if (useAIModel.startsWith('通义')) {
              params['extra_body'] = {"enable_search": true};
            }
          }
          Map<String, String> headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'};
          await postChatData(
            url: baseUrl,
            requestBody: params,
            headers: headers,
            useTools: useTools,
            map: userChatAvailableInfo,
            currentTokens: currentChatTokens,
            isSeniorChat: isSeniorChat,
            canUsedCommonChatNum: canUsedCommonChatNum,
            canUsedSeniorChatNum: canUsedSeniorDrawNum,
          );
        } else {
          bool isOModel = realModelId.contains('o1-pre') && (!useAIModel.contains('all'));
          bool notSupportMoreParams = realModelId.contains('R1') || realModelId == 'o1';
          var request = CreateChatCompletionRequest(
              model: ChatCompletionModel.modelId(realModelId),
              messages: currentMessagesNew,
              stream: isOModel ? false : true,
              temperature: isOModel ? 1 : tem,
              presencePenalty: isOModel ? 0 : pp,
              frequencyPenalty: isOModel ? 0 : fp,
              topP: isOModel ? 1 : tp);
          if (notSupportMoreParams) {
            if (currentMessagesNew.length > 1) {
              currentMessagesNew.removeAt(0);
            }
            request = CreateChatCompletionRequest(
                model: ChatCompletionModel.modelId(realModelId),
                messages: currentMessagesNew,
                stream: true,
                temperature: null,
                presencePenalty: null,
                frequencyPenalty: null,
                topP: null);
          }
          bool isSupportStream = isSupportChatStream(useAIModel);
          if (isSupportStream) {
            final chatStreamNew = OpenAIClientSingleton.instance.client.createChatCompletionStream(request: request);
            _chatStreamSubscription = chatStreamNew.listen(
              (streamChatCompletion) {
                final content = streamChatCompletion.choices.first.delta.content;
                if (content != '' && content != null) {
                  _addMessageToChat(content);
                }
              },
              onDone: () async {
                updateUserPackagesInfo(userChatAvailableInfo, currentChatTokens, isSeniorChat, canUsedSeniorChatNum, canUsedCommonChatNum);
                await finishChat();
              },
              onError: (error) async {
                commonPrint("请求异常: $error");
                if (error is OpenAIClientException) {
                  await handleOpenAIChatError(error);
                }
                await finishChat();
              },
              cancelOnError: true,
            );
          } else {
            try {
              final chatResponse = await OpenAIClientSingleton.instance.client.createChatCompletion(request: request);
              _addMessageToChat(chatResponse.choices.first.message.content ?? '', isFinal: true);
              await finishChat();
            } on OpenAIClientException catch (error) {
              commonPrint("请求异常：$error");
              await handleOpenAIChatError(error);
              await finishChat();
            }
          }
        }
      }
    } else {
      if (!GlobalParams.isAdminVersion && !GlobalParams.isFreeVersion) {
        if (canUsedSeniorDrawNum > 0) {
          //这里执行创建mj任务的操作
          generateImageByMj(text, canDrawNum: canUsedSeniorDrawNum);
        } else {
          setState(() {
            messages.last.text = '您没有绘画次数';
          });
        }
      } else {
        generateImageByMj(text);
      }
    }
  }

  Future<void> handleOpenAIChatError(OpenAIClientException error) async {
    if (error.body is TimeoutException) {
      if ((error.body! as TimeoutException).message!.contains('请求超时')) {
        _addMessageToChat("请求异常：请求超过100秒，请尝试更换模型，或者与管理员联系。", isFinal: true);
      }
    } else if (error.body is String) {
      try {
        Map<String, dynamic>? errorMap = jsonDecode(error.body! as String);
        if (errorMap != null) {
          if (errorMap['error'] != null) {
            String? errorMessage = errorMap['error']['message'];
            if (errorMessage != null) {
              int index = errorMessage.indexOf("(request id:");
              String result = errorMessage;
              if (index != -1) {
                result = errorMessage.substring(0, index).trim();
              }
              dio.Options myOptions = dio.Options(headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer wqjuser'});
              var response = await myApi.myTranslate({"text": result, "source_lang": "EN", "target_lang": "ZH"}, myOptions);
              if (response.statusCode == 200) {
                _addMessageToChat("请求异常：${response.data['data']} 请尝试更换模型，或者与管理员联系。", isFinal: true);
              } else {
                _addMessageToChat("请求异常：$result 请尝试更换模型，或者与管理员联系。", isFinal: true);
              }
            }
          }
        }
      } catch (e) {
        String result = error.message;
        dio.Options myOptions = dio.Options(headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer wqjuser'});
        var response = await myApi.myTranslate({"text": result, "source_lang": "EN", "target_lang": "ZH"}, myOptions);
        if (response.statusCode == 200) {
          _addMessageToChat("请求异常: ${response.data['data']}，请尝试更换模型，或者与管理员联系。", isFinal: true);
        } else {
          _addMessageToChat("请求异常: $result，请尝试更换模型，或者与管理员联系。", isFinal: true);
        }
      }
    } else {
      String result = error.message;
      dio.Options myOptions = dio.Options(headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer wqjuser'});
      var response = await myApi.myTranslate({"text": result, "source_lang": "EN", "target_lang": "ZH"}, myOptions);
      if (response.statusCode == 200) {
        _addMessageToChat("请求异常: ${response.data['data']}，请尝试更换模型，或者与管理员联系。", isFinal: true);
      } else {
        _addMessageToChat("请求异常: $result，请尝试更换模型，或者与管理员联系。", isFinal: true);
      }
    }
  }

  Future<void> updateUserPackagesInfo(
      Map<String, dynamic> map, int currentTokens, int isSeniorChat, int canUsedSeniorChatNum, int canUsedCommonChatNum) async {
    if (!GlobalParams.isFreeVersion) {
      var settings = await Config.loadSettings();
      bool canUseTokens = map['canUseTokens'] ?? false;
      int canUsedTokens = box.read('tokens') ?? 0;
      if (canUseTokens) {
        canUsedTokens = canUsedTokens - currentTokens;
        box.write('tokens', canUsedTokens);
      }
      String userId = settings['user_id'] ?? '';
      int magnification = modelMagnification(useAIModel);
      int amount = canUseTokens ? canUsedTokens : 1 * magnification;
      final response = await SupabaseHelper().runRPC('consume_user_quota', {
        'p_user_id': userId,
        'p_quota_type': canUseTokens
            ? 'token'
            : isSeniorChat == 1
                ? 'premium_chat'
                : 'basic_chat',
        'p_amount': amount
      });
      if (response['code'] == 200) {
        box.write(isSeniorChat == 1 ? 'seniorChatNum' : 'commonChatNum', response['data']['remaining_subscription_quota']);
      } else {
        commonPrint('更新失败, ${response['message']}');
      }
    }
  }

  Future<Map<String, dynamic>> checkChatAvailability(int isSeniorChat, int canUsedSeniorChatNum, int canUsedCommonChatNum, int canUsedTokens,
      int currentTokens, bool canUseChatNum, bool canUseTokens) async {
    // 检查是否是高级模型
    int availableChats = isSeniorChat == 1 ? canUsedSeniorChatNum : canUsedCommonChatNum;
    // 检查次数和token
    if (!GlobalParams.isAdminVersion && !GlobalParams.isFreeVersion) {
      if (availableChats <= 0 && canUsedTokens <= currentTokens) {
        if (mounted) {
          setState(() {
            isAnswering = false;
          });
          String sendTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
          await onMessageDelete(messages.length - 1,
              needChangeValue: false,
              message: ChatMessage(text: '抱歉，您的对话额度不足，请[购买套餐](page:/buy)后再试。', isSentByMe: false, model: '魔镜AI', sendTime: sendTime));
        }
        Map<String, dynamic> map = {'canChat': false};
        return map;
      }
    }
    // 设置可用状态
    canUseChatNum = availableChats > 0;
    canUseTokens = canUsedTokens > currentTokens;
    Map<String, dynamic> map = {'canChat': true, 'canUseChatNum': canUseChatNum, 'canUseTokens': canUseTokens};
    return map;
  }

  Future<int> countCurrentChatTokens(List<ChatCompletionMessage> currentMessagesNew, String realModelId) async {
    int tokens = 0;
    for (var message in currentMessagesNew) {
      if (message.content is String) {
        Map<String, dynamic> params = {
          'model_name': realModelId,
          'prompt': message.content,
        };
        var response = await myApi.getMessageTokens(params);
        if (response.statusCode == 200) {
          tokens += response.data as int;
        }
      } else if (message.content is ChatCompletionMessageContentParts) {
        var thisMessageContent = (message.content as ChatCompletionMessageContentParts).toJson();
        String realContent = thisMessageContent['value'][0]['text'];
        Map<String, dynamic> params = {
          'model_name': realModelId,
          'prompt': realContent,
        };
        var response = await myApi.getMessageTokens(params);
        if (response.statusCode == 200) {
          tokens += response.data as int;
        }
      }
    }
    String responseText = messages.last.fullText != null ? messages.last.fullText! : messages.last.text;
    Map<String, dynamic> params = {
      'model_name': realModelId,
      'prompt': responseText,
    };
    var response = await myApi.getMessageTokens(params);
    if (response.statusCode == 200) {
      tokens += response.data as int;
    }
    return tokens;
  }

  Map<String, dynamic> putFilesIntoChat(
      List<ChatCompletionMessageContentPart> currentMessagesPartsNew, List<ChatCompletionMessage> currentMessagesNew) {
    String fileUrls = '';
    if (tempFiles.isNotEmpty) {
      for (var tempFile in tempFiles) {
        if (tempFile.file.name.startsWith('复制的内容')) {
          fileUrls += '${tempFile.content}\n';
        } else {
          String fileName = path.basename(tempFile.file.path!);
          String fileContent = tempFile.content ?? '';
          String fileUrl = tempFile.fileUrl;
          fileContent = processString(fileContent);
          String lowerFileContent = fileUrl.toLowerCase();
          if (lowerFileContent.endsWith('jpg') || lowerFileContent.endsWith('jpeg') || lowerFileContent.endsWith('png')) {
            if (useAIModel.contains('逆向') ||
                useAIModel.contains('4o') ||
                useAIModel.contains('Mini') ||
                useAIModel.contains('claude') ||
                useAIModel.contains('智谱AI免费') ||
                useAIModel.contains('带思考')) {
              final userMessageNew =
                  ChatCompletionMessageContentPart.image(imageUrl: ChatCompletionMessageImageUrl(url: fileUrl == '' ? fileContent : fileUrl));
              currentMessagesPartsNew.add(userMessageNew);
            } else {
              fileUrls += '文件$fileName的在线路径是$fileContent ';
            }
          } else {
            if (!useAIModel.contains('逆向')) {
              fileContent = 'The file name is $fileName \n Part of this file content is : \n $fileContent\n  ';
            } else {
              fileContent = '';
            }
            fileUrls += '文件$fileName的在线路径是 $fileUrl\n$fileContent\n';
          }
        }
      }
    }
    return {'currentMessagesPartsNew': currentMessagesPartsNew, 'fileUrls': fileUrls};
  }

  Future<void> finishChat() async {
    setState(() {
      isAnswering = false;
      urlContent = '';
      justCleanContext = false;
      hasFileUploaded = false;
      tempFiles.clear();
      _chatListNotifier.value[_selectedIndex].messagesCount = messages.length - 1;
      userChatAvailableInfo = {};
      currentChatTokens = 0;
      canUseTokens = false;
      canUseChatNum = false;
      isSeniorChat = 0;
      canUsedTokens = 0;
      canUsedSeniorChatNum = 0;
      canUsedCommonChatNum = 0;
      canUsedSeniorDrawNum = 0;
    });
    if (autoGenerateTitle) {
      await changeChatTitle();
    }
    tempInt = 0;
    var settings = await Config.loadSettings();
    String userId = settings['user_id'] ?? '';
    SupabaseHelper().update('chat_list', {'messagesCount': messages.length - 1}, updateMatchInfo: {'user_id': userId, 'createTime': createTime});
    String messagesJson = jsonEncode([messages.last.toJson()]);
    if (_useEncrypt && _encryptKey != '') {
      messages.last.isEncrypted = true;
    }
    String chatSettingsStr = jsonEncode(curChatSet);
    SupabaseHelper().insert('chat_contents', {
      'title': currentTitle,
      'createTime': createTime,
      'content': messagesJson,
      'useAIModel': useAIModel,
      'chatSettings': chatSettingsStr,
      'user_id': userId,
      'is_delete': 0,
      'key': const Uuid().v4(),
    });
  }

  // 这里是为了某些中转AI返回的结构体不标准进行的手动解析
  Future<void> postChatData({
    required String url,
    required Map<String, dynamic> requestBody,
    Map<String, String>? headers,
    bool useTools = false,
    required Map<String, dynamic> map,
    required int currentTokens,
    required int isSeniorChat,
    required int canUsedSeniorChatNum,
    required int canUsedCommonChatNum,
  }) async {
    bool isSupportStream = isSupportChatStream(useAIModel);
    if (isSupportStream) {
      await ChatRequest().handleStreamRequest(
          url: url,
          requestBody: requestBody,
          headers: headers ??
              {
                'Content-Type': 'application/json',
              },
          chatStreamSubscription: _chatStreamSubscription,
          onMessage: (String data) {
            _addMessageToChat(data);
          },
          onError: (error) async {
            await handelChatError(error);
          },
          onDone: () async {
            updateUserPackagesInfo(
              map,
              currentTokens,
              isSeniorChat,
              canUsedSeniorChatNum,
              canUsedCommonChatNum,
            );
            await finishChat();
          });
    } else {
      requestBody['stream'] = false;
      try {
        final response = await ChatRequest().handleRequest(
            url: url,
            requestBody: requestBody,
            headers: headers ??
                {
                  'Content-Type': 'application/json',
                });
        _addMessageToChat(response['choices'][0]['message']['content'], isFinal: true);
        updateUserPackagesInfo(
          map,
          currentTokens,
          isSeniorChat,
          canUsedSeniorChatNum,
          canUsedCommonChatNum,
        );
        await finishChat();
      } on ApiException catch (error) {
        // 处理错误
        commonPrint('Error: ${error.message}');
        await handelChatError(error);
      }
    }
  }

  Future<void> handelChatError(ApiException error) async {
    String errorMessage = error.message ?? '';
    int index = errorMessage.indexOf(' (request id');
    if (index != -1) {
      errorMessage = errorMessage.substring(0, index);
    }
    dio.Options myOptions = dio.Options(headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer wqjuser'});
    var response = await myApi.myTranslate({"text": errorMessage, "source_lang": "EN", "target_lang": "ZH"}, myOptions);
    if (response.statusCode == 200) {
      errorMessage = response.data['data'];
    }
    _addMessageToChat("请求异常: $errorMessage，请尝试更换模型，或者与管理员联系。", isFinal: true);
    await finishChat();
  }

  Future<void> generateImageByMj(String text, {int drawSpeedType = 1, int canDrawNum = 0}) async {
    Map<String, dynamic> requestBody = {};
    requestBody['prompt'] = text.replaceAll('画', '');
    dio.Response response;
    try {
      response = await myApi.selfMjDrawCreate(requestBody);
      if (response.statusCode == 200) {
        Map<String, dynamic> data;
        if (response.data is String) {
          data = jsonDecode(response.data);
        } else {
          data = response.data;
        }
        int code = data['code'] ?? -1;
        if (code == 1) {
          messages.removeLast();
          String sendTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
          messages.add(ChatMessage(text: 'MJ绘图任务提交成功', isSentByMe: false, model: useAIModel, sendTime: sendTime));
          setState(() {});
          String result = data['result'];
          int index = messages.length - 1;
          String idWithIndex = '${result}_$index';
          Map<String, dynamic> job = {idWithIndex: '${requestBody['prompt']}'};
          box.write('seniorDrawNum', canDrawNum - 1);
          createTaskQueue(job);
          setState(() {
            isAnswering = false;
          });
        } else {
          if (mounted) {
            messages.removeLast();
            String sendTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
            messages.add(ChatMessage(text: 'MJ绘图任务提交失败\n原因是${data['description']}', isSentByMe: false, model: useAIModel, sendTime: sendTime));
            setState(() {
              isAnswering = false;
            });
            commonPrint('自有mj绘图失败4,原因是${data['description']}');
          }
        }
      } else {
        if (mounted) {
          messages.removeLast();
          String sendTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
          messages.add(ChatMessage(text: 'MJ绘图任务提交失败\n原因是${response.statusMessage}', isSentByMe: false, model: useAIModel, sendTime: sendTime));
          setState(() {
            isAnswering = false;
          });
          commonPrint('自有mj绘图失败1,原因是${response.statusMessage}');
        }
      }
    } catch (e) {
      if (mounted) {
        messages.removeLast();
        String sendTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
        messages.add(ChatMessage(text: 'MJ绘图任务提交失败\n原因是$e', isSentByMe: false, model: useAIModel, sendTime: sendTime));
        setState(() {
          isAnswering = false;
        });
        commonPrint('自有mj绘图失败2,原因是$e');
      }
    }
  }

  Future<void> createTaskQueue(Map<String, dynamic> taskData) async {
    void executeTask(MapEntry<String, dynamic> task) async {
      currentTask = task;
      isExecuting = true;
      String id = currentTask!.key.split('_')[0];
      await _dealJobQueue(currentTask!.key, currentTask!.value);
      commonPrint('任务 $id 执行完成');
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

  Future<void> _dealJobQueue(String jobId, String prompt) async {
    int index = int.parse(jobId.split('_').last);
    String id = jobId.split('_').first;
    String hintStr = useAIModel.contains('MJ') ? 'MJ绘图' : '视频生成';
    try {
      while (true) {
        if (useAIModel.contains('MJ')) {
          dio.Response progressResponse = await myApi.selfMjDrawQuery(id);
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
              if (mounted) {
                messages[index].text = 'MJ绘图进行中，当前的绘制进度是${progressResponse.data['progress'] ?? "0%"}';
                setState(() {});
              }
              if (status == 'SUCCESS') {
                if (progressResponse.data['imageUrl'] != null && progressResponse.data['imageUrl'] != '') {
                  String imageUrl = progressResponse.data['imageUrl'];
                  String useImagePath = await imageUrlToBase64(imageUrl);
                  String filePath = '';
                  File file = await base64ToTempFile(useImagePath);
                  if (file.existsSync()) {
                    filePath = file.path;
                  }
                  if (filePath != '') {
                    imageUrl = await uploadFileToALiOss(filePath, imageUrl, file);
                  }
                  messages[index].text = 'MJ绘图完成\n\n ![$id](${GlobalParams.filesUrl + imageUrl}) \n\n';
                  setState(() {});
                  _scrollToBottom();
                  var settings = await Config.loadSettings();
                  String userId = settings['user_id'] ?? '';
                  final response =
                      await SupabaseHelper().runRPC('consume_user_quota', {'p_user_id': userId, 'p_quota_type': 'fast_drawing', 'p_amount': 1});
                  if (response['code'] == 200) {
                    commonPrint('消耗图片绘制额度成功');
                  } else {
                    commonPrint('消耗图片绘制额度失败,原因是${response['message']}');
                  }
                }
                break;
              }
            } else if (status != '') {
              if (mounted) {
                showHint('$hintStr失败,原因是${progressResponse.data['failReason']}', showType: 3);
                commonPrint('$hintStr失败0,原因是${progressResponse.data['failReason']}');
              }
              int canDrawNum = box.read('seniorDrawNum') ?? 0;
              box.write('seniorDrawNum', canDrawNum + 1);
              break;
            }
          } else {
            if (mounted) {
              showHint('$hintStr失败,原因是${progressResponse.statusMessage}', showType: 3);
              commonPrint('$hintStr失败1,原因是${progressResponse.statusMessage}');
            }
            int canDrawNum = box.read('seniorDrawNum') ?? 0;
            box.write('seniorDrawNum', canDrawNum + 1);
            break;
          }
        } else {
          var configs = await Config.loadSettings();
          dio.Response videoResponse = await myApi.zhipuGetVideo(
              id,
              dio.Options(headers: {
                'Authorization': 'Bearer ${configs['zpai_api_key'] ?? ''}',
              }));
          commonPrint(videoResponse);
          if (videoResponse.statusCode == 200) {
            if (videoResponse.data['task_status'] == 'PROCESSING' || videoResponse.data['task_status'] == 'SUCCESS') {
              if (videoResponse.data['task_status'] == 'SUCCESS') {
                var videoResult = videoResponse.data['video_result'];
                if (videoResult != null && videoResult[0]['url'] != null && videoResult[0]['url'] != '') {
                  String videoUrl = videoResult[0]['url'];
                  String coverImage = videoResult[0]['cover_image_url'];
                  String useImagePath = await imageUrlToBase64(coverImage);
                  String filePath = '';
                  File file = await base64ToTempFile(useImagePath);
                  if (file.existsSync()) {
                    filePath = file.path;
                  }
                  if (filePath != '') {
                    coverImage = await uploadFileToALiOss(filePath, coverImage, file);
                  }
                  messages[index].text = '视频生成完成\n\n !video[${GlobalParams.filesUrl + coverImage}]($videoUrl) \n\n';
                  setState(() {});
                  _scrollToBottom();
                }
                break;
              }
            } else {
              commonPrint(videoResponse.data);
            }
          } else {
            if (mounted) {
              showHint('$hintStr失败,原因是${videoResponse.statusMessage}', showType: 3);
              commonPrint('$hintStr失败2,原因是${videoResponse.statusMessage}');
            }
            break;
          }
        }
        dismissHint();
        await Future.delayed(const Duration(seconds: 5));
      }
    } catch (e) {
      if (mounted) {
        showHint('$hintStr失败，原因是$e', showType: 3);
        commonPrint('$hintStr失败，原因是$e');
      }
      if (useAIModel.contains('MJ')) {
        int canDrawNum = box.read('seniorDrawNum') ?? 0;
        box.write('seniorDrawNum', canDrawNum + 1);
      }
    } finally {
      isAnswering = false;
      // 将新的消息数组序列化为JSON字符串，更新数据库
      String messagesJson = jsonEncode([messages.last.toJson()]);
      String chatSettingsStr = jsonEncode(curChatSet);
      String userId = settings['user_id'] ?? '';
      SupabaseHelper().insert('chat_contents', {
        'title': currentTitle,
        'createTime': createTime,
        'content': messagesJson,
        'useAIModel': useAIModel,
        'chatSettings': chatSettingsStr,
        'user_id': userId,
        'is_delete': 0,
        'key': const Uuid().v4(),
      });
    }
  }

  Future<void> generateVideoByZhipu(String text, String realModelId) async {
    try {
      var config = await Config.loadSettings();
      Map<String, dynamic> requestBody = {
        'model': realModelId,
        'prompt': text,
        'with_audio': aiSound,
        'size': videoImagePath == '' || videoSize == '不指定' ? null : videoSize,
        'image_url': videoImagePath == '' ? null : videoImagePath,
        'duration': int.parse(videoDuration),
        'fps': int.parse(videoFPS)
      };
      commonPrint(requestBody);
      dio.Response response =
          await myApi.zhipuGenerateVideo(requestBody, dio.Options(headers: {'Authorization': 'Bearer ${config['zpai_api_key']}'}));
      if (response.statusCode == 200) {
        if (response.data is String) {
          response.data = jsonDecode(response.data);
        }
        setState(() {
          isAnswering = false;
          allUploadedFiles.clear();
          tempFiles.clear();
        });
        //先把数据库里面的最后一条数据删除了，然后将最后一条消息改为生成中
        String sendTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
        ChatMessage message = ChatMessage(text: '视频生成任务提交成功, 请耐心等待结果', isSentByMe: false, model: useAIModel, sendTime: sendTime);
        await onMessageDelete(messages.length - 1, needChangeValue: false, message: message);
        String result = response.data['id'];
        int index = messages.length - 1;
        String idWithIndex = '${result}_$index';
        Map<String, dynamic> job = {idWithIndex: '${requestBody['prompt']}'};
        createTaskQueue(job);
      } else {
        commonPrint('创建视频生成任务失败，原因是${response.data}');
      }
    } catch (e) {
      commonPrint('创建视频生成任务失败，原因是$e');
    }
  }

  //上传文件并获取文件内容，如果是图片文件的话，同时模型支持视图，那么返回的是图片地址，模型不支持识图则返回ocr的内容
  //文件上传服务参考 https://github.com/Deeptrain-Community/chatnio-blob-service
  //已实现 文件服务地址是 https://file.zxai.fun 这里需要将文件放在body里面传递给接口，等待接口返回文件内容

  Future<void> uploadFileAndGetContent() async {
    FilePickerResult? result = await FilePickerManager()
        .pickFiles(type: FileType.custom, allowedExtensions: ['txt', 'jpg', 'png', 'jpeg', 'mp3', 'wav', 'docx', 'pdf', 'pptx', 'xlsx']);
    if (result != null) {
      String filePath = result.files.single.path ?? '';
      if (filePath != '') {
        fileName = result.files.single.name.toLowerCase();
        showHint('文件上传中...', showType: 5);
        dio.FormData formData = dio.FormData.fromMap({"file": await dio.MultipartFile.fromFile(filePath, filename: fileName)});
        try {
          dio.Response uploadResponse = await myApi.uploadFile(formData);
          if (uploadResponse.statusCode == 200) {
            if (uploadResponse.data['status']) {
              fileContent = removeExtraSpaces(uploadResponse.data['content']);
              if (mounted) {
                showHint('文件上传成功', showType: 2);
              }
            } else {
              showHint('文件上传失败，原因是${uploadResponse.data}', showType: 3);
            }
          } else {
            showHint('文件上传失败，原因是${uploadResponse.data}', showType: 3);
          }
        } catch (e) {
          showHint('文件上传失败，原因是$e', showType: 3);
        } finally {
          dismissHint();
        }
      } else {}
    } else {}
  }

  bool isMoonshotSupportedFileType(String filePath) {
    List<String> validExtensions = [
      '.pdf',
      '.txt',
      '.csv',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
      '.md',
      '.jpeg',
      '.png',
      '.bmp',
      '.gif',
      '.svg',
      '.svgz',
      '.webp',
      '.ico',
      '.xbm',
      '.dib',
      '.pjp',
      '.tif',
      '.pjpeg',
      '.avif',
      '.dot',
      '.apng',
      '.epub',
      '.tiff',
      '.jfif',
      '.html',
      '.json',
      '.mobi',
      '.log',
      '.go',
      '.h',
      '.c',
      '.cpp',
      '.cxx',
      '.cc',
      '.cs',
      '.java',
      '.js',
      '.css',
      '.jsp',
      '.php',
      '.py',
      '.py3',
      '.asp',
      '.yaml',
      '.yml',
      '.ini',
      '.conf',
      '.ts',
      '.tsx'
    ];

    String fileExtension = filePath.toLowerCase();

    // 检查文件是否以任何有效的扩展名结尾
    for (String extension in validExtensions) {
      if (fileExtension.endsWith(extension)) {
        return true;
      }
    }
    return false;
  }

  Future<void> uploadMultipleFiles({bool isCapture = false}) async {
    List<UploadingFile> uploadingFiles = [];
    bool allowMultiple = true;
    List<String>? allowExtensions;
    if (useAIModel.contains('视频')) {
      allowMultiple = false;
      allowExtensions = ['.jpg', '.png', '.jpeg'];
      if (tempFiles.isNotEmpty) {
        showHint('生成视频仅支持一个图片,如需更改请删除之前的');
      }
    }
    FilePickerResult? result =
        await FilePickerManager().pickFiles(allowMultiple: allowMultiple, type: FileType.any, allowedExtensions: allowExtensions);
    if (result != null) {
      setState(() {
        hasFileUploaded = false;
        for (var i = 0; i < result.files.length; i++) {
          uploadingFiles.add(UploadingFile(
            key: getCurrentTimestamp() + const Uuid().v4(),
            // 创建唯一的key
            file: result.files[i],
            cancelToken: dio.CancelToken(),
            isPrivate: _useEncrypt,
            encryptKey: _encryptKey,
          ));
        }
        allUploadedFiles.addAll(uploadingFiles);
      });
      for (var i = 0; i < uploadingFiles.length; i++) {
        await uploadSingleFile(uploadingFiles[i], uploadingFiles[i].key);
      }
      setState(() {
        hasFileUploaded = checkUploadFileStatus();
        tempFiles = List.from(allUploadedFiles);
      });
    }
  }

  Future<String> uploadSingleFile(UploadingFile uploadingFile, String index,
      {bool needDelete = false, bool needOss = true, bool isVideoImage = false}) async {
    String filePath = uploadingFile.file.path!;
    String fileName = uploadingFile.file.name.toLowerCase();
    String fileNameWithoutExtension = fileName.split('.').first;
    String fileUrl = '';
    try {
      File thisFile = File(filePath);
      String fileType = filePath.split('.').last;
      if (needOss) {
        fileUrl = GlobalParams.filesUrl +
            await uploadFileToALiOss(filePath, '', thisFile, fileType: fileType, needDelete: false, setFileName: fileNameWithoutExtension);
        if (isVideoImage) {
          videoImagePath = fileUrl;
        }
      }
      dio.FormData formData = dio.FormData.fromMap({"file": await dio.MultipartFile.fromFile(filePath, filename: fileName)});
      setState(() {
        uploadingFile.fileUrl = fileUrl;
        if (useAIModel.contains('逆向')) {
          uploadingFile.isUploaded = true;
        }
      });
      if (fileName.endsWith('jpg') || fileName.endsWith('png') || fileName.endsWith('jpeg')) {
        dio.Response uploadResponse =
            await myApi.uploadFile(formData, cancelToken: uploadingFile.cancelToken, options: dio.Options(sendTimeout: const Duration(seconds: 120)));
        if (uploadResponse.statusCode == 200 && uploadResponse.data['status']) {
          String fileContent = removeExtraSpaces(uploadResponse.data['content']);
          setState(() {
            uploadingFile.isUploaded = true;
            uploadingFile.content = fileContent;
          });
          if (needDelete) {
            String filePath = uploadingFile.file.path ?? '';
            if (filePath.isNotEmpty) {
              File file = File(filePath);
              if (file.existsSync()) {
                try {
                  file.deleteSync(); // 同步删除文件
                } catch (e) {
                  commonPrint('文件上传后删除文件时出错：$e');
                }
              }
            }
          }
        } else {
          commonPrint('文件 $fileName 上传失败');
          setState(() {
            for (var file in allUploadedFiles) {
              if (file.key == index) {
                file.uploadFailed = true;
              }
            }
          });
        }
      } else if (isMoonshotSupportedFileType(filePath)) {
        var settings = await Config.loadSettings();
        String moonshotApiKey = settings['moonshot_api_key'] ?? '';
        dio.Response uploadResponse = await myApi.uploadFileToMoonshot(formData, 'https://api.moonshot.cn/v1/files',
            options: dio.Options(headers: {'Authorization': 'Bearer $moonshotApiKey'}), cancelToken: uploadingFile.cancelToken);
        if (uploadResponse.statusCode == 200) {
          setState(() {
            uploadingFile.isUploaded = true;
          });
          commonPrint('文件 $fileName 上传成功');
          String fileId = uploadResponse.data['id'];
          dio.Response fileContentResponse = await myApi.getFileContentFromMoonshot('https://api.moonshot.cn/v1/files/$fileId/content',
              options: dio.Options(headers: {'Authorization': 'Bearer $moonshotApiKey'}), cancelToken: uploadingFile.cancelToken);
          if (fileContentResponse.statusCode == 200) {
            String fileContent = removeExtraSpaces(fileContentResponse.data['content']);
            setState(() {
              uploadingFile.content = fileContent;
            });
          }
        } else {
          commonPrint('文件 $fileName 上传失败');
          setState(() {
            for (var file in allUploadedFiles) {
              if (file.key == index) {
                file.uploadFailed = true;
              }
            }
          });
        }
      } else {
        if (!useAIModel.contains('逆向')) {
          //不是逆向模型，尝试以文本形式阅读文件内容
          File file = File(filePath);
          String contents = await file.readAsString();
          setState(() {
            uploadingFile.isUploaded = true;
            uploadingFile.content = contents;
          });
        }
      }
    } catch (e) {
      commonPrint('文件 $fileName 上传失败: $e');
      setState(() {
        for (var file in allUploadedFiles) {
          if (file.key == index) {
            file.uploadFailed = true;
          }
        }
      });
    }
    setState(() {
      tempFiles = List.from(allUploadedFiles);
    });
    return fileUrl;
  }

  void updateFileStatus(String index, bool isUploaded) {
    setState(() {
      for (var file in allUploadedFiles) {
        if (file.key == index) {
          file.uploadFailed = isUploaded;
        }
      }
    });
  }

  //读取单个聊天的内容
  Future<List<ChatMessage>> _readChatContentHistory(String createTime) async {
    showHint('正在读取聊天内容...', showType: 5);
    try {
      settings = await Config.loadSettings();
      String userId = settings['user_id'] ?? '';
      List<Map<String, Object?>> maps =
          await SupabaseHelper().query('chat_contents', {'is_delete': 0, 'createTime': createTime, 'user_id': userId}, isOrdered: true);
      var chats = List<ChatMessage>.from([]);
      if (maps.isNotEmpty) {
        for (int i = 0; i < maps.length; i++) {
          final content = maps[i]['content'];
          if (content is String) {
            final List<dynamic> messagesJson = jsonDecode(content);
            chats.addAll(List<ChatMessage>.from(messagesJson.map((messageJson) => ChatMessage.fromJson(messageJson))));
          } else {
            throw Exception('Content is not a string or is null');
          }
        }
        currentTitle = '${maps.last['title']}';
        final getChatSettings = maps.last['chatSettings'];
        if (getChatSettings is String) {
          Map<String, dynamic> curChatSettings = jsonDecode(getChatSettings);
          curChatSet = curChatSettings;
          _getChatSettings(inputSettings: curChatSettings);
        }
      }
      return chats;
    } catch (e) {
      commonPrint('读取聊天内容异常，错误是$e');
      dismissHint();
      return [];
    } finally {
      dismissHint();
    }
  }

  Future<void> initDatabase() async {
    settings = await Config.loadSettings();
    isLogin = settings['is_login'] ?? false;
    if (isLogin) {
      await _readChatListHistory();
    }
  }

  Future<void> onCopyMessage(int index) async {
    String currentModel = messages[index].model;
    if (currentModel.contains('R1') || currentModel.contains('r1')) {
      String fullText = messages[index].fullText != null ? messages[index].fullText! : messages[index].text;
      List<String> lines = fullText.split('\n');

      // 分离思考内容和正文内容
      List<String> thoughtLines = [];
      List<String> contentLines = [];

      for (String line in lines) {
        if (line.trimLeft().startsWith('>')) {
          // 移除开头的 '>' 并添加到思考内容
          thoughtLines.add(line.replaceFirst(RegExp(r'^\s*>\s*'), ''));
        } else {
          contentLines.add(line);
        }
      }

      // 显示弹窗询问是否包含思考内容
      bool? includeToughts = await showDialog<bool>(
        context: context,
        barrierDismissible: true, // 允许点击外部关闭
        builder: (BuildContext context) {
          return CustomDialog(
            title: '复制选项',
            isConformClose: false,
            isCancelClose: false,
            titleColor: context.read<ChangeSettings>().getForegroundColor(),
            contentBackgroundColor: context.read<ChangeSettings>().getBackgroundColor(),
            description: '是否包含思考过程？',
            descColor: context.read<ChangeSettings>().getForegroundColor(),
            cancelButtonText: '仅复制正文',
            confirmButtonText: '包含思考',
            conformButtonColor: context.read<ChangeSettings>().getSelectedBgColor(),
            cancelButtonColor: context.read<ChangeSettings>().getSelectedBgColor(),
            onCancel: () => Navigator.of(context).pop(false),
            onConfirm: () => Navigator.of(context).pop(true),
          );
        },
      );

      // 如果用户关闭对话框或点击外部，includeToughts 将为 null
      if (includeToughts != null) {
        String messageText = '';
        if (includeToughts && thoughtLines.isNotEmpty) {
          String thoughts = thoughtLines.join('\n').trim();
          String content = contentLines.join('\n').trimLeft();
          messageText = '🤔 思考过程:\n$thoughts\n✨ 思考结束\n\n💡 回答:\n\n$content';
        } else {
          messageText = contentLines.join('\n').trim();
        }

        // 去除开头的多余换行
        messageText = messageText.replaceFirst(RegExp(r'^\s*\n+'), '');

        await Clipboard.setData(ClipboardData(text: messageText));
        showHint('内容已复制到剪切板', showType: 2, showTime: 500);
      }
    } else {
      String messageText = messages[index].fullText != null ? messages[index].fullText! : messages[index].text;
      await Clipboard.setData(ClipboardData(text: messageText));
      showHint('内容已复制到剪切板', showType: 2, showTime: 500);
    }
  }

  Future<void> getSettingsData({needRefreshModel = false}) async {
    myApi = MyApi();
    settings = await Config.loadSettings();
    listenStorage();
    if (needRefreshModel) {
      useAIModel = settings['chatSettings_defaultModel'] ?? '自动选择';
      enableNet = settings['chatSettings_enableNet'] ?? false;
      enableChatContext = settings['chatSettings_enableChatContext'] ?? true;
      alwaysShowModelName = settings['chatSettings_alwaysShowModelName'] ?? false;
    }
  }

  @override
  void initState() {
    super.initState();
    _searchMatchedCreateTimes = {};
    getSettingsData(needRefreshModel: true);
    initDatabase();
    chatService = ChatService();
    chatService.messageStream.listen((message) {
      if (message.isSentByMe == false) {
        setState(() {
          messages.add(message);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    chatService.dispose();
    _searchDebounce?.cancel();
    disposeMessages();
    super.dispose();
  }

  void deleteItem(List<ChatListData> value, int index, BuildContext context, ChangeSettings settings) {
    String temCreateTime = value[index].createTime;
    var temCreateId = value[index].id;
    var temTitle = value[index].title;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomDialog(
            title: '删除确认',
            titleColor: settings.getForegroundColor(),
            contentBackgroundColor: settings.getBackgroundColor(),
            description: '是否删除-$temTitle-会话？',
            descColor: settings.getForegroundColor(),
            cancelButtonText: '取消',
            confirmButtonText: '确定',
            conformButtonColor: settings.getSelectedBgColor(),
            onCancel: () {},
            onConfirm: () async {
              setState(() {
                value.removeAt(index);
                _chatListNotifier.value = List.from(value); // 更新ValueNotifier
                if (temCreateTime == createTime) {
                  if (_chatListNotifier.value.length == 1) {
                    _selectedIndex = 0;
                  } else {
                    if (_chatListNotifier.value.isNotEmpty) {
                      if (_selectedIndex == _chatListNotifier.value.length) {
                        _selectedIndex = _selectedIndex - 1;
                      }
                    }
                  }
                }
                if (value.isEmpty) {
                  _addNewChat('新的聊天');
                }
              });
              if (temCreateTime == createTime) {
                if (_chatListNotifier.value.isNotEmpty) {
                  createTime = _chatListNotifier.value[_selectedIndex].createTime;
                  messages.clear();
                  tempFiles.clear();
                  var chats = await _readChatContentHistory(createTime);
                  setState(() {
                    chatMessagesStartIndex = 0;
                    messages = chats;
                    _keys.clear();
                    for (int i = 0; i < messages.length; i++) {
                      _keys.add(GlobalKey());
                    }
                    _scrollToBottom(isReadHistory: true);
                  });
                } else {
                  messages.clear();
                }
              }
              await _deleteChat(temCreateId, temCreateTime);
            },
          );
        });
  }

  void disposeMessages() {
    for (var message in messages) {
      message.dispose();
    }
    messages.clear();
  }

  //读取内存的键值对
  void listenStorage() async {
    var settings = await Config.loadSettings();
    String userId = settings['user_id'] ?? '';
    box.listenKey('chatSettings_defaultModel', (value) async {
      if (value.contains('实时')) {
        Navigator.pop(context);
        return;
      }
      if (value.contains('绘画')) {
        showHint('您在对话界面选择绘画模型，强烈建议进入AI绘画界面进行绘画', showTime: 1000);
      }
      setState(() {
        useAIModel = value;
        enableChatContext = isSupportChatContext(useAIModel);
        _chatListNotifier.value[_selectedIndex].modelName = value;
        if (useAIModel.contains('联网') && enableNet) {
          enableNet = false;
          showHint('此模型自带联网功能，已关闭系统联网功能', showTime: 500, showType: 2);
        }
      });
      curChatSet['chatSettings_defaultModel'] = value;
      curChatSet['chatSettings_enableNet'] = enableNet;
      String curChatSetStr = jsonEncode(curChatSet);
      await SupabaseHelper().update('chat_contents', {'chatSettings': curChatSetStr}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
      await SupabaseHelper().update('chat_list', {'modelName': value}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
    });
    box.listenKey('chatSettings_autoGenerateTitle', (value) async {
      autoGenerateTitle = value;
      curChatSet['chatSettings_autoGenerateTitle'] = value;
      setState(() {});
      String curChatSetStr = jsonEncode(curChatSet);
      await SupabaseHelper().update('chat_contents', {'chatSettings': curChatSetStr}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
    });
    //视频生成参数开始
    box.listenKey('chatSettings_defaultVideoSize', (value) async {
      videoSize = value;
      curChatSet['chatSettings_defaultVideoSize'] = value;
      setState(() {});
      String curChatSetStr = jsonEncode(curChatSet);
      await SupabaseHelper().update('chat_contents', {'chatSettings': curChatSetStr}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
    });
    box.listenKey('chatSettings_defaultVideoDuration', (value) async {
      videoDuration = value;
      curChatSet['chatSettings_defaultVideoDuration'] = value;
      setState(() {});
      String curChatSetStr = jsonEncode(curChatSet);
      await SupabaseHelper().update('chat_contents', {'chatSettings': curChatSetStr}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
    });
    box.listenKey('chatSettings_defaultVideoFPS', (value) async {
      videoFPS = value;
      curChatSet['chatSettings_defaultVideoFPS'] = value;
      setState(() {});
      String curChatSetStr = jsonEncode(curChatSet);
      await SupabaseHelper().update('chat_contents', {'chatSettings': curChatSetStr}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
    });
    box.listenKey('chatSettings_isAiSound', (value) async {
      aiSound = value;
      curChatSet['chatSettings_defaultVideoSize'] = value;
      setState(() {});
      String curChatSetStr = jsonEncode(curChatSet);
      await SupabaseHelper().update('chat_contents', {'chatSettings': curChatSetStr}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
    });
    box.listenKey('chatSettings_videoImagePath', (value) async {
      videoImagePath = value;
      if (value.isNotEmpty) {
        setState(() {
          allUploadedFiles.clear();
          tempFiles.clear();
        });
        var captureImage = PlatformFile(name: path.basename(value), size: 0, path: value);
        var captureImageFile = UploadingFile(
            key: GlobalKey().toString(),
            file: captureImage,
            content: pastedContent,
            isPrivate: _useEncrypt,
            encryptKey: _encryptKey,
            isUploaded: false);
        setState(() {
          hasFileUploaded = false;
          allUploadedFiles.add(captureImageFile);
        });
        await uploadSingleFile(captureImageFile, captureImageFile.key, needDelete: false, isVideoImage: true);
        setState(() {
          hasFileUploaded = checkUploadFileStatus();
        });
      } else {
        setState(() {
          allUploadedFiles.clear();
          tempFiles.clear();
        });
      }
      curChatSet['chatSettings_videoImagePath'] = value;
      setState(() {});
      String curChatSetStr = jsonEncode(curChatSet);
      await SupabaseHelper().update('chat_contents', {'chatSettings': curChatSetStr}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
    });
    //视频生成参数结束
    box.listenKey('chatSettings_enableChatContext', (value) async {
      enableChatContext = value;
      curChatSet['chatSettings_enableChatContext'] = value;
      setState(() {});
      String curChatSetStr = jsonEncode(curChatSet);
      await SupabaseHelper().update('chat_contents', {'chatSettings': curChatSetStr}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
    });
    box.listenKey('chatSettings_defaultImageSize', (value) async {
      useImageSize = value;
      curChatSet['chatSettings_defaultImageSize'] = value;
      setState(() {});
      String curChatSetStr = jsonEncode(curChatSet);
      await SupabaseHelper().update('chat_contents', {'chatSettings': curChatSetStr}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
    });
    box.listenKey('chatSettings_enableNet', (value) async {
      if (!useAIModel.contains('联网')) {
        enableNet = value;
        curChatSet['chatSettings_enableNet'] = value;
        setState(() {});
        String curChatSetStr = jsonEncode(curChatSet);
        await SupabaseHelper()
            .update('chat_contents', {'chatSettings': curChatSetStr}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
      }
    });
    box.listenKey('chatSettings_alwaysShowModelName', (value) async {
      alwaysShowModelName = value;
      curChatSet['chatSettings_alwaysShowModelName'] = value;
      setState(() {});
      String curChatSetStr = jsonEncode(curChatSet);
      await SupabaseHelper().update('chat_contents', {'chatSettings': curChatSetStr}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
    });
    box.listenKey('chatSettings_captureCloseWindow', (value) async {
      _closeWindowWhenCapturing = value;
      curChatSet['chatSettings_captureCloseWindow'] = value;
      setState(() {});
      String curChatSetStr = jsonEncode(curChatSet);
      await SupabaseHelper().update('chat_contents', {'chatSettings': curChatSetStr}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
    });
    box.listenKey('chatSettings_maxTokens', (value) async {
      maxTokens = int.parse(value);
      curChatSet['chatSettings_maxTokens'] = value;
      setState(() {});
      String curChatSetStr = jsonEncode(curChatSet);
      await SupabaseHelper().update('chat_contents', {'chatSettings': curChatSetStr}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
    });
    box.listenKey('chatSettings_tem', (value) async {
      tem = value;
      curChatSet['chatSettings_tem'] = value;
      setState(() {});
      String curChatSetStr = jsonEncode(curChatSet);
      await SupabaseHelper().update('chat_contents', {'chatSettings': curChatSetStr}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
    });
    box.listenKey('chatSettings_top_p', (value) async {
      tp = value;
      curChatSet['chatSettings_top_p'] = value;
      setState(() {});
      String curChatSetStr = jsonEncode(curChatSet);
      await SupabaseHelper().update('chat_contents', {'chatSettings': curChatSetStr}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
    });
    box.listenKey('chatSettings_fp', (value) async {
      fp = value;
      curChatSet['chatSettings_fp'] = value;
      setState(() {});
      String curChatSetStr = jsonEncode(curChatSet);
      await SupabaseHelper().update('chat_contents', {'chatSettings': curChatSetStr}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
    });
    box.listenKey('chatSettings_pp', (value) async {
      pp = value;
      curChatSet['chatSettings_pp'] = value;
      setState(() {});
      String curChatSetStr = jsonEncode(curChatSet);
      await SupabaseHelper().update('chat_contents', {'chatSettings': curChatSetStr}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
    });
    box.listenKey('chatSettings_apiUrl', (value) async {
      //对话接口地址发生更改
      OpenAIClientSingleton.instance.updateBaseUrl(value);
    });
    box.listenKey('chatSettings_apiKey', (value) async {
      //对话接口key发生更改
      OpenAIClientSingleton.instance.updateApiKey(value);
    });
    box.listenKey('chatSettings_defaultLanguage', (value) async {
      //指定回复语言发生更改
      curChatSet['chatSettings_defaultLanguage'] = value;
      setState(() {
        defaultAIResponseLanguage = value;
      });
      String curChatSetStr = jsonEncode(curChatSet);
      await SupabaseHelper().update('chat_contents', {'chatSettings': curChatSetStr}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
    });
    box.listenKey('chatSettings_defaultGenerateTitleModel', (value) async {
      //生成标题的模型发生更改
      curChatSet['chatSettings_defaultGenerateTitleModel'] = value;
      String curChatSetStr = jsonEncode(curChatSet);
      await SupabaseHelper().update('chat_contents', {'chatSettings': curChatSetStr}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
    });
    box.listenKey('chatSettings_enablePrivateMode', (value) async {
      //隐私模式发生更改
      curChatSet['chatSettings_enablePrivateMode'] = value;
      _useEncrypt = value;
      String curChatSetStr = jsonEncode(curChatSet);
      await SupabaseHelper().update('chat_contents', {'chatSettings': curChatSetStr}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
    });
    box.listenKey('chatSettings_privateModeKey', (value) async {
      //隐私模式加密Key发生更改
      curChatSet['chatSettings_privateModeKey'] = value;
      _encryptKey = value;
      String curChatSetStr = jsonEncode(curChatSet);
      await SupabaseHelper().update('chat_contents', {'chatSettings': curChatSetStr}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
    });
    box.listenKey('is_login', (value) async {
      //用户登录状态发生变化，重新获取数据
      if (value) {
        await _readChatListHistory();
        setState(() {});
      } else {
        setState(() {
          _chatTitleKeys.clear();
          _chatListNotifier.value.clear();
          messages.clear();
        });
      }
    });
    box.listenKey('curPage', (value) async {
      //当前页面不在顶部的时候禁用drop
      setState(() {
        _enableDrop = value == 0;
      });
    });
  }

  // 添加一个新方法来构建文件预览
  Widget _buildFilePreview(UploadingFile uploadingFile, String index) {
    final extension = uploadingFile.file.extension?.toLowerCase() ?? '';
    if (['jpg', 'jpeg', 'png'].contains(extension)) {
      // 如果是图片文件,显示图片预览
      return InkWell(
        onLongPress: () {
          setState(() {
            uploadingFile.cancelToken?.cancel('取消上传');
            allUploadedFiles.removeWhere((file) => file.key == uploadingFile.key);
            hasFileUploaded = checkUploadFileStatus();
            tempFiles = List.from(allUploadedFiles);
            _questionList.retainWhere((question) => question.key == uploadingFile.key);
          });
        },
        child: Stack(
          children: [
            ImagePreviewWidget(
              imageUrl: uploadingFile.file.path!,
              isOnline: false,
              previewWidth: 60,
              previewHeight: 60,
            ),
            if (uploadingFile.uploadFailed)
              Positioned.fill(
                // 确保文本占据整个 Stack
                child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(128),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            uploadingFile.uploadFailed = false;
                            uploadingFile.isUploaded = false;
                          });
                          uploadSingleFile(uploadingFile, index);
                        },
                        child: const Text(
                          '上传失败\n点击重试',
                          textAlign: TextAlign.center, // 确保文本居中
                          style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )),
              )
          ],
        ),
      );
    } else {
      // 如果不是图片文件,显示文件图标和文件名
      return InkWell(
          onTap: () {
            showFileViewerDialog(uploadingFile.content!, uploadingFile.file.name, uploadingFile.key);
          },
          onLongPress: () {
            setState(() {
              uploadingFile.cancelToken?.cancel('取消上传');
              allUploadedFiles.removeWhere((file) => file.key == uploadingFile.key);
              hasFileUploaded = checkUploadFileStatus();
              tempFiles = List.from(allUploadedFiles);
              _questionList.retainWhere((question) => question.key == uploadingFile.key);
            });
          },
          child: FileDisplayWidget(file: uploadingFile));
    }
  }

  void showFileViewerDialog(String fileContent, String fileName, String fileKey) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FileContentViewer(
          fileContent: fileContent,
          fileName: fileName,
          isEditable: true,
          onContentChanged: (content) {
            for (var file in allUploadedFiles) {
              if (file.key == fileKey) {
                setState(() {
                  file.content = content;
                });
                break;
              }
            }
          },
        );
      },
    );
  }

  bool checkUploadFileStatus() {
    if (allUploadedFiles.isEmpty) {
      return false;
    }
    for (var file in allUploadedFiles) {
      if (file.uploadFailed) {
        return false;
      }
    }
    return true;
  }

  // 封装进一个通用的布局函数
  Widget _buildProgressLayout({required bool isImage, required ChangeSettings settings}) {
    return Flex(
      direction: isImage ? Axis.vertical : Axis.horizontal,
      // 根据是否是图片动态选择 Row 或 Column
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8, height: 8), // 同时为 Row 和 Column 提供间距
        Text(
          isImage ? '上传中...' : '文件上传中...',
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), // 统一字体样式
        ),
      ],
    );
  }

  // 检查文本行数是否超出限制
  bool _checkLineCount(String text) {
    final int lineCount = '\n'.allMatches(text).length + 1;
    return lineCount <= 200;
  }

  // 处理文本输入和粘贴
  TextEditingValue _handleTextInput(TextEditingValue oldValue, TextEditingValue newValue) {
    // 如果文本没有变化，直接返回
    if (oldValue.text == newValue.text) {
      return newValue;
    }
    // 检查是否是粘贴操作（文本长度显著增加）
    if (newValue.text.length > oldValue.text.length + 1) {
      // 获取粘贴的内容
      pastedContent = newValue.text.replaceRange(0, oldValue.text.length.clamp(0, newValue.text.length), '');
      // 检查行数
      if (!_checkLineCount(pastedContent)) {
        var pastedFile = UploadingFile(
            key: GlobalKey().toString(),
            file: PlatformFile(name: '复制的内容.txt', size: 0),
            content: pastedContent,
            isPrivate: _useEncrypt,
            encryptKey: _encryptKey,
            isUploaded: true);
        _questionList.add(QuestionData(
          index: _questionList.length + 1,
          name: '复制的内容',
          content: pastedContent,
          key: pastedFile.key,
        ));
        setState(() {
          allUploadedFiles.add(pastedFile);
          hasFileUploaded = checkUploadFileStatus();
        });
        return oldValue; // 保持原来的值
      }
    }
    return newValue;
  }

  // 发送消息时重建完整文本
  void _sendMessagePre() {
    if (_controller.text.isNotEmpty || hasFileUploaded) {
      String finalContent = _controller.text;
      tempFiles = List.from(allUploadedFiles);
      // 发送最终内容
      _sendMessage(finalContent);
      setState(() {
        allUploadedFiles.clear();
        hasFileUploaded = false;
        _controller.clear();
        _textSegments.clear(); // 清空片段记录
        _questionList.clear();
      });
    } else {
      showHint('请输入文字或者检查文件上传是否存在异常');
    }
  }

  void _showDeleteConfirmDialog(List<int> indexes, ChangeSettings settings) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomDialog(
            title: '删除确认',
            titleColor: settings.getForegroundColor(),
            contentBackgroundColor: settings.getBackgroundColor(),
            description: '是否删除选中的 ${indexes.length} 个会话？',
            descColor: settings.getForegroundColor(),
            cancelButtonText: '取消',
            confirmButtonText: '确定',
            conformButtonColor: settings.getSelectedBgColor(),
            onCancel: () {},
            onConfirm: () async {
              // 按索引从大到小排序，以避免删除时索引变化
              indexes.sort((a, b) => b.compareTo(a));
              Map<dynamic, dynamic> needDeletes = {};
              for (var index in indexes) {
                String temCreateTime = _chatListNotifier.value[index].createTime;
                var temCreateId = _chatListNotifier.value[index].id;
                setState(() {
                  _chatListNotifier.value.removeAt(index);
                });
                needDeletes[temCreateId] = temCreateTime;
              }
              setState(() {
                _chatListNotifier.value = List.from(_chatListNotifier.value);
                _isMultiSelectMode = false;
                _selectedItems.clear();
                _isAllSelected = false; // 重置全选状态
                if (_chatListNotifier.value.isEmpty) {
                  _addNewChat('新的聊天');
                }
              });
              // 如果当前显示的聊天被删除，需要更新显示
              if (_chatListNotifier.value.isNotEmpty) {
                for (var entry in needDeletes.entries) {
                  if (entry.value == createTime) {
                    //说明需要删除的聊天包含当前的聊天
                    createTime = _chatListNotifier.value[0].createTime;
                    messages.clear();
                    tempFiles.clear();
                    _selectedIndex = 0;
                    var chats = await _readChatContentHistory(createTime);
                    setState(() {
                      chatMessagesStartIndex = 0;
                      messages = chats;
                      _keys.clear();
                      for (int i = 0; i < messages.length; i++) {
                        _keys.add(GlobalKey());
                      }
                      _scrollToBottom(isReadHistory: true);
                    });
                  }
                }
              } else {
                messages.clear();
              }
              for (var entry in needDeletes.entries) {
                await _deleteChat(entry.key, entry.value);
              }
            },
          );
        });
  }

// 修改全选状态检查方法
  bool _checkAllSelected() {
    for (int i = 0; i < _chatListNotifier.value.length; i++) {
      final chatItem = _chatListNotifier.value[i];
      // 只检查可见项
      final bool isVisible = _searchKeyword.isEmpty ||
          chatItem.title.toLowerCase().contains(_searchKeyword.toLowerCase()) ||
          _searchMatchedCreateTimes.contains(chatItem.createTime);
      if (isVisible && !_selectedItems.contains(i)) {
        return false;
      }
    }
    return true;
  }

  Future<Set<String>> _searchChats(String keyword) async {
    try {
      if (keyword.isEmpty) {
        setState(() {
          _isSearching = false;
        });
        return {};
      }
      String encryptedKeyword = '';
      if (_encryptKey.isNotEmpty) {
        encryptedKeyword = EncryptionUtils.encrypt(keyword, _encryptKey);
      }
      final settings = await Config.loadSettings();
      String userId = settings['user_id'] ?? '';
      // 先从 chat_contents 表中查询匹配的记录
      String orInfo = 'content.ilike.%$keyword%';
      if (encryptedKeyword.isNotEmpty) {
        orInfo = '$orInfo,content.ilike.%$encryptedKeyword%';
      }
      final response = await SupabaseHelper()
          .query('chat_contents', {'is_delete': 0, 'user_id': userId}, selectInfo: 'createTime,content', isOrdered: false, orInfo: orInfo);
      // 解析 content 字段并进行内容匹配
      Set<String> matchedCreateTimes = {};
      if (response.isEmpty) {
        setState(() {
          _isSearching = false;
        });
        return {};
      } else {
        for (var result in response) {
          matchedCreateTimes.add(result['createTime']);
        }
        return matchedCreateTimes;
      }
    } catch (e) {
      commonPrint('Error searching chats: $e');
      setState(() {
        _isSearching = false;
      });
      return {};
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> onMessageDelete(int index, {bool needChangeValue = true, ChatMessage? message}) async {
    if (!isAnswering) {
      String curMessageText = messages[index].text;
      bool isPrivate = messages[index].isPrivate ?? false;
      String dataEncryptKey = messages[index].encryptKey ?? '';
      bool isEncrypted = messages[index].isEncrypted ?? false;
      setState(() {
        messages.removeAt(index);
      });
      if (!needChangeValue) {
        if (message != null) {
          setState(() {
            messages.add(message);
          });
        }
      }
      if (isPrivate && isEncrypted) {
        curMessageText = EncryptionUtils.encrypt(curMessageText, dataEncryptKey);
      }
      if (needChangeValue) {
        _chatListNotifier.value[_selectedIndex].messagesCount = messages.length - 1;
      }
      var settings = await Config.loadSettings();
      String userId = settings['user_id'] ?? '';
      SupabaseHelper().update('chat_list', {'messagesCount': messages.length - 1}, updateMatchInfo: {'createTime': createTime, 'user_id': userId});
      var readMessages = await SupabaseHelper().query('chat_contents', {'createTime': createTime, 'user_id': userId});
      if (readMessages.isNotEmpty) {
        for (int i = 0; i < readMessages.length; i++) {
          List<Map<String, dynamic>> content = List<Map<String, dynamic>>.from(jsonDecode(readMessages[i]['content']));
          String key = readMessages[i]['key'];
          for (int i = 0; i < content.length; i++) {
            var element = content[i];
            if (element['text'] == curMessageText || element['fullText'] == curMessageText) {
              await SupabaseHelper().update('chat_contents', {'is_delete': 1}, updateMatchInfo: {'key': key});
              break;
            }
          }
        }
      }
    }
  }

  Future<void> onMessageRetry(int index) async {
    if (messages[index].isSentByMe) {
      if (index == messages.length - 1) {
        tempFiles = List.from(messages[index].files ?? []);
        _sendMessage(messages[index].text, isRetry: true);
      } else {
        var curMessage = messages[index];
        var nextMessage = messages[index + 1];
        String curMessageText = curMessage.text;
        String nextMessageText = nextMessage.text;
        messages.remove(curMessage);
        messages.remove(nextMessage);
        messages.add(curMessage);
        bool isPrivate = messages[index].isPrivate ?? false;
        String dataEncryptKey = messages[index].encryptKey ?? '';
        bool isEncrypted = messages[index].isEncrypted ?? false;
        if (isPrivate && isEncrypted) {
          curMessageText = EncryptionUtils.encrypt(curMessageText, dataEncryptKey);
          nextMessageText = EncryptionUtils.encrypt(nextMessageText, dataEncryptKey);
        }
        var tempMessages = List.from(messages);
        tempFiles = List.from(curMessage.files ?? []);
        _sendMessage(curMessage.text, isRetry: true);
        _scrollToBottom();
        setState(() {});
        var readMessages = await SupabaseHelper().query('chat_contents', {'createTime': createTime});
        if (readMessages.isNotEmpty) {
          for (int i = 0; i < readMessages.length; i++) {
            List<Map<String, dynamic>> content = List<Map<String, dynamic>>.from(jsonDecode(readMessages[i]['content']));
            String key = readMessages[i]['key'];
            for (int i = 0; i < content.length; i++) {
              var element = content[i];
              if (element['text'] == curMessageText) {
                await SupabaseHelper().update('chat_contents', {'is_delete': 1}, updateMatchInfo: {'key': key});
                break;
              }
              if (element['text'] == nextMessageText) {
                await SupabaseHelper().update('chat_contents', {'is_delete': 1}, updateMatchInfo: {'key': key});
                break;
              }
            }
          }
        }
        String messagesJson = jsonEncode([tempMessages.last.toJson()]);
        String curChatSetStr = jsonEncode(curChatSet);
        var settings = await Config.loadSettings();
        String userId = settings['user_id'] ?? '';
        SupabaseHelper().insert('chat_contents', {
          'title': currentTitle,
          'createTime': createTime,
          'content': messagesJson,
          'useAIModel': useAIModel,
          'chatSettings': curChatSetStr,
          'user_id': userId,
          'is_delete': 0,
          'key': const Uuid().v4(),
        });
      }
    } else {
      if (index == messages.length - 1) {
        var tempMessages = List.from(messages);
        setState(() {
          messages.removeAt(index);
        });
        tempFiles = List.from(tempMessages[index - 1].files ?? []);
        _sendMessage(tempMessages[index - 1].text, isRetry: true);
        String curMessageText = tempMessages[index].text;
        bool isPrivate = tempMessages[index].isPrivate ?? false;
        String dataEncryptKey = tempMessages[index].encryptKey ?? '';
        bool isEncrypted = tempMessages[index].isEncrypted ?? false;
        if (isPrivate && isEncrypted) {
          curMessageText = EncryptionUtils.encrypt(curMessageText, dataEncryptKey);
        }
        var readMessages = await SupabaseHelper().query('chat_contents', {'createTime': createTime});
        if (readMessages.isNotEmpty) {
          for (int i = 0; i < readMessages.length; i++) {
            List<Map<String, dynamic>> content = List<Map<String, dynamic>>.from(jsonDecode(readMessages[i]['content']));
            String key = readMessages[i]['key'];
            for (int i = 0; i < content.length; i++) {
              var element = content[i];
              if (element['text'] == curMessageText || element['fullText'] == curMessageText) {
                await SupabaseHelper().update('chat_contents', {'is_delete': 1}, updateMatchInfo: {'key': key});
                break;
              }
            }
          }
        }
      } else {
        var curMessage = messages[index];
        var preMessage = messages[index - 1];
        var tempMessages = List.from(messages);
        messages.remove(curMessage);
        messages.remove(preMessage);
        messages.add(preMessage);
        tempFiles = List.from(preMessage.files ?? []);
        String curMessageText = curMessage.text;
        String nextMessageText = preMessage.text;
        _sendMessage(preMessage.text, isRetry: true);
        bool isPrivate = tempMessages[index].isPrivate ?? false;
        String dataEncryptKey = tempMessages[index].encryptKey ?? '';
        bool isEncrypted = tempMessages[index].isEncrypted ?? false;
        if (isPrivate && isEncrypted) {
          curMessageText = EncryptionUtils.encrypt(curMessageText, dataEncryptKey);
          nextMessageText = EncryptionUtils.encrypt(nextMessageText, dataEncryptKey);
        }
        _scrollToBottom();
        setState(() {});
        var readMessages = await SupabaseHelper().query('chat_contents', {'createTime': createTime});
        if (readMessages.isNotEmpty) {
          for (int i = 0; i < readMessages.length; i++) {
            List<Map<String, dynamic>> content = List<Map<String, dynamic>>.from(jsonDecode(readMessages[i]['content']));
            String key = readMessages[i]['key'];
            for (int i = 0; i < content.length; i++) {
              var element = content[i];
              if (element['text'] == curMessageText || element['fullText'] == curMessageText) {
                await SupabaseHelper().update('chat_contents', {'is_delete': 1}, updateMatchInfo: {'key': key});
                break;
              }
              if (element['text'] == nextMessageText || element['fullText'] == nextMessageText) {
                await SupabaseHelper().update('chat_contents', {'is_delete': 1}, updateMatchInfo: {'key': key});
                break;
              }
            }
          }
        }
        String messagesJson = jsonEncode([tempMessages.last.toJson()]);
        String curChatSetStr = jsonEncode(curChatSet);
        var settings = await Config.loadSettings();
        String userId = settings['user_id'] ?? '';
        SupabaseHelper().insert('chat_contents', {
          'title': currentTitle,
          'createTime': createTime,
          'content': messagesJson,
          'useAIModel': useAIModel,
          'chatSettings': curChatSetStr,
          'user_id': userId,
          'is_delete': 0,
          'key': const Uuid().v4(),
        });
      }
    }
  }

  Future<void> _showUserQuotaDialog({required BuildContext context, required String userName}) async {
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

  void _showFeatureDescription(BuildContext context, String label, Color color, ChangeSettings settings) {
    String userAvatar = getAvatarImage(label, false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: settings.getBackgroundColor(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.only(left: 10, top: 10),
          title: Row(
            children: [
              ClipOval(
                  child: ExtendedImage.asset(
                userAvatar,
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              )),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: settings.getForegroundColor(),
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            findModelDescByName(label),
            style: TextStyle(
              color: settings.getForegroundColor(),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                '知道了',
                style: TextStyle(
                  color: getRealDarkMode(settings) ? color.withAlpha(230) : color,
                  fontSize: 16,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showMaskDialog({required BuildContext context, required ChangeSettings settings}) async {}

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withAlpha(76),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    final bool isMobile = Platform.isAndroid || Platform.isIOS;
    final Orientation orientation = MediaQuery.of(context).orientation;
    var width = isMobile
        ? orientation == Orientation.portrait
            ? MediaQuery.of(context).size.width
            : _leftPanelWidth
        : _leftPanelWidth;
    bool showLeftPanel = (!isMobile || (isMobile && _showLeftPanel) || (isMobile && orientation == Orientation.landscape));
    return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Shortcuts(
              shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
              },
              child: Actions(
                actions: <Type, Action<Intent>>{
                  ActivateIntent: CallbackAction<ActivateIntent>(
                    onInvoke: (intent) => _sendMessagePre(),
                  ),
                },
                child: ClipboardListenerWidget(
                    onFilesReceived: (filePaths) {
                      if (_enableDrop) {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return CustomDialog(
                                title: '文件导入',
                                maxHeight: 400,
                                description: '是否导入这${filePaths.length}个文件？',
                                titleColor: settings.getTextColor(),
                                descColor: settings.getTextColor(),
                                backgroundColor: settings.getBackgroundColor(),
                                contentBackgroundColor: settings.getBackgroundColor(),
                                showConfirmButton: true,
                                showCancelButton: true,
                                confirmButtonText: '导入',
                                cancelButtonText: '取消',
                                useScrollContent: true,
                                conformButtonColor: settings.getSelectedBgColor(),
                                content: SizedBox(
                                    height: 200,
                                    child: ListView.builder(
                                        itemCount: filePaths.length,
                                        itemBuilder: (context, index) {
                                          String fileExtension = path.extension(filePaths[index]);
                                          bool isImage = isImageFile(filePaths[index]);
                                          return ListTile(
                                            leading: isImage
                                                ? ExtendedImage.file(
                                                    File(filePaths[index]),
                                                    width: 30,
                                                    height: 30,
                                                  )
                                                : Icon(getFileIcon(fileExtension)),
                                            title: Text(
                                              path.basename(filePaths[index]),
                                              maxLines: 1,
                                              overflow: TextOverflow.clip,
                                            ),
                                          );
                                        })),
                                onConfirm: () async {
                                  List<UploadingFile> uploadingFiles = [];
                                  setState(() {
                                    hasFileUploaded = false;
                                    for (var i = 0; i < filePaths.length; i++) {
                                      uploadingFiles.add(UploadingFile(
                                        key: getCurrentTimestamp() + const Uuid().v4(),
                                        // 创建唯一的key
                                        file: PlatformFile(name: path.basename(filePaths[i]), path: filePaths[i], size: 0),
                                        cancelToken: dio.CancelToken(),
                                        isPrivate: _useEncrypt,
                                        encryptKey: _encryptKey,
                                      ));
                                    }
                                    allUploadedFiles.addAll(uploadingFiles);
                                  });
                                  for (var i = 0; i < uploadingFiles.length; i++) {
                                    await uploadSingleFile(uploadingFiles[i], uploadingFiles[i].key);
                                  }
                                  setState(() {
                                    hasFileUploaded = checkUploadFileStatus();
                                    tempFiles = List.from(allUploadedFiles);
                                  });
                                },
                                onCancel: () {},
                              );
                            });
                      }
                    },
                    child: Container(
                      color: settings.getBackgroundColor(),
                      child: Row(
                        children: [
                          // 左侧面板
                          if (showLeftPanel) ...[
                            Container(
                              width: width,
                              constraints: BoxConstraints(minWidth: width),
                              decoration: BoxDecoration(
                                color: settings.getCardColor(),
                              ),
                              child: Column(
                                children: [
                                  // 搜索框和多选按钮行
                                  Container(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: settings.getBackgroundColor(),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: settings.getBorderColor()),
                                            ),
                                            child: TextField(
                                              controller: _searchController,
                                              style: TextStyle(color: settings.getTextColor()),
                                              decoration: InputDecoration(
                                                hintText: '搜索聊天',
                                                hintStyle: TextStyle(color: settings.getHintTextColor()),
                                                prefixIcon: Icon(Icons.search, color: settings.getHintTextColor()),
                                                // 添加后缀图标，仅在有文本时显示
                                                suffixIcon: _searchController.text.isNotEmpty
                                                    ? IconButton(
                                                        icon: Icon(
                                                          Icons.clear,
                                                          color: settings.getHintTextColor(),
                                                          size: 18,
                                                        ),
                                                        onPressed: () {
                                                          _searchController.clear(); // 清空文本
                                                          setState(() {
                                                            _searchKeyword = ''; // 清空搜索关键词
                                                            _isSearching = false;
                                                            _searchMatchedCreateTimes = {};
                                                          });
                                                        },
                                                      )
                                                    : null,
                                                border: InputBorder.none,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  _searchKeyword = value;
                                                  _isSearching = true;
                                                });
                                                // 添加防抖，避免频繁请求
                                                if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
                                                _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
                                                  final matchedCreateTimes = await _searchChats(_searchKeyword);
                                                  setState(() {
                                                    _searchMatchedCreateTimes = matchedCreateTimes;
                                                  });
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // 多选按钮
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _isMultiSelectMode = !_isMultiSelectMode;
                                              if (!_isMultiSelectMode) {
                                                _selectedItems.clear();
                                                _isAllSelected = false; // 重置全选状态
                                              }
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: _isMultiSelectMode ? settings.getSelectedBgColor() : settings.getBackgroundColor(),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: settings.getBorderColor()),
                                            ),
                                            child: Icon(
                                              _isMultiSelectMode ? Icons.close : Icons.checklist,
                                              color: _isMultiSelectMode ? Colors.white : settings.getTextColor(),
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 多选模式下的操作栏
                                  if (_isMultiSelectMode)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      color: settings.getCardColor(),
                                      child: Row(
                                        children: [
                                          // 添加全选复选框
                                          Checkbox(
                                            value: _isAllSelected,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                _isAllSelected = value ?? false;
                                                if (_isAllSelected) {
                                                  // 全选时，将所有可见项（考虑搜索过滤）的索引添加到选中集合
                                                  _selectedItems.clear();
                                                  for (int i = 0; i < _chatListNotifier.value.length; i++) {
                                                    if (_searchKeyword.isEmpty ||
                                                        _chatListNotifier.value[i].title.toLowerCase().contains(_searchKeyword.toLowerCase())) {
                                                      _selectedItems.add(i);
                                                    }
                                                  }
                                                } else {
                                                  // 取消全选时，清空选中集合
                                                  _selectedItems.clear();
                                                }
                                              });
                                            },
                                            activeColor: settings.getSelectedBgColor(),
                                          ),
                                          Text(
                                            '全选',
                                            style: TextStyle(color: settings.getTextColor()),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            '已选择 ${_selectedItems.length} 项',
                                            style: TextStyle(color: settings.getTextColor()),
                                          ),
                                          const Spacer(),
                                          // 只在有选中项时显示删除按钮
                                          if (_selectedItems.isNotEmpty)
                                            TextButton.icon(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              label: const Text('删除', style: TextStyle(color: Colors.red)),
                                              onPressed: () {
                                                _showDeleteConfirmDialog(_selectedItems.toList(), settings);
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                  // 使用ValueListenableBuilder来异步加载ListView
                                  Expanded(
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ScrollConfiguration(
                                            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                                            // 禁用系统默认滚动条
                                            child: ValueListenableBuilder<List<ChatListData>>(
                                              valueListenable: _chatListNotifier,
                                              builder: (context, value, child) {
                                                if (value.isEmpty) {
                                                  return Center(
                                                      child: Container(
                                                    margin: const EdgeInsets.only(left: 6, right: 6),
                                                    child: Text(
                                                      '暂无聊天,点击下面的新的聊天开始吧',
                                                      style: TextStyle(color: settings.getForegroundColor()),
                                                    ),
                                                  ));
                                                } else {
                                                  return RawScrollbar(
                                                      thumbColor: settings.getScrollbarColor(), // 滚动条颜色
                                                      radius: const Radius.circular(10), // 滚动条圆角
                                                      controller: _leftScrollController,
                                                      child: ListView.builder(
                                                          controller: _leftScrollController,
                                                          itemCount: value.length,
                                                          itemBuilder: (context, index) {
                                                            final chatItem = value[index];
                                                            // 同时检查标题和内容匹配
                                                            final bool matchesSearch = _searchKeyword.isEmpty ||
                                                                chatItem.title.toLowerCase().contains(_searchKeyword.toLowerCase()) ||
                                                                _searchMatchedCreateTimes.contains(chatItem.createTime);

                                                            if (!matchesSearch) {
                                                              return const SizedBox.shrink();
                                                            }
                                                            _hovering[index] = _hovering[index] ?? false;
                                                            final bool isSelected =
                                                                _isMultiSelectMode ? _selectedItems.contains(index) : _selectedIndex == index;
                                                            return MouseRegion(
                                                              key: _chatTitleKeys[index],
                                                              onEnter: (event) => setState(() => _hovering[index] = true),
                                                              onExit: (event) => setState(() => _hovering[index] = false),
                                                              child: InkWell(
                                                                onTap: () async {
                                                                  if (_isMultiSelectMode) {
                                                                    setState(() {
                                                                      if (_selectedItems.contains(index)) {
                                                                        _selectedItems.remove(index);
                                                                        // 当取消选择某项时，确保全选状态为 false
                                                                        _isAllSelected = false;
                                                                      } else {
                                                                        _selectedItems.add(index);
                                                                        // 检查是否所有可见项都被选中
                                                                        _isAllSelected = _checkAllSelected();
                                                                      }
                                                                    });
                                                                    return;
                                                                  }
                                                                  if (isMobile) {
                                                                    setState(() {
                                                                      _showLeftPanel = false;
                                                                    });
                                                                  }
                                                                  int preIndex = _selectedIndex;
                                                                  if (_selectedIndex != index) {
                                                                    _selectedIndex = index;
                                                                  }
                                                                  String tmpCreateTime = value[index].createTime;
                                                                  String preCreateTime = value[preIndex].createTime;
                                                                  if (tmpCreateTime != createTime) {
                                                                    //这里应该是拿到列表的时间值，然后查询数据
                                                                    createTime = value[index].createTime;
                                                                    var chats = await _readChatContentHistory(createTime);
                                                                    setState(() {
                                                                      chatMessagesStartIndex = 0;
                                                                      tempFiles.clear();
                                                                      messages = chats;
                                                                      _keys.clear();
                                                                      for (int i = 0; i < messages.length; i++) {
                                                                        _keys.add(GlobalKey());
                                                                      }
                                                                    });
                                                                    _scrollToBottom(isReadHistory: true);
                                                                    SupabaseHelper().update('chat_list', {'isSelected': true},
                                                                        updateMatchInfo: {'createTime': createTime});
                                                                    SupabaseHelper().update('chat_list', {'isSelected': false},
                                                                        updateMatchInfo: {'createTime': preCreateTime});
                                                                  }
                                                                },
                                                                onLongPress: () {
                                                                  deleteItem(value, index, context, settings);
                                                                },
                                                                child: Stack(
                                                                  alignment: Alignment.topRight,
                                                                  children: [
                                                                    Container(
                                                                      height: 66,
                                                                      margin: const EdgeInsets.all(4.0),
                                                                      decoration: BoxDecoration(
                                                                        color: settings.getBackgroundColor(),
                                                                        borderRadius: BorderRadius.circular(10),
                                                                        border: isSelected
                                                                            ? Border.all(color: settings.getBorderColor(), width: 2)
                                                                            : null,
                                                                        boxShadow: [
                                                                          BoxShadow(
                                                                            color: Colors.grey.withAlpha(51),
                                                                            spreadRadius: 1,
                                                                            blurRadius: 5,
                                                                            offset: const Offset(0, 3),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      child: Row(children: [
                                                                        if (_isMultiSelectMode)
                                                                          Padding(
                                                                            padding: const EdgeInsets.only(left: 8),
                                                                            child: Checkbox(
                                                                              value: _selectedItems.contains(index),
                                                                              onChanged: (bool? value) {
                                                                                setState(() {
                                                                                  if (value ?? false) {
                                                                                    _selectedItems.add(index);
                                                                                  } else {
                                                                                    _selectedItems.remove(index);
                                                                                  }
                                                                                  _isAllSelected = _checkAllSelected();
                                                                                });
                                                                              },
                                                                              activeColor: settings.getSelectedBgColor(),
                                                                            ),
                                                                          ),
                                                                        Expanded(
                                                                          child: ListTile(
                                                                            contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                                            title: Row(
                                                                              children: [
                                                                                ClipOval(
                                                                                  child: ExtendedImage.asset(
                                                                                    getAvatarImage(value[index].modelName ?? '', false),
                                                                                    width: 24,
                                                                                    height: 24,
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(width: 4),
                                                                                Text(
                                                                                  truncateString(value[index].title, 9),
                                                                                  maxLines: 1,
                                                                                  overflow: TextOverflow.ellipsis,
                                                                                  style: TextStyle(
                                                                                      fontWeight: FontWeight.bold,
                                                                                      fontSize: 18,
                                                                                      color: settings.getTextColor()),
                                                                                )
                                                                              ],
                                                                            ),
                                                                            subtitle: Row(
                                                                              children: [
                                                                                Align(
                                                                                  alignment: Alignment.bottomLeft,
                                                                                  child: Column(
                                                                                    children: [
                                                                                      const SizedBox(
                                                                                        height: 6,
                                                                                      ),
                                                                                      Text(
                                                                                        '${value[index].messagesCount}条对话',
                                                                                        style: TextStyle(
                                                                                            fontSize: 12, color: settings.getHintTextColor()),
                                                                                      )
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                                const Spacer(),
                                                                                Align(
                                                                                    alignment: Alignment.bottomRight,
                                                                                    child: Column(
                                                                                      children: [
                                                                                        const SizedBox(
                                                                                          height: 6,
                                                                                        ),
                                                                                        Text(
                                                                                          value[index].createTime,
                                                                                          style: TextStyle(
                                                                                              fontSize: 12, color: settings.getHintTextColor()),
                                                                                        ),
                                                                                      ],
                                                                                    )),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ]),
                                                                    ),
                                                                    if (_hovering[index]! && !_isMultiSelectMode) // 只有在鼠标悬停时才显示删除图标
                                                                      Positioned(
                                                                        top: 16,
                                                                        right: 16,
                                                                        child: InkWell(
                                                                          child: Icon(
                                                                            Icons.close,
                                                                            size: 16,
                                                                            color: settings.getBorderColor(),
                                                                          ),
                                                                          onTap: () async {
                                                                            deleteItem(value, index, context, settings);
                                                                          },
                                                                        ),
                                                                      ),
                                                                  ],
                                                                ),
                                                              ),
                                                            );
                                                          }));
                                                }
                                              },
                                            )),
                                        if (_isSearching) ...[
                                          Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                CircularProgressIndicator(
                                                  color: settings.getTextColor(),
                                                ),
                                                Text(
                                                  '加载中...',
                                                  style: TextStyle(color: settings.getTextColor()),
                                                )
                                              ],
                                            ),
                                          )
                                        ]
                                      ],
                                    ),
                                  ),
                                  if (!isMobile) ...[
                                    SizedBox(
                                      height: 100,
                                      width: _leftPanelWidth,
                                      child: ListView(
                                        children: <Widget>[
                                          ListTile(
                                            leading: Icon(
                                              Icons.add_box_outlined,
                                              color: settings.getTextColor(),
                                            ),
                                            title: Text(
                                              '新的聊天',
                                              style: TextStyle(color: settings.getTextColor()),
                                            ),
                                            onTap: () {
                                              _addNewChat('新的聊天');
                                            },
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ListTile(
                                                  leading: Icon(
                                                    Icons.settings,
                                                    color: settings.getTextColor(),
                                                  ),
                                                  title: Text(
                                                    '聊天全局设置',
                                                    style: TextStyle(color: settings.getTextColor()),
                                                  ),
                                                  onTap: () {
                                                    _setChat(settings: settings);
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (isMobile) ...[
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                        children: [
                                          Expanded(
                                              child: _buildButton(
                                                  label: '新的聊天',
                                                  onPressed: () {
                                                    _addNewChat('新的聊天');
                                                    setState(() {
                                                      _showLeftPanel = false;
                                                    });
                                                  },
                                                  backgroundColor: settings.getSelectedBgColor())),
                                          const SizedBox(width: 10),
                                          Expanded(
                                              child: _buildButton(
                                                  label: '聊天全局设置',
                                                  onPressed: () {
                                                    _setChat(settings: settings);
                                                  },
                                                  backgroundColor: settings.getSelectedBgColor())),
                                        ],
                                      ),
                                    )
                                  ]
                                ],
                              ),
                            )
                          ],
                          // 可拖动的分割线
                          if (!isMobile || orientation == Orientation.landscape) ...[
                            GestureDetector(
                              onHorizontalDragUpdate: (details) {
                                setState(() {
                                  _leftPanelWidth = (_leftPanelWidth + details.delta.dx).clamp(270.0, 320);
                                });
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.resizeColumn,
                                child: Container(
                                  width: 4, // 增加宽度便于拖动
                                  color: Colors.transparent,
                                  child: Center(
                                    child: Container(
                                      width: 1,
                                      color: settings.getSelectedBgColor(),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                          if ((isMobile && !_showLeftPanel) || !isMobile || (isMobile && orientation == Orientation.landscape)) ...[
                            // 右侧面板
                            Expanded(
                              child: DragDropWidget(
                                showDropMask: true,
                                dropHintTextColor: settings.getForegroundColor(),
                                dropMaskColor: getRealDarkMode(settings) ? Colors.white.withAlpha(128) : Colors.black.withAlpha(128),
                                onDragDone: (details) async {
                                  if (_enableDrop) {
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return CustomDialog(
                                            title: '文件导入',
                                            maxHeight: 400,
                                            description: '是否导入这${details.files.length}个文件？',
                                            titleColor: settings.getTextColor(),
                                            descColor: settings.getTextColor(),
                                            backgroundColor: settings.getBackgroundColor(),
                                            contentBackgroundColor: settings.getBackgroundColor(),
                                            showConfirmButton: true,
                                            showCancelButton: true,
                                            confirmButtonText: '导入',
                                            cancelButtonText: '取消',
                                            useScrollContent: true,
                                            conformButtonColor: settings.getSelectedBgColor(),
                                            content: SizedBox(
                                                height: 200,
                                                child: ListView.builder(
                                                    itemCount: details.files.length,
                                                    itemBuilder: (context, index) {
                                                      String fileExtension = path.extension(details.files[index].name);
                                                      bool isImage = isImageFile(details.files[index].path);
                                                      return ListTile(
                                                        leading: isImage
                                                            ? ExtendedImage.file(
                                                                File(details.files[index].path),
                                                                width: 30,
                                                                height: 30,
                                                              )
                                                            : Icon(getFileIcon(fileExtension)),
                                                        title: Text(
                                                          details.files[index].name,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.clip,
                                                        ),
                                                      );
                                                    })),
                                            onConfirm: () async {
                                              List<UploadingFile> uploadingFiles = [];
                                              setState(() {
                                                hasFileUploaded = false;
                                                for (var i = 0; i < details.files.length; i++) {
                                                  uploadingFiles.add(UploadingFile(
                                                    key: getCurrentTimestamp() + const Uuid().v4(),
                                                    // 创建唯一的key
                                                    file: PlatformFile(name: details.files[i].name, path: details.files[i].path, size: 0),
                                                    cancelToken: dio.CancelToken(),
                                                    isPrivate: _useEncrypt,
                                                    encryptKey: _encryptKey,
                                                  ));
                                                }
                                                allUploadedFiles.addAll(uploadingFiles);
                                              });
                                              for (var i = 0; i < uploadingFiles.length; i++) {
                                                await uploadSingleFile(uploadingFiles[i], uploadingFiles[i].key);
                                              }
                                              setState(() {
                                                hasFileUploaded = checkUploadFileStatus();
                                                tempFiles = List.from(allUploadedFiles);
                                              });
                                            },
                                            onCancel: () {},
                                          );
                                        });
                                  }
                                },
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: ChatListView(
                                        key: _chatListKey,
                                        padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0, bottom: 40),
                                        itemCount: messages.length,
                                        itemBuilder: (BuildContext context, int index) {
                                          return RepaintBoundary(
                                              key: _keys[index],
                                              child: ChatItem(
                                                message: messages[index],
                                                index: index,
                                                isAnswering: isAnswering,
                                                onAvatarTap: (isUser) {
                                                  if (isUser) {
                                                    _showUserQuotaDialog(context: context, userName: messages[index].userName);
                                                  } else {
                                                    if (messages[index].model != '魔镜AI') {
                                                      _showFeatureDescription(context, messages[index].model, Colors.blueAccent, settings);
                                                    }
                                                  }
                                                },
                                                onRetry: () => onMessageRetry(index),
                                                onCopy: () {
                                                  onCopyMessage(index);
                                                },
                                                onDelete: () => onMessageDelete(index),
                                              ));
                                        },
                                        autoScroll: true,
                                        onScrollStateChanged: (scrollState) {
                                          setState(() {
                                            isOnBottom = scrollState.isAtBottom;
                                            isUserScrollUp = scrollState.userScrolledUp;
                                          });
                                        },
                                      ),
                                    ),
                                    Container(
                                      height: 1, // 宽度为1
                                      color: settings.getSelectedBgColor(), // 分割线颜色
                                    ),
                                    //这里添加几个操作按钮
                                    Container(
                                        margin: EdgeInsets.only(left: 0, right: isMobile ? 0 : 6, top: 6),
                                        child: ChatControls(
                                          enableChatContext: enableChatContext,
                                          enableNet: enableNet,
                                          isOnBottom: isOnBottom,
                                          useAIModel: useAIModel,
                                          alwaysShowModelName: alwaysShowModelName,
                                          onReturnList: () {
                                            setState(() {
                                              _showLeftPanel = true;
                                            });
                                          },
                                          onChatContextChanged: (value) async {
                                            setState(() {
                                              enableChatContext = value;
                                            });
                                            showHint(value ? '已开启聊天上下文' : '已关闭聊天上下文', showType: 2);
                                            curChatSet['chatSettings_enableChatContext'] = value;
                                            String curChatSetStr = jsonEncode(curChatSet);
                                            await SupabaseHelper().update(
                                              'chat_contents',
                                              {'chatSettings': curChatSetStr},
                                              updateMatchInfo: {'createTime': createTime},
                                            );
                                          },
                                          onCleanContext: () {
                                            if (enableChatContext) {
                                              justCleanContext = true;
                                              chatMessagesStartIndex = messages.length - 1;
                                              showHint('聊天上下文已清除', showType: 2, showTime: 100);
                                            } else {
                                              showHint('未启用聊天上下文，无需清除', showType: 4);
                                            }
                                          },
                                          onHybridChanged: (value) {},
                                          enableHybrid: false,
                                          onNetChanged: (value) async {
                                            if (!useAIModel.contains('联网')) {
                                              setState(() {
                                                enableNet = value;
                                              });
                                              showHint(value ? '当前对话已开启联网' : '当前已关闭联网', showType: 2);
                                              curChatSet['chatSettings_enableNet'] = value;
                                              String curChatSetStr = jsonEncode(curChatSet);
                                              var settings = await Config.loadSettings();
                                              String userId = settings['user_id'] ?? '';
                                              await SupabaseHelper().update(
                                                'chat_contents',
                                                {'chatSettings': curChatSetStr},
                                                updateMatchInfo: {
                                                  'createTime': createTime,
                                                  'user_id': userId,
                                                },
                                              );
                                            } else {
                                              showHint('当前模型自带联网,无需开启系统联网');
                                            }
                                          },
                                          onUploadFile: () => uploadMultipleFiles(),
                                          onChatSettings: () => _setChat(
                                            isSingleChatSet: true,
                                            isGlobalChatSet: false,
                                            settings: settings,
                                          ),
                                          onModelSettings: () => _setChat(
                                            isSingleChat: true,
                                            isGlobalChatSet: false,
                                            settings: settings,
                                          ),
                                          onShare: () async {
                                            var savedSettings = await Config.loadSettings();
                                            String userAvatar = savedSettings['user_avatar'] ?? '';
                                            if (context.mounted) {
                                              showDialog(
                                                  context: context,
                                                  builder: (context) => CustomDialog(
                                                        title: '分享对话',
                                                        titleColor: settings.getForegroundColor(),
                                                        showCancelButton: false,
                                                        showConfirmButton: false,
                                                        useScrollContent: false,
                                                        maxHeight: 700,
                                                        maxWidth: 500,
                                                        contentBackgroundColor: settings.getBackgroundColor(),
                                                        content: ShareableMessageList(
                                                          messages: messages,
                                                          messageCount: messages.length,
                                                          model: useAIModel,
                                                          title: currentTitle,
                                                          createTime: createTime,
                                                          userAvatar: userAvatar,
                                                        ),
                                                      ));
                                            }
                                          },
                                          onCapture: () async {
                                            await _captureScreen();
                                          },
                                          onMask: () async {
                                            await _showMaskDialog(
                                              context: context,
                                              settings: settings,
                                            );
                                          },
                                          onScrollToBottom: _scrollToBottom,
                                          settings: settings,
                                        )),
                                    Container(
                                      margin: const EdgeInsets.all(6),
                                      // 外部边框和圆角
                                      decoration: BoxDecoration(
                                        border: Border.all(color: settings.getSelectedBgColor(), width: 2),
                                        // 灰色宽度为1的边框
                                        borderRadius: BorderRadius.circular(8), // 圆角为6
                                      ),
                                      padding: const EdgeInsets.all(8), // 内部留一些空间
                                      child: Column(
                                        children: [
                                          LayoutBuilder(
                                            builder: (context, constraints) {
                                              return SizedBox(
                                                  width: constraints.maxWidth,
                                                  child: SingleChildScrollView(
                                                    scrollDirection: Axis.horizontal,
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        ...allUploadedFiles.map((uploadingFile) => Padding(
                                                              padding: const EdgeInsets.all(12.0),
                                                              // 增加padding，为删除按钮留出空间
                                                              child: MouseRegion(
                                                                onEnter: (_) => setState(() => uploadingFile.isHovered = true),
                                                                onExit: (_) => setState(() => uploadingFile.isHovered = false),
                                                                child: Stack(
                                                                  clipBehavior: Clip.none, // 允许子组件超出边界
                                                                  children: [
                                                                    _buildFilePreview(uploadingFile, uploadingFile.key),
                                                                    if (!uploadingFile.isUploaded && !uploadingFile.uploadFailed)
                                                                      Positioned.fill(
                                                                        child: Container(
                                                                          decoration: BoxDecoration(
                                                                            color: Colors.black.withAlpha(128),
                                                                            borderRadius: BorderRadius.circular(8), // 圆角效果
                                                                          ),
                                                                          child: Stack(
                                                                            children: [
                                                                              // 上传进度的布局
                                                                              Center(
                                                                                child: isImageFile(uploadingFile.file.name)
                                                                                    ? _buildProgressLayout(
                                                                                        isImage: true, settings: settings) // 图片上传布局
                                                                                    : _buildProgressLayout(
                                                                                        isImage: false, settings: settings), // 文件上传布局
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    if (uploadingFile.isHovered)
                                                                      Positioned(
                                                                        top: -10, // 调整位置，确保按钮完全可见
                                                                        right: -10, // 调整位置，确保按钮完全可见
                                                                        child: InkWell(
                                                                          onTap: () {
                                                                            setState(() {
                                                                              uploadingFile.cancelToken?.cancel('取消上传');
                                                                              allUploadedFiles.removeWhere((file) => file.key == uploadingFile.key);
                                                                              hasFileUploaded = checkUploadFileStatus();
                                                                              tempFiles = List.from(allUploadedFiles);
                                                                              _questionList
                                                                                  .retainWhere((question) => question.key == uploadingFile.key);
                                                                            });
                                                                          },
                                                                          child: Container(
                                                                            width: 24, // 稍微减小按钮大小
                                                                            height: 24, // 稍微减小按钮大小
                                                                            decoration: const BoxDecoration(
                                                                              color: Colors.red,
                                                                              shape: BoxShape.circle,
                                                                            ),
                                                                            child: const Center(
                                                                              child: Icon(
                                                                                Icons.close,
                                                                                size: 16,
                                                                                color: Colors.white,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                  ],
                                                                ),
                                                              ),
                                                            )),
                                                      ],
                                                    ),
                                                  ));
                                            },
                                          ),
                                          ValueListenableBuilder<TextEditingValue>(
                                              valueListenable: _controller,
                                              builder: (context, value, child) {
                                                return Row(
                                                  crossAxisAlignment: !value.text.contains('\n') ? CrossAxisAlignment.center : CrossAxisAlignment.end,
                                                  children: [
                                                    // 使用Expanded使文本输入框填充左侧空间
                                                    Expanded(
                                                      child: KeyboardListener(
                                                          focusNode: FocusNode(),
                                                          onKeyEvent: (event) async {
                                                            if (event.logicalKey == LogicalKeyboardKey.enter &&
                                                                event.logicalKey == LogicalKeyboardKey.shift) {
                                                              // 按下shift+enter键时插入换行符
                                                              _controller.value = TextEditingValue(
                                                                text: '${value.text}\n',
                                                                selection: TextSelection.collapsed(offset: value.text.length + 1),
                                                              );
                                                            }
                                                          },
                                                          child: TextField(
                                                            key: _textFieldKey,
                                                            controller: _controller,
                                                            // 设置为多行文本输入
                                                            maxLines: 10,
                                                            // 默认行数为1，即默认高度
                                                            minLines: 1,
                                                            style: TextStyle(color: settings.getForegroundColor(), fontSize: 16),
                                                            decoration: InputDecoration(
                                                              hintText:
                                                                  (Platform.isWindows || Platform.isMacOS) ? 'enter键发送，shift+enter键换行' : '提出你的问题吧',
                                                              hintStyle: TextStyle(
                                                                color: settings.getForegroundColor().withAlpha(128),
                                                              ),
                                                              // 设置默认边框
                                                              border: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(8.0),
                                                                borderSide: BorderSide.none,
                                                              ),
                                                              // 设置获取焦点时的边框
                                                              fillColor: settings.getCardColor(),
                                                              filled: true,
                                                            ),
                                                            // 处理键盘输入，包括粘贴操作
                                                            inputFormatters: [
                                                              TextInputFormatter.withFunction(_handleTextInput),
                                                            ],
                                                          )),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    // 发送按钮
                                                    Align(
                                                      alignment: Alignment.bottomRight, // 右下角对齐
                                                      child: Tooltip(
                                                        message: value.text.isEmpty && !hasFileUploaded
                                                            ? '输入不能为空或者文件上传存在异常'
                                                            : isAnswering
                                                                ? '停止回复'
                                                                : '点击发送',
                                                        child: InkWell(
                                                          onTap: () async {
                                                            FocusScope.of(context).unfocus();
                                                            if (isAnswering) {
                                                              _chatStreamSubscription?.cancel();
                                                              setState(() {
                                                                allUploadedFiles.clear();
                                                              });
                                                              await updateUserPackagesInfo(userChatAvailableInfo, currentChatTokens, isSeniorChat,
                                                                  canUsedSeniorChatNum, canUsedCommonChatNum);
                                                              await finishChat();
                                                            } else {
                                                              _sendMessagePre();
                                                            }
                                                          },
                                                          child: Container(
                                                            width: 40.0,
                                                            height: 40.0,
                                                            decoration: BoxDecoration(
                                                              color: (value.text.trimRight().isEmpty && !hasFileUploaded && !isAnswering)
                                                                  ? const Color(0xFFD7D7D7)
                                                                  : settings.getSelectedBgColor(), // 圆形的背景颜色
                                                              shape: BoxShape.circle, // 设置为圆形
                                                            ),
                                                            child: Center(
                                                              child: AnimatedSwitcher(
                                                                duration: const Duration(milliseconds: 300), // 动画持续时间
                                                                transitionBuilder: (Widget child, Animation<double> animation) {
                                                                  // 动画过渡效果，使用缩放或淡入淡出
                                                                  return ScaleTransition(scale: animation, child: child);
                                                                },
                                                                child: isAnswering
                                                                    ? SvgPicture.asset(
                                                                        'assets/images/stop.svg', // stop 图标路径
                                                                        key: ValueKey<bool>(isAnswering),
                                                                        // 用于区分不同的图标
                                                                        width: 20,
                                                                        height: 20,
                                                                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                                                        semanticsLabel: 'stop',
                                                                      )
                                                                    : SvgPicture.asset(
                                                                        'assets/images/send.svg', // send 图标路径
                                                                        key: ValueKey<bool>(isAnswering),
                                                                        // 用于区分不同的图标
                                                                        width: 30,
                                                                        height: 30,
                                                                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                                                        semanticsLabel: 'send',
                                                                      ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            )
                          ],
                        ],
                      ),
                    )),
              )),
        ));
  }
}
