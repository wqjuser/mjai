import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/utils/common_methods.dart';
import '../config/config.dart';
import '../config/global_params.dart';
import 'common_dropdown.dart';
import 'my_text_field.dart';

class ChatSettings extends StatefulWidget {
  final bool isSingleChat;
  final bool isSingleChatSet;
  final bool isGlobalChatSet;
  final Map<String, dynamic>? currentSettings;
  final Function(String modelName)? onConfirm;
  final Function(Map<String, dynamic> singleChatSet)? onConfirmSingleChatSet;
  final String? modelName;
  final bool isKnowledgeMode;

  const ChatSettings(
      {super.key,
      this.isSingleChat = false,
      this.isSingleChatSet = false,
      this.isGlobalChatSet = true,
      this.currentSettings,
      this.onConfirm,
      this.onConfirmSingleChatSet,
      this.isKnowledgeMode = false,
      this.modelName});

  @override
  State<ChatSettings> createState() => _ChatSettingsState();
}

class _ChatSettingsState extends State<ChatSettings> {
  late Map<String, dynamic> globalChatSettings;
  String defaultModel = '自动选择';
  String defaultSize = '1024x1024';
  String defaultLanguage = '自动选择';
  String defaultGenerateTitleModel = '自动选择';
  bool autoGenerateTitle = true;
  bool alwaysShowModelName = false;
  bool enableNet = false;
  bool enablePrivateMode = true;
  bool showAdvancedParameters = false;
  bool enableChatContext = true;
  bool captureCloseWindow = false;
  List<String> availableModels = ['自动选择'];
  List<String> availableSizes = ['1024x1024', '768x1344', '1344x768', '864x1152', '1152x864', '1440x720', '720x1440'];
  List<String> availableVideoSizes = [
    '不指定',
    '720x480',
    '1024x1024',
    '1280x960',
    '960x1280',
    '1920x1080',
    '1080x1920',
    '2048x1080',
    '3840x2160'
  ];
  List<String> availableVideoDurations = ['5', '10'];
  String defaultVideoDuration = '5';
  List<String> availableVideoFPS = ['30', '60'];
  String defaultVideoFPS = '30';
  String defaultVideoSize = '不指定';
  List<String> availableLanguages = ['自动选择', '中文', '英语', '日语'];
  List<String> userAddModels = [];
  double _temValue = 0.6;
  final double _minTem = 0;
  final double _maxTem = 1.0;
  final int _temStep = 10;
  double _netSearchValue = 10;
  final double _minNetSearch = 1;
  final double _maxNetSearch = 10;
  final int _netSearchStep = 9;
  double _topPValue = 1.0;
  final double _minTopP = 0;
  final double _maxTopP = 1.0;
  final int _topPStep = 10;
  double _ppValue = 0.0;
  final double _minPp = -2.0;
  final double _maxPp = 2.0;
  final int _pPStep = 40;
  double _fpValue = 0.0;
  final double _minFp = -2.0;
  final double _maxFp = 2.0;
  final int _fPStep = 40;
  double _withContextValue = 5.0;
  final double _minWithContext = -0.0;
  final double _maxWithContext = 10.0;
  final int _withContextStep = 10;
  String chatBaseUrl = '';
  String chatMaxTokens = '2048';
  String chatApiKey = '';
  String useNetUrl = '';
  String privateModeKey = '';
  TextEditingController chatUrlController = TextEditingController(text: '');
  TextEditingController chatMaxTokensController = TextEditingController(text: '2048');
  TextEditingController chatKeyController = TextEditingController(text: '');
  TextEditingController userModelsController = TextEditingController(text: '');
  TextEditingController userNetUrlController = TextEditingController(text: '');
  TextEditingController privateModeKeyController = TextEditingController(text: '');
  bool isSingleChat = false;
  bool isSingleChatSet = false;
  Map<String, dynamic>? currentSettings = {};
  final box = GetStorage();
  bool isKnowledgeMode = false;
  bool isAiSound = false;
  String selectedImage = '';

  void initSettings() async {
    if (!isKnowledgeMode) {
      Map<String, dynamic> settings = await Config.loadSettings();
      userAddModels = List<String>.from(settings['chatSettings_userAddModels'] ?? []);
      alwaysShowModelName = settings['chatSettings_alwaysShowModelName'] ?? true;
      for (int i = 0; i < GlobalParams.aiModels.length; i++) {
        availableModels.add(GlobalParams.aiModels[i]['model_name']);
      }
      if (widget.isGlobalChatSet) {
        defaultModel = settings['chatSettings_defaultModel'] ?? '自动选择';
        defaultSize = settings['chatSettings_defaultImageSize'] ?? '1024x1024';
        autoGenerateTitle = settings['chatSettings_autoGenerateTitle'] ?? true;
        captureCloseWindow = settings['chatSettings_captureCloseWindow'] ?? false;
        defaultGenerateTitleModel = settings['chatSettings_defaultGenerateTitleModel'] ?? '自动选择';
        defaultLanguage = settings['chatSettings_defaultLanguage'] ?? '自动选择';
        enableNet = settings['chatSettings_enableNet'] ?? false;
        enableChatContext = settings['chatSettings_enableChatContext'] ?? true;
        enablePrivateMode = settings['chatSettings_enablePrivateMode'] ?? true;
        _temValue = settings['chatSettings_tem'] ?? 0.6;
        _netSearchValue = settings['chatSettings_netSearch'] ?? 10;
        _topPValue = settings['chatSettings_top_p'] ?? 1.0;
        _ppValue = settings['chatSettings_pp'] ?? 0.0;
        _fpValue = settings['chatSettings_fp'] ?? 0.0;
        _withContextValue = settings['chatSettings_withContextValue'] ?? 4.0;
        chatBaseUrl = settings['chatSettings_apiUrl'] ?? settings['chat_api_url'] ?? '';
        chatMaxTokens = settings['chatSettings_maxTokens'] ?? '2048';
        chatApiKey = settings['chatSettings_apiKey'] ?? settings['chat_api_key'] ?? '';
        useNetUrl = settings['chatSettings_useNetUrl'] ?? '';
        privateModeKey = settings['chatSettings_privateModeKey'] ?? '';
        chatUrlController.text = chatBaseUrl;
        chatKeyController.text = chatApiKey;
        userNetUrlController.text = useNetUrl;
        chatMaxTokensController.text = chatMaxTokens;
        privateModeKeyController.text = privateModeKey;
        String userModels = '';
        for (int i = 0; i < userAddModels.length; i++) {
          if (i != userAddModels.length - 1) {
            userModels += ('${userAddModels[i]},');
          } else {
            userModels += userAddModels[i];
          }
        }
        userModelsController.text = userModels;
      }
      if (currentSettings != null) {
        defaultModel = currentSettings!['chatSettings_defaultModel'] ?? '自动选择';
        defaultSize = currentSettings!['chatSettings_defaultImageSize'] ?? '1024x1024';
        autoGenerateTitle = currentSettings!['chatSettings_autoGenerateTitle'] ?? true;
        captureCloseWindow = currentSettings!['chatSettings_captureCloseWindow'] ?? false;
        defaultLanguage = currentSettings!['chatSettings_defaultLanguage'] ?? '自动选择';
        alwaysShowModelName = currentSettings!['chatSettings_alwaysShowModelName'] ?? true;
        enablePrivateMode = currentSettings!['chatSettings_enablePrivateMode'] ?? true;
        defaultGenerateTitleModel = currentSettings!['chatSettings_defaultGenerateTitleModel'] ?? '自动选择';
        enableNet = currentSettings!['chatSettings_enableNet'] ?? false;
        enableChatContext = currentSettings!['chatSettings_enableChatContext'] ?? true;
        _temValue = currentSettings!['chatSettings_tem'] ?? 0.6;
        _netSearchValue = currentSettings!['chatSettings_netSearch'] ?? 10;
        _topPValue = currentSettings!['chatSettings_top_p'] ?? 1.0;
        _ppValue = currentSettings!['chatSettings_pp'] ?? 0.0;
        _fpValue = currentSettings!['chatSettings_fp'] ?? 0.0;
        _withContextValue = currentSettings!['chatSettings_withContextValue'] ?? 4.0;
        chatMaxTokens = currentSettings!['chatSettings_maxTokens'] ?? '2048';
      }
      if (widget.modelName != null) {
        defaultModel = widget.modelName!;
      }
      if (isSingleChat || isSingleChatSet) {
        availableModels.addAll(userAddModels);
      }
      setState(() {
        chatMaxTokensController.text = chatMaxTokens;
      });
    } else {
      availableModels = ['QAnything 16k', 'QAnything 4o mini', 'QAnything 4o'];
      defaultModel = 'QAnything 16k';
      if (currentSettings != null) {
        defaultModel = currentSettings!['chatSettings_defaultModel'] ?? 'QAnything 16k';
      }
    }
  }

  void changeDefaultModel(String modelName) async {
    setState(() {
      defaultModel = modelName;
      selectedImage = '';
    });
    if (!isKnowledgeMode) {
      if (widget.isGlobalChatSet) {
        Map<String, dynamic> settings = {
          'chatSettings_defaultModel': modelName,
        };
        await Config.saveSettings(settings);
      }
      box.write('chatSettings_defaultModel', modelName);
      if (isSingleChatSet) {
        currentSettings!['useAIModel'] = defaultModel;
      }
    } else {
      box.write('kb_model', defaultModel);
    }
  }

  void changeVideoSize(String videoSize) async {
    defaultVideoSize = videoSize;
    if (!isKnowledgeMode) {
      box.write('chatSettings_defaultVideoSize', videoSize);
    }
  }

  void changeDefaultSize(String sizeName) async {
    defaultSize = sizeName;
    if (!isKnowledgeMode) {
      if (widget.isGlobalChatSet) {
        Map<String, dynamic> settings = {
          'chatSettings_defaultImageSize': sizeName,
        };
        await Config.saveSettings(settings);
      }
      box.write('chatSettings_defaultImageSize', sizeName);
      if (isSingleChatSet) {
        currentSettings!['useImageSize'] = defaultSize;
      }
    }
  }

  void changeVideoDuration(String durationName) {
    defaultVideoDuration = durationName;
    if (!isKnowledgeMode) {
      box.write('chatSettings_defaultVideoDuration', durationName);
    }
  }

  void changeVideoFPS(String fPSName) {
    defaultVideoFPS = fPSName;
    if (!isKnowledgeMode) {
      box.write('chatSettings_defaultVideoFPS', fPSName);
    }
  }

  void changeDefaultLanguage(String languageName) async {
    defaultLanguage = languageName;
    if (widget.isGlobalChatSet) {
      Map<String, dynamic> settings = {
        'chatSettings_defaultLanguage': defaultLanguage,
      };
      await Config.saveSettings(settings);
    }
    if (isSingleChatSet) {
      currentSettings!['defaultLanguage'] = defaultLanguage;
    }
    box.write('chatSettings_defaultLanguage', defaultLanguage);
  }

  void changeDefaultGenerateTitleModel(String modelName) async {
    defaultGenerateTitleModel = modelName;
    Map<String, dynamic> settings = {
      'chatSettings_defaultGenerateTitleModel': modelName,
    };
    await Config.saveSettings(settings);
    if (isSingleChatSet) {
      currentSettings!['chatSettings_defaultGenerateTitleModel'] = modelName;
    }
    box.write('chatSettings_defaultGenerateTitleModel', modelName);
  }

  @override
  void initState() {
    super.initState();
    isSingleChat = widget.isSingleChat;
    isSingleChatSet = widget.isSingleChatSet;
    currentSettings = widget.currentSettings;
    isKnowledgeMode = widget.isKnowledgeMode;
    initSettings();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    final bool isMobile = Platform.isAndroid || Platform.isIOS;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 24),
      decoration: BoxDecoration(
        color: settings.getBackgroundColor(),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(settings),
            const SizedBox(height: 16),
            _buildBaseSettings(settings),
            if (!isSingleChat) ...[
              const SizedBox(height: 16),
              _buildPrivacySettings(settings),
              const SizedBox(height: 16),
              _buildAdvancedSettings(settings),
              const SizedBox(height: 16),
              _buildNetworkSettings(settings),
              _buildApiSettings(settings),
              _buildAdvancedParameters(settings),
              _buildConfirmButton(settings),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ChangeSettings settings) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: settings.getForegroundColor().withAlpha(25),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isSingleChat ? '当前聊天模型设置' : (isSingleChatSet ? '当前聊天设置' : '全局聊天设置'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: settings.getForegroundColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoParams(ChangeSettings settings) {
    //生成视频的参数视图
    return Visibility(
      visible: isSingleChat && (defaultModel.contains('视频')),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.0),
              color: settings.getBackgroundColor().withAlpha(128),
              border: Border.all(
                color: settings.getForegroundColor().withAlpha(25),
                width: 1.0,
              ),
            ),
            child: selectedImage == ''
                ? Center(
                    child: InkWell(
                    child: Tooltip(
                      message: '上传图片(大小在5M以内,可选,不选是文生视频,选择是图生视频)',
                      child: Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: settings.getSelectedBgColor(),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: SvgPicture.asset(
                          'assets/images/upload_image.svg',
                          semanticsLabel: '上传图片',
                          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                        ),
                      ),
                    ),
                    onTap: () async {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'png', 'jpeg']);
                      if (result != null) {
                        String imagePath = result.files.single.path!;
                        String base64Path = await imageToBase64(imagePath);
                        String compress = await compressBase64Image(base64Path);
                        setState(() {
                          selectedImage = compress;
                        });
                        await box.write('chatSettings_videoImagePath', imagePath);
                      }
                    },
                  ))
                : Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6.0),
                          image: DecorationImage(
                            image: MemoryImage(base64Decode(selectedImage)),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          InkWell(
                            child: Tooltip(
                              message: '换一张图片',
                              child: Container(
                                width: 40,
                                height: 40,
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: settings.getSelectedBgColor(),
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: SvgPicture.asset(
                                  'assets/images/upload_image.svg',
                                  semanticsLabel: '换一张图片',
                                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                ),
                              ),
                            ),
                            onTap: () async {
                              FilePickerResult? result = await FilePicker.platform
                                  .pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'png', 'jpeg']);
                              if (result != null) {
                                String imagePath = result.files.single.path!;
                                String base64Path = await imageToBase64(imagePath);
                                String compress = await compressBase64Image(base64Path);
                                setState(() {
                                  selectedImage = compress;
                                });
                                await box.write('chatSettings_videoImagePath', imagePath);
                              }
                            },
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            child: Tooltip(
                              message: '删除此图片',
                              child: Container(
                                width: 40,
                                height: 40,
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: settings.getSelectedBgColor(),
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: SvgPicture.asset(
                                  'assets/images/delete.svg',
                                  semanticsLabel: '删除此图片',
                                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                ),
                              ),
                            ),
                            onTap: () async {
                              setState(() {
                                selectedImage = '';
                              });
                              await box.write('chatSettings_videoImagePath', '');
                            },
                          ),
                        ])),
                      )
                    ],
                  ),
          ),
          Visibility(
              visible: selectedImage.isNotEmpty,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    settings,
                    title: '视频尺寸',
                    child: CommonDropdownWidget(
                      dropdownData: availableVideoSizes,
                      selectedValue: defaultVideoSize,
                      onChangeValue: changeVideoSize,
                    ),
                  ),
                ],
              )),
          Visibility(
              visible: selectedImage.isNotEmpty,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildSettingItem(settings,
                      title: '视频时长(秒)',
                      child: CommonDropdownWidget(
                        dropdownData: availableVideoDurations,
                        selectedValue: defaultVideoDuration,
                        onChangeValue: changeVideoDuration,
                      )),
                ],
              )),
          Visibility(
              visible: selectedImage.isNotEmpty,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildSettingItem(settings,
                      title: '视频帧率(FPS)',
                      child: CommonDropdownWidget(
                        dropdownData: availableVideoFPS,
                        selectedValue: defaultVideoFPS,
                        onChangeValue: changeVideoFPS,
                      )),
                ],
              )),
          const SizedBox(height: 16),
          _buildSettingItem(settings,
              title: 'AI 音效',
              hasTooltip: true,
              tooltipMessage: '是否生成 AI 音效',
              isSwitch: true,
              child: Switch(
                value: isAiSound,
                onChanged: (value) async {
                  setState(() {
                    isAiSound = value;
                  });
                  if (!isKnowledgeMode) {
                    box.write('chatSettings_isAiSound', value);
                  }
                },
              )),
          // const SizedBox(height: 16),
          // _buildSettingItem(
          //   settings,
          //   title: '视频质量',
          //   child: CommonDropdownWidget(
          //     dropdownData: availableVideoQualities,
          //     selectedValue: defaultVideoQuality,
          //     onChangeValue: changeDefaultVideoQuality,
          //   ),
          // ),
          // const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBaseSettings(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 模型选择
        _buildSettingItem(
          settings,
          title: isSingleChat ? '当前聊天模型选择' : (isSingleChatSet ? '当前聊天模型选择' : '默认聊天使用模型'),
          child: CommonDropdownWidget(
            dropdownData: availableModels,
            selectedValue: defaultModel,
            onChangeValue: changeDefaultModel,
          ),
        ),
        Visibility(
          visible: defaultModel.contains('免费绘图') || widget.isGlobalChatSet,
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildSettingItem(
                settings,
                title: isSingleChat ? '当前绘图尺寸选择' : (isSingleChatSet ? '当前绘图尺寸选择' : '默认绘图尺寸选择'),
                child: CommonDropdownWidget(
                  dropdownData: availableSizes,
                  selectedValue: defaultSize,
                  onChangeValue: changeDefaultSize,
                ),
              ),
            ],
          ),
        ),
        _buildVideoParams(settings),
        Visibility(
            visible: Platform.isWindows || Platform.isMacOS,
            child: Column(
              children: [
                const SizedBox(height: 16),
                // 显示模型名称开关
                _buildSettingItem(
                  settings,
                  title: '总是显示模型名称',
                  hasTooltip: true,
                  tooltipMessage: '开启时聊天界面下方会完整显示当前使用的模型名称',
                  isSwitch: true,
                  child: Switch(
                    value: alwaysShowModelName,
                    onChanged: (value) async {
                      setState(() {
                        alwaysShowModelName = value;
                      });
                      if (!isKnowledgeMode) {
                        box.write('chatSettings_alwaysShowModelName', value);
                        if (!isSingleChat) {
                          Map<String, dynamic> settings = {
                            'chatSettings_alwaysShowModelName': value,
                          };
                          await Config.saveSettings(settings);
                        }
                      } else {
                        box.write('kb_alwaysShowModelName', value);
                      }
                    },
                    activeTrackColor: settings.getSelectedBgColor().withAlpha(51),
                    activeColor: settings.getSelectedBgColor(),
                  ),
                ),
              ],
            )),

        const SizedBox(height: 16),
        if (!isKnowledgeMode && Platform.isWindows && !isSingleChat) ...[
          _buildSettingItem(
            settings,
            title: '截图时最小化此应用',
            hasTooltip: true,
            tooltipMessage: '开启后会最小化此应用，避免截屏时截取到此应用',
            isSwitch: true,
            child: Switch(
              value: captureCloseWindow,
              onChanged: (value) async {
                setState(() {
                  captureCloseWindow = value;
                });
                if (!isKnowledgeMode) {
                  await box.write('chatSettings_captureCloseWindow', value);
                  Map<String, dynamic> settings = {
                    'chatSettings_captureCloseWindow': value,
                  };
                  await Config.saveSettings(settings);
                }
              },
              activeTrackColor: settings.getSelectedBgColor().withAlpha(51),
              activeColor: settings.getSelectedBgColor(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        // 语言设置（仅在非单聊模式下显示）
        if (!isSingleChat)
          _buildSettingItem(
            settings,
            title: 'AI默认回复语言',
            child: CommonDropdownWidget(
              dropdownData: availableLanguages,
              selectedValue: defaultLanguage,
              onChangeValue: changeDefaultLanguage,
            ),
          ),
      ],
    );
  }

  Widget _buildSettingItem(
    ChangeSettings settings, {
    required String title,
    required Widget child,
    bool hasTooltip = false,
    String tooltipMessage = '',
    bool isSwitch = false,
  }) {
    final bool isMobile = Platform.isAndroid || Platform.isIOS;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: settings.getBackgroundColor().withAlpha(128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: settings.getForegroundColor().withAlpha(25),
        ),
      ),
      child: isMobile && !isSwitch
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        color: settings.getForegroundColor(),
                      ),
                    ),
                    if (hasTooltip) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: tooltipMessage,
                        child: Icon(
                          Icons.info_outlined,
                          size: 16,
                          color: settings.getForegroundColor().withAlpha(128),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: child,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          color: settings.getForegroundColor(),
                        ),
                      ),
                      if (hasTooltip) ...[
                        const SizedBox(width: 8),
                        Tooltip(
                          message: tooltipMessage,
                          child: Icon(
                            Icons.info_outlined,
                            size: 16,
                            color: settings.getForegroundColor().withAlpha(128),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  width: isSwitch ? 60 : 300,
                  child: child,
                ),
              ],
            ),
    );
  }

  Widget _buildPrivacySettings(ChangeSettings settings) {
    if (isSingleChat || isKnowledgeMode) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingItem(
          settings,
          title: '隐私模式',
          hasTooltip: true,
          tooltipMessage: '开启后会对聊天内容进行加密处理，除你之外任何人无法查看，但无法搜索聊天记录',
          isSwitch: true,
          child: Switch(
            value: enablePrivateMode,
            onChanged: (value) async {
              setState(() {
                enablePrivateMode = value;
              });
              if (!isKnowledgeMode) {
                box.write('chatSettings_enablePrivateMode', value);
                Map<String, dynamic> settings = {
                  'chatSettings_enablePrivateMode': value,
                };
                await Config.saveSettings(settings);
              } else {
                box.write('kb_privateMode', value);
              }
            },
            activeTrackColor: settings.getSelectedBgColor().withAlpha(51),
            activeColor: settings.getSelectedBgColor(),
          ),
        ),
        // 隐私模式密钥输入框
        if (enablePrivateMode && !isKnowledgeMode && widget.isGlobalChatSet) ...[
          const SizedBox(height: 16),
          _buildInputField(
            settings,
            title: '隐私模式加密密钥',
            controller: privateModeKeyController,
            labelText: '隐私模式加密key，请自行设置，如果为空，隐私模式将不会生效',
            onChanged: (value) async {
              box.write('chatSettings_privateModeKey', value);
              await Config.saveSettings({
                'chatSettings_privateModeKey': value,
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedSettings(ChangeSettings settings) {
    if (!isSingleChat && !isSingleChatSet && !widget.isGlobalChatSet) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 自动更新标题设置
        _buildSettingItem(
          settings,
          title: '自动更新聊天标题',
          hasTooltip: true,
          tooltipMessage: '根据聊天内容自动更新聊天标题',
          isSwitch: true,
          child: Switch(
            value: autoGenerateTitle,
            onChanged: (value) async {
              setState(() {
                autoGenerateTitle = value;
              });
              box.write('chatSettings_autoGenerateTitle', value);
              if (widget.isGlobalChatSet) {
                await Config.saveSettings({
                  'chatSettings_autoGenerateTitle': value,
                });
              }
            },
            activeTrackColor: settings.getSelectedBgColor().withAlpha(51),
            activeColor: settings.getSelectedBgColor(),
          ),
        ),
        const SizedBox(height: 16),

        // 更新标题使用的模型选择
        if (autoGenerateTitle)
          _buildSettingItem(
            settings,
            title: '更新标题使用模型',
            child: CommonDropdownWidget(
              dropdownData: availableModels,
              selectedValue: defaultGenerateTitleModel,
              onChangeValue: changeDefaultGenerateTitleModel,
            ),
          ),
        if (autoGenerateTitle) const SizedBox(height: 16),

        // 聊天上下文设置
        _buildSettingItem(
          settings,
          title: '启用聊天上下文',
          hasTooltip: true,
          tooltipMessage: '启用聊天上下文可以让聊天过程保持一定程度的连续性',
          isSwitch: true,
          child: Switch(
            value: enableChatContext,
            onChanged: (value) async {
              setState(() {
                enableChatContext = value;
              });
              box.write('chatSettings_enableChatContext', value);
              if (widget.isGlobalChatSet) {
                await Config.saveSettings({
                  'chatSettings_enableChatContext': value,
                });
              }
            },
            activeTrackColor: settings.getSelectedBgColor().withAlpha(51),
            activeColor: settings.getSelectedBgColor(),
          ),
        ),
        const SizedBox(height: 16),

        // 上下文数量滑块
        if (enableChatContext)
          _buildSliderItem(
            settings,
            title: '携带上下文条数',
            tooltip: '这个值越大，聊天上下文记忆越多，但是消耗Token也越大',
            value: _withContextValue,
            min: _minWithContext,
            max: _maxWithContext,
            divisions: _withContextStep,
            onChanged: (value) async {
              setState(() {
                _withContextValue = value;
              });
              box.write('chatSettings_withContextValue', value);
              if (widget.isGlobalChatSet) {
                await Config.saveSettings({
                  'chatSettings_withContextValue': value,
                });
              }
            },
            displayValue: _withContextValue.toInt().toString(),
          ),
      ],
    );
  }

  Widget _buildSliderItem(
    ChangeSettings settings, {
    required String title,
    required String tooltip,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
    required String displayValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: settings.getBackgroundColor().withAlpha(128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: settings.getForegroundColor().withAlpha(25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: settings.getForegroundColor(),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: tooltip,
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: settings.getForegroundColor().withAlpha(128),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 45,
                alignment: Alignment.center,
                child: Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 16,
                    color: settings.getForegroundColor(),
                  ),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: getRealDarkMode(settings) ? settings.getSelectedBgColor() : GlobalParams.themeColor,
                    inactiveTrackColor: getRealDarkMode(settings)
                        ? settings.getSelectedBgColor().withAlpha(51)
                        : GlobalParams.themeColor.withAlpha(51),
                    thumbColor: getRealDarkMode(settings) ? settings.getSelectedBgColor() : GlobalParams.themeColor,
                    overlayColor: getRealDarkMode(settings)
                        ? settings.getSelectedBgColor().withAlpha(25)
                        : GlobalParams.themeColor.withAlpha(25),
                  ),
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: divisions,
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkSettings(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 聊天联网开关
        _buildSettingItem(
          settings,
          title: '聊天联网',
          hasTooltip: true,
          tooltipMessage: GlobalParams.isFreeVersion ? '启用聊天联网需要搭建联网服务，阅读说明书了解如何搭建' : '启用后会先对输入内容进行联网搜索，请谨慎使用',
          isSwitch: true,
          child: Switch(
            value: enableNet,
            onChanged: (value) async {
              if (isSingleChatSet && defaultModel.contains('联网')) {
                enableNet = false;
                showHint('当前模型自带联网,无需开启系统联网');
              } else {
                setState(() => enableNet = value);
                box.write('chatSettings_enableNet', value);
                if (widget.isGlobalChatSet) {
                  await Config.saveSettings({
                    'chatSettings_enableNet': value,
                  });
                }
              }
            },
            activeTrackColor: GlobalParams.themeColor,
            activeColor: settings.getSelectedBgColor(),
          ),
        ),

        // 联网服务配置（条件显示）
        if (enableNet && widget.isGlobalChatSet && (GlobalParams.isAdminVersion || GlobalParams.isFreeVersion)) ...[
          const SizedBox(height: 16),
          _buildInputField(
            settings,
            title: '联网服务地址',
            controller: userNetUrlController,
            labelText: '联网服务地址，阅读说明书搭建服务，若留空无法使用聊天联网',
            onChanged: (value) async {
              box.write('chatSettings_useNetUrl', value);
              await Config.saveSettings({
                'chatSettings_useNetUrl': value,
              });
            },
          ),
          const SizedBox(height: 16),
          _buildSliderItem(
            settings,
            title: '联网查询数量',
            tooltip: '这个值越大，查询结果越多',
            value: _netSearchValue,
            min: _minNetSearch,
            max: _maxNetSearch,
            divisions: _netSearchStep,
            onChanged: (value) async {
              setState(() => _netSearchValue = value);
              if (widget.isGlobalChatSet) {
                await Config.saveSettings({
                  'chatSettings_netSearch': double.parse(value.toStringAsFixed(0)),
                });
              }
            },
            displayValue: _netSearchValue.toInt().toString(),
          ),
        ],
      ],
    );
  }

  Widget _buildApiSettings(ChangeSettings settings) {
    if (!widget.isGlobalChatSet || (!GlobalParams.isFreeVersion && !GlobalParams.isAdminVersion)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'API配置',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: settings.getForegroundColor(),
              ),
            ),
          ),
          _buildInputField(
            settings,
            title: '自定义接口地址',
            controller: chatUrlController,
            labelText: '需要完整的http(s)接口地址',
            onChanged: (value) async {
              box.write('chatSettings_apiUrl', value);
              await Config.saveSettings({
                'chatSettings_apiUrl': value,
              });
            },
          ),
          const SizedBox(height: 16),
          _buildInputField(
            settings,
            title: '接口的请求密钥',
            controller: chatKeyController,
            labelText: '通常是以sk开头的密钥',
            onChanged: (value) async {
              box.write('chatSettings_apiKey', value);
              await Config.saveSettings({
                'chatSettings_apiKey': value,
              });
            },
          ),
          Visibility(
              visible: false,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildInputField(
                    settings,
                    title: '添加自定义模型',
                    controller: userModelsController,
                    labelText: '自定义模型名称，多个模型使用英文的逗号隔开',
                    onChanged: (value) async {
                      if (value.isNotEmpty) {
                        List<String> userModels = value.split(',');
                        await Config.saveSettings({
                          'chatSettings_userAddModels': userModels,
                        });
                      } else {
                        await Config.saveSettings({
                          'chatSettings_userAddModels': [],
                        });
                      }
                    },
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildInputField(
    ChangeSettings settings, {
    required String title,
    required TextEditingController controller,
    required String labelText,
    required Function(String) onChanged,
    TextInputType? keyboardType,
    bool hasTooltip = false,
    String? tooltipMessage,
    bool isShow = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: settings.getBackgroundColor().withAlpha(128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: settings.getForegroundColor().withAlpha(25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: settings.getForegroundColor(),
            ),
          ),
          const SizedBox(height: 12),
          MyTextField(
            style: TextStyle(color: settings.getForegroundColor()),
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            isShow: isShow,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              labelText: labelText,
              labelStyle: TextStyle(
                color: settings.getForegroundColor().withAlpha(178),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedParameters(ChangeSettings settings) {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 高级参数标题
          Row(
            children: [
              Text(
                '高级参数设置',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: settings.getForegroundColor(),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: Colors.amber,
              ),
              const Text(
                ' 请谨慎修改',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 最大Token输入
          _buildInputField(
            settings,
            title: '单次回复最大Token值',
            controller: chatMaxTokensController,
            labelText: '单次回复最大Token值，请根据具体模型来修改这个值',
            hasTooltip: true,
            isShow: true,
            tooltipMessage: '单次聊天完成最大可返回的Token数量，请根据具体模型来修改这个值',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) async {
              box.write('chatSettings_maxTokens', value);
              await Config.saveSettings({
                'chatSettings_maxTokens': value,
              });
            },
          ),
          const SizedBox(height: 16),

          // Temperature设置
          _buildSliderItem(
            settings,
            title: '随机性',
            tooltip: '这个值越大，AI的回复越随机',
            value: _temValue,
            min: _minTem,
            max: _maxTem,
            divisions: _temStep,
            onChanged: (value) async {
              setState(() => _temValue = value);
              box.write('chatSettings_tem', value);
              if (widget.isGlobalChatSet) {
                await Config.saveSettings({
                  'chatSettings_tem': value,
                });
              }
            },
            displayValue: _temValue.toStringAsFixed(1),
          ),
          const SizedBox(height: 16),

          // Top P设置
          _buildSliderItem(
            settings,
            title: '核采样',
            tooltip: '与随机性类似，但是不要同时更改这两个值',
            value: _topPValue,
            min: _minTopP,
            max: _maxTopP,
            divisions: _topPStep,
            onChanged: (value) async {
              setState(() => _topPValue = value);
              box.write('chatSettings_top_p', value);
              if (widget.isGlobalChatSet) {
                await Config.saveSettings({
                  'chatSettings_top_p': value,
                });
              }
            },
            displayValue: _topPValue.toStringAsFixed(1),
          ),
          const SizedBox(height: 16),

          // Presence Penalty设置
          _buildSliderItem(
            settings,
            title: '话题新鲜度',
            tooltip: '这个值越大，越容易扩展到新话题，一般不要修改',
            value: _ppValue,
            min: _minPp,
            max: _maxPp,
            divisions: _pPStep,
            onChanged: (value) async {
              setState(() => _ppValue = value);
              box.write('chatSettings_pp', value);
              if (widget.isGlobalChatSet) {
                await Config.saveSettings({
                  'chatSettings_pp': value,
                });
              }
            },
            displayValue: _ppValue.toStringAsFixed(1),
          ),
          const SizedBox(height: 16),

          // Frequency Penalty设置
          _buildSliderItem(
            settings,
            title: '频率惩罚度',
            tooltip: '这个值越大，越容易降低重复字词，一般不要修改',
            value: _fpValue,
            min: _minFp,
            max: _maxFp,
            divisions: _fPStep,
            onChanged: (value) async {
              setState(() => _fpValue = value);
              box.write('chatSettings_fp', value);
              if (widget.isGlobalChatSet) {
                await Config.saveSettings({
                  'chatSettings_fp': value,
                });
              }
            },
            displayValue: _fpValue.toStringAsFixed(1),
          ),
        ],
      ),
    );
  }

// 确认按钮（仅在单聊模式下显示）
  Widget _buildConfirmButton(ChangeSettings settings) {
    if (!isSingleChat) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 32),
      child: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: settings.getSelectedBgColor(),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
          onPressed: () {
            if (isSingleChat) {
              widget.onConfirm!(defaultModel);
            } else {
              widget.onConfirmSingleChatSet!(currentSettings!);
            }
          },
          child: const Text(
            '确认',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
