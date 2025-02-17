import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/config/config.dart';
import 'package:tuitu/config/global_params.dart';
import 'package:tuitu/pages/settings/state/settings_state.dart';
import 'package:tuitu/pages/settings/presenter/settings_presenter.dart';
import 'package:tuitu/widgets/common_dropdown.dart';

class SDConfigSection extends StatefulWidget {
  final SettingsState state;
  final SettingsPresenter presenter;

  const SDConfigSection({
    super.key,
    required this.state,
    required this.presenter,
  });

  @override
  State<SDConfigSection> createState() => _SDConfigSectionState();
}

class _SDConfigSectionState extends State<SDConfigSection> {
  String _selectedModel = '选择模型';
  String _selectedLora = '选择Lora';
  String _selectedVae = '自动选择';
  String _selectedSampler = 'Euler a';
  String _selectedUpscalers = '选择放大算法';
  bool _isHiresFix = false;
  bool _useADetail = false;
  bool _useRestoreFace = false;

  List<String> _models = ['选择模型'];
  List<String> _loras = ['选择Lora'];
  List<String> _vaes = [
    '无',
    '自动选择',
  ];
  List<String> _samplers = ['Euler a'];
  List<String> _upscalers = ['选择放大算法'];

  @override
  void initState() {
    super.initState();
    _loadSDSettings();
    _initData();
  }

  Future<void> _loadSDSettings() async {
    final settings = await Config.loadSettings();
    if (mounted) {
      setState(() {
        _selectedModel = '选择模型';
        _selectedLora = '选择Lora';
        _selectedVae = '自动选择';
        _selectedSampler = settings['sampler'] ?? 'Euler a';
        _selectedUpscalers = '选择放大算法';
        _isHiresFix = settings['hires_fix'] ?? false;
        _useADetail = settings['use_adetail'] ?? false;
        _useRestoreFace = settings['restore_face'] ?? false;
      });
    }
  }

  Future<void> _initData() async {
    //获取默认配置项
    await widget.presenter.getOptions('无', 'None', '自动选择', 'Euler a');
    //获取模型列表
    var modelsMap = await widget.presenter.getModels(_models, _selectedModel);
    //获取Lora列表
    var lorasMap = await widget.presenter.getLoras(_loras, _selectedLora);
    //获取Vae列表
    var vaesMap = await widget.presenter.getVaes(_vaes, _selectedVae);
    //获取采样器列表
    var samplersMap = await widget.presenter.getSamplers(_samplers, _selectedSampler);
    //获取放大算法列表
    var upscalersMap = await widget.presenter.getUpscalers(_upscalers, _selectedUpscalers);

    setState(() {
      _models = modelsMap['models'] ?? ['选择模型'];
      _selectedModel = modelsMap['selectedModel'] ?? '选择模型';
      _loras = lorasMap['loras'] ?? ['选择Lora'];
      _selectedLora = lorasMap['loraName'] ?? '选择Lora';
      _vaes = vaesMap['vaes'] ?? ['无', '自动选择'];
      _selectedVae = vaesMap['vaeName'] ?? '无';
      _samplers = samplersMap['samplers'] ?? ['Euler a'];
      _selectedSampler = samplersMap['sampler'] ?? 'Euler a';
      _upscalers = upscalersMap['upscalers'] ?? ['选择放大算法'];
      _selectedUpscalers = upscalersMap['upscaler'] ?? '选择放大算法';
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stable Diffusion 设置',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: settings.getForegroundColor(),
          ),
        ),
        const SizedBox(height: 16),
        if (GlobalParams.isAdminVersion || GlobalParams.isFreeVersion) ...[
          //sdUrl配置
          _buildSettingsCard(
            title: 'Stable Diffusion URL配置',
            settings: settings,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: widget.state.getTextController('sdApiUrl'),
                        label: 'API地址',
                        hint: 'https://xxx.xxx.com',
                        onChanged: (text) async {
                          await Config.saveSettings({'sdUrl': text});
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
                        await widget.presenter.testSD(widget.state.getControllerText('sdApiUrl'));
                      },
                      isPrimary: true,
                      settings: settings,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        // 模型设置
        _buildSettingsCard(
          title: '模型设置',
          settings: settings,
          child: Column(
            children: [
              // 基础模型选择
              _buildSettingRow(
                label: '基础模型',
                content: Expanded(
                  child: CommonDropdownWidget(
                    selectedValue: _selectedModel,
                    dropdownData: _models,
                    onChangeValue: (value) async {
                      bool isSuccess = await widget.presenter.handleModelChange(value);
                      if (isSuccess) {
                        setState(() => _selectedModel = value);
                      }
                    },
                  ),
                ),
                action: _buildActionButton(
                  label: '刷新模型列表',
                  onPressed: () => widget.presenter.getModels(_models, _selectedModel),
                  settings: settings,
                ),
                settings: settings,
              ),
              const SizedBox(height: 16),

              // Lora模型选择
              _buildSettingRow(
                label: 'Lora模型',
                content: Expanded(
                  child: CommonDropdownWidget(
                    selectedValue: _selectedLora,
                    dropdownData: _loras,
                    onChangeValue: (value) async {
                      await widget.presenter.handleLoraChange(value);
                      setState(() => _selectedLora = value);
                    },
                  ),
                ),
                action: _buildActionButton(
                  label: '刷新Lora列表',
                  onPressed: () => widget.presenter.getLoras(_loras, _selectedLora),
                  settings: settings,
                ),
                settings: settings,
              ),
              const SizedBox(height: 16),

              // VAE模型选择
              _buildSettingRow(
                label: 'VAE模型',
                content: Expanded(
                  child: CommonDropdownWidget(
                    selectedValue: _selectedVae,
                    dropdownData: _vaes,
                    onChangeValue: (value) async {
                      bool isSuccess = await widget.presenter.handleVaeChange(value);
                      if (isSuccess) {
                        setState(() => _selectedVae = value);
                      }
                    },
                  ),
                ),
                action: _buildActionButton(
                  label: '刷新VAE列表',
                  onPressed: () => widget.presenter.getVaes(_vaes, _selectedVae),
                  settings: settings,
                ),
                settings: settings,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 采样设置
        _buildSettingsCard(
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
                        CommonDropdownWidget(
                          selectedValue: _selectedSampler,
                          dropdownData: _samplers,
                          onChangeValue: (value) async {
                            await Config.saveSettings({'sampler': value});
                            setState(() => _selectedSampler = value);
                          },
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
                          controller: widget.state.getTextController('steps'),
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
                          controller: widget.state.getTextController('picWidth'),
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
                          controller: widget.state.getTextController('picHeight'),
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
                          controller: widget.state.getTextController('denoising'),
                          hint: '0.7',
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

              // 高清修复设置
              Row(
                children: [
                  _buildToggleOption(
                    label: '启用面部修复',
                    value: _useRestoreFace,
                    onChanged: (value) async {
                      await Config.saveSettings({'restore_face': value});
                      setState(() {
                        _useRestoreFace = value;
                      });
                    },
                    settings: settings,
                  ),
                  const SizedBox(width: 24),
                  _buildToggleOption(
                    label: '启用高清修复',
                    value: _isHiresFix,
                    onChanged: (value) async {
                      await Config.saveSettings({'hires_fix': value});
                      setState(() {
                        _isHiresFix = value;
                        if (_isHiresFix) {
                          widget.presenter.getUpscalers(_upscalers, _selectedUpscalers);
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
                      await Config.saveSettings({'use_adetail': value});
                      setState(() => _useADetail = value);
                    },
                    settings: settings,
                  ),
                ],
              ),

              if (_isHiresFix) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      '高清修复算法:',
                      style: TextStyle(
                        color: settings.getForegroundColor(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 300,
                      child: CommonDropdownWidget(
                        selectedValue: _selectedUpscalers,
                        dropdownData: _upscalers,
                        onChangeValue: (value) async {
                          await Config.saveSettings({'hires_fix_sampler': value});
                          setState(() => _selectedUpscalers = value);
                        },
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
                            controller: widget.state.getTextController('hireFix1'),
                            hint: '10',
                            helperText: '范围：5-10(不建议过多的步数)',
                            decimal: true,
                            onChanged: (value) async {
                              if (value.isNotEmpty) {
                                await Config.saveSettings({
                                  'hires_fix_steps': double.parse(value),
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
                            controller: widget.state.getTextController('hireFix2'),
                            hint: '0.5',
                            helperText: '范围：0-1',
                            decimal: true,
                            onChanged: (value) async {
                              if (value.isNotEmpty) {
                                await Config.saveSettings({
                                  'hires_fix_amplitude': double.parse(value),
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
                            controller: widget.state.getTextController('hireFix3'),
                            hint: '2',
                            helperText: '范围：1-4(不建议过多的放大倍数)',
                            decimal: true,
                            onChanged: (value) async {
                              if (value.isNotEmpty) {
                                await Config.saveSettings({
                                  'hires_fix_multiple': double.parse(value),
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
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 提示词设置
        _buildSettingsCard(
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
                    child: CommonDropdownWidget(
                      selectedValue: widget.state.selectedOption,
                      dropdownData: const ['0.无', '1.基本提示(通用)', '2.基本提示(通用修手)', '3.基本提示(增加细节1)', '4.基本提示(增加细节2)', '5.基本提示(梦幻童话)'],
                      onChangeValue: (value) async {
                        int type = int.parse(value.split('.')[0]);
                        await Config.saveSettings({'default_positive_prompts_type': type});
                        widget.state.updateState({'selectedOption': value});
                      },
                    ),
                  ),
                  const SizedBox(width: 24),
                  _buildToggleOption(
                    label: '组合类别',
                    value: widget.state.isMixPrompt,
                    onChanged: (value) async {
                      await Config.saveSettings({'is_compiled_positive_prompts': value});
                      widget.state.updateState({'isMixPrompt': value});
                    },
                    settings: settings,
                  ),
                  if (widget.state.isMixPrompt) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: widget.state.getTextController('combinedPositivePrompts'),
                        label: '',
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
                    value: widget.state.isSelfPositivePrompt,
                    onChanged: (value) async {
                      await Config.saveSettings({'use_self_positive_prompts': value});
                      widget.state.updateState({'isSelfPositivePrompt': value});
                    },
                    settings: settings,
                  ),
                  const SizedBox(width: 24),
                  _buildToggleOption(
                    label: '自定义负面提示词',
                    value: widget.state.isSelfNegativePrompt,
                    onChanged: (value) async {
                      await Config.saveSettings({'use_self_negative_prompts': value});
                      widget.state.updateState({'isSelfNegativePrompt': value});
                    },
                    settings: settings,
                  ),
                ],
              ),

              if (widget.state.isSelfPositivePrompt || widget.state.isSelfNegativePrompt) const SizedBox(height: 16),

              // 自定义提示词输入区域
              Row(
                children: [
                  if (widget.state.isSelfPositivePrompt)
                    Expanded(
                      child: _buildTextField(
                        controller: widget.state.getTextController('selfPositivePrompts'),
                        label: '默认正面提示词',
                        hint: '影响每一张图片的正面提示词',
                        maxLines: 3,
                        onChanged: (text) async {
                          await Config.saveSettings({'self_positive_prompts': text});
                        },
                        settings: settings,
                      ),
                    ),
                  if (widget.state.isSelfPositivePrompt && widget.state.isSelfNegativePrompt) const SizedBox(width: 16),
                  if (widget.state.isSelfNegativePrompt)
                    Expanded(
                      child: _buildTextField(
                        controller: widget.state.getTextController('selfNegativePrompts'),
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
                controller: widget.state.getTextController('lora'),
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
        ),
      ],
    );
  }
}

// 文本输入框
Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required Function(String) onChanged,
  required ChangeSettings settings,
  String? hint,
  int? maxLines,
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
      TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: settings.getForegroundColor()),
        maxLines: maxLines,
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

// 小数输入格式化器
class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;
  final double minValue;
  final double maxValue;

  DecimalTextInputFormatter({
    required this.decimalRange,
    required this.minValue,
    required this.maxValue,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;
    if (newText.isEmpty) {
      return newValue;
    }

    if (newText == '.') {
      return const TextEditingValue(
        text: '0.',
        selection: TextSelection.collapsed(offset: 2),
      );
    }

    // 验证格式
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(newText)) {
      return oldValue;
    }

    // 限制小数位数
    if (newText.contains('.')) {
      int decimalDigits = newText.split('.')[1].length;
      if (decimalDigits > decimalRange) {
        return oldValue;
      }
    }

    // 验证范围
    double? value = double.tryParse(newText);
    if (value != null && (value < minValue || value > maxValue)) {
      return oldValue;
    }

    return newValue;
  }
}
