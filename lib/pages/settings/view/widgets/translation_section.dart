import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/pages/settings/state/settings_state.dart';
import 'package:tuitu/pages/settings/presenter/settings_presenter.dart';
import 'package:tuitu/config/config.dart';
import 'package:tuitu/widgets/my_text_field.dart';

class TranslationSection extends StatelessWidget {
  final SettingsState state;
  final SettingsPresenter presenter;

  const TranslationSection({
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
        _buildSectionTitle('翻译设置', settings),
        const SizedBox(height: 16),

        // 百度翻译配置卡片
        _buildBaiduTranslateCard(settings),
        const SizedBox(height: 16),

        // DeepL翻译配置卡片
        _buildDeepLTranslateCard(settings),
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

  // 百度翻译配置卡片
  Widget _buildBaiduTranslateCard(ChangeSettings settings) {
    return _buildSettingsCard(
      title: '百度翻译配置',
      settings: settings,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: state.getTextController('baidu_trans_app_id'),
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
                  controller: state.getTextController('baidu_trans_app_key'),
                  label: 'App Key',
                  onChanged: (text) async {
                    await Config.saveSettings({'baidu_trans_app_key': text});
                  },
                  settings: settings,
                  isPassword: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // DeepL翻译配置卡片
  Widget _buildDeepLTranslateCard(ChangeSettings settings) {
    return _buildSettingsCard(
      title: 'DeepL翻译配置',
      settings: settings,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: state.getTextController('deepl_api_key'),
                  label: 'API Key',
                  onChanged: (text) async {
                    await Config.saveSettings({'deepl_api_key': text});
                  },
                  settings: settings,
                  isPassword: true,
                ),
              ),
            ],
          ),
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
}
