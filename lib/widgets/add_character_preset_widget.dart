import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tuitu/utils/common_methods.dart';

import '../config/config.dart';
import '../net/my_api.dart';
import 'common_dropdown.dart';

class AddCharacterPreset extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController contentController;
  final bool isModify;
  final Function() onClearCharacterPresets;
  final Function(int modifyPosition) onChangedCharacterPresetsPosition;
  final Function(int deletePosition) onDeleteCharacterPresets;

  const AddCharacterPreset(
      {super.key,
      required this.titleController,
      required this.contentController,
      required this.isModify,
      required this.onClearCharacterPresets,
      required this.onChangedCharacterPresetsPosition,
      required this.onDeleteCharacterPresets});

  @override
  State<AddCharacterPreset> createState() => _AddCharacterPresetState();
}

class _AddCharacterPresetState extends State<AddCharacterPreset> {
  late TextEditingController titleController;
  late TextEditingController contentController;
  double loraWeights = 0.8;
  late MyApi myApi;
  final List<String> _loras = ['请检查sd配置'];
  String _selectedLora = '请检查sd配置';
  String _lastSelectedLora = '';
  String characterPresetDesc = '';
  String selectedCharacterPresets = '0.无';
  int selectedCharacterPresetsPosition = 0;
  List<String> readCharacterPresets = ['0.无'].obs;
  List<String> readCharacterPresetDescriptions = [''].obs;

  Future<List<String>> _getCharacterPresets() async {
    Map<String, dynamic> savedCharacterPresets = await Config.loadSettings(type: 2);
    readCharacterPresets = List<String>.from(savedCharacterPresets['character_list']);
    readCharacterPresets.removeLast();
    return readCharacterPresets;
  }

  Future<List<String>> _getCharacterPresetsDescriptions() async {
    Map<String, dynamic> savedCharacterPresets = await Config.loadSettings(type: 2);
    readCharacterPresetDescriptions = List<String>.from(savedCharacterPresets['character_prompts']);
    return readCharacterPresetDescriptions;
  }

  Future<void> _getLoras(String url) async {
    try {
      dio.Response response = await myApi.getSDLoras(url);
      if (response.statusCode == 200) {
        _loras.clear();
        for (int i = 0; i < response.data.length; i++) {
          _loras.add(response.data[i]['name']);
        }
      } else {
        commonPrint('获取Lora列表失败，错误是${response.statusMessage}');
      }
    } catch (error) {
      commonPrint('获取Lora列表失败，错误是$error');
    }
    setState(() {
      if (_loras.isNotEmpty) {
        _selectedLora = _loras[0];
      }
    });
  }

  Future<void> loadSettings() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String? sdUrl = settings['sdUrl'];
    if (sdUrl == null || sdUrl == '') {
      _selectedLora = '请检查sd配置';
    } else {
      _getLoras(sdUrl);
    }
    if (widget.isModify) {
      await _getCharacterPresets();
      await _getCharacterPresetsDescriptions();
      // 增加数据更改刷新，否则数据更新不生效
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    myApi = MyApi();
    loadSettings();
    titleController = widget.titleController;
    contentController = widget.contentController;
    if (widget.isModify) {
      titleController.text = '0.无';
      contentController.text = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Visibility(
          visible: widget.isModify,
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    '选择预设：',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Expanded(
                      child: CommonDropdownWidget(
                          selectedValue: selectedCharacterPresets,
                          dropdownData: readCharacterPresets,
                          onChangeValue: (characterPreset) {
                            for (int i = 0; i < readCharacterPresets.length; i++) {
                              if (characterPreset == readCharacterPresets[i]) {
                                characterPresetDesc = readCharacterPresetDescriptions[i];
                                selectedCharacterPresetsPosition = i;
                                widget.onChangedCharacterPresetsPosition(selectedCharacterPresetsPosition);
                              }
                            }
                            setState(() {
                              titleController.text = characterPreset;
                              contentController.text = characterPresetDesc;
                              selectedCharacterPresets = characterPreset;
                            });
                          }))
                ],
              ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
        Row(
          children: [
            const Text(
              '预设标题：',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Expanded(
                child: TextField(
              controller: titleController,
              // onChanged: (title) {
              //   // setState(() {
              //   //   titleController.text = title;
              //   // });
              // },
              style: TextStyle(
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.grey.withAlpha(128),
                    offset: const Offset(0, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
              decoration: const InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2.0),
                ),
                labelText: '预设标题',
                labelStyle: TextStyle(color: Colors.white),
              ),
            ))
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          children: [
            const Text('预设描述：', style: TextStyle(color: Colors.white, fontSize: 16)),
            Expanded(
                child: TextField(
              controller: contentController,
              // onChanged: (content) {
              //   // setState(() {
              //     contentController.text = content;
              //   // });
              // },
              maxLines: 3,
              minLines: 3,
              keyboardType: TextInputType.multiline,
              style: TextStyle(
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.grey.withAlpha(128),
                    offset: const Offset(0, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
              decoration: const InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2.0),
                ),
                labelText: '预设描述',
                labelStyle: TextStyle(color: Colors.white),
              ),
            ))
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(width: 2, color: Colors.white), // 边框样式
            ),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('预设lora：', style: TextStyle(color: Colors.white, fontSize: 16)),
                      Expanded(
                        child: CommonDropdownWidget(
                            selectedValue: _selectedLora,
                            dropdownData: _loras,
                            onChangeValue: (newValue) async {
                              setState(() {
                                _selectedLora = newValue;
                                loraWeights = 0.8;
                              });
                            }),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      Text('lora权重(${loraWeights.toStringAsFixed(1)}):',
                          style: const TextStyle(color: Colors.white, fontSize: 16)),
                      Expanded(
                        child: Slider(
                          value: loraWeights,
                          min: 0.1,
                          max: 2.0,
                          divisions: 20,
                          onChanged: (value) {
                            setState(() {
                              loraWeights = value;
                            });
                          },
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ElevatedButton(
                            onPressed: () async {
                              if (_selectedLora != _lastSelectedLora) {
                                setState(() {
                                  if (!contentController.text.endsWith(', ') && contentController.text != '') {
                                    contentController.text =
                                        '${contentController.text}, <lora:$_selectedLora:${loraWeights.toStringAsFixed(1)}>, ';
                                  } else {
                                    contentController.text =
                                        '${contentController.text}<lora:$_selectedLora:${loraWeights.toStringAsFixed(1)}>, ';
                                  }
                                  _lastSelectedLora = _selectedLora;
                                });
                              }
                            },
                            child: const Text('使用该lora及权重')),
                      ),
                    ],
                  ),
                ],
              ),
            )),
        Visibility(
            visible: widget.isModify,
            child: Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                Padding(
                    padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              if (selectedCharacterPresetsPosition == 0) {
                                showHint('预设"0.无"不能删除', showType: 3);
                              } else {
                                widget.onDeleteCharacterPresets(selectedCharacterPresetsPosition);
                              }
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(Colors.blue),
                              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                            child: const Text('删除选中预设', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              widget.onClearCharacterPresets();
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(Colors.blue),
                              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                            child: const Text('清空所有预设', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    )),
              ],
            ))
      ],
    );
  }
}
