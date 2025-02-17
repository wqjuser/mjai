import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/config/global_params.dart';
import 'package:tuitu/pages/settings/state/settings_state.dart';
import 'package:tuitu/pages/settings/presenter/settings_presenter.dart';
import 'package:tuitu/config/config.dart';
import 'package:tuitu/widgets/my_text_field.dart';
import 'package:tuitu/pages/settings/view/widgets/sd_config_section.dart';

class DrawingEngineSection extends StatelessWidget {
  final SettingsState state;
  final SettingsPresenter presenter;
  final GetStorage box;

  const DrawingEngineSection({
    super.key,
    required this.state,
    required this.presenter,
    required this.box,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('绘图引擎设置', settings),
        const SizedBox(height: 16),
        if (GlobalParams.isAdminVersion || GlobalParams.isFreeVersion) ...[
          // 支持的绘图引擎选项
          _buildSupportedEnginesCard(settings),
          const SizedBox(height: 16),
        ],

        // 引擎配置卡片
        _buildCurrentEngineCard(settings),
        const SizedBox(height: 16),

        // 当前引擎特定配置
        if (state.drawEngine == 0) ...[
          SDConfigSection(
            state: state,
            presenter: presenter,
          )
        ] // Stable Diffusion
        else if (state.drawEngine == 1 || state.drawEngine == 2) ...[
          if (GlobalParams.isAdminVersion || GlobalParams.isFreeVersion) ...[_buildMidjourneyConfigCard(settings)]
        ]
        // Midjourney
        else if (state.drawEngine == 3) ...[
          if (GlobalParams.isAdminVersion || GlobalParams.isFreeVersion) ...[_buildComfyUIConfigCard(settings)]
        ],
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

  // 支持的绘图引擎卡片
  Widget _buildSupportedEnginesCard(ChangeSettings settings) {
    return _buildSettingsCard(
      title: '支持的绘图引擎',
      settings: settings,
      child: Row(
        children: [
          Expanded(
            child: _buildEngineOption(
              label: 'Stable Diffusion',
              value: state.supportDrawEngine1,
              onChanged: (value) async {
                await Config.saveSettings({'supportDrawEngine1': value});
                state.updateState({'supportDrawEngine1': value});

                // 如果取消支持当前选中的引擎，切换到第一个支持的引擎
                if (!value && state.drawEngine == 0) {
                  _switchToFirstSupportedEngine();
                }
              },
              settings: settings,
            ),
          ),
          Visibility(
              visible: false,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildEngineOption(
                      label: 'Midjourney(知数云)',
                      value: state.supportDrawEngine2,
                      onChanged: (value) async {
                        await Config.saveSettings({'supportDrawEngine2': value});
                        state.updateState({'supportDrawEngine2': value});

                        // 如果取消支持当前选中的引擎，切换到第一个支持的引擎
                        if (!value && state.drawEngine == 1) {
                          _switchToFirstSupportedEngine();
                        }
                      },
                      settings: settings,
                    ),
                  ),
                ],
              )),
          const SizedBox(width: 12),
          Expanded(
            child: _buildEngineOption(
              label: 'Midjourney(中转)',
              value: state.supportDrawEngine3,
              onChanged: (value) async {
                await Config.saveSettings({'supportDrawEngine3': value});
                state.updateState({'supportDrawEngine3': value});

                // 如果取消支持当前选中的引擎，切换到第一个支持的引擎
                if (!value && state.drawEngine == 2) {
                  _switchToFirstSupportedEngine();
                }
              },
              settings: settings,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildEngineOption(
              label: 'Comfyui',
              value: state.supportDrawEngine4,
              onChanged: (value) async {
                await Config.saveSettings({'supportDrawEngine4': value});
                state.updateState({'supportDrawEngine4': value});

                // 如果取消支持当前选中的引擎，切换到第一个支持的引擎
                if (!value && state.drawEngine == 3) {
                  _switchToFirstSupportedEngine();
                }
              },
              settings: settings,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildEngineOption(
              label: 'Fooocus',
              value: state.supportDrawEngine5,
              onChanged: (value) async {
                await Config.saveSettings({'supportDrawEngine5': value});
                state.updateState({'supportDrawEngine5': value});
                // 如果取消支持当前选中的引擎，切换到第一个支持的引擎
                if (!value && state.drawEngine == 4) {
                  _switchToFirstSupportedEngine();
                }
              },
              settings: settings,
            ),
          ),
        ],
      ),
    );
  }

  // 切换到第一个支持的引擎
  void _switchToFirstSupportedEngine() async {
    int newEngine = 0;
    if (state.supportDrawEngine1) {
      newEngine = 0;
    } else if (state.supportDrawEngine2) {
      newEngine = 1;
    } else if (state.supportDrawEngine3) {
      newEngine = 2;
    } else if (state.supportDrawEngine4) {
      newEngine = 3;
    } else if (state.supportDrawEngine5) {
      newEngine = 4;
    }

    await Config.saveSettings({'drawEngine': newEngine});
    state.updateState({'drawEngine': newEngine});
  }

  // 引擎选项
  Widget _buildEngineOption({
    required String label,
    required bool value,
    required Function(bool) onChanged,
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
                onChanged: (v) => onChanged(v ?? false),
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

  // 当前绘图引擎卡片
  Widget _buildCurrentEngineCard(ChangeSettings settings) {
    return _buildSettingsCard(
      title: '当前绘图引擎',
      settings: settings,
      child: Row(
        children: _buildCurrentEngineOptions(settings),
      ),
    );
  }

  // 当前引擎选项列表
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

    // 根据支持状态添加选项
    addOption(state.supportDrawEngine1, 'Stable Diffusion', 0);
    addOption(state.supportDrawEngine2, 'Midjourney-1', 1);
    addOption(state.supportDrawEngine3, 'Midjourney', 2);
    addOption(state.supportDrawEngine4, 'ComfyUI', 3);
    addOption(state.supportDrawEngine5, 'Fooocus', 4);

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

  // 当前引擎选项
  Widget _buildCurrentEngineOption({
    required String label,
    required int value,
    required ChangeSettings settings,
  }) {
    final isSelected = state.drawEngine == value;
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
          state.updateState({'drawEngine': value});
          await box.write('drawEngine', value);
          await Config.saveSettings({'drawEngine': value});
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Radio<int>(
                value: value,
                groupValue: state.drawEngine,
                onChanged: null,
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

  // Midjourney配置卡片
  Widget _buildMidjourneyConfigCard(ChangeSettings settings) {
    return _buildSettingsCard(
      title: 'Midjourney配置',
      settings: settings,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: state.getTextController('mj_api_url'),
                  label: 'API地址',
                  hint: 'https://xxx.xxx.com',
                  onChanged: (text) async {
                    await Config.saveSettings({'mj_api_url': text});
                  },
                  settings: settings,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: state.getTextController('mj_api_secret'),
                  label: 'API密钥',
                  hint: '(选填)',
                  onChanged: (text) async {
                    await Config.saveSettings({'mj_api_secret': text});
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
                label: '测试连接',
                onPressed: () async {
                  await presenter.testMidjourney();
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

  Widget _buildComfyUIConfigCard(ChangeSettings settings) {
    return _buildSettingsCard(
      title: 'ComfyUI配置',
      settings: settings,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: state.getTextController('cu_api_url'),
                  label: 'API地址',
                  hint: 'http://127.0.0.1:8188',
                  onChanged: (text) async {
                    await Config.saveSettings({'cu_url': text});
                  },
                  isPassword: false,
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
                  await presenter.testComfyUI();
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
