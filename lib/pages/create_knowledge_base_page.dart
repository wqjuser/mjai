import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tuitu/config/config.dart';
import 'package:tuitu/net/my_api.dart';
import 'package:tuitu/pages/modify_knowledge_base_page.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'package:tuitu/utils/supabase_helper.dart';
import '../config/change_settings.dart';
import '../json_models/chat_message.dart';
import '../json_models/kb_list_data.dart';
import '../widgets/chat_controls.dart';
import '../widgets/chat_item_view.dart';
import '../widgets/chat_settings.dart';
import '../widgets/custom_dialog.dart';
import 'dart:ui' as ui;

class CreateKnowledgeBasePage extends StatefulWidget {
  const CreateKnowledgeBasePage({super.key});

  @override
  State<CreateKnowledgeBasePage> createState() => _CreateKnowledgeBasePageState();
}

class _CreateKnowledgeBasePageState extends State<CreateKnowledgeBasePage> {
  final ValueNotifier<List<KBListData>> _kbListNotifier = ValueNotifier([]);
  final box = GetStorage();
  TextEditingController kbTitleController = TextEditingController();
  TextEditingController kbChangeTitleController = TextEditingController();
  late MyApi myApi;
  String appKey = '';
  String appSec = '';
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> messages = [];
  bool isAnswering = false;
  final supabase = Supabase.instance.client;
  bool enableChatContext = false;
  bool isHovering1 = false;
  bool justCleanContext = false;
  bool isHovering6 = false;
  final TextEditingController _controller = TextEditingController();
  int tempInt = 0;
  List history = [];
  Map<String, dynamic> historyinfo = {};
  final GlobalKey _textFieldKey = GlobalKey();
  int _currentLines = 1;
  late double _textFieldWidth = 0;
  double _leftPanelWidth = 260;
  String useAIModel = 'QAnything 16k';
  bool enableNet = false;
  bool enableHybrid = false;
  bool isOnBottom = false;
  bool alwaysShowModelName = false;
  Map<String, dynamic> curChatSet = {};
  bool _showLeftPanel = true;

  //对话的流式请求
  StreamSubscription<dynamic>? _chatStreamSubscription;

  Future<void> initData() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    bool isLogin = settings['is_login'] ?? false;
    String userId = settings['user_id'] ?? '';
    if (isLogin && userId != '') {
      final List<Map<String, dynamic>> maps =
          await SupabaseHelper().query('kb_list', {'user_id': userId, 'is_delete': false}, isOrdered: true);
      _kbListNotifier.value = List.generate(maps.length, (i) {
        return KBListData(
            id: maps[i]['kb_id'],
            title: maps[i]['kb_title'],
            filesNum: maps[i]['kb_file_num'],
            createTime: maps[i]['kb_add_time'],
            modifyTime: maps[i]['kb_modify_time'],
            isSelected: maps[i]['is_selected']);
      });
      final List<Map<String, dynamic>> userChats = await SupabaseHelper().query('chat_kb', {'user_id': userId});
      if (userChats.isNotEmpty) {
        var chatContents = userChats[0]['chat_contents'];
        try {
          chatContents = jsonDecode(chatContents);
          if (chatContents is List) {
            if (chatContents.isNotEmpty) {
              setState(() {
                messages = List.generate(chatContents.length, (i) {
                  return ChatMessage(
                    text: chatContents[i]['text'],
                    isSentByMe: chatContents[i]['isSentByMe'],
                    model: '',
                    sendTime: chatContents[i]['sendTime'] ?? '',
                  );
                });
              });
            }
          }
          _scrollToBottom();
        } catch (e) {
          commonPrint(e);
        }
      } else {
        await SupabaseHelper().insert('chat_kb', {'user_id': userId, 'chat_contents': []});
      }
    }
  }

  Future<void> createKB() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    bool isLogin = settings['is_login'] ?? false;
    appKey = settings['kb_app_id'] ?? '';
    appSec = settings['kb_app_sec'] ?? '';
    if (!isLogin) {
      showHint('请先登录');
      return;
    }
    String userId = settings['user_id'] ?? '';
    String kbTitle = kbTitleController.text;
    if (kbTitle.isEmpty) {
      showHint('请输入知识库标题');
      return;
    }
    // 获取当前时间
    DateTime now = DateTime.now();
    // 将当前时间转换为时间戳，精确到秒
    int timestamp = now.millisecondsSinceEpoch ~/ 1000;
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    String formatTime = formatter.format(date);
    Map<String, dynamic> payload = {};
    payload['kbName'] = kbTitle;
    try {
      showHint('正在创建知识库...', showType: 5);
      var response = await myApi.createKB(payload);
      if (response.data is String) {
        response.data = jsonDecode(response.data);
      }
      if (response.statusCode == 200) {
        if (response.data['msg'] == 'SUCCESS') {
          showHint('知识库$kbTitle创建成功', showType: 2);
          kbTitleController.text = '';
          String kbId = response.data['result']['kbId'];
          var kbListData = KBListData(id: kbId, title: kbTitle, createTime: formatTime, modifyTime: formatTime);
          _kbListNotifier.value = List.from(_kbListNotifier.value)..insert(0, kbListData);
          dismissHint();
          Map<String, dynamic> kbInfo = {
            'user_id': userId,
            'kb_id': kbId,
            'kb_title': kbTitle,
            'kb_add_time': formatTime,
            'kb_modify_time': formatTime,
            'kb_file_num': 0,
          };
          await SupabaseHelper().insert('kb_list', kbInfo);
        }
      } else {
        showHint('知识库创建失败,原因是${response.data['msg']}', showType: 3);
        commonPrint('知识库创建失败2,原因是${response.data['msg']},${response.statusCode}');
      }
    } catch (e) {
      showHint('知识库创建失败,原因是$e', showType: 3);
      commonPrint('知识库创建失败1,原因是$e');
    } finally {
      dismissHint();
    }
  }

  //获取知识库的所有文件
  Future<List> getAllKBFiles(String kbId) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    appKey = settings['kb_app_id'] ?? '';
    appSec = settings['kb_app_sec'] ?? '';
    List filesStatus = [];
    Map<String, dynamic> payload = {'kbId': kbId};
    try {
      var response = await myApi.fileListKB(payload);
      if (response.statusCode == 200) {
        if (response.data is String) {
          response.data = jsonDecode(response.data);
        }
        if (response.data['result'] is List) {
          List<String> fileIds = [];
          for (var fileInfo in response.data['result']) {
            fileIds.add(fileInfo['fileId']);
          }
          deleteFile(kbId, fileIds);
        }
      } else {
        commonPrint('查询知识库文件失败,原因是${response.data['msg']}');
      }
    } catch (e) {
      commonPrint('查询知识库文件失败,原因是$e');
    }
    return filesStatus;
  }

  //删除知识库的文件
  Future<void> deleteFile(String kbId, List<String> fileIds) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    appKey = settings['kb_app_id'] ?? '';
    appSec = settings['kb_app_sec'] ?? '';
    String userId = settings['user_id'] ?? '';
    Map<String, dynamic> payload = {'kbId': kbId};
    try {
      var response = await myApi.deleteFileKB(payload);
      if (response.statusCode == 200) {
        if (response.data is String) {
          response.data = jsonDecode(response.data);
        }
        if (response.data['msg'] == 'SUCCESS') {
          commonPrint('文件删除成功');
          for (String fileId in fileIds) {
            await SupabaseHelper()
                .update('kb_file', {'is_delete': true}, updateMatchInfo: {'user_id': userId, 'kb_file_id': fileId});
          }
        } else {
          commonPrint('文件删除失败，原因是${response.data['msg']}');
        }
      }
    } catch (e) {
      commonPrint('文件删除失败，原因是$e');
    }
  }

  //删除知识库
  Future<void> deleteKB(String kbId, int index) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    appKey = settings['kb_app_id'] ?? '';
    appSec = settings['kb_app_sec'] ?? '';
    var kbData = _kbListNotifier.value[index];
    setState(() {
      _kbListNotifier.value.removeAt(index);
    });
    //1.查询该知识库的相关文件
    await getKBFiles(kbId);
    //2.删除所有该知识库的文件
    await getAllKBFiles(kbId);
    //3.删除该知识库
    Map<String, dynamic> payload = {};
    payload['kbId'] = kbId;
    try {
      var response = await myApi.deleteKB(payload);
      if (response.statusCode == 200) {
        if (response.data is String) {
          response.data = jsonDecode(response.data);
        }
        //4.逻辑删除sup数据库的数据
        await SupabaseHelper().update('kb_list', {'is_delete': true}, updateMatchInfo: {'kb_id': kbId});
      } else {
        commonPrint('知识库删除失败，原因是${response.data['msg']}');
      }
    } catch (e) {
      commonPrint('知识库删除失败，原因是$e');
      _kbListNotifier.value = List.from(_kbListNotifier.value)..insert(index, kbData);
    }
  }

  //查询知识库文档列表
  Future<void> getKBFiles(String kbId) async {
    Map<String, dynamic> payload = {};
    payload['kbId'] = kbId;
    try {
      var response = await myApi.fileListKB(payload);
      if (response.statusCode == 200) {
        if (response.data is String) {
          response.data = jsonDecode(response.data);
        }
      } else {
        commonPrint('知识库文档查询失败，原因是${response.data['msg']}');
      }
    } catch (e) {
      commonPrint('知识库文档查询失败，原因是$e');
    }
  }

  Future<void> showWarnDialog(String kbId, int index) async {
    final changeSettings = context.read<ChangeSettings>();
    if (mounted) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomDialog(
              title: '提示',
              titleColor: changeSettings.getForegroundColor(),
              showConfirmButton: true,
              showCancelButton: true,
              contentBackgroundColor: changeSettings.getBackgroundColor(),
              description: '确定删除这个知识库吗？删除后知识库中上传的文件也会被删除，此操作不可逆。',
              confirmButtonText: '确认',
              cancelButtonText: '取消',
              descColor: changeSettings.getForegroundColor(),
              conformButtonColor: changeSettings.getSelectedBgColor(),
              useScrollContent: true,
              onCancel: () {},
              onConfirm: () {
                deleteKB(kbId, index);
              },
            );
          });
    }
  }

  //更改知识库标题
  Future<void> changeKBTitle(String kbId) async {
    Map<String, dynamic> payload = {};
    payload['kbId'] = kbId;
    payload['kbName'] = kbChangeTitleController.text;
    try {
      var response = await myApi.changeKBTitle(payload);
      if (response.statusCode == 200) {
        await SupabaseHelper().update('kb_list', {'kb_title': kbChangeTitleController.text}, updateMatchInfo: {'kb_id': kbId});
      } else {
        showHint('知识库标题修改失败，请稍后重试', showType: 3);
      }
    } catch (e) {
      showHint('知识库标题修改失败，请稍后重试', showType: 3);
      commonPrint('知识库名称修改失败，原因是$e');
    }
    kbChangeTitleController.text = '';
  }

  //更改知识库的选中状态，仅仅修改sup数据库的值
  Future<void> changeSelectedStatus(String kbId, bool isSelected) async {
    await SupabaseHelper().update('kb_list', {'is_selected': isSelected}, updateMatchInfo: {'kb_id': kbId});
  }

  void _scrollToBottom({bool isReadHistory = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        _scrollController.animateTo(
          //这里在我自己的电脑上的系数是2.1，在其他电脑上可能是不同的系数
          maxScroll,
          // * (isReadHistory ? (Platform.isWindows ? 2.1 : 2.01) : 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInQuad,
        );
        setState(() {
          isOnBottom = true;
        });
      }
    });
  }

  void _addMessageToChat(String text, {bool isIncremental = false}) async {
    setState(() {
      if (isIncremental && messages.isNotEmpty) {
        // 更新最后一条消息的内容
        var lastMessage = messages.last;
        if (!lastMessage.isSentByMe) {
          // 如果是思考中的消息，直接替换
          if (lastMessage.text == '思考中，请稍后...') {
            messages.last = ChatMessage(
                text: text,
                isSentByMe: false,
                model: useAIModel,
                sendTime: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
                userName: 'QAnything');
          } else {
            // 否则追加内容
            messages.last = ChatMessage(
                text: lastMessage.text + text,
                isSentByMe: false,
                model: lastMessage.model,
                sendTime: lastMessage.sendTime,
                userName: lastMessage.userName);
          }
        }
      } else {
        // 添加新消息
        messages.add(ChatMessage(
            text: text,
            isSentByMe: false,
            model: useAIModel,
            sendTime: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
            userName: 'QAnything'));
      }
      _scrollToBottom();
    });
  }

  void _sendMessage(String text, {bool isRetry = false}) async {
    Map<String, dynamic> settings = await Config.loadSettings();
    Map<String, dynamic> history1 = {};
    Map<String, dynamic> history2 = {};
    isAnswering = true;

    if (text.trimRight().isEmpty) {
      _controller.clear();
      return;
    }
    String userName = settings['user_name'] ?? '';
    if (enableChatContext) {
      if (messages.length >= 2) {
        if (messages.length == 2) {
          history.clear();
          history1 = {"question": messages[0].text, "response": messages[1].text};
          history.add(history1);
        } else if (messages.length == 4) {
          history.clear();
          history1 = {"question": messages[0].text, "response": messages[1].text};
          history2 = {"question": messages[2].text, "response": messages[3].text};
          history.add(history1);
          history.add(history2);
        } else if (messages.length >= 4) {
          history.clear();
          history2 = {"question": messages[messages.length - 2].text, "response": messages[messages.length - 1].text};
          history1 = {"question": messages[messages.length - 4].text, "response": messages[messages.length - 3].text};
          history.add(history1);
          history.add(history2);
        }
      }
    } else {
      history.clear();
    }

    setState(() {
      if (!isRetry) {
        String sendTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
        messages.add(ChatMessage(text: text, isSentByMe: true, model: '', sendTime: sendTime, userName: userName));
      }
      _addMessageToChat('思考中，请稍后...');
      _controller.clear();
      _scrollToBottom();
    });

    List<String> kbIds = [];
    for (var kb in _kbListNotifier.value) {
      if (kb.isSelected) {
        kbIds.add(kb.id);
      }
    }

    Map<String, dynamic> payload = {
      'question': text,
      'kbIds': kbIds,
      'history': history,
      "prompt": "",
      "model": useAIModel,
      "hybridSearch": enableHybrid,
      "networking": enableNet
    };

    try {
      var response = await myApi.chatStreamKB(payload);
      String currentResponse = ''; // 用于累积当前的回复文本
      Map<String, dynamic>? finalResult; // 用于存储最终的完整结果

      _chatStreamSubscription =
          response.data.stream.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).listen(
        (String data) {
          if (data.startsWith("data:")) {
            data = data.substring(5).trim();
          }
          if (data.startsWith("event:data")) {
            data = '';
          }
          if (data.isEmpty || data == "[DONE]") {
            return;
          }

          try {
            var jsonData = jsonDecode(data);
            var result = jsonData['result'];
            // 处理增量响应
            if (result != null && result['response'] != null) {
              String newContent = result['response'];
              // 检查是否是新的内容
              if (newContent != currentResponse) {
                String incrementalContent = newContent;
                currentResponse += newContent;
                _addMessageToChat(incrementalContent, isIncremental: true);
              }
              // 如果包含完整信息，保存下来
              if (result['source'] != null || result['history'] != null) {
                finalResult = result;
              }
            }
          } catch (e) {
            commonPrint("JSON解析错误: $e");
          }
        },
        onDone: () async {
          // 处理最终的完整结果
          if (finalResult != null) {
            // 这里可以处理 source、history 等完整信息
            // 例如：更新UI显示引用源
            if (finalResult!['source'] != null) {
              // 处理信息来源
            }
          }
          await finishChat();
        },
        onError: (error) async {
          commonPrint("请求异常: ${error.message}");
          _addMessageToChat("请求异常: ${error.message}，请稍后重试。");
          await finishChat();
        },
        cancelOnError: true,
      );
    } catch (e) {
      commonPrint('回复获取失败,原因是$e');
      _addMessageToChat("请求异常，请稍后重试。");
      await finishChat();
    }
  }

  Future<void> finishChat() async {
    var settings = await Config.loadSettings();
    String userId = settings['user_id'] ?? '';
    isAnswering = false;
    justCleanContext = false;
    tempInt = 0;
    String messagesJson = jsonEncode(messages.map((m) => m.toJson()).toList());
    await SupabaseHelper().update('chat_kb', {'chat_contents': messagesJson}, updateMatchInfo: {'user_id': userId});
  }

  // 聊天设置
  Future<void> _setChat(
      {isSingleChat = false,
      isSingleChatSet = false,
      isGlobalChatSet = false,
      ChangeSettings? settings,
      bool isKnowledgeBase = false}) async {
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
              padding: const EdgeInsets.all(10),
              child: ChatSettings(
                isSingleChat: isSingleChat,
                isSingleChatSet: isSingleChatSet,
                isGlobalChatSet: isGlobalChatSet,
                currentSettings: isSingleChatSet ? curChatSet : null,
                isKnowledgeMode: true,
                onConfirm: isSingleChat
                    ? (modelName) {
                        Navigator.of(context).pop();
                        showHint('当前聊天模型已更改为：$modelName', showType: 2);
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

  @override
  void initState() {
    super.initState();
    myApi = MyApi();
    listenStorage();
    initData();
  }

  void listenStorage() {
    box.listenKey('kb_model', (value) {
      setState(() {
        useAIModel = value;
      });
    });
    box.listenKey('kb_alwaysShowModelName', (value) {
      setState(() {
        alwaysShowModelName = value;
      });
    });
    box.listenKey('is_login', (value) {
      if (value == false) {
        setState(() {
          _kbListNotifier.value = [];
          messages = [];
        });
      } else {
        initData();
      }
    });
  }

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
    return SafeArea(
      child: Shortcuts(
          shortcuts: <LogicalKeySet, Intent>{
            LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (intent) => _sendMessage(_controller.text.trimRight())),
            },
            child: Container(
              color: settings.getBackgroundColor(),
              child: Row(
                children: [
                  if (showLeftPanel) ...[
                    Container(
                      width: width,
                      constraints: BoxConstraints(minWidth: width),
                      child: Column(
                        children: [
                          // 使用ValueListenableBuilder来异步加载ListView
                          Expanded(
                            child: ValueListenableBuilder<List<KBListData>>(
                              valueListenable: _kbListNotifier,
                              builder: (context, value, child) {
                                if (value.isEmpty) {
                                  return Center(
                                      child: Container(
                                    margin: const EdgeInsets.only(left: 6, right: 6),
                                    child: const Text('暂无知识库,点击下面的新建知识库吧'),
                                  ));
                                } else {
                                  return ListView.builder(
                                      itemCount: value.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: value[index].isSelected
                                                  ? settings.getSelectedBgColor()
                                                  : settings.getUnselectedBgColor(),
                                              borderRadius: const BorderRadius.all(
                                                Radius.circular(8),
                                              ),
                                            ),
                                            child: InkWell(
                                              onTap: () async {
                                                setState(() {
                                                  value[index].isSelected = !value[index].isSelected;
                                                });
                                                await changeSelectedStatus(value[index].id, value[index].isSelected);
                                              },
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.center, // 将Row的交叉轴对齐设置为居中
                                                children: [
                                                  Expanded(
                                                      child: Column(
                                                    children: [
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      Visibility(
                                                        visible: !value[index].isChangingName,
                                                        child: Text(
                                                          value[index].title,
                                                          style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 16,
                                                              color: settings.getCardTextColor()),
                                                        ),
                                                      ),
                                                      Visibility(
                                                        visible: value[index].isChangingName,
                                                        child: Padding(
                                                          padding: const EdgeInsets.only(left: 6),
                                                          child: Row(
                                                            children: [
                                                              Expanded(
                                                                  child: TextField(
                                                                      controller: kbChangeTitleController,
                                                                      style: TextStyle(color: settings.getForegroundColor()),
                                                                      decoration: InputDecoration(
                                                                          enabledBorder: const OutlineInputBorder(
                                                                            borderSide:
                                                                                BorderSide(color: Colors.white, width: 1.0),
                                                                          ),
                                                                          focusedBorder: const OutlineInputBorder(
                                                                            borderSide:
                                                                                BorderSide(color: Colors.white, width: 1.0),
                                                                          ),
                                                                          hintText: value[index].title,
                                                                          hintStyle:
                                                                              TextStyle(color: settings.getHintTextColor())))),
                                                              const SizedBox(
                                                                width: 5,
                                                              ),
                                                              InkWell(
                                                                onTap: () async {
                                                                  setState(() {
                                                                    value[index].isChangingName = false;
                                                                    value[index].title = kbChangeTitleController.text;
                                                                  });
                                                                  await changeKBTitle(value[index].id);
                                                                },
                                                                child: const Icon(
                                                                  Icons.done,
                                                                  color: Colors.white,
                                                                  size: 20,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 5,
                                                              ),
                                                              InkWell(
                                                                onTap: () {
                                                                  setState(() {
                                                                    value[index].isChangingName = false;
                                                                  });
                                                                },
                                                                //TODO 这里要修改icon颜色
                                                                child: const Icon(
                                                                  Icons.clear,
                                                                  color: Colors.white,
                                                                  size: 20,
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      Text(
                                                        '${value[index].filesNum}个文件',
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 14,
                                                            color: settings.getCardTextColor()),
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      Text(
                                                        '${value[index].createTime} 创建',
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 14,
                                                            color: settings.getCardTextColor()),
                                                      ),
                                                      Visibility(
                                                          visible: false,
                                                          child: Column(
                                                            children: [
                                                              const SizedBox(
                                                                height: 10,
                                                              ),
                                                              Text(
                                                                '${value[index].modifyTime} 修改',
                                                                style: TextStyle(
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 14,
                                                                    color: settings.getTextColor()),
                                                              ),
                                                            ],
                                                          )),
                                                      const SizedBox(
                                                        height: 10,
                                                      )
                                                    ],
                                                  )),
                                                  const SizedBox(
                                                    width: 3,
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 6, bottom: 6, right: 8),
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      // 将Column的主轴对齐设置为居中
                                                      children: [
                                                        SizedBox(
                                                          width: 24,
                                                          height: 24,
                                                          child: Tooltip(
                                                            message: '编辑',
                                                            child: InkWell(
                                                              onTap: () async {
                                                                final result = await Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                      builder: (context) => ModifyKnowledgeBasePage(
                                                                            kbTitle: value[index].title,
                                                                            kbId: value[index].id,
                                                                          )),
                                                                );
                                                                String kbId = result['id'];
                                                                int fileNum = result['file_num'];
                                                                for (int i = 0; i < _kbListNotifier.value.length; i++) {
                                                                  var kbInfo = _kbListNotifier.value[i];
                                                                  if (kbInfo.id == kbId) {
                                                                    setState(() {
                                                                      _kbListNotifier.value[i].filesNum = fileNum;
                                                                    });
                                                                    break;
                                                                  }
                                                                }
                                                              },
                                                              child: SvgPicture.asset('assets/images/modify.svg'),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        SizedBox(
                                                          width: 24,
                                                          height: 24,
                                                          child: Tooltip(
                                                            message: '重命名',
                                                            child: InkWell(
                                                              onTap: () {
                                                                setState(() {
                                                                  value[index].isChangingName = !value[index].isChangingName;
                                                                });
                                                              },
                                                              child: SvgPicture.asset('assets/images/rename.svg'),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        SizedBox(
                                                          width: 24,
                                                          height: 24,
                                                          child: Tooltip(
                                                            message: '删除',
                                                            child: InkWell(
                                                              onTap: () async {
                                                                String kbId = value[index].id;
                                                                showWarnDialog(kbId, index);
                                                              },
                                                              child: SvgPicture.asset('assets/images/new_delete.svg'),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      });
                                }
                              },
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 10, bottom: 10, left: 8, right: 8),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: settings.getBackgroundColor(),
                                      border: Border.all(
                                        color: Colors.grey,
                                        width: 1,
                                      ),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            child: Padding(
                                          padding: const EdgeInsets.only(left: 1, top: 1, bottom: 1),
                                          child: TextField(
                                              style: TextStyle(color: settings.getForegroundColor()),
                                              controller: kbTitleController,
                                              decoration: InputDecoration(
                                                border: const OutlineInputBorder(
                                                  borderSide: BorderSide.none,
                                                ),
                                                hintText: '知识库标题',
                                                hintStyle: TextStyle(color: settings.getHintTextColor()),
                                              )),
                                        )),
                                        const SizedBox(
                                          width: 3,
                                        ),
                                        _buildButton(
                                          label: '新建',
                                          onPressed: () async {
                                            await createKB();
                                          },
                                          backgroundColor: settings.getSelectedBgColor(),
                                        ),
                                        const SizedBox(
                                          width: 3,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (isMobile) ...[
                                const SizedBox(
                                  width: 8,
                                ),
                                SizedBox(
                                    width: 100,
                                    child: _buildButton(
                                        label: '开始聊天',
                                        onPressed: () {
                                          setState(() {
                                            _showLeftPanel = false;
                                          });
                                        },
                                        backgroundColor: settings.getSelectedBgColor())),
                                const SizedBox(
                                  width: 8,
                                ),
                              ]
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  // 可拖动的分割线
                  if (!isMobile || orientation == Orientation.landscape) ...[
                    GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _leftPanelWidth = (_leftPanelWidth + details.delta.dx).clamp(260.0, 360);
                        });
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeColumn,
                        child: Container(
                          width: 8, // 增加宽度便于拖动
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
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              physics: const ClampingScrollPhysics(),
                              padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0, bottom: 40),
                              itemCount: messages.length,
                              itemBuilder: (BuildContext context, int index) {
                                return ChatItem(
                                  message: messages[index],
                                  index: index,
                                  isInKB: true,
                                  isAnswering: isAnswering,
                                  onRetry: () {
                                    if (messages[index].isSentByMe) {
                                      if (index == messages.length - 1) {
                                        _sendMessage(messages[index].text, isRetry: true);
                                      } else {
                                        var curMessage = messages[index];
                                        var nextMessage = messages[index + 1];
                                        messages.remove(curMessage);
                                        messages.remove(nextMessage);
                                        messages.add(curMessage);
                                        _sendMessage(curMessage.text, isRetry: true);
                                        _scrollToBottom();
                                        setState(() {});
                                      }
                                    } else {
                                      if (index == messages.length - 1) {
                                        _sendMessage(messages[index - 1].text, isRetry: true);
                                        setState(() {
                                          messages.removeAt(index);
                                        });
                                      } else {
                                        var curMessage = messages[index];
                                        var preMessage = messages[index - 1];
                                        messages.remove(curMessage);
                                        messages.remove(preMessage);
                                        messages.add(preMessage);
                                        _sendMessage(preMessage.text, isRetry: true);
                                        _scrollToBottom();
                                        setState(() {});
                                      }
                                    }
                                  },
                                  onCopy: () {
                                    Clipboard.setData(ClipboardData(text: messages[index].text)).then((_) {
                                      showHint('内容已复制到剪切板', showType: 2);
                                    });
                                  },
                                  onDelete: () async {
                                    if (!isAnswering) {
                                      setState(() {
                                        messages.removeAt(index);
                                      });
                                      Map<String, dynamic> settings = await Config.loadSettings();
                                      String userId = settings['user_id'] ?? '';
                                      await SupabaseHelper().update(
                                          'chat_kb', {'chat_contents': jsonEncode(messages.map((m) => m.toJson()).toList())},
                                          updateMatchInfo: {'user_id': userId});
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                          Container(
                            height: 1, // 宽度为1
                            color: settings.getSelectedBgColor(), // 分割线颜色
                          ),
                          //这里添加几个操作按钮
                          Container(
                            margin: const EdgeInsets.only(left: 6, right: 6, top: 6),
                            child: ChatControls(
                              enableChatContext: enableChatContext,
                              enableNet: enableNet,
                              isOnBottom: isOnBottom,
                              useAIModel: useAIModel,
                              alwaysShowModelName: alwaysShowModelName,
                              isKnowledgeBase: true,
                              enableHybrid: enableHybrid,
                              onReturnList: () {
                                setState(() {
                                  _showLeftPanel = true;
                                });
                              },
                              onHybridChanged: (value) {
                                setState(() {
                                  enableHybrid = value;
                                });
                                showHint(value ? '已开启混合检索' : '已关闭混合检索', showType: 2);
                                curChatSet['kb_enableHybrid'] = value;
                              },
                              onChatContextChanged: (value) async {
                                setState(() {
                                  enableChatContext = value;
                                });
                                showHint(value ? '已开启聊天上下文' : '已关闭聊天上下文', showType: 2);
                                curChatSet['kb_enableChatContext'] = value;
                              },
                              onCleanContext: () {
                                if (enableChatContext) {
                                  justCleanContext = true;
                                  showHint('聊天上下文已清除', showType: 2);
                                } else {
                                  showHint('未启用聊天上下文，无需清除', showType: 4);
                                }
                              },
                              onNetChanged: (value) async {
                                setState(() {
                                  enableNet = value;
                                });
                                showHint(value ? '已开启联网' : '已关闭联网', showType: 2);
                                curChatSet['kb_enableNet'] = value;
                              },
                              onUploadFile: () {},
                              onChatSettings: () => {},
                              onModelSettings: () =>
                                  _setChat(isSingleChat: true, isGlobalChatSet: false, settings: settings, isKnowledgeBase: true),
                              onScrollToBottom: _scrollToBottom,
                              onShare: () {},
                              onCapture: () {},
                              onMask: () async {},
                              settings: settings,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(6),
                            // 外部边框和圆角
                            decoration: BoxDecoration(
                              border: Border.all(color: settings.getSelectedBgColor(), width: 2),
                              // 灰色宽度为1的边框
                              borderRadius: BorderRadius.circular(6), // 圆角为6
                            ),
                            padding: const EdgeInsets.all(8), // 内部留一些空间
                            child: Row(
                              crossAxisAlignment: _currentLines == 1 ? CrossAxisAlignment.center : CrossAxisAlignment.end,
                              children: [
                                // 使用Expanded使文本输入框填充左侧空间
                                Expanded(
                                  child: KeyboardListener(
                                    focusNode: FocusNode(),
                                    onKeyEvent: (event) {
                                      if (event.logicalKey == LogicalKeyboardKey.enter &&
                                          event.logicalKey == LogicalKeyboardKey.shift) {
                                        // 按下shift+enter键时插入换行符
                                        _controller.value = TextEditingValue(
                                          text: '${_controller.text}\n',
                                          selection: TextSelection.collapsed(offset: _controller.text.length + 1),
                                        );
                                      }
                                    },
                                    child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                                      // 获取TextField的实际可用宽度
                                      _textFieldWidth = constraints.maxWidth;
                                      return TextField(
                                        key: _textFieldKey,
                                        controller: _controller,
                                        maxLines: 10,
                                        // 最大行数为10
                                        minLines: 1,
                                        // 默认行数为3，即默认高度
                                        style: TextStyle(color: settings.getForegroundColor()),
                                        decoration: InputDecoration(
                                          hintText: 'enter键发送，shift+enter键换行',
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
                                        onChanged: (text) {
                                          // 计算基本的换行符行数
                                          int lineCount = '\n'.allMatches(text).length + 1;

                                          // 如果最后一个字符是换行符，需要多加一行
                                          if (text.isNotEmpty && text[text.length - 1] == '\n') {
                                            lineCount++;
                                          }

                                          // 考虑TextField的内边距
                                          double paddingHorizontal = 16.0; // 假设水平内边距为16
                                          double availableWidth = _textFieldWidth - paddingHorizontal * 2;

                                          // 使用TextPainter计算实际行数
                                          final TextPainter textPainter = TextPainter(
                                            text: TextSpan(
                                              text: text,
                                              style: TextStyle(color: settings.getForegroundColor()),
                                            ),
                                            maxLines: null,
                                            textDirection: ui.TextDirection.ltr,
                                          );

                                          // 使用实际可用宽度进行布局计算
                                          textPainter.layout(maxWidth: availableWidth);

                                          // 获取实际行数
                                          final int actualLineCount = textPainter.computeLineMetrics().length;

                                          setState(() {
                                            setState(() {
                                              _currentLines = actualLineCount > lineCount ? actualLineCount : lineCount;
                                            });
                                          });
                                        },
                                      );
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // 发送按钮
                                Align(
                                  alignment: Alignment.bottomRight, // 右下角对齐
                                  child: Tooltip(
                                    message: _controller.text.isEmpty
                                        ? '输入不能为空'
                                        : isAnswering
                                            ? '停止回复'
                                            : '点击发送',
                                    child: InkWell(
                                      onTap: () async {
                                        if (isAnswering) {
                                          _chatStreamSubscription?.cancel();
                                          await finishChat();
                                        } else {
                                          if (_controller.text.isNotEmpty) {
                                            String question = _controller.text;
                                            setState(() {
                                              _controller.clear();
                                            });
                                            _sendMessage(question);
                                          } else {
                                            showHint('请输入文字');
                                          }
                                        }
                                      },
                                      child: Container(
                                        width: 40.0,
                                        height: 40.0,
                                        decoration: BoxDecoration(
                                          color: (_controller.text.trimRight().isEmpty && !isAnswering)
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
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ],
              ),
            ),
          )),
    );
  }
}
