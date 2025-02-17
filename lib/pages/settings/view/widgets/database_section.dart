import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/pages/settings/state/settings_state.dart';
import 'package:tuitu/pages/settings/presenter/settings_presenter.dart';
import 'package:tuitu/config/config.dart';
import 'package:tuitu/widgets/my_text_field.dart';

class DatabaseSection extends StatelessWidget {
  final SettingsState state;
  final SettingsPresenter presenter;

  const DatabaseSection({
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
        _buildSectionTitle('数据库设置', settings),
        const SizedBox(height: 16),

        // Supabase配置卡片
        _buildSupabaseCard(settings),
        const SizedBox(height: 16),

        // 商户系统配置卡片
        _buildMerchantCard(settings),
        const SizedBox(height: 16),

        // 知识库配置卡片
        _buildKBCard(settings),
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

  // Supabase配置卡片
  Widget _buildSupabaseCard(ChangeSettings settings) {
    return _buildSettingsCard(
      title: 'Supabase配置',
      settings: settings,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: state.getTextController('supabase_url'),
                  label: 'URL',
                  onChanged: (text) async {
                    await Config.saveSettings({'supabase_url': text});
                  },
                  settings: settings,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: state.getTextController('supabase_key'),
                  label: 'Key',
                  onChanged: (text) async {
                    await Config.saveSettings({'supabase_key': text});
                  },
                  settings: settings,
                  isPassword: true,
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
                  await presenter.initSupabase();
                },
                isPrimary: true,
                settings: settings,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 商户系统配置卡片
  Widget _buildMerchantCard(ChangeSettings settings) {
    return _buildSettingsCard(
      title: '商户系统配置',
      settings: settings,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: state.getTextController('merchant_id'),
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
                  controller: state.getTextController('merchant_key'),
                  label: '商户Key',
                  onChanged: (text) async {
                    await Config.saveSettings({'merchant_key': text});
                  },
                  settings: settings,
                  isPassword: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: state.getTextController('merchant_url'),
                  label: '商户接口地址',
                  onChanged: (text) async {
                    await Config.saveSettings({'merchant_url': text});
                  },
                  settings: settings,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 知识库配置卡片
  Widget _buildKBCard(ChangeSettings settings) {
    return _buildSettingsCard(
      title: '知识库配置',
      settings: settings,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: state.getTextController('kb_app_id'),
                  label: '管理密钥',
                  onChanged: (text) async {
                    await Config.saveSettings({'kb_app_id': text});
                  },
                  settings: settings,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: state.getTextController('kb_app_sec'),
                  label: '问答密钥',
                  onChanged: (text) async {
                    await Config.saveSettings({'kb_app_sec': text});
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
