import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'tag_item.dart';

class InputWithTags extends StatefulWidget {
  final Function(String) onSure; // 定义一个回调函数

  const InputWithTags({super.key, required this.onSure});

  @override
  State<InputWithTags> createState() => _InputWithTagsState();
}

class _InputWithTagsState extends State<InputWithTags> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _selectedTags = [];

  // 标签列表
  final List<String> _tags = [
    '流行',
    '电子',
    '民谣',
    '说唱',
    '摇滚',
    '爵士',
    'R&B',
    '布鲁斯',
    '金属',
    '后摇',
    '新世纪',
    '古典风',
    '古风',
    '中国风',
    '乡村',
    '快乐',
    '安静',
    '励志',
    '伤感',
    '治愈',
    '寂寞',
    '思念',
    '宣泄',
    '甜蜜'
  ];

  void _onConfirm() {
    // 当确认操作时，调用外部传入的回调函数并传递文本框内容
    widget.onSure(_controller.text);
  }

  @override
  void initState() {
    super.initState();
    _controller.text = '';
  }

  void _onTagTap(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
      _controller.text = _selectedTags.join(',');
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: settings.getBackgroundColor(),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: TextField(
            controller: _controller,
            maxLength: 120,
            maxLines: 3,
            minLines: 1,
            decoration: const InputDecoration(
              hintText: '输入音乐风格',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style:  TextStyle(color: settings.getForegroundColor()),
          ),
        ),
        const SizedBox(height: 8.0),
        Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _scrollController,
            child: Row(
              children: _tags.map((tag) {
                return TagItem(
                  label: tag,
                  isSelected: _selectedTags.contains(tag),
                  onTap: () => _onTagTap(tag),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 10.0),
        // 添加确认按钮
        ElevatedButton(
          onPressed: _onConfirm,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: settings.getSelectedBgColor(),
            // 设置文字颜色为白色
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0), // 设置圆角为10
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            // 设置按钮左右边距为16
            minimumSize: const Size.fromHeight(50), // 设置按钮宽度为父布局的宽度，并且设置最小高度
          ),
          child: const Text('确认'),
        ),
      ],
    );
  }
}
