import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/pages/settings/state/settings_state.dart';
import 'package:tuitu/pages/settings/presenter/settings_presenter.dart';
import 'package:tuitu/config/config.dart';
import 'package:tuitu/widgets/my_text_field.dart';

class AIEngineSection extends StatelessWidget {
  final SettingsState state;
  final SettingsPresenter presenter;

  const AIEngineSection({
    super.key,
    required this.state,
    required this.presenter,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('AI引擎设置', settings),
        const SizedBox(height: 16),

        // AI引擎选择器
        _buildEngineSelector(settings),
        const SizedBox(height: 16),

        // ChatGPT专属模式选择器
        if (state.selectedMode == 0) ...[
          Visibility(
              visible: false,
              child: Column(
                children: [
                  _buildChatGPTModeSelector(settings),
                  const SizedBox(height: 16),
                ],
              ))
        ],

        // API配置卡片
        _buildAPIConfigCard(settings),
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

  // AI引擎选择器
  Widget _buildEngineSelector(ChangeSettings settings) {
    return _buildSettingsCard(
      title: '引擎类型',
      settings: settings,
      child: Row(
        children: [
          _buildEngineOption(
            title: '兼容OpenAI格式供应商',
            icon: Icons.chat,
            value: 0,
            settings: settings,
          ),
          const SizedBox(width: 16),
          _buildEngineOption(
            title: '通义千问',
            icon: Icons.smart_toy,
            value: 1,
            settings: settings,
          ),
          const SizedBox(width: 16),
          _buildEngineOption(
            title: '智谱AI',
            icon: Icons.psychology,
            value: 2,
            settings: settings,
          ),
        ],
      ),
    );
  }

  // ChatGPT专属模式选择器
  Widget _buildChatGPTModeSelector(ChangeSettings settings) {
    return _buildSettingsCard(
      title: 'ChatGPT模式',
      settings: settings,
      child: Row(
        children: [
          _buildModeOption(
            title: 'API模式',
            icon: Icons.api,
            value: 0,
            settings: settings,
          ),
          const SizedBox(width: 16),
          _buildModeOption(
            title: '网页模式',
            icon: Icons.web,
            value: 1,
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
    final isSelected = state.selectedMode == value;

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
            await Config.saveSettings({'use_mode': value});
            state.updateState({'selectedMode': value});
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

  // 模式选项
  Widget _buildModeOption({
    required String title,
    required IconData icon,
    required int value,
    required ChangeSettings settings,
  }) {
    final isSelected = state.chatGPTSelectedMode == value;

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
            await Config.saveSettings({'ChatGPTUseMode': value});
            state.updateState({'chatGPTSelectedMode': value});
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
          // ChatGPT配置
          if (state.selectedMode == 0) ...[
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: state.getTextController('chatApiKey'),
                    label: 'API Key',
                    hint: 'sk-xxxxxxxxxxxx',
                    onChanged: (text) async {
                      await Config.saveSettings({'chat_api_key': text});
                    },
                    settings: settings,
                    isPassword: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: state.getTextController('chatApiUrl'),
                    label: 'API接口地址',
                    hint: 'https://api.openai.com',
                    onChanged: (text) async {
                      await Config.saveSettings({'chat_api_url': text});
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
                    await presenter.testOpenAI(
                      state.getControllerText('chatApiUrl'),
                      "gpt-4o-mini",
                      "你好,请仅仅回答我连接成功这四个字，无需冗余回答。",
                      state.getControllerText('chatApiKey'),
                    );
                  },
                  isPrimary: true,
                  settings: settings,
                ),
              ],
            ),
          ],

          // 通义千问配置
          if (state.selectedMode == 1) ...[
            _buildTextField(
              controller: state.getTextController('tyqwApiKey'),
              label: 'API Key',
              hint: '填写通义千问API密钥',
              onChanged: (text) async {
                await Config.saveSettings({'tyqw_api_key': text});
              },
              settings: settings,
              isPassword: true,
            ),
          ],

          // 智普AI配置
          if (state.selectedMode == 2) ...[
            _buildTextField(
              controller: state.getTextController('zpaiApiKey'),
              label: 'API Key',
              hint: '填写智普AI API密钥',
              onChanged: (text) async {
                await Config.saveSettings({'zpai_api_key': text});
              },
              settings: settings,
              isPassword: true,
            ),
          ],
        ],
      ),
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

  // 操作按钮
  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    required ChangeSettings settings,
    bool isPrimary = false,
  }) {
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
}
