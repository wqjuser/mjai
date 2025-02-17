import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../utils/common_methods.dart';
import 'common_dropdown.dart';

class ControlNetOptionItem extends StatefulWidget {
  final Map<String, dynamic> controlNetOption;
  final List<String> controlTypes;
  final List<String> controlModules;
  final List<String> controlModels;
  final int index;

  const ControlNetOptionItem(
      {super.key,
      required this.controlNetOption,
      required this.controlTypes,
      required this.controlModules,
      required this.controlModels,
      required this.index});

  @override
  State<ControlNetOptionItem> createState() => _ControlNetOptionItemState();
}

class _ControlNetOptionItemState extends State<ControlNetOptionItem> {
  late Map<String, dynamic> controlNetOption;
  late List<String> _controlTypes;
  late List<String> _controlModules;
  late List<String> _controlModels;
  late int index;

  @override
  void initState() {
    controlNetOption = widget.controlNetOption;
    index = widget.index;
    _controlTypes = widget.controlTypes;
    _controlModules = widget.controlModules;
    _controlModels = widget.controlModels;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: Colors.white,
            width: 1.0,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(
              height: 4,
            ),
            Text('controlnet控制单元${index + 1}',
                style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold)),
            const SizedBox(
              height: 6,
            ),
            Container(
              margin: const EdgeInsets.all(4.0),
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(
                  color: Colors.white,
                  width: 1.0,
                ),
              ),
              child: widget.controlNetOption['input_image'] == ''
                  ? Center(
                      child: InkWell(
                      child: Tooltip(
                        message: '上传图片',
                        child: Container(
                          width: 40,
                          height: 40,
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: SvgPicture.asset('assets/images/upload_image.svg', semanticsLabel: '上传图片'),
                        ),
                      ),
                      onTap: () async {
                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'png', 'jpeg']);
                        if (result != null) {
                          String imagePath = result.files.single.path!;
                          String base64Path = await imageToBase64(imagePath);
                          String compress = await compressBase64Image(base64Path);
                          setState(() {
                            controlNetOption['input_image'] = compress;
                            controlNetOption['is_enable'] = true;
                          });
                        }
                      },
                    ))
                  : Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6.0),
                            image: DecorationImage(
                              image: MemoryImage(base64Decode(widget.controlNetOption['input_image'])),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Center(
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            InkWell(
                              child: Tooltip(
                                message: '换一张图片',
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: SvgPicture.asset('assets/images/upload_image.svg', semanticsLabel: '换一张图片'),
                                ),
                              ),
                              onTap: () async {
                                FilePickerResult? result = await FilePicker.platform
                                    .pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'png', 'jpeg']);
                                if (result != null) {
                                  String imagePath = result.files.single.path!;
                                  String base64Path = await imageToBase64(imagePath);
                                  String compress = await compressBase64Image(base64Path);
                                  setState(() {
                                    controlNetOption['input_image'] = compress;
                                    controlNetOption['is_enable'] = true;
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              child: Tooltip(
                                message: '删除此图片',
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: SvgPicture.asset('assets/images/delete.svg', semanticsLabel: '删除此图片'),
                                ),
                              ),
                              onTap: () async {
                                setState(() {
                                  controlNetOption['input_image'] = '';
                                  controlNetOption['is_enable'] = false;
                                });
                              },
                            ),
                          ])),
                        )
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                      child: InkWell(
                          onTap: () {
                            setState(() {
                              controlNetOption['is_enable'] = !controlNetOption['is_enable'];
                            });
                          },
                          child: Row(
                            children: [
                              Theme(
                                  data: ThemeData(
                                    unselectedWidgetColor: Colors.yellowAccent,
                                  ),
                                  child: Checkbox(
                                      value: controlNetOption['is_enable'] ?? false,
                                      onChanged: (value) {
                                        setState(() {
                                          controlNetOption['is_enable'] = value!;
                                        });
                                      })),
                              const SizedBox(width: 2),
                              const Text(
                                '启用',
                                style: TextStyle(color: Colors.white),
                              )
                            ],
                          ))),
                  Expanded(
                      child: InkWell(
                          onTap: () {
                            setState(() {
                              controlNetOption['lowvram'] = !(controlNetOption['lowvram'] ?? false);
                            });
                          },
                          child: Row(
                            children: [
                              Theme(
                                  data: ThemeData(
                                    unselectedWidgetColor: Colors.yellowAccent,
                                  ),
                                  child: Checkbox(
                                      value: controlNetOption['lowvram'] ?? false,
                                      onChanged: (value) {
                                        setState(() {
                                          controlNetOption['lowvram'] = value!;
                                        });
                                      })),
                              const SizedBox(width: 2),
                              const Text(
                                '低显存模式',
                                style: TextStyle(color: Colors.white),
                              )
                            ],
                          ))),
                  Expanded(
                      child: InkWell(
                          onTap: () {
                            setState(() {
                              controlNetOption['pixel_perfect'] = !(controlNetOption['pixel_perfect'] ?? false);
                            });
                          },
                          child: Row(
                            children: [
                              Theme(
                                  data: ThemeData(
                                    unselectedWidgetColor: Colors.yellowAccent,
                                  ),
                                  child: Checkbox(
                                      value: controlNetOption['pixel_perfect'] ?? false,
                                      onChanged: (value) {
                                        setState(() {
                                          controlNetOption['pixel_perfect'] = value!;
                                        });
                                      })),
                              const SizedBox(width: 2),
                              const Text(
                                '完美像素模式',
                                style: TextStyle(color: Colors.white),
                              )
                            ],
                          )))
                ],
              ),
            ),
            Visibility(
              visible: false,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: <Widget>[
                    const Text('控制类型:', style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 4),
                    Expanded(
                        child: CommonDropdownWidget(
                      dropdownData: _controlTypes,
                      selectedValue: controlNetOption['control_type'] ?? 'All',
                      onChangeValue: (controlType) {
                        setState(() {
                          controlNetOption['control_type'] = controlType;
                        });
                      },
                    )),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: <Widget>[
                  const Text('预处理器:', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 4),
                  Expanded(
                      child: CommonDropdownWidget(
                    dropdownData: _controlModules,
                    selectedValue: (controlNetOption['module'] == null || controlNetOption['module'] == 'none')
                        ? '无'
                        : controlNetOption['module'],
                    onChangeValue: (controlModule) {
                      if (controlModule == '无') {
                        controlModule = 'none';
                      }
                      setState(() {
                        controlNetOption['module'] = controlModule;
                      });
                    },
                  )),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: <Widget>[
                  const Text('选择模型:', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 4),
                  Expanded(
                      child: CommonDropdownWidget(
                    dropdownData: _controlModels,
                    selectedValue: (controlNetOption['model'] == null || controlNetOption['model'] == 'None')
                        ? '无'
                        : controlNetOption['model'],
                    onChangeValue: (controlModel) {
                      if (controlModel == '无') {
                        controlModel = 'None';
                      }
                      setState(() {
                        controlNetOption['model'] = controlModel;
                      });
                    },
                  )),
                ],
              ),
            ),
            Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    const Text('控制模式:', style: TextStyle(color: Colors.white)),
                    Expanded(
                        child: Theme(
                      data: ThemeData(
                        unselectedWidgetColor: Colors.yellowAccent,
                      ),
                      child: Tooltip(
                          message: '均衡模式',
                          child: RadioListTile<int>(
                            contentPadding: const EdgeInsets.only(left: 5, right: 5),
                            title: const Text(
                              '模式1',
                              style: TextStyle(color: Colors.white),
                            ),
                            value: 0,
                            groupValue: controlNetOption['control_mode'] ?? 0,
                            onChanged: (value) async {
                              setState(() {
                                controlNetOption['control_mode'] = value;
                              });
                            },
                          )),
                    )),
                    Expanded(
                        child: Theme(
                      data: ThemeData(
                        unselectedWidgetColor: Colors.yellowAccent,
                      ),
                      child: Tooltip(
                          message: '更偏向提示词',
                          child: RadioListTile<int>(
                            contentPadding: const EdgeInsets.only(left: 5, right: 5),
                            title: const Text(
                              '模式2',
                              style: TextStyle(color: Colors.white),
                            ),
                            value: 1,
                            groupValue: controlNetOption['control_mode'] ?? 1,
                            onChanged: (value) async {
                              setState(() {
                                controlNetOption['control_mode'] = value;
                              });
                            },
                          )),
                    )),
                    Expanded(
                        child: Theme(
                      data: ThemeData(
                        unselectedWidgetColor: Colors.yellowAccent,
                      ),
                      child: Tooltip(
                          message: '更偏向controlnet',
                          child: RadioListTile<int>(
                            contentPadding: const EdgeInsets.only(left: 5, right: 5),
                            title: const Text(
                              '模式3',
                              style: TextStyle(color: Colors.white),
                            ),
                            value: 2,
                            groupValue: controlNetOption['control_mode'] ?? 2,
                            onChanged: (value) async {
                              setState(() {
                                controlNetOption['control_mode'] = value;
                              });
                            },
                          )),
                    )),
                  ],
                )),
            Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    const Text('缩放模式:', style: TextStyle(color: Colors.white)),
                    Expanded(
                        child: Theme(
                      data: ThemeData(
                        unselectedWidgetColor: Colors.yellowAccent,
                      ),
                      child: Tooltip(
                          message: '仅调整大小',
                          child: RadioListTile<int>(
                            contentPadding: const EdgeInsets.only(left: 5, right: 5),
                            title: const Text(
                              '模式1',
                              style: TextStyle(color: Colors.white),
                            ),
                            value: 0,
                            groupValue: controlNetOption['resize_mode'] ?? 0,
                            onChanged: (value) async {
                              setState(() {
                                controlNetOption['resize_mode'] = value;
                              });
                            },
                          )),
                    )),
                    Expanded(
                        child: Theme(
                      data: ThemeData(
                        unselectedWidgetColor: Colors.yellowAccent,
                      ),
                      child: Tooltip(
                          message: '裁剪后缩放',
                          child: RadioListTile<int>(
                            contentPadding: const EdgeInsets.only(left: 5, right: 5),
                            title: const Text('模式2', style: TextStyle(color: Colors.white)),
                            value: 1,
                            groupValue: controlNetOption['resize_mode'] ?? 1,
                            onChanged: (value) async {
                              setState(() {
                                controlNetOption['resize_mode'] = value;
                              });
                            },
                          )),
                    )),
                    Expanded(
                        child: Theme(
                      data: ThemeData(
                        unselectedWidgetColor: Colors.yellowAccent,
                      ),
                      child: Tooltip(
                          message: '缩放后填充空白',
                          child: RadioListTile<int>(
                            contentPadding: const EdgeInsets.only(left: 5, right: 5),
                            title: const Text(
                              '模式3',
                              style: TextStyle(color: Colors.white),
                            ),
                            value: 2,
                            groupValue: controlNetOption['resize_mode'] ?? 2,
                            onChanged: (value) async {
                              setState(() {
                                controlNetOption['resize_mode'] = value;
                              });
                            },
                          )),
                    )),
                  ],
                )),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                      child: Row(children: <Widget>[
                    Text(
                      '控制权重(${controlNetOption['weight'].toStringAsFixed(2)})',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Expanded(
                      child: Slider(
                        value: controlNetOption['weight'],
                        min: 0,
                        max: 2,
                        divisions: 200,
                        onChanged: (value) {
                          setState(() {
                            controlNetOption['weight'] = value;
                          });
                        },
                      ),
                    ),
                  ])),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                      child: Row(children: <Widget>[
                    Text(
                      '介入时机(${controlNetOption['guidance_start'].toStringAsFixed(2)})',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Expanded(
                      child: Slider(
                        value: controlNetOption['guidance_start'],
                        min: 0,
                        max: 1,
                        divisions: 100,
                        onChanged: (value) {
                          setState(() {
                            controlNetOption['guidance_start'] = value;
                          });
                        },
                      ),
                    ),
                  ])),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                      child: Row(children: <Widget>[
                    Text(
                      '终止时机(${controlNetOption['guidance_end'].toStringAsFixed(2)})',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Expanded(
                      child: Slider(
                        value: controlNetOption['guidance_end'],
                        min: 0,
                        max: 1,
                        divisions: 100,
                        onChanged: (value) {
                          setState(() {
                            controlNetOption['guidance_end'] = value;
                          });
                        },
                      ),
                    ),
                  ])),
                ],
              ),
            ),
          ],
        ));
  }
}
