import 'dart:async';

import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/common_methods.dart';

class AutoSaveOption extends StatefulWidget {
  final bool isAutoSave;
  final int interval;
  final Function(int interval, bool isAutoSave) onConfirm;

  const AutoSaveOption({super.key, required this.onConfirm, this.isAutoSave = false, this.interval = 5});

  @override
  State<AutoSaveOption> createState() => _AutoSaveOptionState();
}

class _AutoSaveOptionState extends State<AutoSaveOption> {
  late bool isAutoSave;
  late int interval;
  Timer? _debounce;
  TextEditingController autoSaveIntervalController = TextEditingController();

  void initView() {
    isAutoSave = widget.isAutoSave;
    interval = widget.interval;
    autoSaveIntervalController.text = '$interval';
  }

  @override
  void initState() {
    initView();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                isAutoSave = !isAutoSave;
              });
            },
            child: Row(
              children: [
                const Expanded(
                    child: Text(
                  '启用自动保存',
                  style: TextStyle(color: Colors.white),
                )),
                Theme(
                    data: ThemeData(
                      unselectedWidgetColor: Colors.yellowAccent,
                    ),
                    child: Checkbox(
                      value: isAutoSave,
                      onChanged: (bool? newValue) async {
                        setState(() {
                          isAutoSave = newValue ?? false;
                        });
                      },
                    )),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                '每隔',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(
                    color: Colors.white, // 边框颜色
                    width: 1.0, // 边框宽度
                  ), // 6像素的圆角
                ),
                child: AutoSizeTextField(
                  fullwidth: false,
                  minFontSize: 14,
                  scrollPadding: EdgeInsets.zero,
                  onChanged: (content) {
                    if (_debounce != null) {
                      _debounce!.cancel();
                    }
                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      if (content.isEmpty) {
                        autoSaveIntervalController.text = '5';
                        if (mounted) {
                          showHint('自动保存时间间隔不能为空,已为您设置为最小值5分钟');
                        }
                      } else if (int.parse(content.trim()) < 5) {
                        autoSaveIntervalController.text = '5';
                        if (mounted) {
                          showHint('自动保存时间间隔最小值为5分钟,已为您设置为最小值5分钟');
                        }
                      } else if (int.parse(content.trim()) > 30) {
                        autoSaveIntervalController.text = '30';
                        if (mounted) {
                          showHint('自动保存时间间隔最大值为30分钟,已为您设置为最大值30分钟');
                        }
                      }
                    });
                  },
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  controller: autoSaveIntervalController,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly, // 限制只能输入数字
                  ],
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.only(bottom: 4),
                    isCollapsed: true,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              const Text('分钟自动保存', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(Colors.grey),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  child: const Text('取消', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    widget.onConfirm(interval, isAutoSave);
                    Navigator.of(context).pop();
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(Colors.blue),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  child: const Text('确认', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
