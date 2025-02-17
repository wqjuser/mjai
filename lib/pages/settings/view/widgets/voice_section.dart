import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/pages/settings/state/settings_state.dart';
import 'package:tuitu/pages/settings/presenter/settings_presenter.dart';
import 'package:tuitu/widgets/my_text_field.dart';

import '../../../../config/change_settings.dart';
import '../../../../config/config.dart';

class VoiceSection extends StatelessWidget {
  final SettingsState state;
  final SettingsPresenter presenter;

  const VoiceSection({
    super.key,
    required this.state,
    required this.presenter,
  });

  // 构建设置卡片
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

  // 语音引擎选择器
  Widget _buildEngineSelector(ChangeSettings settings) {
    return _buildSettingsCard(
      title: '引擎类型',
      settings: settings,
      child: Row(
        children: [
          _buildEngineOption(
            title: '百度语音',
            icon: Icons.record_voice_over,
            value: 0,
            settings: settings,
          ),
          const SizedBox(width: 16),
          _buildEngineOption(
            title: '阿里云语音',
            icon: Icons.voice_chat,
            value: 1,
            settings: settings,
          ),
          const SizedBox(width: 16),
          _buildEngineOption(
            title: '华为语音',
            icon: Icons.keyboard_voice,
            value: 2,
            settings: settings,
          ),
          const SizedBox(width: 16),
          _buildEngineOption(
            title: 'Azure语音',
            icon: Icons.mic,
            value: 3,
            settings: settings,
          ),
        ],
      ),
    );
  }

  // 引擎选项
  Widget _buildEngineOption({
    required String title,
    required IconData icon,
    required int value,
    required ChangeSettings settings,
  }) {
    final isSelected = state.voiceSelectedMode == value;

    return Expanded(
      child: Container(
        height: 64,
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
            await Config.saveSettings({'use_voice_mode': value});
            presenter.updateVoiceMode(value);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? settings.getSelectedBgColor() : settings.getForegroundColor(),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: settings.getForegroundColor(),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // API配置卡片
  Widget _buildAPIConfigCard(ChangeSettings settings) {
    return _buildSettingsCard(
      title: 'API配置',
      settings: settings,
      child: Column(
        children: [
          // 百度语音配置
          if (state.voiceSelectedMode == 0) ...[
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: state.getTextController('baidu_voice_api_key'),
                    label: 'API Key',
                    hint: 'xxxxxxxxxxxx',
                    onChanged: (text) async {
                      await Config.saveSettings({'baidu_voice_api_key': text});
                    },
                    settings: settings,
                    isPassword: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: state.getTextController('baidu_voice_secret_key'),
                    label: 'Secret Key',
                    hint: 'xxxxxxxxxxxx',
                    onChanged: (text) async {
                      await Config.saveSettings({'baidu_voice_secret_key': text});
                    },
                    settings: settings,
                    isPassword: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: state.getTextController('baidu_voice_app_id'),
                    label: 'App ID',
                    hint: 'xxxxxxxxxxxx',
                    onChanged: (text) async {
                      await Config.saveSettings({'baidu_voice_app_id': text});
                    },
                    settings: settings,
                    isPassword: true,
                  ),
                ),
              ],
            ),
          ],

          // 阿里云语音配置
          if (state.voiceSelectedMode == 1) ...[
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: state.getTextController('ali_voice_access_id'),
                    label: 'Access ID',
                    hint: 'xxxxxxxxxxxx',
                    onChanged: (text) async {
                      await Config.saveSettings({'ali_voice_access_id': text});
                    },
                    settings: settings,
                    isPassword: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: state.getTextController('ali_voice_access_secret'),
                    label: 'Access Secret',
                    hint: 'xxxxxxxxxxxx',
                    onChanged: (text) async {
                      await Config.saveSettings({'ali_voice_access_secret': text});
                    },
                    settings: settings,
                    isPassword: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: state.getTextController('ali_voice_app_key'),
                    label: 'App Key',
                    hint: 'xxxxxxxxxxxx',
                    onChanged: (text) async {
                      await Config.saveSettings({'ali_voice_app_key': text});
                    },
                    settings: settings,
                    isPassword: true,
                  ),
                )
              ],
            ),
          ],

          // 华为语音配置
          if (state.voiceSelectedMode == 2) ...[
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: state.getTextController('huawei_voice_ak'),
                    label: 'AK',
                    hint: 'xxxxxxxxxxxx',
                    onChanged: (text) async {
                      await Config.saveSettings({'huawei_voice_ak': text});
                    },
                    settings: settings,
                    isPassword: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: state.getTextController('huawei_voice_sk'),
                    label: 'SK',
                    hint: 'xxxxxxxxxxxx',
                    onChanged: (text) async {
                      await Config.saveSettings({'huawei_voice_sk': text});
                    },
                    settings: settings,
                    isPassword: true,
                  ),
                ),
              ],
            ),
          ],

          // Azure语音配置
          if (state.voiceSelectedMode == 3) ...[
            _buildTextField(
              controller: state.getTextController('azure_voice_speech_key'),
              label: 'Speech Key',
              hint: 'xxxxxxxxxxxx',
              onChanged: (text) async {
                await Config.saveSettings({'azure_voice_speech_key': text});
              },
              settings: settings,
              isPassword: true,
            ),
          ],
        ],
      ),
    );
  }

  // 操作按钮
  
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '语音设置',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // 语音引擎选择
        _buildEngineSelector(settings),
        const SizedBox(height: 16),

        // API配置
        _buildAPIConfigCard(settings),
      ],
    );
  }

  // 文本输入框
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Function(String) onChanged,
    required ChangeSettings settings,
    String? hint,
    bool isPassword = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              color: settings.getForegroundColor(),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
        MyTextField(
          controller: controller,
          onChanged: onChanged,
          style: TextStyle(color: settings.getForegroundColor()),
          isShow: !isPassword,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: settings.getHintTextColor()),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: settings.getForegroundColor().withAlpha(76),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: settings.getForegroundColor().withAlpha(76),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: settings.getSelectedBgColor(),
              ),
            ),
            filled: true,
            fillColor: settings.getBackgroundColor().withAlpha(13),
          ),
        ),
      ],
    );
  }
}
