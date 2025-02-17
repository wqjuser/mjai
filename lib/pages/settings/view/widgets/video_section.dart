import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/pages/settings/state/settings_state.dart';
import 'package:tuitu/pages/settings/presenter/settings_presenter.dart';
import 'package:tuitu/config/config.dart';
import 'package:tuitu/widgets/my_text_field.dart';

class VideoSection extends StatelessWidget {
  final SettingsState state;
  final SettingsPresenter presenter;

  const VideoSection({
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
        _buildSectionTitle('视频生成设置', settings),
        const SizedBox(height: 16),

        // Luma API配置卡片
        _buildLumaConfigCard(settings),
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

  // Luma API配置卡片
  Widget _buildLumaConfigCard(ChangeSettings settings) {
    return _buildSettingsCard(
      title: 'Luma API配置',
      settings: settings,
      child: Column(
        children: [
          Visibility(
              visible: false,
              child: Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: state.getTextController('luma_cookie'),
                      label: 'Cookie',
                      onChanged: (text) async {
                        await Config.saveSettings({'luma_cookie': text});
                      },
                      settings: settings,
                      isPassword: true,
                    ),
                  ),
                ],
              )),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: state.getTextController('luma_api_url'),
                  label: 'API地址',
                  onChanged: (text) async {
                    await Config.saveSettings({'luma_api_url': text});
                  },
                  settings: settings,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: state.getTextController('luma_api_token'),
                  label: 'API Token',
                  onChanged: (text) async {
                    await Config.saveSettings({'luma_api_token': text});
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
