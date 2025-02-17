/// SettingsState 管理应用程序的各种配置状态
/// 包括AI引擎、绘图引擎、语音、翻译等各个模块的配置
///
/// 该类负责:
/// 1. 维护所有配置项的TextEditingController
/// 2. 提供统一的状态更新接口
/// 3. 确保所有控制器的正确释放
///
/// 使用方式:
/// ```dart
/// final state = SettingsState();
/// // 使用getTextController获取控制器
/// final controller = state.getTextController('chatApiKey');
/// // 或者直接使用属性
/// state.chatApiKey.text = 'new value';
/// ```
import 'package:flutter/material.dart';
import 'package:tuitu/utils/common_methods.dart';

class SettingsState extends ChangeNotifier {
  // 邀请码设置
  final inviteCode = TextEditingController();

  // AI引擎状态
  int selectedMode = 0;
  int chatGPTSelectedMode = 0;
  final chatApiKey = TextEditingController();
  final chatApiUrl = TextEditingController();
  final tyqwApiKey = TextEditingController();
  final zpaiApiKey = TextEditingController();

  // 绘图引擎状态
  bool supportDrawEngine1 = false;
  bool supportDrawEngine2 = false;
  bool supportDrawEngine3 = false;
  bool supportDrawEngine4 = false;
  bool supportDrawEngine5 = false;
  int drawEngine = 0;
  final midjourneyApiUrl = TextEditingController();
  final midjourneyApiToken = TextEditingController();
  final sdApiUrl = TextEditingController();
  final cuApiUrl = TextEditingController();
  final sdUsername = TextEditingController();
  final sdPassword = TextEditingController();

  // 翻译设置
  final baiduTransAppId = TextEditingController();
  final baiduTransAppKey = TextEditingController();
  final deeplApiKey = TextEditingController();

  // 文件保存设置
  final imageSavePath = TextEditingController();
  final jyDraftSavePath = TextEditingController();

  // 语音设置
  int voiceSelectedMode = 0;
  final baiduVoiceApiKey = TextEditingController();
  final baiduVoiceSecretKey = TextEditingController();
  final baiduVoiceAppId = TextEditingController();
  final aliVoiceAccessId = TextEditingController();
  final aliVoiceAccessSecret = TextEditingController();
  final aliVoiceAppKey = TextEditingController();
  final huaweiVoiceAk = TextEditingController();
  final huaweiVoiceSk = TextEditingController();
  final azureVoiceSpeechKey = TextEditingController();

  // 视频设置
  int lumaSelectedMode = 0;
  final lumaCookie = TextEditingController();
  final lumaApiUrl = TextEditingController();
  final lumaApiToken = TextEditingController();

  // 音乐设置
  final sunoApiUrl = TextEditingController();
  final sunoApiKey = TextEditingController();

  // 数据库设置
  final supabaseUrl = TextEditingController();
  final supabaseKey = TextEditingController();
  final merchantId = TextEditingController();
  final merchantKey = TextEditingController();
  final merchantUrl = TextEditingController();
  final kbAppId = TextEditingController();
  final kbAppSec = TextEditingController();

  // OSS设置
  final ossBucketName = TextEditingController();
  final ossEndpoint = TextEditingController();
  final ossApiUrl = TextEditingController();

  // 月之暗面设置
  final moonshotApiKey = TextEditingController();

  // SD配置相关控制器
  final steps = TextEditingController();
  final picWidth = TextEditingController();
  final picHeight = TextEditingController();
  final denoising = TextEditingController();
  final hireFix1 = TextEditingController(); // 高清迭代步数
  final hireFix2 = TextEditingController(); // 高清重绘幅度
  final hireFix3 = TextEditingController(); // 高清放大倍数

  // SD提示词相关控制器
  final selfPositivePrompts = TextEditingController();
  final selfNegativePrompts = TextEditingController();
  final combinedPositivePrompts = TextEditingController();
  final lora = TextEditingController();
  bool isSelfPositivePrompt = false;
  bool isSelfNegativePrompt = false;
  bool isMixPrompt = false;
  String selectedOption = '1.基本提示(通用)';

  /// 根据名称获取对应的文本控制器
  ///
  /// [name] 可以是下划线格式(如'chat_api_key')或驼峰格式(如'chatApiKey')
  ///
  /// Throws:
  /// - [Exception] 当无法找到对应的控制器时抛出异常
  TextEditingController getTextController(String name) {
    switch (name) {
      // 邀请码设置
      case 'inviteCode':
      case 'invite_code':
        return inviteCode;
      // AI引擎控制器
      case 'chatApiKey':
      case 'chat_api_key':
        return chatApiKey;
      case 'chatApiUrl':
      case 'chat_api_url':
        return chatApiUrl;
      case 'tyqw_api_key':
      case 'tyqwApiKey':
        return tyqwApiKey;
      case 'zpai_api_key':
      case 'zpaiApiKey':
        return zpaiApiKey;

      // 绘图引擎控制器
      case 'midjourneyApiUrl':
      case 'mj_api_url':
        return midjourneyApiUrl;
      case 'midjourneyApiToken':
      case 'mj_api_secret':
        return midjourneyApiToken;
      case 'sdApiUrl':
      case 'sd_api_url':
        return sdApiUrl;
      case 'cuApiUrl':
      case 'cu_api_url':
        return cuApiUrl;  
      case 'sd_username':
      case 'sdUsername':
        return sdUsername;
      case 'sd_password':
      case 'sdPassword':
        return sdPassword;

      // 翻译控制器
      case 'baiduTransAppId':
      case 'baidu_trans_app_id':
        return baiduTransAppId;
      case 'baiduTransAppKey':
      case 'baidu_trans_app_key':
        return baiduTransAppKey;
      case 'deeplApiKey':
      case 'deepl_api_key':
        return deeplApiKey;

      // 文件保存控制器
      case 'image_save_path':
      case 'imageSavePath':
        return imageSavePath;
      case 'draftPath':
      case 'jy_draft_save_path':
        return jyDraftSavePath;

      // 语音控制器
      case 'baidu_voice_api_key':
      case 'baiduVoiceApiKey':
        return baiduVoiceApiKey;
      case 'baidu_voice_secret_key':
      case 'baiduVoiceSecretKey':
        return baiduVoiceSecretKey;
      case 'baidu_voice_app_id':
      case 'baiduVoiceAppId':
        return baiduVoiceAppId;
      case 'ali_voice_access_id':
      case 'aliVoiceAccessId':
        return aliVoiceAccessId;
      case 'ali_voice_access_secret':
      case 'aliVoiceAccessSecret':
        return aliVoiceAccessSecret;
      case 'ali_voice_app_key':
      case 'aliVoiceAppKey':
        return aliVoiceAppKey;
      case 'huaweiVoiceAk':
      case 'huawei_voice_ak':
        return huaweiVoiceAk;
      case 'huaweiVoiceSk':
      case 'huawei_voice_sk':
        return huaweiVoiceSk;
      case 'azureVoiceSpeechKey':
      case 'azure_voice_speech_key':
        return azureVoiceSpeechKey;

      // 视频控制器
      case 'lumaCookie':
      case 'luma_cookie':
        return lumaCookie;
      case 'lumaApiUrl':
      case 'luma_api_url':
        return lumaApiUrl;
      case 'lumaApiToken':
      case 'luma_api_token':
        return lumaApiToken;

      // 音乐控制器
      case 'sunoApiUrl':
      case 'suno_api_url':
        return sunoApiUrl;
      case 'sunoApiKey':
      case 'suno_api_key':
        return sunoApiKey;

      // 数据库控制器
      case 'merchantId':
      case 'merchant_id':
        return merchantId;
      case 'merchant_key':
      case 'merchantKey':
        return merchantKey;
      case 'merchant_url':
      case 'merchantUrl':
        return merchantUrl;
      case 'kbAppId':
      case 'kb_app_id':
        return kbAppId;
      case 'kbAppSec':
      case 'kb_app_sec':
        return kbAppSec;
      case 'supabaseUrl':
      case 'supabase_url':
        return supabaseUrl;
      case 'supabaseKey':
      case 'supabase_key':
        return supabaseKey;

      // OSS控制器
      case 'oss_bucket_name':
      case 'ossBucketName':
        return ossBucketName;
      case 'oss_endpoint':
      case 'ossEndpoint':
        return ossEndpoint;
      case 'oss_api_url':
      case 'ossApiUrl':
        return ossApiUrl;

      // 月之暗面控制器
      case 'moonshot_api_key':
      case 'moonshotApiKey':
        return moonshotApiKey;

      // SD配置相关控制器
      case 'steps':
        return steps;
      case 'picWidth':
      case 'pic_width':
        return picWidth;
      case 'picHeight':
      case 'pic_height':
        return picHeight;
      case 'denoising':
        return denoising;
      case 'hireFix1':
      case 'hire_fix_1':
        return hireFix1;
      case 'hireFix2':
      case 'hire_fix_2':
        return hireFix2;
      case 'hireFix3':
      case 'hire_fix_3':
        return hireFix3;

      // SD提示词相关控制器
      case 'selfPositivePrompts':
      case 'self_positive_prompts':
        return selfPositivePrompts;
      case 'selfNegativePrompts':
      case 'self_negative_prompts':
        return selfNegativePrompts;
      case 'combinedPositivePrompts':
      case 'combined_positive_prompts':
        return combinedPositivePrompts;
      case 'lora':
        return lora;

      default:
        throw Exception('未知的控制器名称: $name');
    }
  }

  /// 获取指定控制器的文本内容
  ///
  /// [name] 控制器名称，支持下划线格式和驼峰格式
  String getControllerText(String name) {
    return getTextController(name).text;
  }

  /// 更新状态值
  ///
  /// [updates] 包含需要更新的配置项的Map
  /// - 如果值是字符串类型，会更新对应TextEditingController的文本
  /// - 如果值是其他类型，会更新对应的状态变量
  void updateState(Map<String, dynamic> updates) {
    updates.forEach((key, value) {
      try {
        if (value is String) {
          final controller = getTextController(key);
          controller.text = value;
        } else {
          switch (key) {
            // 邀请码设置
            case 'inviteCode':
            case 'invite_code':
              inviteCode.text = value.toString();
              break;
            // AI引擎设置 
            case 'selectedMode':
            case 'useMode':
              selectedMode = value as int;
              break;
            case 'chatGPTSelectedMode':
              chatGPTSelectedMode = value as int;
              break;
            case 'supportDrawEngine1':
              supportDrawEngine1 = value as bool;
              break;
            case 'supportDrawEngine2':
              supportDrawEngine2 = value as bool;
              break;
            case 'supportDrawEngine3':
              supportDrawEngine3 = value as bool;
              break;
            case 'supportDrawEngine4':
              supportDrawEngine4 = value as bool;
              break;
            case 'supportDrawEngine5':
              supportDrawEngine5 = value as bool;
              break;
            case 'drawEngine':
              drawEngine = value as int;
              break;
            case 'voiceSelectedMode':
            case 'useVoiceMode':
              voiceSelectedMode = value as int;
              break;
            case 'lumaSelectedMode':
            case 'useLumaMode':
              lumaSelectedMode = value as int;
              break;
            case 'steps':
              steps.text = value.toString();
              break;
            case 'picWidth':
            case 'pic_width':
              picWidth.text = value.toString();
              break;
            case 'picHeight':
            case 'pic_height':
              picHeight.text = value.toString();
              break;
            case 'denoising':
              denoising.text = value.toString();
              break;
            case 'hireFix1':
            case 'hire_fix_1':
              hireFix1.text = value.toString();
              break;
            case 'hireFix2':
            case 'hire_fix_2':
              hireFix2.text = value.toString();
              break;
            case 'hireFix3':
            case 'hire_fix_3':
              hireFix3.text = value.toString();
              break;
            // SD提示词相关状态
            case 'isSelfPositivePrompt':
            case 'use_self_positive_prompts':
              isSelfPositivePrompt = value as bool;
              break;
            case 'isSelfNegativePrompt':
            case 'use_self_negative_prompts':
              isSelfNegativePrompt = value as bool;
              break;
            case 'isMixPrompt':
            case 'is_compiled_positive_prompts':
              isMixPrompt = value as bool;
              break;
            case 'selectedOption':
            case 'default_positive_prompts_type':
              selectedOption = value.toString();
              break;
          }
        }
      } catch (e) {
        commonPrint('更新状态失败: key=$key, value=$value, error=$e');
      }
    });
    notifyListeners();
  }

  /// 销毁所有控制器
  ///
  /// 当不再需要该状态管理器时，必须调用该方法释放资源
  @override
  void dispose() {
    super.dispose();
    // 邀请码设置
    inviteCode.dispose();
    // AI引擎控制器
    chatApiKey.dispose();
    chatApiUrl.dispose();
    tyqwApiKey.dispose();
    zpaiApiKey.dispose();

    // 绘图引擎控制器
    midjourneyApiUrl.dispose();
    midjourneyApiToken.dispose();
    sdApiUrl.dispose();
    sdUsername.dispose();
    sdPassword.dispose();

    // 翻译控制器
    baiduTransAppId.dispose();
    baiduTransAppKey.dispose();
    deeplApiKey.dispose();

    // 文件保存控制器
    imageSavePath.dispose();
    jyDraftSavePath.dispose();

    // 语音控制器
    baiduVoiceApiKey.dispose();
    baiduVoiceSecretKey.dispose();
    baiduVoiceAppId.dispose();
    aliVoiceAccessId.dispose();
    aliVoiceAccessSecret.dispose();
    aliVoiceAppKey.dispose();
    huaweiVoiceAk.dispose();
    huaweiVoiceSk.dispose();
    azureVoiceSpeechKey.dispose();

    // 视频控制器
    lumaCookie.dispose();
    lumaApiUrl.dispose();
    lumaApiToken.dispose();

    // 音乐控制器
    sunoApiUrl.dispose();
    sunoApiKey.dispose();

    // 数据库控制器
    supabaseUrl.dispose();
    supabaseKey.dispose();
    merchantId.dispose();
    merchantKey.dispose();
    merchantUrl.dispose();
    kbAppId.dispose();
    kbAppSec.dispose();

    // OSS控制器
    ossBucketName.dispose();
    ossEndpoint.dispose();
    ossApiUrl.dispose();

    // 月之暗面控制器
    moonshotApiKey.dispose();

    // SD配置相关控制器
    steps.dispose();
    picWidth.dispose();
    picHeight.dispose();
    denoising.dispose();
    hireFix1.dispose();
    hireFix2.dispose();
    hireFix3.dispose();

    // SD提示词相关控制器
    selfPositivePrompts.dispose();
    selfNegativePrompts.dispose();
    combinedPositivePrompts.dispose();
    lora.dispose();
  }
}
