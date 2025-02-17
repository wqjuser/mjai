import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';

enum PackageType {
  trial('体验套餐', Colors.blue, 0),
  monthlyBasic('月度基础套餐', Colors.green, 1),
  monthlyPro('月度高级套餐', Colors.green, 2),
  monthlyPremium('月度尊享套餐', Colors.green, 3),
  yearlyBasic('年度基础套餐', Colors.purple, 4),
  yearlyPro('年度高级套餐', Colors.purple, 5),
  yearlyPremium('年度尊享套餐', Colors.purple, 6),
  extra('额外套餐', Colors.orange, 7);

  final String label;
  final Color color;
  final int type;

  const PackageType(this.label, this.color, this.type);

  // 静态方法，通过 type 值获取对应的 PackageType
  static PackageType fromType(int type) {
    return PackageType.values.firstWhere(
      (element) => element.type == type,
      orElse: () => PackageType.monthlyBasic, // 如果找不到，返回 monthly
    );
  }
}

class PackageDialog extends StatefulWidget {
  final Map<dynamic, dynamic> packageInfo;
  final bool isAdd;
  final Function(Map<dynamic, dynamic>) onConfirm;

  const PackageDialog({
    Key? key,
    required this.packageInfo,
    required this.isAdd,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<PackageDialog> createState() => _PackageDialogState();
}

class _PackageDialogState extends State<PackageDialog> {
  late TextEditingController titleController;
  late TextEditingController priceController;
  late TextEditingController normalDrawController;
  late TextEditingController seniorDrawController;
  late TextEditingController normalChatController;
  late TextEditingController seniorChatController;
  late TextEditingController aiMusicController;
  late TextEditingController aiVideoController;
  late TextEditingController tokensController;

  PackageType selectedType = PackageType.monthlyBasic;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (!widget.isAdd) {
      int type = widget.packageInfo['type'];
      selectedType = PackageType.fromType(type);
    }
    titleController = TextEditingController(text: widget.isAdd ? '月度基础套餐' : widget.packageInfo['name']);
    priceController = TextEditingController(text: widget.isAdd ? '0.01' : widget.packageInfo['price'].toString());
    normalDrawController = TextEditingController(text: widget.isAdd ? '0' : widget.packageInfo['slow_drawing_count'].toString());
    seniorDrawController = TextEditingController(text: widget.isAdd ? '0' : widget.packageInfo['fast_drawing_count'].toString());
    normalChatController = TextEditingController(text: widget.isAdd ? '0' : widget.packageInfo['basic_chat_count'].toString());
    seniorChatController = TextEditingController(text: widget.isAdd ? '0' : widget.packageInfo['premium_chat_count'].toString());
    aiMusicController = TextEditingController(text: widget.isAdd ? '0' : widget.packageInfo['ai_music_count']?.toString() ?? '0');
    aiVideoController = TextEditingController(text: widget.isAdd ? '0' : widget.packageInfo['ai_video_count']?.toString() ?? '0');
    tokensController = TextEditingController(text: widget.isAdd ? '0' : widget.packageInfo['token_count']?.toString() ?? '0');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    titleController.dispose();
    priceController.dispose();
    normalDrawController.dispose();
    seniorDrawController.dispose();
    normalChatController.dispose();
    seniorChatController.dispose();
    aiMusicController.dispose();
    aiVideoController.dispose();
    tokensController.dispose();
    super.dispose();
  }

  Widget _buildPackageTypeSelector(ChangeSettings settings, bool isWide) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '套餐类型',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: settings.getForegroundColor(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: PackageType.values.map((type) {
              return ChoiceChip(
                label: Text(
                  type.label,
                  style: TextStyle(
                    color: selectedType == type ? Colors.white : settings.getForegroundColor(),
                  ),
                ),
                selected: selectedType == type,
                selectedColor: type.color,
                backgroundColor: settings.getBackgroundColor(),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      selectedType = type;
                      titleController.text = type.label;
                    });
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool isNumber = true,
    String suffix = '',
    required ChangeSettings settings,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 140,
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: settings.getForegroundColor(),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: settings.getBorderColor()),
              ),
              child: TextField(
                controller: controller,
                keyboardType: isNumber ? TextInputType.number : TextInputType.text,
                inputFormatters: isNumber ? [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*'))] : null,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: InputBorder.none,
                  suffix: Text(
                    suffix,
                    style: TextStyle(
                      fontSize: 14,
                      color: settings.getForegroundColor(),
                    ),
                  ),
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: settings.getForegroundColor(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(ChangeSettings settings, bool isWide) {
    final inputs = [
      _buildInputField(
        label: '套餐名称',
        controller: titleController,
        isNumber: false,
        settings: settings,
      ),
      _buildInputField(
        label: '套餐价格',
        controller: priceController,
        suffix: '元',
        settings: settings,
      ),
      _buildInputField(
        label: '慢速绘图次数',
        controller: normalDrawController,
        suffix: '次',
        settings: settings,
      ),
      _buildInputField(
        label: '快速绘图次数',
        controller: seniorDrawController,
        suffix: '次',
        settings: settings,
      ),
      _buildInputField(
        label: '基础对话次数',
        controller: normalChatController,
        suffix: '次',
        settings: settings,
      ),
      _buildInputField(
        label: '高级对话次数',
        controller: seniorChatController,
        suffix: '次',
        settings: settings,
      ),
      _buildInputField(
        label: 'AI音乐次数',
        controller: aiMusicController,
        suffix: '次',
        settings: settings,
      ),
      _buildInputField(
        label: 'AI视频次数',
        controller: aiVideoController,
        suffix: '次',
        settings: settings,
      ),
      _buildInputField(
        label: 'Tokens数量',
        controller: tokensController,
        settings: settings,
      ),
    ];

    if (!isWide) {
      return Column(children: inputs);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: inputs.sublist(0, (inputs.length / 2).ceil()),
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: Column(
            children: inputs.sublist((inputs.length / 2).ceil()),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: settings.getBackgroundColor(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxHeight > 500;

          return Container(
            width: constraints.maxWidth,
            constraints: const BoxConstraints(
              maxWidth: 600,
              maxHeight: 686,
              minHeight: 400,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: selectedType.color.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isAdd ? '新建套餐' : '修改套餐',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: settings.getForegroundColor(),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: settings.getForegroundColor()),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPackageTypeSelector(settings, isWide),
                          _buildInputSection(settings, isWide),
                        ],
                      ),
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: settings.getBackgroundColor(),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    border: Border(
                      top: BorderSide(
                        color: settings.getBorderColor(),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          '取消',
                          style: TextStyle(color: settings.getSelectedBgColor()),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          final packageInfo = {
                            'name': titleController.text,
                            'type': selectedType.type,
                            'price': double.parse(priceController.text),
                            'slow_drawing_count': int.parse(normalDrawController.text),
                            'fast_drawing_count': int.parse(seniorDrawController.text),
                            'basic_chat_count': int.parse(normalChatController.text),
                            'premium_chat_count': int.parse(seniorChatController.text),
                            'ai_music_count': int.parse(aiMusicController.text),
                            'ai_video_count': int.parse(aiVideoController.text),
                            'token_count': int.parse(tokensController.text),
                          };
                          widget.onConfirm(packageInfo);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedType.color,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          '确认',
                          style: TextStyle(color: settings.getCardTextColor()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
