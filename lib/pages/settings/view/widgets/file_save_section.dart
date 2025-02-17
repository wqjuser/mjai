import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/pages/settings/state/settings_state.dart';
import 'package:tuitu/pages/settings/presenter/settings_presenter.dart';
import 'package:tuitu/config/config.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'package:tuitu/widgets/my_text_field.dart';

class FileSaveSection extends StatelessWidget {
  final SettingsState state;
  final SettingsPresenter presenter;

  const FileSaveSection({
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
        _buildSectionTitle('文件保存设置', settings),
        const SizedBox(height: 16),

        // 文件路径配置卡片
        _buildPathConfigCard(settings),
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

  // 文件路径配置卡片
  Widget _buildPathConfigCard(ChangeSettings settings) {
    return _buildSettingsCard(
      title: '文件保存路径',
      settings: settings,
      child: Column(
        children: [
          _buildPathSelector(
              label: '',
              subtitle: '用于保存生成的图片和相关资源',
              hint: '暂不支持中文，请使用拼音或英文',
              controller: state.getTextController('imageSavePath'),
              onPathSelected: (path) async {
                if (path != null) {
                  await presenter.handleImagePathSelection(path);
                }
              },
              onSave: () async {
                String pathText = state.getControllerText('imageSavePath');
                await presenter.handleImagePathSelection(pathText);
              },
              settings: settings),
          const SizedBox(height: 8),
          _buildPathSelector(
              label: '',
              subtitle: '用于保存剪映草稿相关文件',
              controller: state.getTextController('draftPath'),
              onPathSelected: (path) async {
                if (path != null && path.isNotEmpty) {
                  state.updateState({'jy_draft_save_path': path});
                  await Config.saveSettings({'jy_draft_save_path': path});
                  await commonCreateDirectory(path);
                  showHint('剪映草稿保存路径设置成功', showType: 2);
                } else {
                  showHint('剪映草稿保存路径不能为空', showType: 3);
                }
              },
              onSave: () async {
                String pathText = state.getControllerText('draftPath');
                if (pathText.isNotEmpty) {
                  await Config.saveSettings({'jy_draft_save_path': pathText});
                  await commonCreateDirectory(pathText);
                  showHint('剪映草稿保存路径设置成功', showType: 2);
                } else {
                  showHint('剪映草稿保存路径不能为空', showType: 3);
                }
              },
              settings: settings),
        ],
      ),
    );
  }

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

  // 文本输入框
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Function(String) onChanged,
    required ChangeSettings settings,
    String? hint,
    bool isPassword = false,
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
