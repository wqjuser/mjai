import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/global_params.dart';
import 'package:tuitu/json_models/chat_web_response_entity.dart';
import 'package:tuitu/params/fooocus_translate.dart';
import 'package:tuitu/utils/my_openai_client.dart';
import 'package:tuitu/utils/supabase_helper.dart';
import 'package:tuitu/widgets/common_dropdown.dart';
import '../config/change_settings.dart';
import '../net/my_api.dart';
import '../config/config.dart';
import '../utils/common_methods.dart';
import '../utils/file_picker_manager.dart';
import '../utils/landscape_stateful_mixin.dart';
import '../utils/utils.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../widgets/after_detail_option.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/my_text_field.dart';

@Deprecated('Use /pages/settings/view/settings_page instead')
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with LandscapeStatefulMixin {
  int _selectedMode = 0;
  int _chatGPTSelectedMode = 0;
  int _drawEngine = 0;
  int _mjDrawSpeedType = 0;
  int _voiceSelectedMode = 0;
  int _lumaSelectedMode = 0;
  int _exitAppMode = -1;
  int _slowDrawCanUseTimes = 0;
  int _fastDrawCanUseTimes = 0;
  int _extraDrawCanUseTimes = 0;
  String _sdUrl = '';
  String _chatWebProxy = '';
  String _defaultModel = '';
  String _defaultFSModel = '';
  String _defaultFSREModel = 'None';
  String _defaultVae = '';
  String _sampler = '';
  String _hiresFixSampler = '';
  bool _isMixPrompt = false;
  bool _isSelfPositivePrompt = false;
  bool _isSelfNegativePrompt = false;
  bool _isUseFaceStore = false;
  bool _isHiresFix = false;
  bool _useADetail = false;
  bool _remixAutoSubmit = false;
  bool _joinAccountPool = false;
  bool _haveMJAccount = false;
  String _selectedOption = '0.无';
  final List<String> _loras = ['请先获取可用Lora列表'];
  String _selectedLora = '请先获取可用Lora列表';
  final List<String> _models = ['请先获取可用模型列表'];
  String _selectedModel = '请先获取可用模型列表';
  final List<String> _fsmodels = ['请先获取可用模型列表'];
  String _selectedFSModel = '请先获取可用模型列表';
  final List<String> _fsstyles = [];
  List<String> _selectedFSStyle = ['Fooocus V2提示词智能扩展', 'Fooocus-杰作', 'Fooocus-优化增强'];
  final List<String> _fsREmodels = ['请先获取可用精炼模型列表'];
  String _selectedFSREModel = '请先获取可用精炼模型列表';
  final List<String> _fsQulalities = ['速度', '质量'];
  String _selectedFSQulality = '速度';
  final List<String> _vaes = ['请先获取可用vae列表'];
  String _selectedVae = '请先获取可用vae列表';
  final List<String> _samplers = ['Euler a'];
  String _selectedSampler = 'Euler a';
  final List<String> _upscalers = ['Latent'];
  String _selectedUpscalers = 'Latent';
  final List<String> _options = ['0.无', '1.基本提示(通用)', '2.基本提示(通用修手)', '3.基本提示(增加细节1)', '4.基本提示(增加细节2)', '5.基本提示(梦幻童话)'];
  final List<String> _workflows = ['请先获取工作流列表'];
  String _selectedWorkflow = '请先获取工作流列表';
  late MyApi myApi;
  List<String> fsStyleChoices = [];
  var content = '正在测试连接，请稍后点击';
  var draftContent = '';
  bool supportDrawEngine1 = true;
  bool supportDrawEngine2 = true;
  bool supportDrawEngine3 = true;
  bool supportDrawEngine4 = true;
  bool supportDrawEngine5 = true;
  final box = GetStorage();

  // 使用Map统一管理所有的TextEditingController
  final Map<String, TextEditingController> _controllers = {};

  // 初始化所有控制器
  void _initializeControllers() {
    final Map<String, String?> defaultValues = {
      'sdUrl': _sdUrl,
      'lora': '',
      'cuUrl': '',
      'fsUrl': '',
      'chatProxy': _chatWebProxy,
      'steps': '20',
      'hireFix1': '5',
      'hireFix2': '0.5',
      'hireFix3': '2',
      'reDraw': '0.75',
      'picWidth': '512',
      'picHeight': '512',
      'fsPicWidth': '1024',
      'fsPicHeight': '1024',
      'imageSavePath': _getDefaultImagePath(),
      'chatGPTApiKey': '',
      'chatGPTApiUrl': '',
      'tyqwApiKey': '',
      'zpaiApiKey': '',
      'selfPositivePrompts': '',
      'selfNegativePrompts': '',
      'combinedPositivePrompts': '',
      'baiduTranslateAppId': '',
      'baiduTranslateAppKey': '',
      'deeplTranslateAppKey': '',
      'supabaseUrl': '',
      'supabaseKey': '',
      'merchantID': '',
      'merchantKey': '',
      'merchantUrl': '',
      'zsyToken': '',
      'zsyDescribeToken': '',
      'zsyBlendToken': '',
      'MJSlowSpeedToken': '',
      'MJFastSpeedToken': '',
      'MJExtraSpeedToken': '',
      'MJSlowSpeedID': '',
      'MJFastSpeedID': '',
      'MJExtraSpeedID': '',
      'MJSeverId': '',
      'MJChannelId': '',
      'MJSelfId': '',
      'NJSelfId': '',
      'MJUserToken': '',
      'MJApiUrl': GlobalParams.mjApiUrl,
      'MJApiSecret': '',
      'KBAppId': '',
      'KBAppSec': '',
      'LumaCookie': '',
      'LumaUrl': '',
      'LumaKey': '',
      'SunoUrl': '',
      'SunoKey': '',
      'moonshotKey': '',
      'ossBucketName': '',
      'ossEndpoint': '',
      'ossApiUrl': '',
      'baiduVoiceApiKey': '',
      'baiduVoiceAppId': '',
      'baiduVoiceSecretKey': '',
      'aliVoiceAccessId': '',
      'aliVoiceAccessSecret': '',
      'aliVoiceAppKey': '',
      'huaweiVoiceAK': '',
      'huaweiVoiceSK': '',
      'azureVoiceSK': '',
      'inviteCode': '',
      'draftPath': ''
    };

    // 创建并初始化所有控制器
    defaultValues.forEach((key, value) {
      _controllers[key] = TextEditingController(text: value);
    });
  }

  // 更新控制器值的方法
  void _updateControllerValue(String key, String? value) {
    _controllers[key]?.text = value ?? '';
  }

  // 获取控制器的便捷方法
  TextEditingController getTextController(String key) {
    return _controllers[key] ?? TextEditingController();
  }

  // 获取控制器值的便捷方法
  String getControllerText(String key) {
    return _controllers[key]?.text ?? '';
  }

  // 从设置更新所有控制器
  void _updateControllersFromSettings(Map<String, dynamic> settings) {
    settings.forEach((key, value) {
      if (_controllers.containsKey(key)) {
        _updateControllerValue(key, value?.toString());
      }
    });
  }

  // 获取默认图片保存路径
  String _getDefaultImagePath() {
    if (Platform.isWindows) {
      return 'C:/Users/Administrator/Pictures/ImageGenerator';
    } else if (Platform.isMacOS) {
      return '';
    } else {
      return '非电脑设备，无法保存图片';
    }
  }

  void listenStorage() async {
    box.listenKey('needRefreshSettings', (value) async {
      if (value) {
        await loadSettings();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // 在初始化时创建 MyApi 实例
    myApi = MyApi();
    listenStorage();
    _initializeControllers();
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      Map<String, dynamic> savedSettings = await Config.loadSettings();
      String savePath = savedSettings['image_save_path'] ?? '';
      String lumaCookie = savedSettings['luma_cookie'] ?? '';
      String folderPath = '$savePath${Platform.pathSeparator}cu_workflows';
      List<String> workflowNames = await getNonHiddenFileNames(folderPath);
      String selectWorkflow = savedSettings['select_cu_workflow'] ?? '';
      String selectedFSStyles = savedSettings['fs_selected_styles'] ?? '';
      var apiKey = savedSettings['chat_api_key'] ?? savedSettings['chatSettings_apiKey'] ?? '';
      var baseUrl = (savedSettings['chat_api_url'] ?? savedSettings['chatSettings_apiUrl'] ?? '') + '/v1';
      if (baseUrl == '/v1') {
        baseUrl = 'https://api.openai.com/v1';
      }
      if (apiKey.isEmpty) {
        commonPrint('AI聊天 API 密钥未设置，不初始化OpenAI客户端');
      } else {
        await OpenAIClientSingleton.instance.init();
      }
      // 更新所有控制器的值
      _updateControllersFromSettings({
        'sdUrl': savedSettings['sdUrl'],
        'cuUrl': savedSettings['cu_url'],
        'fsUrl': savedSettings['fs_url'],
        'chatProxy': savedSettings['chat_web_proxy'],
        'chatGPTApiKey': savedSettings['chat_api_key'],
        'tyqwApiKey': savedSettings['tyqw_api_key'],
        'zpaiApiKey': savedSettings['zpai_api_key'],
        'chatGPTApiUrl': savedSettings['chat_api_url'],
        'selfPositivePrompts': savedSettings['self_positive_prompts'],
        'selfNegativePrompts': savedSettings['self_negative_prompts'],
        'draftPath': savedSettings['jy_draft_save_path'] ?? '',
        'zsyToken': savedSettings['zsy_token'],
        'zsyDescribeToken': savedSettings['zsy_describe_token'],
        'zsyBlendToken': savedSettings['zsy_blend_token'],
        'MJSlowSpeedToken': savedSettings['mj_slow_speed_token'],
        'MJFastSpeedToken': savedSettings['mj_fast_speed_token'],
        'MJExtraSpeedToken': savedSettings['mj_extra_speed_token'],
        'MJSlowSpeedID': savedSettings['mj_slow_speed_id'],
        'MJFastSpeedID': savedSettings['mj_fast_speed_id'],
        'MJExtraSpeedID': savedSettings['mj_extra_speed_id'],
        'MJSeverId': savedSettings['mj_sever_id'],
        'MJChannelId': savedSettings['mj_channel_id'],
        'MJSelfId': savedSettings['mj_self_id'],
        'NJSelfId': savedSettings['nj_self_id'],
        'MJUserToken': savedSettings['mj_user_token'],
        'inviteCode': savedSettings['invite_code'] ?? '',
        'combinedPositivePrompts': savedSettings['compiled_positive_prompts_type'],
        'picWidth': savedSettings['width']?.toString(),
        'picHeight': savedSettings['height']?.toString(),
        'fsPicWidth': (savedSettings['fs_width'] ?? 1024).toString(),
        'fsPicHeight': (savedSettings['fs_height'] ?? 1024).toString(),
        'steps': savedSettings['steps']?.toString(),
        'hireFix1': savedSettings['hires_fix_steps']?.toString(),
        'hireFix2': savedSettings['hires_fix_amplitude']?.toString(),
        'reDraw': (savedSettings['redraw_range'] ?? 0.75).toString(),
        'hireFix3': (savedSettings['hires_fix_multiple'] ?? 2.0).toString(),
        'baiduTranslateAppId': savedSettings['baidu_trans_app_id'],
        'baiduTranslateAppKey': savedSettings['baidu_trans_app_key'],
        'supabaseUrl': savedSettings['supabase_url'] ?? '',
        'supabaseKey': savedSettings['supabase_key'] ?? '',
        'merchantID': savedSettings['merchant_id'] ?? '',
        'merchantKey': savedSettings['merchant_key'] ?? '',
        'merchantUrl': savedSettings['merchant_url'] ?? '',
        'deeplTranslateAppKey': savedSettings['deepl_api_key'],
        'baiduVoiceApiKey': savedSettings['baidu_voice_api_key'],
        'baiduVoiceAppId': savedSettings['baidu_voice_app_id'],
        'baiduVoiceSecretKey': savedSettings['baidu_voice_secret_key'],
        'aliVoiceAccessId': savedSettings['ali_voice_access_id'],
        'aliVoiceAppKey': savedSettings['ali_voice_app_key'],
        'aliVoiceAccessSecret': savedSettings['ali_voice_access_secret'],
        'huaweiVoiceAK': savedSettings['huawei_voice_ak'],
        'huaweiVoiceSK': savedSettings['huawei_voice_sk'],
        'azureVoiceSK': savedSettings['azure_voice_speech_key'],
        'imageSavePath': savedSettings['image_save_path'] ?? '',
        'MJApiUrl': savedSettings['mj_api_url'] ?? GlobalParams.mjApiUrl,
        'MJApiSecret': savedSettings['mj_api_secret'] ?? '',
        'KBAppId': savedSettings['kb_app_id'] ?? '',
        'KBAppSec': savedSettings['kb_app_sec'] ?? '',
        'LumaCookie': lumaCookie,
        'LumaUrl': savedSettings['luma_api_url'] ?? '',
        'LumaKey': savedSettings['luma_api_token'] ?? '',
        'SunoUrl': savedSettings['suno_api_url'] ?? '',
        'SunoKey': savedSettings['suno_api_key'] ?? '',
        'moonshotKey': savedSettings['moonshot_api_key'] ?? '',
        'ossBucketName': savedSettings['oss_bucket_name'] ?? '',
        'ossEndpoint': savedSettings['oss_endpoint'] ?? '',
        'ossApiUrl': savedSettings['oss_api_url'] ?? '',
      });

      setState(() {
        _drawEngine = savedSettings['drawEngine'] ?? 0;
        _mjDrawSpeedType = savedSettings['MJDrawSpeedType'] ?? 0;
        if (savedSettings['sdUrl'] != null) {
          _sdUrl = savedSettings['sdUrl'];
        }
        if (savedSettings['chat_web_proxy'] != null) {
          _chatWebProxy = savedSettings['chat_web_proxy'];
        }
        _selectedMode = savedSettings['use_mode'] ?? 0;
        if (savedSettings['ChatGPTUseMode'] != null) {
          _chatGPTSelectedMode = savedSettings['ChatGPTUseMode'];
        }
        _defaultModel = savedSettings['default_model'];
        _sampler = savedSettings['Sampler'];
        _lumaSelectedMode = savedSettings['use_luma_mode'] ?? 0;
        _exitAppMode = savedSettings['exit_app_method'] ?? -1;
        _voiceSelectedMode = savedSettings['use_voice_mode'];
        _isMixPrompt = savedSettings['is_compiled_positive_prompts'] ?? false;
        _isSelfPositivePrompt = savedSettings['use_self_positive_prompts'] ?? false;
        _isSelfNegativePrompt = savedSettings['use_self_negative_prompts'] ?? false;
        _isUseFaceStore = savedSettings['restore_face'] ?? false;
        _isHiresFix = savedSettings['hires_fix'] ?? false;
        _useADetail = savedSettings['use_adetail'] ?? false;
        _remixAutoSubmit = savedSettings['remix_auto_submit'] ?? false;
        _joinAccountPool = savedSettings['join_account_pool'] ?? false;
        _haveMJAccount = savedSettings['have_mj_account'] ?? false;

        _hiresFixSampler = savedSettings['hires_fix_sampler'];
        _defaultFSModel = savedSettings['fs_base_model'] ?? 'animagineXL_v10.safetensors';
        _defaultFSREModel = savedSettings['fs_ref_model'] ?? 'None';

        supportDrawEngine1 = savedSettings['supportDrawEngine1'] ?? true;
        supportDrawEngine2 = savedSettings['supportDrawEngine2'] ?? true;
        supportDrawEngine3 = savedSettings['supportDrawEngine3'] ?? true;
        supportDrawEngine4 = savedSettings['supportDrawEngine4'] ?? true;
        supportDrawEngine5 = savedSettings['supportDrawEngine5'] ?? true;

        if (savedSettings['default_positive_prompts_type'] != null) {
          _selectedOption = _options[savedSettings['default_positive_prompts_type']];
        }

        // 工作流相关设置
        if (savedSettings['cu_url'] != '' && _drawEngine == 3) {
          _workflows.clear();
          _workflows.addAll(workflowNames);
          if (_workflows.isNotEmpty) {
            if (selectWorkflow != '') {
              bool isContains = false;
              for (var element in _workflows) {
                if (element == selectWorkflow) {
                  _selectedWorkflow = element;
                  isContains = true;
                  break;
                }
              }
              if (!isContains) {
                _selectedWorkflow = _workflows[0];
              }
            } else {
              _selectedWorkflow = _workflows[0];
            }
          }
        }

        // FS样式相关设置
        if (selectedFSStyles != '') {
          _selectedFSStyle = selectedFSStyles.split(',');
        }
      });

      // 初始化不同引擎的设置
      if (_sdUrl != '' && _drawEngine == 0) {
        await Future.wait(
            [_getModels(_sdUrl), _getSamplers(_sdUrl), _getLoras(_sdUrl), _getVaes(_sdUrl), _getUpscalers(_sdUrl), _getOptions(_sdUrl)]);
      }

      if (_drawEngine == 1 && savedSettings['zsy_token'] != null) {
        _getDrawTimes(_mjDrawSpeedType, savedSettings['zsy_token']);
      }

      if (savedSettings['fs_url'] != '' && _drawEngine == 4) {
        await Future.wait([_getFSStyles(), _getFSModels(true), _getFSModels(false)]);
      }

      // 更新Provider
      Map<String, dynamic> aiModeSettings = {'use_mode': savedSettings['use_mode'] ?? 0};
      if (mounted) {
        Provider.of<ChangeSettings>(context, listen: false).changeValue(aiModeSettings);
      }
    } catch (e) {
      commonPrint('加载设置时出错: $e');
      // 可以添加错误提示
    }
  }

  @override
  void dispose() {
    // 释放所有控制器
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> testOpenAI(String apiKey, String modelName, String prompts, String baseUrl) async {
    content = "正在测试连接，请稍后...";
    if (mounted) {
      showHint(content);
    }
    try {
      await OpenAIClientSingleton.instance.client.createChatCompletion(
          request: CreateChatCompletionRequest(
        model: ChatCompletionModel.modelId(modelName),
        messages: [
          ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.string(prompts),
          ),
        ],
      ));
      content = '连接成功';
    } on Exception catch (e) {
      content = "连接失败，原因是$e";
      commonPrint(e);
    }
  }

  Future<void> testWebOpenAI(String path) async {
    if (path == '') {
      if (mounted) {
        showHint('代理地址为空无法连接', showPosition: 2);
      }
    } else {
      content = "正在测试连接，请稍后...";
      if (mounted) {
        showHint(content);
      }
      Response<ChatWebResponseEntity> response = await myApi.testWebChatGPT(path);
      if (response.statusCode == 200) {
        content = "连接成功";
      } else {
        content = "连接失败";
      }
      if (mounted) {
        showHint(content, showPosition: 2);
      }
    }
  }

  Future<void> testTYQWAI() async {
    content = "正在测试连接，请稍后...";
    if (mounted) {
      showHint(content);
    }
    Map<String, dynamic> payload = {};
    payload['model'] = 'qwen-7b-chat';
    payload['input'] = {'prompt': '你好,请回答我测试成功'};
    try {
      Response response = await myApi.tyqwAI(payload);
      if (response.statusCode == 200) {
        content = '连接成功';
      } else {
        content = "连接失败，原因是${response.statusMessage}";
      }
    } catch (e) {
      content = "连接失败，原因是$e";
    }
  }

  Future<void> testZPAI() async {
    content = "正在测试连接，请稍后...";
    if (mounted) {
      showHint(content);
    }
    Map<String, dynamic> settings = await Config.loadSettings();
    try {
      final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      final oneWeekLater = DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch;
      String apiId = (settings['zpai_api_key'] ?? '').split('.')[0];
      String secretKey = (settings['zpai_api_key'] ?? '').split('.')[1];
      Map<String, dynamic> payload = {'api_key': apiId, 'exp': oneWeekLater, 'timestamp': currentTimestamp};
      final jwt = JWT(payload, header: GlobalParams.zpaiHeaders);
      final token = jwt.sign(SecretKey(secretKey));
      Map<String, dynamic> inputs = {};
      inputs['prompt'] = [
        {'role': 'user', 'content': '你好,请回答我测试成功'}
      ];
      inputs['top_p'] = 0.9;
      Response response = await myApi.zpai(inputs, token, model: 'chatglm_pro', isStream: false);
      if (response.statusCode == 200) {
        content = '连接成功';
      } else {
        content = "连接失败，原因是${response.statusMessage}";
      }
    } catch (e) {
      content = "连接失败，原因是$e";
    }
  }

  Future<void> _testSDConnection(String url) async {
    try {
      Response response = await myApi.testSDConnection(url);
      if (response.statusCode == 200) {
        content = '连接成功';
      } else {
        content = '连接失败，错误是${response.statusMessage}';
      }
    } catch (error) {
      content = '连接失败，错误是$error';
    }
  }

  Future<void> _testCUConnection() async {
    try {
      Response response = await myApi.cuGetSystemStats();
      if (response.statusCode == 200) {
        content = '连接成功';
      } else {
        content = '连接失败，错误是${response.statusMessage}';
      }
    } catch (error) {
      content = '连接失败，错误是$error';
    }
  }

  Future<void> _testFSConnection() async {
    try {
      Response response = await myApi.fsGetSystemStats();
      if (response.statusCode == 200) {
        content = '连接成功';
      } else {
        content = '连接失败，错误是${response.statusMessage}';
      }
    } catch (error) {
      content = '连接失败，错误是$error';
    }
  }

  Future<void> _getLoras(String url) async {
    try {
      Response response = await myApi.getSDLoras(url);
      if (response.statusCode == 200) {
        _loras.clear();
        _loras.add('未选择lora');
        for (int i = 0; i < response.data.length; i++) {
          _loras.add(response.data[i]['name']);
        }
      } else {
        if (kDebugMode) {
          print('获取Lora列表失败，错误是${response.statusMessage}');
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('获取Lora列表失败，错误是$error');
      }
    }
    setState(() {
      if (_loras.isNotEmpty) {
        _selectedLora = _loras[0];
      }
    });
  }

  Future<void> _getModels(String url) async {
    try {
      Response response = await myApi.getSDModels(url);
      if (response.statusCode == 200) {
        _models.clear();
        for (int i = 0; i < response.data.length; i++) {
          var input = response.data[i]['title'];
          int indexOfBracket = input.indexOf('['); // 查找 "[" 的索引位置
          String result = '';
          if (indexOfBracket != -1) {
            result = input.substring(0, indexOfBracket).trim();
          } else {
            result = input; // 获取 "[" 前面的子字符串，并去除前面的空格
          }
          _models.add(result);
        }
      } else {
        commonPrint('获取模型列表失败1，错误是${response.statusMessage}');
      }
    } catch (error) {
      commonPrint('获取模型列表失败2，错误是$error');
    }
    if (_models.isNotEmpty) {
      for (int i = 0; i < _models.length; i++) {
        if (_models[i] == _defaultModel) {
          _selectedModel = _models[i];
          break;
        }
      }
      if (_selectedModel == "请先获取可用模型列表") {
        _selectedModel = _models[0];
      }
    }
    setState(() {});
  }

  Future<void> _getFSModels(bool isRE) async {
    try {
      Response response = await myApi.fsGetModels();
      if (response.statusCode == 200) {
        if (isRE) {
          _fsREmodels.clear();
          _fsREmodels.add('None');
        } else {
          _fsmodels.clear();
        }
        for (int i = 0; i < response.data['model_filenames'].length; i++) {
          var input = response.data['model_filenames'][i];
          if (isRE) {
            if (!_fsREmodels.contains(input)) {
              _fsREmodels.add(input);
            }
          } else {
            if (input.contains('xl') || input.contains('XL')) {
              if (!_fsmodels.contains(input)) {
                _fsmodels.add(input);
              }
            }
          }
        }
      } else {
        if (kDebugMode) {
          print('获取模型列表失败1，错误是${response.statusMessage}');
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('获取模型列表失败2，错误是$error');
      }
    }
    if (isRE) {
      if (_fsREmodels.isNotEmpty) {
        for (int i = 0; i < _fsREmodels.length; i++) {
          if (_fsREmodels[i] == _defaultFSREModel) {
            _selectedFSREModel = _fsREmodels[i];
            break;
          }
        }
        if (_selectedFSREModel == "请先获取可用精炼模型列表") {
          _selectedFSREModel = _fsREmodels[0];
        }
      }
    } else {
      if (_fsmodels.isNotEmpty) {
        for (int i = 0; i < _fsmodels.length; i++) {
          if (_fsmodels[i] == _defaultFSModel) {
            _selectedFSModel = _fsmodels[i];
            break;
          }
        }
        if (_selectedFSModel == "请先获取可用模型列表") {
          _selectedFSModel = _fsmodels[0];
        }
      }
    }
    setState(() {});
  }

  Future<void> _getFSStyles() async {
    try {
      Response response = await myApi.fsGetStyles();
      if (response.statusCode == 200) {
        _fsstyles.clear();
        fsStyleChoices.clear();
        // fsStyleChoices = _selectedFSStyle;
        fsStyleChoices.addAll(_selectedFSStyle);
        response.data.forEach((element) {
          fooocusTranslate.forEach((key, value) {
            if (key == element) {
              if (!fsStyleChoices.contains(value)) {
                fsStyleChoices.add(value);
              }
              _fsstyles.add(value);
            }
          });
        });
      } else {
        if (kDebugMode) {
          print('获取模型列表失败1，错误是${response.statusMessage}');
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('获取模型列表失败2，错误是$error');
      }
    }
    setState(() {});
  }

  Future<void> _getVaes(String url) async {
    try {
      Response response = await myApi.getSDVaes(url);
      if (response.statusCode == 200) {
        _vaes.clear();
        _vaes.add("无");
        _vaes.add("自动选择");
        for (int i = 0; i < response.data.length; i++) {
          _vaes.add(response.data[i]['model_name']);
        }
      } else {
        if (kDebugMode) {
          print('获取vae列表失败1，错误是${response.statusMessage}');
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('获取模型vae失败2，错误是$error');
      }
    }
    if (_vaes.isNotEmpty) {
      _selectedVae = _vaes[0];
    }
    setState(() {});
  }

  Future<void> _getSamplers(String url) async {
    try {
      Response response = await myApi.getSDSamplers(url);
      if (response.statusCode == 200) {
        _samplers.clear();
        for (int i = 0; i < response.data.length; i++) {
          _samplers.add(response.data[i]['name']);
        }
      } else {
        if (kDebugMode) {
          print('获取采样器列表失败1，错误是${response.statusMessage}');
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('获取模型采样器失败2，错误是$error');
      }
    }
    if (_samplers.isNotEmpty) {
      for (int i = 0; i < _samplers.length; i++) {
        if (_samplers[i] == _sampler) {
          _selectedSampler = _samplers[i];
          break;
        }
      }
      if (_selectedSampler == "Euler a") {
        _selectedSampler = _samplers[0];
      }
    }
    setState(() {});
  }

  Future<void> _getUpscalers(String url) async {
    try {
      Response response = await myApi.getSDlLatentUpscaleModes(url);
      if (response.statusCode == 200) {
        _upscalers.clear();
        for (int i = 0; i < response.data.length; i++) {
          _upscalers.add(response.data[i]['name']);
        }
      } else {
        if (kDebugMode) {
          print('获取高清修复算法列表失败1，错误是${response.statusMessage}');
        }
      }
      Response response1 = await myApi.getSDUpscalers(url);
      if (response1.statusCode == 200) {
        for (int i = 0; i < response1.data.length; i++) {
          _upscalers.add(response1.data[i]['name']);
        }
      } else {
        if (kDebugMode) {
          print('获取高清修复算法列表失败3，错误是${response1.statusMessage}');
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('获取高清修复算法列表失败2，错误是$error');
      }
    }
    if (_upscalers.isNotEmpty) {
      for (int i = 0; i < _upscalers.length; i++) {
        if (_upscalers[i] == _hiresFixSampler) {
          _selectedUpscalers = _upscalers[i];
          break;
        }
      }
      if (_selectedUpscalers == 'Latent') {
        _selectedUpscalers = _upscalers[0];
      }
    }
    setState(() {});
  }

  Future<void> _getOptions(String url) async {
    try {
      Response response = await myApi.getSDOptions(url);
      if (response.statusCode == 200) {
        _defaultVae = response.data['sd_vae'];
        _defaultModel = response.data['sd_model_checkpoint'];
        int indexOfBracket = _defaultModel.indexOf('['); // 查找 "[" 的索引位置
        String result = '';
        if (indexOfBracket != -1) {
          result = _defaultModel.substring(0, indexOfBracket).trim();
        } else {
          result = _defaultModel; // 获取 "[" 前面的子字符串，并去除前面的空格
        }
        setState(() {
          if (_defaultVae == 'Automatic') {
            _defaultVae = '自动选择';
          } else if (_defaultVae == 'None') {
            _defaultVae = '无';
          }
          _selectedVae = _defaultVae;
        });
        setState(() {
          _selectedModel = result;
        });
      } else {
        commonPrint('获取sd设置失败，原因是${response.statusMessage}');
      }
    } catch (e) {
      commonPrint('获取sd设置失败，原因是$e');
    }
  }

  Future<void> _onChangeUseADetail() async {
    final colorSettings = context.read<ChangeSettings>();
    Map<String, dynamic> settings = await Config.loadSettings();
    List<Map<String, dynamic>> afterDetailOptions = List<Map<String, dynamic>>.from(settings['adetail_options'] ?? []);
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomDialog(
              title: null,
              showConfirmButton: false,
              showCancelButton: false,
              contentBackgroundColor: colorSettings.getBackgroundColor(),
              description: null,
              useScrollContent: false,
              maxWidth: 550,
              minWidth: 400,
              minHeight: 100,
              content: AfterDetailOption(
                afterDetailOptions: afterDetailOptions,
                sdSamplers: _samplers,
                onConfirm: (options) async {
                  _useADetail = false;
                  for (var option in options) {
                    if (option['is_enable']) {
                      _useADetail = true;
                      break;
                    }
                  }
                  Map<String, dynamic> settings = {'use_adetail': _useADetail, 'adetail_options': options};
                  await Config.saveSettings(settings);
                  setState(() {});
                },
              ));
        },
      );
    }
  }

  Future<void> _getDrawTimes(int type, String token) async {
    String applicationId = '';
    switch (type) {
      case 0:
        applicationId = getControllerText('MJSlowSpeedID');
        break;
      case 1:
        applicationId = getControllerText('MJFastSpeedID');
        break;
      case 2:
        applicationId = getControllerText('MJExtraSpeedID');
        break;
      default:
        break;
    }
    if (applicationId.isNotEmpty) {
      try {
        Response response = await myApi.getDrawCanUseTimes(applicationId, token);
        if (response.statusCode == 200) {
          double? remainingAmount = response.data['remaining_amount'];
          if (remainingAmount != null) {
            if (type == 0) {
              _slowDrawCanUseTimes = remainingAmount.toInt();
            } else if (type == 1) {
              _fastDrawCanUseTimes = remainingAmount.toInt();
            } else if (type == 2) {
              _extraDrawCanUseTimes = remainingAmount.toInt();
            }
          }
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          showHint('获取剩余绘图次数失败，原因是$e', showType: 3);
        }
      }
    }
  }

  Future<void> addMJAccount() async {
    final settings = context.read<ChangeSettings>();
    if (getControllerText('MJSeverId').isEmpty) {
      if (mounted) {
        showHint('mj服务器id不能为空', showType: 3);
      }
      return;
    } else if (getControllerText('MJChannelId').isEmpty) {
      if (mounted) {
        showHint('mj频道id不能为空', showType: 3);
      }
      return;
    } else if (getControllerText('MJUserToken').isEmpty) {
      if (mounted) {
        showHint('mj用户token不能为空', showType: 3);
      }
      return;
    }
    if (getControllerText('MJSelfId').isEmpty || getControllerText('NJSelfId').isEmpty) {
      var hintText = '';
      if (getControllerText('MJSelfId').isEmpty && getControllerText('NJSelfId').isEmpty) {
        hintText = '当前MJ和NJ的私信ID均未设置，将无法获取图片Seed,确认添加账号吗？\n';
      } else if (getControllerText('MJSelfId').isEmpty && getControllerText('NJSelfId').isNotEmpty) {
        hintText = '当前MJ的私信ID未设置将无法获取MJ绘制的图片Seed,确认添加账号吗？\n';
      } else if (getControllerText('MJSelfId').isNotEmpty && getControllerText('NJSelfId').isEmpty) {
        hintText = '当前NJ的私信ID未设置将无法获取NJ绘制的图片Seed,确认添加账号吗？\n';
      }
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomDialog(
              title: '提示',
              titleColor: settings.getForegroundColor(),
              contentBackgroundColor: settings.getBackgroundColor(),
              useScrollContent: false,
              description: hintText,
              descColor: settings.getForegroundColor(),
              showCancelButton: true,
              confirmButtonText: '确认',
              cancelButtonText: '取消',
              onConfirm: () async {
                await afterCheckMJAccount();
              },
              onCancel: () {
                return;
              },
            );
          },
        );
      }
    } else {
      await afterCheckMJAccount();
    }
  }

  Future<void> afterCheckMJAccount() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String userName = settings['user_name'] ?? '';
    Map<String, dynamic> payload = {};
    payload['guildId'] = getControllerText('MJSeverId');
    payload['channelId'] = getControllerText('MJChannelId');
    payload['mjBotChannelId'] = getControllerText('MJSelfId');
    payload['nijiBotChannelId'] = getControllerText('NJSelfId');
    payload['userToken'] = getControllerText('MJUserToken');
    payload['remark'] = userName;
    payload['remixAutoSubmit'] = _remixAutoSubmit;
    try {
      Response addAccountResponse = await myApi.addMJAccount(payload);
      if (addAccountResponse.statusCode == 200) {
        int code = addAccountResponse.data['code'];
        if (code == 0) {
          if (mounted) {
            showHint('添加账号成功');
          }
          Map<String, dynamic> settings = {'have_mj_account': true};
          await Config.saveSettings(settings);
          setState(() {
            _haveMJAccount = true;
          });
        } else {
          if (mounted) {
            showHint('添加账号失败，原因是${addAccountResponse.data['description']}');
          }
        }
      } else if (addAccountResponse.statusCode == 201) {
        if (mounted) {
          showHint('添加账号失败，原因是此账号已存在');
        }
      } else {
        if (mounted) {
          showHint('添加账号失败，原因是${addAccountResponse.data['description']}');
        }
        commonPrint('添加账号失败，原因是${addAccountResponse.data['description']}');
      }
    } catch (e) {
      if (mounted) {
        showHint('添加账号失败，原因是$e');
      }
      commonPrint('添加账号失败，原因是$e');
    }
  }

  Future<void> refreshMJAccount() async {
    final settings = context.read<ChangeSettings>();
    var mjChannelID = '';
    var njChannelID = '';
    var otherHintText = '注意：更新账号后，该账号相关未完成的任务（未启动、已提交、窗口等待、执行中）将会丢失！';
    if (getControllerText('MJSeverId').isEmpty) {
      if (mounted) {
        showHint('mj服务器id不能为空', showType: 3);
      }
      return;
    } else if (getControllerText('MJChannelId').isEmpty) {
      if (mounted) {
        showHint('mj频道id不能为空', showType: 3);
      }
      return;
    } else if (getControllerText('MJUserToken').isEmpty) {
      if (mounted) {
        showHint('mj用户token不能为空', showType: 3);
      }
      return;
    }
    if (getControllerText('MJSelfId').isEmpty || getControllerText('NJSelfId').isEmpty) {
      var hintText = '';
      if (getControllerText('MJSelfId').isEmpty && getControllerText('NJSelfId').isEmpty) {
        hintText = '当前MJ和NJ的私信ID均未设置，将无法获取图片Seed,确认更新账号吗？\n';
      } else if (getControllerText('MJSelfId').isEmpty && getControllerText('NJSelfId').isNotEmpty) {
        njChannelID = getControllerText('NJSelfId');
        hintText = '当前MJ的私信ID未设置将无法获取MJ绘制的图片Seed,确认更新账号吗？\n';
      } else if (getControllerText('MJSelfId').isNotEmpty && getControllerText('NJSelfId').isEmpty) {
        mjChannelID = getControllerText('MJSelfId');
        hintText = '当前NJ的私信ID未设置将无法获取NJ绘制的图片Seed,确认更新账号吗？\n';
      }
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomDialog(
              title: '提示',
              titleColor: settings.getForegroundColor(),
              contentBackgroundColor: settings.getBackgroundColor(),
              useScrollContent: false,
              description: hintText + otherHintText,
              descColor: settings.getForegroundColor(),
              showCancelButton: true,
              confirmButtonText: '确认',
              cancelButtonText: '取消',
              onConfirm: () async {
                Navigator.of(context).pop();
                await modifyMJAccount(mjChannelID, njChannelID);
              },
              onCancel: () {
                return;
              },
            );
          },
        );
      }
    } else {
      mjChannelID = getControllerText('MJSelfId');
      njChannelID = getControllerText('NJSelfId');
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomDialog(
              title: '提示',
              titleColor: settings.getForegroundColor(),
              contentBackgroundColor: settings.getBackgroundColor(),
              useScrollContent: false,
              description: otherHintText,
              descColor: settings.getForegroundColor(),
              showCancelButton: true,
              confirmButtonText: '确认',
              cancelButtonText: '取消',
              onConfirm: () async {
                await modifyMJAccount(mjChannelID, njChannelID);
              },
              onCancel: () {},
            );
          },
        );
      }
    }
  }

  Future<void> modifyMJAccount(String mjChannelID, String njChannelID) async {
    String mjAccountId = getControllerText('MJChannelId');
    Map<String, dynamic> payload = {};
    payload['mjBotChannelId'] = mjChannelID;
    payload['nijiBotChannelId'] = njChannelID;
    payload['userToken'] = getControllerText('MJUserToken');
    payload['remixAutoSubmit'] = _remixAutoSubmit;
    payload['enable'] = true;
    try {
      Response refreshAccountResponse = await myApi.updateAndReconnectMJAccount(payload, mjAccountId);
      commonPrint('更新账号返回值是$refreshAccountResponse');
      if (refreshAccountResponse.statusCode == 200) {
        if (mounted) {
          showHint('账号更新成功');
        }
      } else {
        if (mounted) {
          showHint('账号更新失败，原因是${refreshAccountResponse.data['description']}');
        }
        commonPrint('账号更新失败，原因是${refreshAccountResponse.data['description']}');
      }
    } catch (e) {
      if (mounted) {
        showHint('账号更新失败，原因是$e');
      }
      commonPrint('账号更新失败，原因是$e');
    }
  }

  Future<void> deleteMJAccount() async {
    if (getControllerText('MJSeverId').isEmpty) {
      if (mounted) {
        showHint('mj服务器id不能为空', showType: 3);
      }
      return;
    } else if (getControllerText('MJChannelId').isEmpty) {
      if (mounted) {
        showHint('mj频道id不能为空', showType: 3);
      }
      return;
    } else if (getControllerText('MJSelfId').isEmpty) {
      if (mounted) {
        showHint('mj私信id不能为空', showType: 3);
      }
      return;
    } else if (getControllerText('MJUserToken').isEmpty) {
      if (mounted) {
        showHint('mj用户token不能为空', showType: 3);
      }
      return;
    }
    String mjAccountId = getControllerText('MJChannelId');
    Map<String, dynamic> payload = {};
    payload['mjBotChannelId'] = getControllerText('MJSelfId');
    payload['userToken'] = getControllerText('MJUserToken');
    payload['remixAutoSubmit'] = _remixAutoSubmit;
    try {
      Response deleteAccountResponse = await myApi.deleteMJAccount(mjAccountId);
      if (deleteAccountResponse.statusCode == 200) {
        if (mounted) {
          showHint('账号删除成功');
        }
        Map<String, dynamic> settings = {'have_mj_account': false};
        await Config.saveSettings(settings);
        setState(() {
          _haveMJAccount = false;
        });
      } else {
        if (mounted) {
          showHint('账号删除失败，原因是${deleteAccountResponse.data['description']}');
        }
        commonPrint('账号删除失败，原因是${deleteAccountResponse.data['description']}');
      }
    } catch (e) {
      if (mounted) {
        showHint('账号删除失败，原因是$e');
      }
      commonPrint('账号删除失败，原因是$e');
    }
  }

  void setMultipleSelected(List<String> value) async {
    setState(() {
      _selectedFSStyle = value;
    });
    String selectStyles = '';
    for (var element in _selectedFSStyle) {
      selectStyles += '$element,';
    }
    Map<String, dynamic> settings = {'fs_selected_styles': selectStyles.substring(0, selectStyles.length - 1)};
    await Config.saveSettings(settings);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();

    return SafeArea(
        child: Container(
      decoration: BoxDecoration(
        color: settings.getBackgroundColor(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ListView(
                children: <Widget>[
                  const SizedBox(height: 16),
                  // 管理员设置
                  if (GlobalParams.isAdminVersion) ...[
                    _buildAdminSection(settings),
                    const SizedBox(height: 24),
                  ],
                  // 绘图引擎设置
                  _buildDrawingEngineSection(settings),
                  const SizedBox(height: 24),
                  if (GlobalParams.isFreeVersion || GlobalParams.isAdminVersion) ...[
                    // 引擎特定设置
                    if (_drawEngine == 0) _buildStableDiffusionSettings(settings),
                    if (_drawEngine == 1) _buildMidjourneySettings(settings),
                    if (_drawEngine == 2) _buildMidjourneyCustomSettings(settings),
                    if (_drawEngine == 3) _buildComfyUISettings(settings),
                    if (_drawEngine == 4) _buildFooocusSettings(settings),
                    const SizedBox(height: 24),
                    // AI引擎设置
                    if (GlobalParams.isAdminVersion || GlobalParams.isFreeVersion) ...[
                      _buildAIEngineSettings(settings),
                      const SizedBox(height: 24),
                      // 翻译设置
                      _buildTranslationSettings(settings),
                      const SizedBox(height: 24),
                    ],
                  ],
                  // 文件保存设置
                  _buildFileSaveSettings(settings),
                  const SizedBox(height: 24),
                  // 语音设置
                  _buildVoiceSettings(settings),
                  const SizedBox(height: 24),
                  if (GlobalParams.isFreeVersion || GlobalParams.isAdminVersion) ...[
                    // 数据库设置
                    if (GlobalParams.isAdminVersion || GlobalParams.isFreeVersion) ...[
                      _buildDatabaseSettings(settings),
                      const SizedBox(height: 24),
                    ],

                    // OSS设置
                    if (GlobalParams.isAdminVersion || GlobalParams.isFreeVersion) ...[
                      _buildOSSSettings(settings),
                      const SizedBox(height: 24),
                    ],

                    // AI音乐设置
                    if (GlobalParams.isAdminVersion || GlobalParams.isFreeVersion) ...[
                      _buildAIMusicSettings(settings),
                      const SizedBox(height: 24),
                    ],

                    // AI视频设置
                    if (GlobalParams.isAdminVersion || GlobalParams.isFreeVersion) ...[
                      _buildAIVideoSettings(settings),
                      const SizedBox(height: 24),
                    ],

                    // 月之暗面设置
                    if (GlobalParams.isAdminVersion || GlobalParams.isFreeVersion) ...[
                      _buildMoonshotSettings(settings),
                      const SizedBox(height: 24),
                    ],
                  ],

                  // 退出应用设置
                  _buildExitSettings(settings),

                  // 底部间距
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  // 管理员设置区域
  Widget _buildAdminSection(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('管理员设置', settings),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: getTextController('inviteCode'),
                label: '管理员邀请码',
                hint: '设置用户邀请码后，其他用户在注册时输入该邀请码，会与该管理员设置信息绑定',
                onChanged: (value) async {
                  await Config.saveSettings({'invite_code': value});
                },
                settings: settings,
              ),
            ),
            const SizedBox(width: 16),
            _buildPrimaryButton(
              '设置',
              onPressed: () async {
                if (getControllerText('inviteCode').isEmpty) {
                  showHint('邀请码不能为空');
                  return;
                }
                showHint('设置邀请码中...', showType: 5);
                Map<String, dynamic> settings = await Config.loadSettings();
                String userId = settings['user_id'] ?? '';
                await SupabaseHelper().update('my_users', {'invite_code': getControllerText('inviteCode')}, updateMatchInfo: {'user_id': userId});
                if (context.mounted) {
                  showHint('邀请码设置成功', showType: 2);
                }
              },
              settings: settings,
            ),
          ],
        ),
      ],
    );
  }

  // 构建章节标题
  Widget _buildSectionTitle(String title, ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: settings.getForegroundColor(),
          ),
        ),
        const SizedBox(height: 8),
        Divider(
          color: settings.getForegroundColor().withAlpha(76),
          thickness: 1,
        ),
      ],
    );
  }

  // 统一的文本输入框样式
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Function(String) onChanged,
    required ChangeSettings settings,
    int maxLines = 1,
    bool isShow = false,
    String? hint,
  }) {
    return maxLines == 1
        ? MyTextField(
            controller: controller,
            onChanged: onChanged,
            isShow: isShow,
            style: TextStyle(color: settings.getForegroundColor()),
            maxLines: maxLines,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: TextStyle(color: settings.getForegroundColor()),
              hintStyle: TextStyle(color: settings.getHintTextColor()),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: settings.getForegroundColor().withAlpha(76)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: settings.getForegroundColor().withAlpha(76)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: settings.getSelectedBgColor()),
              ),
              filled: true,
              fillColor: settings.getBackgroundColor().withAlpha(13),
            ),
          )
        : TextField(
            controller: controller,
            onChanged: onChanged,
            style: TextStyle(color: settings.getForegroundColor()),
            maxLines: maxLines,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: TextStyle(color: settings.getForegroundColor()),
              hintStyle: TextStyle(color: settings.getHintTextColor()),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: settings.getForegroundColor().withAlpha(76)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: settings.getForegroundColor().withAlpha(76)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: settings.getSelectedBgColor()),
              ),
              filled: true,
              fillColor: settings.getBackgroundColor().withAlpha(13),
            ),
          );
  }

  // 统一的按钮样式
  Widget _buildPrimaryButton(String text, {required VoidCallback onPressed, required ChangeSettings settings}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: settings.getSelectedBgColor(),
        foregroundColor: settings.getCardTextColor(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(text),
    );
  }

  // 绘图引擎选择部分
  Widget _buildDrawingEngineSection(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (GlobalParams.isFreeVersion || GlobalParams.isAdminVersion) ...[
          _buildSectionTitle('绘图引擎设置', settings),
          const SizedBox(height: 16),
          // 支持的绘图引擎
          _buildSettingsCard(
            title: '支持的绘图引擎',
            settings: settings,
            child: Row(
              children: [
                Expanded(
                  child: _buildEngineOption(
                    label: 'Stable Diffusion',
                    value: supportDrawEngine1,
                    onChanged: (value) async {
                      setState(() => supportDrawEngine1 = value!);
                      await Config.saveSettings({'supportDrawEngine1': value});
                    },
                    settings: settings,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEngineOption(
                    label: 'Midjourney(知数云)',
                    value: supportDrawEngine2,
                    onChanged: (value) async {
                      setState(() => supportDrawEngine2 = value!);
                      await Config.saveSettings({'supportDrawEngine2': value});
                    },
                    settings: settings,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEngineOption(
                    label: 'Midjourney(中转)',
                    value: supportDrawEngine3,
                    onChanged: (value) async {
                      setState(() => supportDrawEngine3 = value!);
                      await Config.saveSettings({'supportDrawEngine3': value});
                    },
                    settings: settings,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEngineOption(
                    label: 'Comfyui',
                    value: supportDrawEngine4,
                    onChanged: (value) async {
                      setState(() => supportDrawEngine4 = value!);
                      await Config.saveSettings({'supportDrawEngine4': value});
                    },
                    settings: settings,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEngineOption(
                    label: 'Fooocus',
                    value: supportDrawEngine5,
                    onChanged: (value) async {
                      setState(() => supportDrawEngine5 = value!);
                      await Config.saveSettings({'supportDrawEngine5': value});
                    },
                    settings: settings,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        // 当前绘图引擎
        _buildSettingsCard(
          title: '当前绘图引擎',
          settings: settings,
          child: Row(
            children: _buildCurrentEngineOptions(settings),
          ),
        ),
      ],
    );
  }

  // 构建当前引擎选项列表
  List<Widget> _buildCurrentEngineOptions(ChangeSettings settings) {
    List<Widget> options = [];

    void addOption(bool condition, String label, int value) {
      if (condition) {
        if (options.isNotEmpty) {
          options.add(const SizedBox(width: 12));
        }
        options.add(
          Expanded(
            child: _buildCurrentEngineOption(
              label: label,
              value: value,
              settings: settings,
            ),
          ),
        );
      }
    }

    addOption(supportDrawEngine1, 'Stable Diffusion', 0);
    addOption(supportDrawEngine2, 'Midjourney-1', 1);
    addOption(supportDrawEngine3, 'Midjourney', 2);
    addOption(supportDrawEngine4, 'ComfyUI', 3);
    addOption(supportDrawEngine5, 'Fooocus', 4);

    // 如果没有可用选项，添加提示
    if (options.isEmpty) {
      options.add(
        Expanded(
          child: Center(
            child: Text(
              '请先选择支持的绘图引擎',
              style: TextStyle(
                color: settings.getForegroundColor().withAlpha(153),
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    return options;
  }

  // 当前绘图引擎选项
  Widget _buildCurrentEngineOption({
    required String label,
    required int value,
    required ChangeSettings settings,
  }) {
    final isSelected = _drawEngine == value;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? settings.getSelectedBgColor() : settings.getForegroundColor().withAlpha(25),
        ),
        color: isSelected ? settings.getSelectedBgColor().withAlpha(25) : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          Map<String, dynamic> settings = {'drawEngine': value};
          await Config.saveSettings(settings);
          setState(() {
            _drawEngine = value;
            if (_sdUrl != '' && _drawEngine == 0) {
              _getModels(_sdUrl);
              _getSamplers(_sdUrl);
              _getLoras(_sdUrl);
              _getVaes(_sdUrl);
              _getUpscalers(_sdUrl);
              _getOptions(_sdUrl);
            }
          });
          if (mounted) {
            Provider.of<ChangeSettings>(context, listen: false).changeValue(settings);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Radio<int>(
                value: value,
                groupValue: _drawEngine,
                onChanged: (value) async {
                  Map<String, dynamic> settings = {'drawEngine': value!};
                  await Config.saveSettings(settings);
                  setState(() {
                    _drawEngine = value;
                    if (_sdUrl != '' && _drawEngine == 0) {
                      _getModels(_sdUrl);
                      _getSamplers(_sdUrl);
                      _getLoras(_sdUrl);
                      _getVaes(_sdUrl);
                      _getUpscalers(_sdUrl);
                      _getOptions(_sdUrl);
                    }
                  });
                  if (mounted) {
                    Provider.of<ChangeSettings>(context, listen: false).changeValue(settings);
                  }
                },
                activeColor: settings.getSelectedBgColor(),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: settings.getForegroundColor(),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 支持的绘图引擎选项
  Widget _buildEngineOption({
    required String label,
    required bool value,
    required Function(bool?) onChanged,
    required ChangeSettings settings,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? settings.getSelectedBgColor() : settings.getForegroundColor().withAlpha(25),
        ),
        color: value ? settings.getSelectedBgColor().withAlpha(25) : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: settings.getSelectedBgColor(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: settings.getForegroundColor(),
                    fontSize: 14,
                    fontWeight: value ? FontWeight.w500 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Stable Diffusion 设置界面
  Widget _buildStableDiffusionSettings(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Stable Diffusion 设置', settings),
        const SizedBox(height: 16),

        // 服务器连接设置
        _buildServerSettings(settings, isMJ: false),
        const SizedBox(height: 16),

        // 模型设置
        _buildModelSettings(settings),
        const SizedBox(height: 16),

        // 采样设置
        _buildSamplingSettings(settings),
        const SizedBox(height: 16),

        // 提示词设置
        _buildPromptSettings(settings),
      ],
    );
  }

// 模型设置卡片
  Widget _buildModelSettings(ChangeSettings settings) {
    return _buildSettingsCard(
      title: '模型设置',
      settings: settings,
      child: Column(
        children: [
          // 基础模型选择
          _buildSettingRow(
            label: '基础模型',
            content: Expanded(
              child: _buildDropdownButton(
                value: _selectedModel,
                items: _models,
                onChanged: (value) => _handleModelChange(value, settings),
                settings: settings,
              ),
            ),
            action: _buildActionButton(
              label: '刷新模型列表',
              onPressed: () => _handleRefreshModels(),
              settings: settings,
            ),
            settings: settings,
          ),
          const SizedBox(height: 16),

          // Lora模型选择
          _buildSettingRow(
            label: 'Lora模型',
            content: Expanded(
              child: _buildDropdownButton(
                value: _selectedLora,
                items: _loras,
                onChanged: (value) => _handleLoraChange(value),
                settings: settings,
              ),
            ),
            action: _buildActionButton(
              label: '刷新Lora列表',
              onPressed: () => _handleRefreshLoras(),
              settings: settings,
            ),
            settings: settings,
          ),
          const SizedBox(height: 16),

          // VAE模型选择
          _buildSettingRow(
            label: 'VAE模型',
            content: Expanded(
              child: _buildDropdownButton(
                value: _selectedVae,
                items: _vaes,
                onChanged: (value) => _handleVaeChange(value),
                settings: settings,
              ),
            ),
            action: _buildActionButton(
              label: '刷新VAE列表',
              onPressed: () => _handleRefreshVaes(),
              settings: settings,
            ),
            settings: settings,
          ),
        ],
      ),
    );
  }

// 通用设置卡片组件
  Widget _buildSettingsCard({
    required String title,
    required Widget child,
    required ChangeSettings settings,
  }) {
    return Card(
      elevation: 0,
      color: settings.getBackgroundColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: settings.getForegroundColor().withAlpha(76),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: settings.getForegroundColor(),
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  // 设置行组件
  Widget _buildSettingRow({
    required String label,
    required Widget content,
    required Widget action,
    required ChangeSettings settings,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: settings.getForegroundColor(),
              fontSize: 14,
            ),
          ),
        ),
        content,
        const SizedBox(width: 16),
        action,
      ],
    );
  }

  // 下拉按钮组件
  Widget _buildDropdownButton({
    required String value,
    required List<String> items,
    required Function(String) onChanged,
    required ChangeSettings settings,
  }) {
    return CommonDropdownWidget(
      selectedValue: value,
      dropdownData: items,
      onChangeValue: (value) {
        onChanged(value);
      },
    );
  }

  // 处理器方法
  void _handleModelChange(String value, ChangeSettings settings) async {
    showHint('开始更换模型，请耐心等待更换完成', showType: 5, showTime: 2000);
    Map<String, dynamic> settings = {'default_model': value};
    await Config.saveSettings(settings);
    Map<String, dynamic> options = {'sd_model_checkpoint': value};
    Response response = await myApi.setSDOptions(getControllerText('sdUrl'), options);
    String setResult = response.statusCode == 200 ? "模型更改成功，已更换为${value.split('.')[0]}模型" : "模型更改失败";
    setState(() {
      _selectedModel = value;
    });
    showHint(setResult, showTime: 500);
  }

  void _handleRefreshModels() async {
    if (getControllerText('sdUrl').isNotEmpty) {
      await _getModels(getControllerText('sdUrl'));
    } else {
      showHint('请先配置sd地址');
    }
  }

  void _handleLoraChange(String value) {
    setState(() {
      if (_selectedLora != value) {
        _updateControllerValue('lora', '${getControllerText('lora')}<lora:$value:1>, ');
      }
      _selectedLora = value;
    });
  }

  void _handleRefreshLoras() async {
    if (getControllerText('sdUrl').isNotEmpty) {
      await _getLoras(getControllerText('sdUrl'));
    } else {
      showHint('请先配置sd地址');
    }
  }

  void _handleVaeChange(String value) async {
    String vaeValue = value;
    if (value == '无') {
      vaeValue = 'None';
    } else if (value == '自动选择') {
      vaeValue = 'Automatic';
    }

    Map<String, dynamic> options = {'sd_vae': vaeValue};
    Response response = await myApi.setSDOptions(getControllerText('sdUrl'), options);

    if (response.statusCode == 200) {
      if (vaeValue == 'None') {
        vaeValue = '无';
      } else if (vaeValue == 'Automatic') {
        vaeValue = '自动选择';
      }
      setState(() {
        _selectedVae = vaeValue;
      });
      showHint("vae更改成功，已更换为${vaeValue.split('.')[0]}模型", showPosition: 2, showTime: 2);
    } else {
      showHint("vae更改失败", showPosition: 2, showTime: 2);
    }
  }

  void _handleRefreshVaes() async {
    if (getControllerText('sdUrl').isNotEmpty) {
      await _getVaes(getControllerText('sdUrl'));
    } else {
      showHint('请先配置sd地址');
    }
  }

  // 采样设置卡片
  Widget _buildSamplingSettings(ChangeSettings settings) {
    return _buildSettingsCard(
      title: '采样设置',
      settings: settings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基础采样设置行
          Row(
            children: [
              // 采样算法选择
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '采样算法',
                      style: TextStyle(
                        color: settings.getForegroundColor(),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDropdownButton(
                      value: _selectedSampler,
                      items: _samplers,
                      onChanged: (value) => _handleSamplerChange(value),
                      settings: settings,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // 迭代步数
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '迭代步数',
                      style: TextStyle(
                        color: settings.getForegroundColor(),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildNumberField(
                      controller: getTextController('steps'),
                      hint: '20',
                      onChanged: (value) async {
                        if (value.isNotEmpty) {
                          await Config.saveSettings({
                            'steps': int.parse(value),
                          });
                        }
                      },
                      settings: settings,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 图片尺寸设置行
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '图片宽度',
                      style: TextStyle(
                        color: settings.getForegroundColor(),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildNumberField(
                      controller: getTextController('picWidth'),
                      hint: '512',
                      helperText: '范围：64-2048',
                      onChanged: (value) async {
                        if (value.isNotEmpty) {
                          await Config.saveSettings({
                            'width': int.parse(value),
                          });
                        }
                      },
                      settings: settings,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '图片高度',
                      style: TextStyle(
                        color: settings.getForegroundColor(),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildNumberField(
                      controller: getTextController('picHeight'),
                      hint: '512',
                      helperText: '范围：64-2048',
                      onChanged: (value) async {
                        if (value.isNotEmpty) {
                          await Config.saveSettings({
                            'height': int.parse(value),
                          });
                        }
                      },
                      settings: settings,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '重绘幅度',
                      style: TextStyle(
                        color: settings.getForegroundColor(),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildNumberField(
                      controller: getTextController('reDraw'),
                      hint: '0.75',
                      helperText: '范围：0-1',
                      decimal: true,
                      onChanged: (value) async {
                        if (value.isNotEmpty) {
                          await Config.saveSettings({
                            'redraw_range': double.parse(value),
                          });
                        }
                      },
                      settings: settings,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 高级选项行
          Row(
            children: [
              _buildToggleOption(
                label: '面部修复',
                value: _isUseFaceStore,
                onChanged: (value) async {
                  await Config.saveSettings({'restore_face': value});
                  setState(() => _isUseFaceStore = value);
                },
                settings: settings,
              ),
              const SizedBox(width: 24),
              _buildToggleOption(
                label: '高清修复',
                value: _isHiresFix,
                onChanged: (value) async {
                  await Config.saveSettings({'hires_fix': value});
                  setState(() {
                    _isHiresFix = value;
                    if (_isHiresFix) {
                      _getUpscalers(getControllerText('sdUrl'));
                    }
                  });
                },
                settings: settings,
              ),
              const SizedBox(width: 24),
              _buildToggleOption(
                label: '启用ADetail',
                value: _useADetail,
                onChanged: (value) async {
                  await Config.saveSettings({'hires_fix': value});
                  setState(() {
                    _onChangeUseADetail();
                  });
                },
                settings: settings,
              ),
            ],
          ),
          if (_isHiresFix) ...[
            Column(
              children: [
                const SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Text('高清修复算法:', style: TextStyle(color: settings.getForegroundColor())),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 300,
                      child: _buildDropdownButton(
                        value: _selectedUpscalers,
                        items: _upscalers,
                        onChanged: (value) => _handleUpscalerChange(value),
                        settings: settings,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '高清迭代步数',
                            style: TextStyle(
                              color: settings.getForegroundColor(),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildNumberField(
                            controller: getTextController('hireFix1'),
                            hint: '10',
                            helperText: '范围：5-10(不建议过多的步数)',
                            decimal: true,
                            onChanged: (value) async {
                              if (value.isNotEmpty) {
                                await Config.saveSettings({
                                  'redraw_range': double.parse(value),
                                });
                              }
                            },
                            settings: settings,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '高清重绘幅度',
                            style: TextStyle(
                              color: settings.getForegroundColor(),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildNumberField(
                            controller: getTextController('hireFix2'),
                            hint: '0.5',
                            helperText: '范围：0-1',
                            decimal: true,
                            onChanged: (value) async {
                              if (value.isNotEmpty) {
                                await Config.saveSettings({
                                  'redraw_range': double.parse(value),
                                });
                              }
                            },
                            settings: settings,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '高清放大倍数',
                            style: TextStyle(
                              color: settings.getForegroundColor(),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildNumberField(
                            controller: getTextController('hireFix2'),
                            hint: '2',
                            helperText: '范围：1-4(不建议过多的放大倍数)',
                            decimal: true,
                            onChanged: (value) async {
                              if (value.isNotEmpty) {
                                await Config.saveSettings({
                                  'redraw_range': double.parse(value),
                                });
                              }
                            },
                            settings: settings,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          ],
        ],
      ),
    );
  }

  // 提示词设置卡片
  Widget _buildPromptSettings(ChangeSettings settings) {
    return _buildSettingsCard(
      title: '提示词设置',
      settings: settings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 提示词类别选择
          Row(
            children: [
              Text(
                '默认正面提示词类别:',
                style: TextStyle(
                  color: settings.getForegroundColor(),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 300,
                child: _buildDropdownButton(
                  value: _selectedOption,
                  items: _options,
                  onChanged: (value) => _handlePromptTypeChange(value),
                  settings: settings,
                ),
              ),
              const SizedBox(width: 24),
              _buildToggleOption(
                label: '组合类别',
                value: _isMixPrompt,
                onChanged: (value) async {
                  await Config.saveSettings({'is_compiled_positive_prompts': value});
                  setState(() => _isMixPrompt = value);
                },
                settings: settings,
              ),
              if (_isMixPrompt) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: getTextController('combinedPositivePrompts'),
                    label: '组合类别',
                    hint: '输入组合类别，比如1+2，请勿组合过多种类',
                    onChanged: (text) async {
                      await Config.saveSettings({'compiled_positive_prompts_type': text});
                    },
                    settings: settings,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // 自定义提示词选项
          Row(
            children: [
              _buildToggleOption(
                label: '自定义正面提示词',
                value: _isSelfPositivePrompt,
                onChanged: (value) async {
                  await Config.saveSettings({'use_self_positive_prompts': value});
                  setState(() => _isSelfPositivePrompt = value);
                },
                settings: settings,
              ),
              const SizedBox(width: 24),
              _buildToggleOption(
                label: '自定义负面提示词',
                value: _isSelfNegativePrompt,
                onChanged: (value) async {
                  await Config.saveSettings({'use_self_negative_prompts': value});
                  setState(() => _isSelfNegativePrompt = value);
                },
                settings: settings,
              ),
            ],
          ),

          if (_isSelfPositivePrompt || _isSelfNegativePrompt) const SizedBox(height: 16),

          // 自定义提示词输入区域
          Row(
            children: [
              if (_isSelfPositivePrompt)
                Expanded(
                  child: _buildTextField(
                    controller: getTextController('selfPositivePrompts'),
                    label: '默认正面提示词',
                    hint: '影响每一张图片的正面提示词',
                    maxLines: 3,
                    onChanged: (text) async {
                      await Config.saveSettings({'self_positive_prompts': text});
                    },
                    settings: settings,
                  ),
                ),
              if (_isSelfPositivePrompt && _isSelfNegativePrompt) const SizedBox(width: 16),
              if (_isSelfNegativePrompt)
                Expanded(
                  child: _buildTextField(
                    controller: getTextController('selfNegativePrompts'),
                    label: '默认负面提示词',
                    hint: '影响每一张图片的负面提示词',
                    maxLines: 3,
                    onChanged: (text) async {
                      await Config.saveSettings({'self_negative_prompts': text});
                    },
                    settings: settings,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Lora设置
          _buildTextField(
            controller: getTextController('lora'),
            label: 'Lora设置',
            hint: '格式是<lora:lora的名字:lora的权重>,支持多个lora，例如 <lora:fashionGirl_v54:0.5>, <lora:cuteGirlMix4_v10:0.6>',
            maxLines: 3,
            onChanged: (text) async {
              await Config.saveSettings({'loras': text});
            },
            settings: settings,
          ),
        ],
      ),
    );
  }

  // 数字输入框组件
  Widget _buildNumberField({
    required TextEditingController controller,
    required String hint,
    required Function(String) onChanged,
    required ChangeSettings settings,
    String? helperText,
    bool decimal = false,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(
        color: settings.getForegroundColor(),
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        helperText: helperText,
        helperStyle: TextStyle(
          color: settings.getForegroundColor().withAlpha(153),
          fontSize: 12,
        ),
        hintStyle: TextStyle(
          color: settings.getHintTextColor(),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: settings.getForegroundColor().withAlpha(51),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: settings.getForegroundColor().withAlpha(51),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: settings.getSelectedBgColor(),
          ),
        ),
      ),
      keyboardType: decimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
      inputFormatters: [
        if (decimal) DecimalTextInputFormatter(decimalRange: 2, minValue: 0, maxValue: 1) else FilteringTextInputFormatter.digitsOnly,
      ],
      onChanged: onChanged,
    );
  }

  // 开关选项组件
  Widget _buildToggleOption({
    required String label,
    required bool value,
    required Function(bool) onChanged,
    required ChangeSettings settings,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? settings.getSelectedBgColor() : settings.getForegroundColor().withAlpha(51),
          ),
          color: value ? settings.getSelectedBgColor().withAlpha(25) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: settings.getSelectedBgColor(),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: settings.getForegroundColor(),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 处理器方法
  void _handleSamplerChange(String value) async {
    await Config.saveSettings({'Sampler': value});
    setState(() => _selectedSampler = value);
  }

  void _handleUpscalerChange(String value) async {
    await Config.saveSettings({'hires_fix_sampler': value});
    setState(() => _selectedUpscalers = value);
  }

  void _handlePromptTypeChange(String value) async {
    int type = int.parse(value.split('.')[0]);
    await Config.saveSettings({'default_positive_prompts_type': type});
    setState(() => _selectedOption = value);
  }

  // Midjourney 设置界面
  Widget _buildMidjourneySettings(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Midjourney 设置', settings),
        const SizedBox(height: 16),

        // 速度模式设置
        _buildSpeedModeSettings(settings),
        const SizedBox(height: 16),

        // API配置设置
        _buildApiSettings(settings),
      ],
    );
  }

  // 速度模式设置卡片
  Widget _buildSpeedModeSettings(ChangeSettings settings) {
    return _buildSettingsCard(
      title: '速度模式设置',
      settings: settings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 模式选择
          _buildSpeedModeSelector(settings),
          const SizedBox(height: 20),

          // 模式特定配置
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildSpeedModeConfig(settings),
          ),
        ],
      ),
    );
  }

  // 速度模式选择器
  Widget _buildSpeedModeSelector(ChangeSettings settings) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: settings.getForegroundColor().withAlpha(25),
        ),
      ),
      child: Column(
        children: [
          _buildSpeedModeOption(
            title: '慢速模式',
            subtitle: '3-4分钟出图 (不保证)',
            value: 0,
            settings: settings,
          ),
          Divider(
            height: 1,
            color: settings.getForegroundColor().withAlpha(25),
          ),
          _buildSpeedModeOption(
            title: '快速模式',
            subtitle: '1-2分钟出图',
            value: 1,
            settings: settings,
          ),
          Divider(
            height: 1,
            color: settings.getForegroundColor().withAlpha(25),
          ),
          _buildSpeedModeOption(
            title: '极速模式',
            subtitle: '0.5-1分钟出图',
            value: 2,
            settings: settings,
          ),
        ],
      ),
    );
  }

  // 速度模式选项
  Widget _buildSpeedModeOption({
    required String title,
    required String subtitle,
    required int value,
    required ChangeSettings settings,
  }) {
    final isSelected = _mjDrawSpeedType == value;

    return InkWell(
      onTap: () async {
        await Config.saveSettings({'MJDrawSpeedType': value});
        setState(() => _mjDrawSpeedType = value);
        if (getControllerText('zsyToken').isNotEmpty) {
          await _getDrawTimes(value, getControllerText('zsyToken'));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? settings.getSelectedBgColor().withAlpha(25) : null,
        ),
        child: Row(
          children: [
            Radio<int>(
              value: value,
              groupValue: _mjDrawSpeedType,
              onChanged: (v) async {
                await Config.saveSettings({'MJDrawSpeedType': v});
                setState(() => _mjDrawSpeedType = v!);
                if (getControllerText('zsyToken').isNotEmpty) {
                  await _getDrawTimes(v!, getControllerText('zsyToken'));
                }
              },
              activeColor: settings.getSelectedBgColor(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: settings.getForegroundColor(),
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: settings.getForegroundColor().withAlpha(153),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 速度模式配置
  Widget _buildSpeedModeConfig(ChangeSettings settings) {
    switch (_mjDrawSpeedType) {
      case 0:
        return _buildModeConfigFields(
          tokenController: getTextController('MJSlowSpeedToken'),
          idController: getTextController('MJSlowSpeedID'),
          remainingTimes: _slowDrawCanUseTimes,
          prefix: 'slow',
          settings: settings,
        );
      case 1:
        return _buildModeConfigFields(
          tokenController: getTextController('MJFastSpeedToken'),
          idController: getTextController('MJFastSpeedID'),
          remainingTimes: _fastDrawCanUseTimes,
          prefix: 'fast',
          settings: settings,
        );
      case 2:
        return _buildModeConfigFields(
          tokenController: getTextController('MJExtraSpeedToken'),
          idController: getTextController('MJExtraSpeedID'),
          remainingTimes: _extraDrawCanUseTimes,
          prefix: 'extra',
          settings: settings,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // 模式配置字段
  Widget _buildModeConfigFields({
    required TextEditingController tokenController,
    required TextEditingController idController,
    required int remainingTimes,
    required String prefix,
    required ChangeSettings settings,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: tokenController,
            label: '模式Token',
            onChanged: (text) async {
              await Config.saveSettings({'mj_${prefix}_speed_token': text});
            },
            settings: settings,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTextField(
            controller: idController,
            label: '模式ID',
            onChanged: (text) async {
              await Config.saveSettings({'mj_${prefix}_speed_id': text});
            },
            settings: settings,
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: settings.getForegroundColor().withAlpha(51),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '剩余次数：',
                style: TextStyle(
                  color: settings.getForegroundColor(),
                  fontSize: 14,
                ),
              ),
              Text(
                '$remainingTimes次',
                style: TextStyle(
                  color: settings.getForegroundColor(),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _buildActionButton(
          label: '刷新次数',
          onPressed: () async {
            if (getControllerText('zsyToken').isNotEmpty) {
              await _getDrawTimes(_mjDrawSpeedType, getControllerText('zsyToken'));
            }
          },
          settings: settings,
        ),
      ],
    );
  }

  // API配置设置卡片
  Widget _buildApiSettings(ChangeSettings settings) {
    return _buildSettingsCard(
      title: 'API配置',
      settings: settings,
      child: Row(
        children: [
          Expanded(
            child: _buildTextField(
              controller: getTextController('zsyDescribeToken'),
              label: '知数云图生文Token',
              onChanged: (text) async {
                await Config.saveSettings({'zsy_describe_token': text});
              },
              settings: settings,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTextField(
              controller: getTextController('zsyBlendToken'),
              label: '知数云融图令牌',
              onChanged: (text) async {
                await Config.saveSettings({'zsy_blend_token': text});
              },
              settings: settings,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTextField(
              controller: getTextController('zsyToken'),
              label: '知数云平台令牌',
              onChanged: (text) async {
                await Config.saveSettings({'zsy_token': text});
              },
              settings: settings,
            ),
          ),
        ],
      ),
    );
  }

  // Midjourney 自定义中转设置界面
  Widget _buildMidjourneyCustomSettings(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Midjourney 自定义设置', settings),
        const SizedBox(height: 16),

        // API配置
        _buildCustomApiSettings(settings),
        const SizedBox(height: 16),

        // 服务器配置
        _buildServerSettings(settings, isMJ: true),
        const SizedBox(height: 16),
      ],
    );
  }

  // API配置卡片
  Widget _buildCustomApiSettings(ChangeSettings settings) {
    return _buildSettingsCard(
      title: 'API配置',
      settings: settings,
      child: Row(
        children: [
          Expanded(
            child: _buildTextField(
              controller: getTextController('MJApiUrl'),
              label: '自有MJ的API接口地址',
              hint: '留空将使用系统默认地址',
              onChanged: (text) async {
                await Config.saveSettings({'mj_api_url': text});
              },
              settings: settings,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTextField(
              controller: getTextController('MJApiSecret'),
              label: '自有MJ的API接口密钥',
              hint: '留空将使用系统默认密钥',
              onChanged: (text) async {
                await Config.saveSettings({'mj_api_secret': text});
              },
              settings: settings,
            ),
          ),
        ],
      ),
    );
  }

  // 服务器配置卡片
  Widget _buildServerSettings(ChangeSettings settings, {bool isMJ = false}) {
    return _buildSettingsCard(
      title: isMJ ? 'MJ账号配置(若使用中转,无需配置)' : '服务器配置',
      settings: settings,
      child: Column(
        children: [
          if (!isMJ) ...[
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: getTextController('sdUrl'),
                    label: 'SD服务器地址',
                    hint: '输入包含端口号的完整地址',
                    onChanged: (text) async {
                      await Config.saveSettings({'sdUrl': text});
                    },
                    settings: settings,
                  ),
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  label: '测试连接',
                  onPressed: () async {
                    await _testSDConnection(getControllerText('sdUrl'));
                    if (context.mounted) {
                      int type = content.contains('连接成功') ? 2 : 3;
                      showHint(content, showType: type);
                    }
                  },
                  settings: settings,
                  isPrimary: true,
                ),
              ],
            ),
          ],
          if (isMJ) ...[
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: getTextController('MJSeverId'),
                    label: 'MJ服务器ID',
                    onChanged: (text) async {
                      await Config.saveSettings({'mj_sever_id': text});
                    },
                    settings: settings,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: getTextController('MJChannelId'),
                    label: 'MJ频道ID',
                    onChanged: (text) async {
                      await Config.saveSettings({'mj_channel_id': text});
                    },
                    settings: settings,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: getTextController('MJSelfId'),
                    label: 'MJ私信ID',
                    onChanged: (text) async {
                      await Config.saveSettings({'mj_self_id': text});
                    },
                    settings: settings,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: getTextController('NJSelfId'),
                    label: 'NJ私信ID',
                    onChanged: (text) async {
                      await Config.saveSettings({'nj_self_id': text});
                    },
                    settings: settings,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: getTextController('MJUserToken'),
                    label: 'MJ用户Token',
                    onChanged: (text) async {
                      await Config.saveSettings({'mj_user_token': text});
                    },
                    settings: settings,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildToggleCard(
                    title: 'Remix自动提交',
                    subtitle: '建议启用',
                    value: _remixAutoSubmit,
                    onChanged: (value) async {
                      await Config.saveSettings({'remix_auto_submit': value});
                      setState(() => _remixAutoSubmit = value);
                    },
                    settings: settings,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildToggleCard(
                    title: '加入账号池',
                    subtitle: '阅读说明书了解账号池机制',
                    value: _joinAccountPool,
                    onChanged: (value) async {
                      Map<String, dynamic> savedSettings = await Config.loadSettings();
                      bool canUseMJ = savedSettings['can_use_mj'] ?? false;
                      if (canUseMJ) {
                        await Config.saveSettings({'join_account_pool': value});
                        setState(() => _joinAccountPool = value);
                      } else {
                        showHint('您目前不可加入账号池，不保证您的账号的后续可用性，请阅读说明书了解');
                      }
                    },
                    settings: settings,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton(
                  label: '添加新账号',
                  onPressed: () async {
                    await addMJAccount();
                  },
                  settings: settings,
                  isPrimary: true,
                ),
                if (_haveMJAccount) ...[
                  const SizedBox(width: 16),
                  _buildActionButton(
                    label: '更新此账号',
                    onPressed: () async {
                      await refreshMJAccount();
                      await Config.saveSettings({'have_mj_account': true});
                      setState(() => _haveMJAccount = true);
                    },
                    settings: settings,
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    label: '删除此账号',
                    onPressed: () async {
                      await deleteMJAccount();
                    },
                    settings: settings,
                    isDanger: true,
                  ),
                ],
              ],
            ),
          ]
        ],
      ),
    );
  }

  // 开关卡片组件
  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required ChangeSettings settings,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? settings.getSelectedBgColor() : settings.getForegroundColor().withAlpha(25),
          ),
          color: value ? settings.getSelectedBgColor().withAlpha(25) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: settings.getForegroundColor(),
                      fontSize: 15,
                      fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: settings.getForegroundColor().withAlpha(153),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: settings.getSelectedBgColor(),
            ),
          ],
        ),
      ),
    );
  }

  // 扩展操作按钮支持危险操作样式
  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    required ChangeSettings settings,
    bool isPrimary = false,
    bool isDanger = false,
  }) {
    if (isDanger) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(label),
      );
    }

    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: settings.getSelectedBgColor(),
          foregroundColor: settings.getCardTextColor(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(label),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: settings.getSelectedBgColor(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        side: BorderSide(color: settings.getSelectedBgColor()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label),
    );
  }

  // ComfyUI 设置界面
  Widget _buildComfyUISettings(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ComfyUI 设置', settings),
        const SizedBox(height: 16),

        // 服务器设置
        _buildSettingsCard(
          title: '服务器设置',
          settings: settings,
          child: Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: getTextController('cuUrl'),
                  label: 'ComfyUI服务器地址',
                  hint: '输入包含端口号的完整地址',
                  onChanged: (text) async {
                    await Config.saveSettings({'cu_url': text});
                  },
                  settings: settings,
                ),
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                label: '测试连接',
                onPressed: () async {
                  await _testCUConnection();
                  if (context.mounted) {
                    int type = content.contains('连接成功') ? 2 : 3;
                    showHint(content, showType: type);
                  }
                },
                settings: settings,
                isPrimary: true,
              ),
            ],
          ),
        ),
        Visibility(
            visible: false,
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildSettingsCard(
                  title: '工作流配置',
                  settings: settings,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          '工作流:',
                          style: TextStyle(
                            color: settings.getForegroundColor(),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdownButton(
                          value: _selectedWorkflow,
                          items: _workflows,
                          onChanged: (newValue) async {
                            _selectedWorkflow = newValue;
                            await Config.saveSettings({
                              'select_cu_workflow': _selectedWorkflow,
                            });
                          },
                          settings: settings,
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildActionButton(
                        label: '获取工作流',
                        onPressed: () async {
                          Map<String, dynamic> savedSettings = await Config.loadSettings();
                          String savePath = savedSettings['image_save_path'] ?? '';
                          String folderPath = '$savePath${Platform.pathSeparator}cu_workflows';
                          List<String> workflowNames = await getNonHiddenFileNames(folderPath);
                          setState(() {
                            _workflows.clear();
                            _workflows.addAll(workflowNames);
                            if (_workflows.isNotEmpty) {
                              _selectedWorkflow = _workflows[0];
                            }
                          });
                        },
                        settings: settings,
                      ),
                    ],
                  ),
                ),
              ],
            ))
      ],
    );
  }

  // Fooocus 设置界面
  Widget _buildFooocusSettings(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Fooocus 设置', settings),
        const SizedBox(height: 16),

        // 服务器设置
        _buildSettingsCard(
          title: '服务器设置',
          settings: settings,
          child: Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: getTextController('fsUrl'),
                  label: 'Fooocus服务器地址',
                  hint: '输入包含端口号的完整地址',
                  onChanged: (text) async {
                    await Config.saveSettings({'fs_url': text});
                  },
                  settings: settings,
                ),
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                label: '测试连接',
                onPressed: () async {
                  await _testFSConnection();
                  if (context.mounted) {
                    int type = content.contains('连接成功') ? 2 : 3;
                    showHint(content, showType: type);
                  }
                },
                settings: settings,
                isPrimary: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 模型设置
        _buildSettingsCard(
          title: '模型配置',
          settings: settings,
          child: Column(
            children: [
              // 基础模型
              _buildModelRow(
                label: '基础模型',
                value: _selectedFSModel,
                items: _fsmodels,
                onChanged: (newValue) async {
                  await Config.saveSettings({'fs_base_model': newValue});
                  setState(() => _selectedFSModel = newValue);
                  if (context.mounted) {
                    showHint(
                      "模型更改成功，已更换为${newValue.split('.')[0]}模型",
                      showPosition: 2,
                      showTime: 2,
                    );
                  }
                },
                onRefresh: () async {
                  if (getControllerText('fsUrl').isNotEmpty) {
                    await _getFSModels(false);
                  } else {
                    showHint('请先配置Fooocus地址');
                  }
                },
                settings: settings,
              ),
              const SizedBox(height: 16),

              // 精炼模型
              _buildModelRow(
                label: '精炼模型',
                value: _selectedFSREModel,
                items: _fsREmodels,
                onChanged: (newValue) async {
                  await Config.saveSettings({'fs_ref_model': newValue});
                  setState(() => _selectedFSREModel = newValue);
                  if (context.mounted) {
                    showHint(
                      "精炼模型更改成功，已更换为${newValue.split('.')[0]}模型",
                      showPosition: 2,
                      showTime: 2,
                    );
                  }
                },
                onRefresh: () async {
                  if (getControllerText('fsUrl').isNotEmpty) {
                    await _getFSModels(true);
                  } else {
                    showHint('请先配置Fooocus地址');
                  }
                },
                settings: settings,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 样式设置
        _buildSettingsCard(
          title: '样式配置',
          settings: settings,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '选择绘图样式:',
                    style: TextStyle(
                      color: settings.getForegroundColor(),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStyleSelector(
                      value: _selectedFSStyle,
                      items: fsStyleChoices,
                      onChanged: setMultipleSelected,
                      settings: settings,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    label: '获取可用样式',
                    onPressed: () async {
                      if (getControllerText('fsUrl').isNotEmpty) {
                        await _getFSStyles();
                      } else {
                        showHint('请先配置Fooocus地址');
                      }
                    },
                    settings: settings,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPerformanceSettings(settings),
            ],
          ),
        ),
      ],
    );
  }

  // 模型选择行组件
  Widget _buildModelRow({
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
    required Function() onRefresh,
    required ChangeSettings settings,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              color: settings.getForegroundColor(),
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDropdownButton(
            value: value,
            items: items,
            onChanged: onChanged,
            settings: settings,
          ),
        ),
        const SizedBox(width: 16),
        _buildActionButton(
          label: '刷新模型列表',
          onPressed: onRefresh,
          settings: settings,
        ),
      ],
    );
  }

  // 样式选择器组件
  Widget _buildStyleSelector({
    required List<String> value,
    required List<String> items,
    required Function(List<String>) onChanged,
    required ChangeSettings settings,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = value.contains(item);
        return InkWell(
          onTap: () {
            final newSelection = List<String>.from(value);
            if (isSelected) {
              newSelection.remove(item);
            } else {
              newSelection.add(item);
            }
            onChanged(newSelection);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isSelected ? settings.getSelectedBgColor().withAlpha(25) : null,
              border: Border.all(
                color: isSelected ? settings.getSelectedBgColor() : settings.getForegroundColor().withAlpha(51),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              item,
              style: TextStyle(
                color: settings.getForegroundColor(),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 性能设置组件
  Widget _buildPerformanceSettings(ChangeSettings settings) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '绘图性能:',
                style: TextStyle(
                  color: settings.getForegroundColor(),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              _buildDropdownButton(
                value: _selectedFSQulality,
                items: _fsQulalities,
                onChanged: (newValue) async {
                  await Config.saveSettings({'fs_performance_selection': newValue});
                  setState(() => _selectedFSQulality = newValue);
                },
                settings: settings,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDimensionField(
            label: '图片宽度',
            controller: getTextController('fsPicWidth'),
            hint: '1024',
            onChanged: (value) async {
              if (value.isNotEmpty) {
                await Config.saveSettings({
                  'fs_width': int.parse(value),
                });
              }
            },
            settings: settings,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDimensionField(
            label: '图片高度',
            controller: getTextController('fsPicHeight'),
            hint: '1024',
            onChanged: (value) async {
              if (value.isNotEmpty) {
                await Config.saveSettings({
                  'fs_height': int.parse(value),
                });
              }
            },
            settings: settings,
          ),
        ),
      ],
    );
  }

  // 尺寸输入框组件
  Widget _buildDimensionField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required Function(String) onChanged,
    required ChangeSettings settings,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: settings.getForegroundColor(),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        _buildNumberField(
          controller: controller,
          hint: hint,
          helperText: '范围：64-2048',
          onChanged: onChanged,
          settings: settings,
        ),
      ],
    );
  }

  // 文件保存设置
  Widget _buildFileSaveSettings(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('文件保存设置', settings),
        const SizedBox(height: 16),
        // 基本保存路径设置
        _buildSettingsCard(
          title: '基础路径配置',
          settings: settings,
          child: Column(
            children: [
              // 图片保存路径
              _buildPathSelector(
                label: '图片保存路径',
                subtitle: '用于保存生成的图片和相关资源',
                hint: '暂不支持中文，请使用拼音或英文',
                controller: getTextController('imageSavePath'),
                onPathSelected: (path) async {
                  if (path != null) {
                    _handleImagePathSelection(path);
                  }
                },
                onSave: () async {
                  await _saveImagePath();
                },
                settings: settings,
              ),
              const SizedBox(height: 16),
              // 草稿保存路径
              _buildPathSelector(
                label: '剪映草稿保存路径',
                subtitle: '用于保存剪映草稿相关文件',
                controller: getTextController('draftPath'),
                onPathSelected: (path) async {
                  if (path != null) {
                    _updateControllerValue('draftPath', path);
                    if (path.isNotEmpty) {
                      await Config.saveSettings({'jy_draft_save_path': path});
                      await commonCreateDirectory(path);
                      showHint('剪映草稿保存路径设置成功', showType: 2);
                    }
                  }
                },
                onSave: () async {
                  if (getControllerText('draftPath').isNotEmpty) {
                    await Config.saveSettings({
                      'jy_draft_save_path': getControllerText('draftPath'),
                    });
                    showHint('剪映草稿保存路径设置成功', showType: 2);
                  } else {
                    showHint('路径为空不能设置，将使用上次的成功配置', showType: 3);
                  }
                },
                settings: settings,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 语音设置
  Widget _buildVoiceSettings(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('语音设置', settings),
        const SizedBox(height: 16),
        // 语音引擎选择
        _buildSettingsCard(
          title: '语音引擎',
          settings: settings,
          child: _buildVoiceEngineSelector(settings),
        ),
        if (GlobalParams.isFreeVersion || GlobalParams.isAdminVersion) ...[
          const SizedBox(height: 16),
          // 引擎特定配置
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildVoiceEngineConfig(settings),
          ),
        ]
      ],
    );
  }

  // 路径选择器组件
  Widget _buildPathSelector({
    required String label,
    required TextEditingController controller,
    required Function(String?) onPathSelected,
    required Function() onSave,
    required ChangeSettings settings,
    String? subtitle,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subtitle != null) ...[
          Text(
            label,
            style: TextStyle(
              color: settings.getForegroundColor(),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: settings.getForegroundColor().withAlpha(153),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: InkWell(
                onDoubleTap: () async {
                  String? directoryPath = await FilePicker.platform.getDirectoryPath();
                  onPathSelected(directoryPath);
                },
                child: _buildTextField(
                  controller: controller,
                  label: label,
                  hint: hint,
                  isShow: true,
                  onChanged: (_) {},
                  settings: settings,
                ),
              ),
            ),
            const SizedBox(width: 16),
            _buildActionButton(
              label: '选择路径',
              onPressed: () async {
                String? directoryPath = await FilePicker.platform.getDirectoryPath();
                onPathSelected(directoryPath);
              },
              settings: settings,
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              label: '保存设置',
              onPressed: onSave,
              settings: settings,
              isPrimary: true,
            ),
          ],
        ),
      ],
    );
  }

  // 语音引擎选择器
  Widget _buildVoiceEngineSelector(ChangeSettings settings) {
    const engines = [
      {'id': 0, 'name': '百度语音', 'icon': Icons.speaker},
      {'id': 1, 'name': '阿里语音', 'icon': Icons.record_voice_over},
      {'id': 2, 'name': '华为语音', 'icon': Icons.mic},
      {'id': 3, 'name': '微软语音', 'icon': Icons.headset_mic},
    ];

    return Row(
      children: engines.map((engine) {
        final isSelected = _voiceSelectedMode == engine['id'];
        return Expanded(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: InkWell(
                onTap: () async {
                  await Config.saveSettings({'use_voice_mode': engine['id']});
                  setState(() => _voiceSelectedMode = engine['id'] as int);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? settings.getSelectedBgColor() : settings.getForegroundColor().withAlpha(25),
                    ),
                    color: isSelected ? settings.getSelectedBgColor().withAlpha(25) : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        engine['icon'] as IconData,
                        size: 32,
                        color: isSelected ? settings.getSelectedBgColor() : settings.getForegroundColor(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        engine['name'] as String,
                        style: TextStyle(
                          color: settings.getForegroundColor(),
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        );
      }).toList(),
    );
  }

  // 语音引擎配置
  Widget _buildVoiceEngineConfig(ChangeSettings settings) {
    switch (_voiceSelectedMode) {
      case 0:
        return _buildBaiduVoiceConfig(settings);
      case 1:
        return _buildAliVoiceConfig(settings);
      case 2:
        return _buildHuaweiVoiceConfig(settings);
      case 3:
        return _buildAzureVoiceConfig(settings);
      default:
        return const SizedBox.shrink();
    }
  }

  // 百度语音配置
  Widget _buildBaiduVoiceConfig(ChangeSettings settings) {
    return _buildSettingsCard(
      title: '百度语音配置',
      settings: settings,
      child: Row(
        children: [
          Expanded(
            child: _buildTextField(
              controller: getTextController('baiduVoiceApiKey'),
              label: 'API Key',
              onChanged: (text) async {
                await Config.saveSettings({'baidu_voice_api_key': text});
              },
              settings: settings,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTextField(
              controller: getTextController('baiduVoiceSecretKey'),
              label: 'Secret Key',
              onChanged: (text) async {
                await Config.saveSettings({'baidu_voice_secret_key': text});
              },
              settings: settings,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTextField(
              controller: getTextController('baiduVoiceAppId'),
              label: 'App ID',
              onChanged: (text) async {
                await Config.saveSettings({'baidu_voice_app_id': text});
              },
              settings: settings,
            ),
          ),
        ],
      ),
    );
  }

  // 阿里语音配置
  Widget _buildAliVoiceConfig(ChangeSettings settings) {
    return _buildSettingsCard(
      title: '阿里语音配置',
      settings: settings,
      child: Row(
        children: [
          Expanded(
            child: _buildTextField(
              controller: getTextController('aliVoiceAccessId'),
              label: 'Access ID',
              onChanged: (text) async {
                await Config.saveSettings({'ali_voice_access_id': text});
              },
              settings: settings,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTextField(
              controller: getTextController('aliVoiceAccessSecret'),
              label: 'Access Secret',
              onChanged: (text) async {
                await Config.saveSettings({'ali_voice_access_secret': text});
              },
              settings: settings,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTextField(
              controller: getTextController('aliVoiceAppKey'),
              label: 'App Key',
              onChanged: (text) async {
                await Config.saveSettings({'ali_voice_app_key': text});
              },
              settings: settings,
            ),
          ),
        ],
      ),
    );
  }

  // 华为语音配置
  Widget _buildHuaweiVoiceConfig(ChangeSettings settings) {
    return _buildSettingsCard(
      title: '华为语音配置',
      settings: settings,
      child: Row(
        children: [
          Expanded(
            child: _buildTextField(
              controller: getTextController('huaweiVoiceAK'),
              label: 'AK',
              onChanged: (text) async {
                await Config.saveSettings({'huawei_voice_ak': text});
              },
              settings: settings,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTextField(
              controller: getTextController('huaweiVoiceSK'),
              label: 'SK',
              onChanged: (text) async {
                await Config.saveSettings({'huawei_voice_sk': text});
              },
              settings: settings,
            ),
          ),
        ],
      ),
    );
  }

  // 微软语音配置
  Widget _buildAzureVoiceConfig(ChangeSettings settings) {
    return _buildSettingsCard(
      title: '微软语音配置',
      settings: settings,
      child: _buildTextField(
        controller: getTextController('azureVoiceSK'),
        label: 'Speech Key',
        onChanged: (text) async {
          await Config.saveSettings({'azure_voice_speech_key': text});
        },
        settings: settings,
      ),
    );
  }

  // 处理图片保存路径选择
  void _handleImagePathSelection(String path) async {
    _updateControllerValue('imageSavePath', path);
    if (path.isNotEmpty) {
      if (containsChinese(path)) {
        showHint('文件保存路径设置失败，文件保存路径不能包含中文，请更换保存路径', showType: 3);
      } else {
        await Config.saveSettings({'image_save_path': path});
        await commonCreateDirectory(path);
        Map<String, dynamic> savedSettings = await Config.loadSettings();
        String savePath = savedSettings['image_save_path'] ?? '';
        await commonCreateDirectory('$savePath${Platform.pathSeparator}cu_workflows');
        showHint('文件保存路径设置成功', showType: 2);
      }
    }
  }

  // 保存图片路径
  Future<void> _saveImagePath() async {
    int type = 2;
    if (getControllerText('imageSavePath').isNotEmpty) {
      if (containsChinese(getControllerText('imageSavePath'))) {
        type = 3;
        draftContent = '文件保存路径设置失败，文件保存路径不能包含中文，请更换保存路径';
      } else {
        await Config.saveSettings({
          'image_save_path': getControllerText('imageSavePath'),
        });
        await commonCreateDirectory(getControllerText('imageSavePath'));
        Map<String, dynamic> savedSettings = await Config.loadSettings();
        String savePath = savedSettings['image_save_path'] ?? '';
        await commonCreateDirectory('$savePath${Platform.pathSeparator}cu_workflows');
        draftContent = '文件保存路径设置成功';
      }
    } else {
      type = 3;
      draftContent = '文件保存路径设置失败，路径为空不能设置，将使用上次的成功配置';
    }
    if (context.mounted) {
      showHint(draftContent, showType: type);
    }
  }

  // AI引擎设置
  Widget _buildAIEngineSettings(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('AI引擎设置', settings),
        const SizedBox(height: 16),
        // 引擎选择
        _buildSettingsCard(
          title: '选择AI引擎',
          settings: settings,
          child: _buildAIEngineSelector(settings),
        ),
        const SizedBox(height: 16),

        // 引擎特定配置
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildAIEngineConfig(settings),
        ),
      ],
    );
  }

// AI引擎选择器
  Widget _buildAIEngineSelector(ChangeSettings settings) {
    const engines = [
      {'id': 0, 'name': 'ChatGPT', 'icon': Icons.chat_bubble_outline},
      {'id': 1, 'name': '通义千问', 'icon': Icons.psychology_outlined},
      {'id': 2, 'name': '智谱AI', 'icon': Icons.smart_toy_outlined},
    ];

    return Row(
      children: engines.map((engine) {
        final isSelected = _selectedMode == engine['id'];
        return Expanded(
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: InkWell(
                  onTap: () async {
                    await Config.saveSettings({'use_mode': engine['id']});
                    setState(() => _selectedMode = engine['id'] as int);
                    if (mounted) {
                      Provider.of<ChangeSettings>(context, listen: false).changeValue({'use_mode': engine['id']});
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 200,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? settings.getSelectedBgColor() : settings.getForegroundColor().withAlpha(25),
                      ),
                      color: isSelected ? settings.getSelectedBgColor().withAlpha(25) : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          engine['icon'] as IconData,
                          size: 36,
                          color: isSelected ? settings.getSelectedBgColor() : settings.getForegroundColor(),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          engine['name'] as String,
                          style: TextStyle(
                            color: settings.getForegroundColor(),
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                )));
      }).toList(),
    );
  }

// AI引擎配置
  Widget _buildAIEngineConfig(ChangeSettings settings) {
    switch (_selectedMode) {
      case 0:
        return _buildChatGPTConfig(settings);
      case 1:
        return _buildTongYiConfig(settings);
      case 2:
        return _buildZhiPuConfig(settings);
      default:
        return const SizedBox.shrink();
    }
  }

// ChatGPT配置
  Widget _buildChatGPTConfig(ChangeSettings settings) {
    return Column(
      children: [
        // API模式选择
        _buildSettingsCard(
          title: '使用模式',
          settings: settings,
          child: _buildChatGPTModeSelector(settings),
        ),
        const SizedBox(height: 16),

        // 配置详情
        _buildSettingsCard(
          title: 'API配置',
          settings: settings,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _chatGPTSelectedMode == 0 ? _buildChatGPTApiConfig(settings) : _buildChatGPTWebConfig(settings),
          ),
        ),
      ],
    );
  }

// ChatGPT模式选择器
  Widget _buildChatGPTModeSelector(ChangeSettings settings) {
    return Row(
      children: [
        _buildModeOption(
          title: 'API模式',
          value: 0,
          groupValue: _chatGPTSelectedMode,
          onChanged: (value) async {
            await Config.saveSettings({'ChatGPTUseMode': value});
            setState(() => _chatGPTSelectedMode = value!);
            if (mounted) {
              Provider.of<ChangeSettings>(context, listen: false).changeValue({'ChatGPTUseMode': value});
            }
          },
          settings: settings,
        ),
        const SizedBox(width: 16),
        _buildModeOption(
          title: 'Web模式',
          value: 1,
          groupValue: _chatGPTSelectedMode,
          onChanged: (value) async {
            await Config.saveSettings({'ChatGPTUseMode': value});
            setState(() => _chatGPTSelectedMode = value!);
            if (mounted) {
              Provider.of<ChangeSettings>(context, listen: false).changeValue({'ChatGPTUseMode': value});
            }
          },
          settings: settings,
        ),
      ],
    );
  }

// 模式选项卡
  Widget _buildModeOption({
    required String title,
    required int value,
    required int groupValue,
    required Function(int?) onChanged,
    required ChangeSettings settings,
  }) {
    final isSelected = value == groupValue;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? settings.getSelectedBgColor() : settings.getForegroundColor().withAlpha(25),
            ),
            color: isSelected ? settings.getSelectedBgColor().withAlpha(25) : null,
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: settings.getForegroundColor(),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

// ChatGPT API配置
  Widget _buildChatGPTApiConfig(ChangeSettings settings) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: getTextController('chatGPTApiKey'),
                label: 'API Key',
                hint: 'sk-xxxxxxxxxxxx',
                onChanged: (value) async {
                  await Config.saveSettings({'chat_api_key': value});
                  OpenAIClientSingleton.instance.updateApiKey(value);
                },
                settings: settings,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: getTextController('chatGPTApiUrl'),
                label: 'API接口地址',
                hint: 'http(s)://openai.api',
                onChanged: (value) async {
                  await Config.saveSettings({'chat_api_url': value});
                  OpenAIClientSingleton.instance.updateBaseUrl(value);
                },
                settings: settings,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildActionButton(
              label: '测试连接',
              onPressed: () async {
                await testOpenAI(
                  getControllerText('chatGPTApiUrl'),
                  "gpt-3.5-turbo",
                  "你好,请回答我测试成功",
                  getControllerText('chatGPTApiUrl'),
                );
                if (context.mounted) {
                  int showType = content.contains('成功') ? 2 : 3;
                  showHint(content, showTime: 300, showType: showType);
                }
              },
              settings: settings,
              isPrimary: true,
            ),
          ],
        ),
      ],
    );
  }

// ChatGPT Web配置
  Widget _buildChatGPTWebConfig(ChangeSettings settings) {
    return Column(
      children: [
        _buildTextField(
          controller: getTextController('chatProxy'),
          label: 'ChatGPT代理服务地址',
          hint: 'https://xxxxxxxxxxxx',
          onChanged: (text) async {
            await Config.saveSettings({'chat_web_proxy': text});
            if (mounted) {
              Provider.of<ChangeSettings>(context, listen: false).changeValue({'chat_web_proxy': text});
            }
          },
          settings: settings,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildActionButton(
              label: '测试连接',
              onPressed: () async {
                await testWebOpenAI(getControllerText('chatProxy'));
              },
              settings: settings,
              isPrimary: true,
            ),
          ],
        ),
      ],
    );
  }

// 通义千问配置
  Widget _buildTongYiConfig(ChangeSettings settings) {
    return _buildSettingsCard(
      title: '通义千问配置',
      settings: settings,
      child: Column(
        children: [
          _buildTextField(
            controller: getTextController('tyqwApiKey'),
            label: 'API Key',
            hint: 'sk-xxxxxxxxxxxx',
            onChanged: (text) async {
              await Config.saveSettings({'tyqw_api_key': text});
            },
            settings: settings,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton(
                label: '测试连接',
                onPressed: () async {
                  await testTYQWAI();
                  if (context.mounted) {
                    showHint(content, showPosition: 2, showTime: 3);
                  }
                },
                settings: settings,
                isPrimary: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

// 智谱AI配置
  Widget _buildZhiPuConfig(ChangeSettings settings) {
    return _buildSettingsCard(
      title: '智谱AI配置',
      settings: settings,
      child: Column(
        children: [
          _buildTextField(
            controller: getTextController('zpaiApiKey'),
            label: 'API Key',
            hint: 'xxxxxxxxxxxx.xxxx',
            onChanged: (text) async {
              await Config.saveSettings({'zpai_api_key': text});
            },
            settings: settings,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton(
                label: '测试连接',
                onPressed: () async {
                  await testZPAI();
                  if (context.mounted) {
                    showHint(content, showPosition: 2, showTime: 3);
                  }
                },
                settings: settings,
                isPrimary: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 翻译设置
  Widget _buildTranslationSettings(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('翻译设置', settings),
        const SizedBox(height: 16),

        // 百度翻译设置
        _buildSettingsCard(
          title: '百度翻译',
          settings: settings,
          child: Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: getTextController('baiduTranslateAppId'),
                  label: 'App ID',
                  onChanged: (text) async {
                    await Config.saveSettings({'baidu_trans_app_id': text});
                  },
                  settings: settings,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: getTextController('baiduTranslateAppKey'),
                  label: 'App Key',
                  onChanged: (text) async {
                    await Config.saveSettings({'baidu_trans_app_key': text});
                  },
                  settings: settings,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // DeepL翻译设置
        _buildSettingsCard(
          title: 'DeepL翻译',
          settings: settings,
          child: _buildTextField(
            controller: getTextController('deeplTranslateAppKey'),
            label: 'API Key',
            onChanged: (text) async {
              await Config.saveSettings({'deepl_api_key': text});
            },
            settings: settings,
          ),
        ),
      ],
    );
  }

// 数据库设置
  Widget _buildDatabaseSettings(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Supabase数据库设置', settings),
        const SizedBox(height: 16),

        _buildSettingsCard(
          title: '数据库配置',
          settings: settings,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: getTextController('supabaseUrl'),
                      label: '连接地址',
                      onChanged: (text) async {
                        await Config.saveSettings({'supabase_url': text});
                      },
                      settings: settings,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: getTextController('supabaseKey'),
                      label: '公钥',
                      onChanged: (text) async {
                        await Config.saveSettings({'supabase_key': text});
                      },
                      settings: settings,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    label: '初始化数据库',
                    onPressed: () async {
                      try {
                        var client = await SupabaseHelper().init();
                        commonPrint(client);
                        int showType = client != null ? 2 : 3;
                        String content = client != null ? '数据库初始化成功' : '数据库初始化失败，请检查配置';
                        showHint(content, showType: showType);
                      } catch (e) {
                        if ('$e'.contains('already initialized')) {
                          showHint('数据库已经初始化了,无需再次初始化。');
                        } else {
                          commonPrint(e);
                          showHint('数据库初始化失败，请检查配置');
                        }
                      }
                    },
                    settings: settings,
                    isPrimary: true,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 扩展功能设置
        _buildSettingsCard(
          title: '扩展功能配置',
          settings: settings,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 码/易支付设置
              Text(
                '码/易支付设置',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: settings.getForegroundColor(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: getTextController('merchantID'),
                      label: '商户ID',
                      onChanged: (text) async {
                        await Config.saveSettings({'merchant_id': text});
                      },
                      settings: settings,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: getTextController('merchantKey'),
                      label: '商户公钥',
                      onChanged: (text) async {
                        await Config.saveSettings({'merchant_key': text});
                      },
                      settings: settings,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: getTextController('merchantUrl'),
                      label: '接口地址',
                      onChanged: (text) async {
                        await Config.saveSettings({'merchant_url': text});
                      },
                      settings: settings,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 知识库设置
              Text(
                '知识库(QA)设置',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: settings.getForegroundColor(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: getTextController('KBAppId'),
                      label: '管理秘钥',
                      onChanged: (text) async {
                        await Config.saveSettings({'kb_app_id': text});
                      },
                      settings: settings,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: getTextController('KBAppSec'),
                      label: '问答秘钥',
                      onChanged: (text) async {
                        await Config.saveSettings({'kb_app_sec': text});
                      },
                      settings: settings,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // OSS设置
  Widget _buildOSSSettings(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('阿里云OSS设置', settings),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: 'OSS基础配置',
          settings: settings,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: getTextController('ossBucketName'),
                      label: 'Bucket名称',
                      onChanged: (text) async {
                        await Config.saveSettings({'oss_bucket_name': text});
                      },
                      settings: settings,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: getTextController('ossEndpoint'),
                      label: '访问端点',
                      onChanged: (text) async {
                        await Config.saveSettings({'oss_endpoint': text});
                      },
                      settings: settings,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: getTextController('ossApiUrl'),
                      label: '认证地址',
                      onChanged: (text) async {
                        await Config.saveSettings({'oss_api_url': text});
                      },
                      settings: settings,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    label: '测试连接',
                    onPressed: () async {
                      FilePickerResult? result = await FilePickerManager().pickFiles();
                      if (result != null) {
                        showHint('正在测试文件上传到oss...', showType: 5);
                        File file = File(result.files.single.path!);
                        String fileType = file.path.split('.').last;
                        String fileName = path.basenameWithoutExtension(file.path);
                        String url = await uploadFileToALiOss(
                          file.path,
                          '',
                          file,
                          fileType: fileType,
                          setFileName: fileName,
                          needDelete: false,
                        );
                        int type = url != '' ? 2 : 3;
                        commonPrint('${GlobalParams.filesUrl}$url');
                        content = url != '' ? '连接成功' : '连接失败';
                        showHint(content, showType: type);
                      } else {
                        showHint('未选择文件无法测试oss连接');
                      }
                    },
                    settings: settings,
                    isPrimary: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

// AI音乐设置
  Widget _buildAIMusicSettings(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('AI音乐(Suno)设置', settings),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: '接口配置',
          settings: settings,
          child: Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: getTextController('SunoUrl'),
                  label: '中转地址',
                  onChanged: (text) async {
                    await Config.saveSettings({'suno_api_url': text});
                  },
                  settings: settings,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: getTextController('SunoKey'),
                  label: '中转密钥',
                  onChanged: (text) async {
                    await Config.saveSettings({'suno_api_key': text});
                  },
                  settings: settings,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

// AI视频设置
  Widget _buildAIVideoSettings(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('AI视频(Luma)设置', settings),
        const SizedBox(height: 16),

        // 平台渠道选择
        _buildSettingsCard(
          title: '平台渠道',
          settings: settings,
          child: Row(
            children: [
              Expanded(
                child: _buildChannelOption(
                  title: '自有账号',
                  value: 0,
                  groupValue: _lumaSelectedMode,
                  onChanged: (value) async {
                    await Config.saveSettings({'use_luma_mode': value});
                    setState(() => _lumaSelectedMode = value!);
                  },
                  settings: settings,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildChannelOption(
                  title: '自定义中转',
                  value: 1,
                  groupValue: _lumaSelectedMode,
                  onChanged: (value) async {
                    await Config.saveSettings({'use_luma_mode': value});
                    setState(() => _lumaSelectedMode = value!);
                  },
                  settings: settings,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 配置详情
        _buildSettingsCard(
          title: '接口配置',
          settings: settings,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _lumaSelectedMode == 0 ? _buildLumaAccountConfig(settings) : _buildLumaProxyConfig(settings),
          ),
        ),
      ],
    );
  }

// 平台渠道选项
  Widget _buildChannelOption({
    required String title,
    required int value,
    required int groupValue,
    required Function(int?) onChanged,
    required ChangeSettings settings,
  }) {
    final isSelected = value == groupValue;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? settings.getSelectedBgColor() : settings.getForegroundColor().withAlpha(25),
        ),
        color: isSelected ? settings.getSelectedBgColor().withAlpha(25) : null,
      ),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Radio<int>(
                value: value,
                groupValue: groupValue,
                onChanged: onChanged,
                activeColor: settings.getSelectedBgColor(),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: settings.getForegroundColor(),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Luma自有账号配置
  Widget _buildLumaAccountConfig(ChangeSettings settings) {
    return _buildTextField(
      controller: getTextController('LumaCookie'),
      label: 'Luma的Cookie',
      onChanged: (text) async {
        await Config.saveSettings({'luma_cookie': text});
      },
      settings: settings,
    );
  }

// Luma中转配置
  Widget _buildLumaProxyConfig(ChangeSettings settings) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildTextField(
            controller: getTextController('LumaUrl'),
            label: '中转地址',
            onChanged: (text) async {
              await Config.saveSettings({'luma_api_url': text});
            },
            settings: settings,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTextField(
            controller: getTextController('LumaKey'),
            label: '中转密钥',
            onChanged: (text) async {
              await Config.saveSettings({'luma_api_token': text});
            },
            settings: settings,
          ),
        ),
      ],
    );
  }

// 月之暗面设置
  Widget _buildMoonshotSettings(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('月之暗面设置', settings),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: 'API配置',
          settings: settings,
          child: _buildTextField(
            controller: getTextController('moonshotKey'),
            label: 'API Key',
            onChanged: (text) async {
              await Config.saveSettings({'moonshot_api_key': text});
            },
            settings: settings,
          ),
        ),
      ],
    );
  }

// 退出应用设置
  Widget _buildExitSettings(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('退出应用设置', settings),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: '退出模式',
          settings: settings,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: _buildExitModeOption(
                      title: '退出时询问',
                      subtitle: '每次退出时显示确认对话框',
                      value: -1,
                      settings: settings,
                    )),
              ),
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _buildExitModeOption(
                        title: Platform.isMacOS ? '最小化到程序坞' : '最小化到系统托盘',
                        subtitle: '应用将继续在后台运行',
                        value: 0,
                        settings: settings,
                      ))),
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _buildExitModeOption(
                        title: '退出应用',
                        subtitle: '完全关闭应用程序',
                        value: 1,
                        settings: settings,
                      ))),
            ],
          ),
        ),
      ],
    );
  }

// 退出模式选项卡
  Widget _buildExitModeOption({
    required String title,
    required String subtitle,
    required int value,
    required ChangeSettings settings,
  }) {
    final isSelected = _exitAppMode == value;
    return InkWell(
      onTap: () async {
        await Config.saveSettings({'exit_app_method': value});
        setState(() => _exitAppMode = value);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? settings.getSelectedBgColor() : settings.getForegroundColor().withAlpha(76),
          ),
          color: isSelected ? settings.getSelectedBgColor().withAlpha(76) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: settings.getForegroundColor(),
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: settings.getForegroundColor().withAlpha(153),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
