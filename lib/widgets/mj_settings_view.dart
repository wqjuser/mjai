import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/widgets/common_dropdown.dart';

import '../config/global_params.dart';
import '../utils/file_picker_manager.dart';

class MidjourneySettingsView extends StatefulWidget {
  final Function(Map<String, dynamic> finalOptions) onConfirm;
  final int intoType;
  final Map<String, dynamic> options;

  const MidjourneySettingsView({super.key, required this.onConfirm, this.intoType = 0, required this.options});

  @override
  State<MidjourneySettingsView> createState() => _MidjourneySettingsViewState();
}

class _MidjourneySettingsViewState extends State<MidjourneySettingsView> {
  List<String> models = [
    'MJ 6.1 (通用模型)',
    'MJ 6.0 (通用模型)',
    'MJ 5.2 (通用模型)',
    'MJ 5.1 (通用模型)',
    'MJ 5 (通用模型)',
    'MJ 4 (通用模型)',
  ];
  final List<String> bots = ['Midjourney', 'Nijijourney'];
  final List<String> aspects = ['1:1', '9:16', '16:9', '4:3', '3:4', '3:2', '2:3'];
  final List<List<String>> styles = [
    ['default', 'raw'],
    ['default', 'raw'],
    ['default'],
    ['default'],
    ['default', 'original', 'cute', 'expressive', 'scenic']
  ];
  final List<String> qualities = ['0.25', '0.5', '1'];
  String selectModel = '';
  String selectBot = '';
  String selectAspect = '';
  List<String> selectStyles = [''];
  String selectStyle = '';
  String selectQuality = '';
  double selectStylize = 100;
  double selectWeird = 0;
  double selectChaos = 0;
  double selectImageWeight = 1;
  final TextEditingController seedTextEditingController = TextEditingController();
  final TextEditingController noTextEditingController = TextEditingController();
  bool isPublic = false;

  // 添加新的状态变量
  List<String> referenceImages = ['', ''];
  List<String> characterImages = ['', ''];
  double referenceWeight = 100;
  double characterWeight = 100;

  // 添加一个新的状态变量
  bool _retainParametersAfterSubmission = false;

  @override
  void initState() {
    super.initState();
    _retainParametersAfterSubmission = widget.options['retainParameters'] ?? false;
    selectModel = models[0];
    selectBot = bots[0];
    selectAspect = aspects[0];
    selectStyles = styles[0];
    selectStyle = selectStyles[0];
    selectQuality = qualities[2];
    fillInfo();
  }

  void fillInfo() {
    if (!_retainParametersAfterSubmission) return;

    String? finalOptions;

    // 设置bot类型以及finalOptions
    if (widget.options['MID_JOURNEY'] != null) {
      selectBot = bots[0];
      finalOptions = widget.options['MID_JOURNEY'];
    } else if (widget.options['NIJI_JOURNEY'] != null) {
      selectBot = bots[1];
      finalOptions = widget.options['NIJI_JOURNEY'];
    }

    // 如果finalOptions为null，直接返回
    if (finalOptions == null) return;

    // 赋值公共属性
    characterImages = widget.options['characterImages'];
    referenceImages = widget.options['referenceImages'];

    // 正则表达式匹配 "--key value" 模式
    RegExp exp = RegExp(r'--(\w+)\s+(\S+)');
    Map<String, String> result = {for (var match in exp.allMatches(finalOptions)) match.group(1)!: match.group(2)!};

    // 处理结果
    result.forEach((key, value) {
      switch (key) {
        case 'v':
          // 选择模型，根据不同的bot设置模型
          if (selectBot == bots[0]) {
            models = ['MJ 6.1 (通用模型)', 'MJ 6.0 (通用模型)', 'MJ 5.2 (通用模型)', 'MJ 5.1 (通用模型)', 'MJ 5 (通用模型)', 'MJ 4 (通用模型)'];
          } else if (selectBot == bots[1]) {
            models = ['Niji 6 (动漫模型)', 'Niji 5 (动漫模型)', 'Niji 4 (动漫模型)'];
          }
          selectModel = models.firstWhere((model) => model.contains(value), orElse: () => models[0]);
          break;

        case 'ar':
          // 选择画幅比率
          Map<String, String> aspectMap = {
            '1:1': aspects[0],
            '9:16': aspects[1],
            '16:9': aspects[2],
            '4:3': aspects[3],
            '3:4': aspects[4],
            '3:2': aspects[5],
            '2:3': aspects[6],
          };
          selectAspect = aspectMap[value] ?? aspects[0];
          break;

        case 'iw':
          selectImageWeight = double.tryParse(value) ?? 1.0;
          break;

        case 'weird':
          selectWeird = double.tryParse(value) ?? 0.0;
          break;

        case 'chaos':
          selectChaos = double.tryParse(value) ?? 0.0;
          break;

        case 'seed':
          seedTextEditingController.text = value;
          break;

        case 'no':
          noTextEditingController.text = value;
          break;

        case 'sw':
          referenceWeight = double.tryParse(value) ?? 100.0;
          break;

        case 'cw':
          characterWeight = double.tryParse(value) ?? 100.0;
          break;

        case 'q':
          selectQuality = value;
          break;

        case 'style':
          selectStyle = value;
          break;

        case 'stylize':
          selectStylize = double.tryParse(value) ?? 100.0;
          break;
      }
    });
  }

  Future<void> _pickImage(int index, bool isReference) async {
    FilePickerResult? result = await FilePickerManager().pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        if (isReference) {
          referenceImages[index] = result.files.single.path!;
        } else {
          characterImages[index] = result.files.single.path!;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Platform.isIOS || Platform.isAndroid;
    final changeSettings = context.watch<ChangeSettings>();
    return Container(
      decoration: BoxDecoration(
        color: changeSettings.getBackgroundColor(),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // 顶部标题栏
          Container(
            padding: EdgeInsets.symmetric(vertical: isMobile ? 0 : 16),
            decoration: BoxDecoration(
              color: changeSettings.getBackgroundColor(),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Text(
                'MJ设置选项',
                style: TextStyle(
                  color: changeSettings.getForegroundColor(),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

          // 主要内容区域
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModelSection(changeSettings),
                    const SizedBox(height: 20),
                    _buildStyleSection(changeSettings),
                    const SizedBox(height: 20),
                    _buildAdvancedSection(changeSettings),
                    const SizedBox(height: 20),
                    _buildReferenceImagesSection(changeSettings),
                    const SizedBox(height: 20),
                    if (widget.intoType == 0) _buildSettingsSection(changeSettings),
                  ],
                ),
              ),
            ),
          ),

          // 底部按钮区域
          _buildBottomButtons(changeSettings),
        ],
      ),
    );
  }

  Widget _buildModelSection(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('基础设置', settings, icon: Icons.tune),
        const SizedBox(height: 16),
        // 绘画底模选择
        _buildDropdownField(
          label: '绘画底模',
          tooltip: '选择要使用的AI绘画模型类型',
          settings: settings,
          child: CommonDropdownWidget(
            dropdownData: bots,
            selectedValue: selectBot,
            onChangeValue: (bot) {
              selectBot = bot;
              switch (bot) {
                case 'Midjourney':
                  models = ['MJ 6.1 (通用模型)', 'MJ 6.0 (通用模型)', 'MJ 5.2 (通用模型)', 'MJ 5.1 (通用模型)', 'MJ 5 (通用模型)', 'MJ 4 (通用模型)'];
                  break;
                case 'Nijijourney':
                  models = ['Niji 6 (动漫模型)', 'Niji 5 (动漫模型)', 'Niji 4 (动漫模型)'];
                  break;
              }
              selectModel = models[0];
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 12),
        // 绘画模型选择
        _buildDropdownField(
          settings: settings,
          label: '绘画模型',
          tooltip: '选择具体的模型版本',
          child: CommonDropdownWidget(
            dropdownData: models,
            selectedValue: selectModel,
            onChangeValue: (model) {
              selectModel = model;
              switch (model) {
                case 'MJ 6.0 (通用模型)':
                  selectStyles = styles[0];
                  selectStyle = selectStyles[0];
                  break;
                case 'MJ 5.2 (通用模型)':
                  selectStyles = styles[0];
                  selectStyle = selectStyles[0];
                  break;
                case 'MJ 5.1 (通用模型)':
                  selectStyles = styles[1];
                  selectStyle = selectStyles[0];
                  break;
                case 'Niji 5 (动漫模型)':
                  selectStyles = styles[4];
                  selectStyle = selectStyles[0];
                  break;
                default:
                  selectStyles = ['default'];
                  selectStyle = 'default';
                  break;
              }
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStyleSection(ChangeSettings settings) {
    if (!(selectModel == 'MJ 6.0 (通用模型)' ||
        selectModel == 'MJ 5.2 (通用模型)' ||
        selectModel == 'MJ 5.1 (通用模型)' ||
        selectModel == 'Niji 5 (动漫模型)' ||
        selectModel == 'Niji 6 (动漫模型)')) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('风格设置', settings, icon: Icons.style),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: '模型风格',
          tooltip: '选择生成图片的风格类型',
          settings: settings,
          child: CommonDropdownWidget(
            dropdownData: selectStyles,
            selectedValue: selectStyle,
            onChangeValue: (style) {
              selectStyle = style;
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildDropdownField(
          label: '图片比例',
          tooltip: '选择生成图片的宽高比',
          settings: settings,
          child: CommonDropdownWidget(
            dropdownData: aspects,
            selectedValue: selectAspect,
            onChangeValue: (aspect) {
              selectAspect = aspect;
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildDropdownField(
          label: '图片质量',
          tooltip: '选择生成图片的质量等级',
          settings: settings,
          child: CommonDropdownWidget(
            dropdownData: qualities,
            selectedValue: selectQuality,
            onChangeValue: (quality) {
              selectQuality = quality;
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

// 通用的标题组件
  Widget _buildSectionTitle(String title, ChangeSettings changeSettings, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: changeSettings.getForegroundColor(), size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: TextStyle(
            color: changeSettings.getForegroundColor(),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

// 通用的下拉框字段组件
  Widget _buildDropdownField({
    required String label,
    required Widget child,
    required ChangeSettings settings,
    String? tooltip,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: settings.getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Tooltip(
            message: tooltip ?? label,
            child: Text(
              '$label：',
              style: TextStyle(
                color: settings.getForegroundColor(),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildAdvancedSection(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('高级参数', settings, icon: Icons.settings_applications),
        const SizedBox(height: 16),

        // 风格化滑块
        _buildSliderField(
          label: '风格化',
          value: selectStylize,
          min: 0,
          max: 1000,
          tooltip: '这个值越低会更符合 prompt 的描述，数值越高艺术性就会越强，但跟 prompt 关联性就会比较弱',
          settings: settings,
          formatLabel: (value) => value.toStringAsFixed(0),
          onChanged: (value) {
            setState(() {
              selectStylize = value;
            });
          },
        ),
        const SizedBox(height: 12),

        // 奇妙性滑块
        _buildSliderField(
          label: '奇妙性',
          value: selectWeird,
          min: 0,
          max: 3000,
          tooltip: '生成的图像引入奇特和离奇的特质，从而产生独特而意想不到的结果',
          settings: settings,
          formatLabel: (value) => value.toStringAsFixed(0),
          onChanged: (value) {
            setState(() {
              selectWeird = value;
            });
          },
        ),
        const SizedBox(height: 12),

        // 多样性滑块
        _buildSliderField(
          label: '多样性',
          value: selectChaos,
          min: 0,
          max: 100,
          tooltip: '这个值越低生成的四张图风格越相似，反之差异越大',
          settings: settings,
          formatLabel: (value) => value.toStringAsFixed(0),
          onChanged: (value) {
            setState(() {
              selectChaos = value;
            });
          },
        ),
        const SizedBox(height: 12),

        // 图片权重滑块
        _buildSliderField(
          label: '图片权重',
          value: selectImageWeight,
          min: 0,
          max: 2,
          divisions: 200,
          tooltip: '上传图片时生效，这个值越高，上传的图像对最终效果的影响就越大',
          settings: settings,
          formatLabel: (value) => value.toStringAsFixed(2),
          onChanged: (value) {
            setState(() {
              selectImageWeight = value;
            });
          },
        ),
        const SizedBox(height: 16),

        // 图片种子输入框
        _buildTextField(
          label: '图片种子',
          controller: seedTextEditingController,
          tooltip: '指定图片的种子值，一般会生成类似的图片，但是从mj5版本以后貌似效果不太明显了',
          settings: settings,
          hintText: '请输入图片种子(可留空)',
        ),
        const SizedBox(height: 12),

        // 排除元素输入框
        _buildTextField(
            label: '排除元素',
            controller: noTextEditingController,
            tooltip: '用于指定不想在图片中出现的元素',
            hintText: '请输入不想在图片中出现的元素(可留空)',
            settings: settings),
      ],
    );
  }

// 通用的滑块字段组件
  Widget _buildSliderField({
    required String label,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
    required String Function(double) formatLabel,
    required ChangeSettings settings,
    String? tooltip,
    int? divisions,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: settings.getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Tooltip(
                message: tooltip ?? label,
                child: Text(
                  label,
                  style: TextStyle(
                    color: settings.getForegroundColor(),
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                formatLabel(value),
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: settings.getSelectedBgColor(),
              inactiveTrackColor: settings.getForegroundColor().withAlpha(51),
              thumbColor: settings.getSelectedBgColor(),
              overlayColor: settings.getSelectedBgColor().withAlpha(51),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions ?? (max - min).toInt(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

// 通用的输入框字段组件
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required ChangeSettings settings,
    String? tooltip,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: settings.getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tooltip(
            message: tooltip ?? label,
            child: Text(
              label,
              style: TextStyle(
                color: settings.getForegroundColor(),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            style: TextStyle(color: settings.getForegroundColor()),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceImagesSection(ChangeSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('参考图片', settings, icon: Icons.image),
        const SizedBox(height: 16),

        // 样式参考图部分
        _buildImageSection(
          title: '样式参考图',
          subtitle: '上传图片以作为生成图片的风格参考',
          images: referenceImages,
          weight: referenceWeight,
          maxWeight: 1000,
          settings: settings,
          onImagePick: (index) => _pickImage(index, true),
          onImageRemove: (index) {
            setState(() {
              referenceImages[index] = '';
            });
          },
          onWeightChanged: (value) {
            setState(() {
              referenceWeight = value;
            });
          },
        ),
        const SizedBox(height: 20),

        // 角色参考图部分
        _buildImageSection(
          title: '角色参考图',
          subtitle: '上传图片以作为生成角色的参考',
          images: characterImages,
          weight: characterWeight,
          maxWeight: 100,
          settings: settings,
          onImagePick: (index) => _pickImage(index, false),
          onImageRemove: (index) {
            setState(() {
              characterImages[index] = '';
            });
          },
          onWeightChanged: (value) {
            setState(() {
              characterWeight = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildImageSection({
    required String title,
    required String subtitle,
    required List<String> images,
    required double weight,
    required double maxWeight,
    required Function(int) onImagePick,
    required Function(int) onImageRemove,
    required Function(double) onWeightChanged,
    required ChangeSettings settings,
  }) {
    final bool isMobile = Platform.isAndroid || Platform.isIOS;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: isMobile ? 6 : 16),
      decoration: BoxDecoration(
        color: settings.getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: settings.getForegroundColor(),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
                2,
                (index) => _buildImageBox(
                    imagePath: images[index],
                    onPick: () => onImagePick(index),
                    onRemove: () => onImageRemove(index),
                    settings: settings)),
          ),
          const SizedBox(height: 16),
          _buildWeightSlider(weight: weight, maxWeight: maxWeight, onChanged: onWeightChanged, settings: settings),
        ],
      ),
    );
  }

  Widget _buildImageBox({
    required String imagePath,
    required VoidCallback onPick,
    required VoidCallback onRemove,
    required ChangeSettings settings,
  }) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: settings.getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: imagePath.isEmpty ? Colors.grey[700]! : Colors.blue,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            if (imagePath.isEmpty)
              InkWell(
                onTap: onPick,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        color: Colors.grey[400],
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '添加图片',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Stack(
                fit: StackFit.expand,
                children: [
                  ExtendedImage.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(178),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightSlider({
    required double weight,
    required double maxWeight,
    required Function(double) onChanged,
    required ChangeSettings settings,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '参考权重',
              style: TextStyle(
                color: settings.getForegroundColor(),
                fontSize: 14,
              ),
            ),
            Text(
              weight.toStringAsFixed(0),
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: settings.getSelectedBgColor(),
            inactiveTrackColor: settings.getForegroundColor().withAlpha(51),
            thumbColor: settings.getSelectedBgColor(),
            overlayColor: settings.getSelectedBgColor().withAlpha(51),
            trackHeight: 4,
          ),
          child: Slider(
            value: weight,
            min: 0,
            max: maxWeight,
            divisions: maxWeight.toInt(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // 设置部分
  Widget _buildSettingsSection(ChangeSettings settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: settings.getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('其他设置', settings, icon: Icons.settings),
          const SizedBox(height: 16),
          // 保留参数开关
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '提交后保留参数',
                    style: TextStyle(
                      color: settings.getForegroundColor(),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '开启后下次打开将保持当前设置',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _retainParametersAfterSubmission,
                onChanged: (value) {
                  setState(() {
                    _retainParametersAfterSubmission = value;
                  });
                },
                activeTrackColor: GlobalParams.themeColor,
                activeColor: Colors.pinkAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

// 底部按钮部分
  Widget _buildBottomButtons(ChangeSettings settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: settings.getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildButton(
              label: '取消',
              onPressed: () => Navigator.of(context).pop(),
              backgroundColor: Colors.grey[700]!,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildButton(
              label: '确认',
              onPressed: _handleConfirm,
              backgroundColor: settings.getSelectedBgColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withAlpha(76),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  void _handleConfirm() {
    Map<String, dynamic> finalOptionsMap = {};
    String finalOptions = '';

    // 根据选择的模型构建参数
    switch (selectModel) {
      case 'MJ 6.1 (通用模型)':
        finalOptions += ' --v 6.1';
        if (selectWeird != 0) {
          finalOptions += ' --weird ${selectWeird.toStringAsFixed(0)}';
        }
        if (selectImageWeight != 1) {
          finalOptions += ' --iw ${selectImageWeight.toStringAsFixed(2)}';
        }
        break;
      case 'MJ 6.0 (通用模型)':
        finalOptions += ' --v 6.0';
        if (selectStyle == 'raw') {
          finalOptions += ' --style raw';
        }
        if (selectWeird != 0) {
          finalOptions += ' --weird ${selectWeird.toStringAsFixed(0)}';
        }
        if (selectImageWeight != 1) {
          finalOptions += ' --iw ${selectImageWeight.toStringAsFixed(2)}';
        }
        break;
      case 'MJ 5.2 (通用模型)':
        finalOptions += ' --v 5.2';
        if (selectStyle == 'raw') {
          finalOptions += ' --style raw';
        }
        if (selectWeird != 0) {
          finalOptions += ' --weird ${selectWeird.toStringAsFixed(0)}';
        }
        if (selectImageWeight != 1) {
          finalOptions += ' --iw ${selectImageWeight.toStringAsFixed(2)}';
        }
        break;
      case 'MJ 5.1 (通用模型)':
        finalOptions += ' --v 5.1';
        if (selectStyle == 'raw') {
          finalOptions += ' --style raw';
        }
        if (selectWeird != 0) {
          finalOptions += ' --weird ${selectWeird.toStringAsFixed(0)}';
        }
        if (selectImageWeight != 1) {
          finalOptions += ' --iw ${selectImageWeight.toStringAsFixed(2)}';
        }
        break;
      case 'MJ 5 (通用模型)':
        finalOptions += ' --v 5';
        if (selectWeird != 0) {
          finalOptions += ' --weird ${selectWeird.toStringAsFixed(0)}';
        }
        if (selectImageWeight != 1) {
          finalOptions += ' --iw ${selectImageWeight.toStringAsFixed(2)}';
        }
        break;
      case 'MJ 4 (通用模型)':
        finalOptions += ' --v 4';
        break;
      case 'Niji 4 (动漫模型)':
        finalOptions += ' --niji 4';
        if (selectStyle != 'default') {
          finalOptions += ' --style $selectStyle';
        }
        if (selectImageWeight != 1) {
          finalOptions += ' --iw ${selectImageWeight.toStringAsFixed(2)}';
        }
        break;
      case 'Niji 5 (动漫模型)':
        finalOptions += ' --niji 5';
        if (selectStyle != 'default') {
          finalOptions += ' --style $selectStyle';
        }
        if (selectImageWeight != 1) {
          finalOptions += ' --iw ${selectImageWeight.toStringAsFixed(2)}';
        }
        break;
      case 'Niji 6 (动漫模型)':
        finalOptions += ' --niji 6';
        if (selectStyle != 'default') {
          finalOptions += ' --style $selectStyle';
        }
        if (selectImageWeight != 1) {
          finalOptions += ' --iw ${selectImageWeight.toStringAsFixed(2)}';
        }
        break;
      default:
        finalOptions += ' --v 6.0';
        break;
    }

    // 添加通用参数
    finalOptions += ' --ar $selectAspect';
    if (selectQuality != '1') {
      finalOptions += ' --q $selectQuality';
    }
    if (selectStylize != 100) {
      finalOptions += ' --stylize ${selectStylize.toStringAsFixed(0)}';
    }
    if (selectChaos != 0) {
      finalOptions += ' --chaos ${selectChaos.toStringAsFixed(0)}';
    }

    // 添加种子和排除元素
    if (seedTextEditingController.text.isNotEmpty) {
      finalOptions += ' --seed ${seedTextEditingController.text}';
    }
    if (noTextEditingController.text.isNotEmpty) {
      finalOptions += ' --no ${noTextEditingController.text}';
    }

    // 添加参考图片权重
    if (referenceWeight != 100) {
      finalOptions += ' --sw ${referenceWeight.toStringAsFixed(0)}';
    }
    if (characterWeight != 100) {
      finalOptions += ' --cw ${characterWeight.toStringAsFixed(0)}';
    }

    // 根据选择的底模设置最终选项
    if (selectBot == 'Midjourney') {
      finalOptionsMap['MID_JOURNEY'] = finalOptions;
    } else {
      finalOptionsMap['NIJI_JOURNEY'] = finalOptions;
    }

    // 添加图片数组
    if (characterImages.isNotEmpty) {
      finalOptionsMap['characterImages'] = characterImages;
    }
    if (referenceImages.isNotEmpty) {
      finalOptionsMap['referenceImages'] = referenceImages;
    }

    // 添加参数保留设置
    finalOptionsMap['retainParameters'] = _retainParametersAfterSubmission;

    // 调用回调并关闭对话框
    widget.onConfirm(finalOptionsMap);
    Navigator.of(context).pop();
  }
}
