import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/pages/settings/state/settings_state.dart';
import 'package:tuitu/pages/settings/presenter/settings_presenter.dart';
import 'package:tuitu/pages/settings/view/settings_view.dart';
import 'package:tuitu/config/config.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsState _state;
  late SettingsPresenter _presenter;
  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    _listenStorage();
    _state = SettingsState();
    _presenter = SettingsPresenter(state: _state);
    _loadSettings();
  }

  Future<void> _listenStorage() async {
    box.listenKey('needRefreshSettings', (value) {
      if (value) {
        _loadSettings();
      } else {
        _loadSettings(isClear: true);
      }
    });
  }

  Future<void> _loadSettings({bool isClear = false}) async {
    final settings = await Config.loadSettings();
    if (isClear) {
      settings.clear();
    }

    // 邀请码设置
    final inviteCodeSettings = {
      'inviteCode': settings['invite_code'] ?? '',
    };

    // AI引擎设置
    final aiEngineSettings = {
      'selectedMode': settings['use_mode'] ?? 0,
      'chatGPTSelectedMode': settings['ChatGPTUseMode'] ?? 0,
      'chatApiKey': settings['chat_api_key'] ?? '',
      'chatApiUrl': settings['chat_api_url'] ?? '',
      'tyqwApiKey': settings['tyqw_api_key'] ?? '',
      'zpaiApiKey': settings['zpai_api_key'] ?? '',
    };

    // 绘图引擎设置
    final drawingEngineSettings = {
      'supportDrawEngine1': settings['supportDrawEngine1'] ?? false,
      'supportDrawEngine2': settings['supportDrawEngine2'] ?? false,
      'supportDrawEngine3': settings['supportDrawEngine3'] ?? false,
      'supportDrawEngine4': settings['supportDrawEngine4'] ?? false,
      'supportDrawEngine5': settings['supportDrawEngine5'] ?? false,
      'drawEngine': settings['drawEngine'] ?? 0,
      'midjourneyApiUrl': settings['mj_api_url'] ?? '',
      'midjourneyApiToken': settings['mj_api_secret'] ?? '',
      'sdApiUrl': settings['sdUrl'] ?? '',
      'cuApiUrl': settings['cu_url'] ?? '',
      'sdUsername': settings['sd_username'] ?? '',
      'sdPassword': settings['sd_password'] ?? '',
    };

    // 翻译设置
    final translationSettings = {
      'baiduTransAppId': settings['baidu_trans_app_id'] ?? '',
      'baiduTransAppKey': settings['baidu_trans_app_key'] ?? '',
      'deeplApiKey': settings['deepl_api_key'] ?? '',
    };

    // 文件保存设置
    final fileSettings = {
      'imageSavePath': settings['image_save_path'] ?? '',
      'draftPath': settings['jy_draft_save_path'] ?? '',
    };

    // 语音设置
    final voiceSettings = {
      'voiceSelectedMode': settings['use_voice_mode'] ?? 0,
      'baiduVoiceApiKey': settings['baidu_voice_api_key'] ?? '',
      'baiduVoiceSecretKey': settings['baidu_voice_secret_key'] ?? '',
      'baiduVoiceAppId': settings['baidu_voice_app_id'] ?? '',
      'aliVoiceAccessId': settings['ali_voice_access_id'] ?? '',
      'aliVoiceAccessSecret': settings['ali_voice_access_secret'] ?? '',
      'aliVoiceAppKey': settings['ali_voice_app_key'] ?? '',
      'huaweiVoiceAk': settings['huawei_voice_ak'] ?? '',
      'huaweiVoiceSk': settings['huawei_voice_sk'] ?? '',
      'azureVoiceSpeechKey': settings['azure_voice_speech_key'] ?? '',
    };

    // 数据库设置
    final databaseSettings = {
      'supabaseUrl': settings['supabase_url'] ?? '',
      'supabaseKey': settings['supabase_key'] ?? '',
      'merchantId': settings['merchant_id'] ?? '',
      'merchantKey': settings['merchant_key'] ?? '',
      'merchantUrl': settings['merchant_url'] ?? '',
      'kbAppId': settings['kb_app_id'] ?? '',
      'kbAppSec': settings['kb_app_sec'] ?? '',
    };

    // OSS设置
    final ossSettings = {
      'ossBucketName': settings['oss_bucket_name'] ?? '',
      'ossEndpoint': settings['oss_endpoint'] ?? '',
      'ossApiUrl': settings['oss_api_url'] ?? '',
    };

    // 音乐设置
    final musicSettings = {
      'sunoApiUrl': settings['suno_api_url'] ?? '',
      'sunoApiKey': settings['suno_api_key'] ?? '',
    };

    // 视频设置
    final videoSettings = {
      'lumaSelectedMode': settings['use_luma_mode'] ?? 0,
      'lumaCookie': settings['luma_cookie'] ?? '',
      'lumaApiUrl': settings['luma_api_url'] ?? '',
      'lumaApiToken': settings['luma_api_token'] ?? '',
    };

    // 月之暗面设置
    final moonshotSettings = {
      'moonshotApiKey': settings['moonshot_api_key'] ?? '',
    };

    if (mounted) {
      setState(() {
        _state.updateState({
          ...inviteCodeSettings,
          ...aiEngineSettings,
          ...drawingEngineSettings,
          ...translationSettings,
          ...fileSettings,
          ...voiceSettings,
          ...databaseSettings,
          ...ossSettings,
          ...musicSettings,
          ...videoSettings,
          ...moonshotSettings,
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return SafeArea(
        child: Container(
      color: settings.getBackgroundColor(),
      child: ChangeNotifierProvider.value(
        value: _state,
        child: SettingsView(
          state: _state,
          presenter: _presenter,
        ),
      ),
    ));
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }
}
