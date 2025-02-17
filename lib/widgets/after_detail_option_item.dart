import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';

import '../params/models.dart';
import 'common_dropdown.dart';

class AfterDetailOptionItem extends StatefulWidget {
  final Map<String, dynamic> afterDetailOption;
  final List<String> sdSamplers;
  final int index;

  const AfterDetailOptionItem(
      {super.key, required this.afterDetailOption, required this.sdSamplers, required this.index});

  @override
  State<AfterDetailOptionItem> createState() => _AfterDetailOptionItemState();
}

class _AfterDetailOptionItemState extends State<AfterDetailOptionItem> {
  late Map<String, dynamic> afterDetailOption;
  late List<String> aDetailModels;
  late String selectADetailModel;
  late List<String> _samplers;
  late String selectSampler;
  late TextEditingController positivePromptController;
  late TextEditingController negativePromptController;
  late List<String> adControlNetModels;
  late String selectAdControlNetModel;
  late int index;

  void initData() {
    afterDetailOption = widget.afterDetailOption;
    index = widget.index;
    aDetailModels = models['ADetailer_models'];
    adControlNetModels = models['ADetailer_controlNet_models'];
    selectAdControlNetModel = afterDetailOption['ad_controlnet_model'];
    positivePromptController = TextEditingController(text: afterDetailOption['ad_prompt'] ?? '');
    negativePromptController = TextEditingController(text: afterDetailOption['ad_negative_prompt'] ?? '');
    selectADetailModel = afterDetailOption['ad_model'];
    _samplers = widget.sdSamplers;
    selectSampler = afterDetailOption['ad_sampler'];
  }

  @override
  void initState() {
    initData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return Container(
        padding: const EdgeInsets.all(4.0),
        margin: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: settings.getSelectedBgColor(),
            width: 1.0,
          ),
        ),
        child: Column(children: [
          Text('ADetail控制单元${index + 1}',
              style:  TextStyle(color: settings.getSelectedBgColor(), fontWeight: FontWeight.bold)),
          const SizedBox(
            height: 6,
          ),
          Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(
                  color: settings.getSelectedBgColor(),
                  width: 1.0,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: InkWell(
                              onTap: () {
                                setState(() {
                                  afterDetailOption['is_enable'] = !(afterDetailOption['is_enable'] ?? true);
                                });
                              },
                              child: Row(
                                children: [
                                   Expanded(
                                      child: Text(
                                    '启用ADetail',
                                    style: TextStyle(color: settings.getSelectedBgColor()),
                                  )),
                                  Theme(
                                      data: ThemeData(
                                        unselectedWidgetColor: Colors.yellowAccent,
                                      ),
                                      child: Checkbox(
                                          value: afterDetailOption['is_enable'] ?? true,
                                          onChanged: (value) {
                                            setState(() {
                                              afterDetailOption['is_enable'] = value!;
                                            });
                                          })),
                                ],
                              ))),
                    ],
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Row(
                    children: [
                       Text(
                        'ADetail模型:',
                        style: TextStyle(color: settings.getSelectedBgColor()),
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      Expanded(
                          child: CommonDropdownWidget(
                        dropdownData: aDetailModels,
                        onChangeValue: (model) {
                          setState(() {
                            afterDetailOption['ad_model'] = model;
                          });
                        },
                        selectedValue: afterDetailOption['ad_model'],
                      ))
                    ],
                  ),
                ],
              )),
          const SizedBox(
            height: 6,
          ),
           Text(
            '!!!以下选项是高级选项，一般不用修改!!!',
            style: TextStyle(color: settings.getSelectedBgColor(), fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
          ),
          const SizedBox(
            height: 6,
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: settings.getSelectedBgColor(),
                width: 1.0,
              ),
            ),
            child: Column(
              children: [
                 Text('提示词相关', style: TextStyle(color: settings.getSelectedBgColor())),
                const SizedBox(height: 10),
                TextField(
                    controller: positivePromptController,
                    maxLines: 10,
                    minLines: 1,
                    onChanged: (content) {
                      afterDetailOption['ad_prompt'] = content;
                    },
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(color: Colors.yellowAccent),
                    decoration:  InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: settings.getSelectedBgColor(), width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: settings.getSelectedBgColor(), width: 1.0),
                        ),
                        labelText: 'ADetail正向提示词，为空时使用sd的正向提示词',
                        labelStyle: TextStyle(color: settings.getSelectedBgColor()))),
                const SizedBox(height: 10),
                TextField(
                    controller: negativePromptController,
                    maxLines: 10,
                    minLines: 1,
                    onChanged: (content) {
                      afterDetailOption['ad_negative_prompt'] = content;
                    },
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(color: Colors.yellowAccent),
                    decoration:  InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: settings.getSelectedBgColor(), width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: settings.getSelectedBgColor(), width: 1.0),
                        ),
                        labelText: 'ADetail反向提示词，为空时使用sd的反向提示词',
                        labelStyle: TextStyle(color: settings.getSelectedBgColor()))),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: settings.getSelectedBgColor(),
                width: 1.0,
              ),
            ),
            child: Column(
              children: [
                 Text('检测相关', style: TextStyle(color: settings.getSelectedBgColor())),
                Row(
                  children: [
                    SizedBox(
                        width: 160,
                        child: Text('模型置信阈值(${afterDetailOption['ad_confidence'].toStringAsFixed(2)})',
                            style:  TextStyle(color: settings.getSelectedBgColor()))),
                    Expanded(
                        child: Slider(
                            min: 0,
                            max: 1,
                            divisions: 100,
                            value: afterDetailOption['ad_confidence'],
                            onChanged: (value) {
                              setState(() {
                                afterDetailOption['ad_confidence'] = double.parse(value.toStringAsFixed(2));
                              });
                            }))
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                        width: 160,
                        child: Text('蒙板区域最小比率(${afterDetailOption['ad_mask_min_ratio'].toStringAsFixed(2)})',
                            style:  TextStyle(color: settings.getSelectedBgColor()))),
                    Expanded(
                        child: Slider(
                            min: 0,
                            max: 1,
                            divisions: 100,
                            value: afterDetailOption['ad_mask_min_ratio'],
                            onChanged: (value) {
                              setState(() {
                                afterDetailOption['ad_mask_min_ratio'] = double.parse(value.toStringAsFixed(2));
                              });
                            }))
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                        width: 160,
                        child: Text('蒙板区域最大比率(${afterDetailOption['ad_mask_max_ratio'].toStringAsFixed(2)})',
                            style:  TextStyle(color: settings.getSelectedBgColor()))),
                    Expanded(
                        child: Slider(
                            min: 0,
                            max: 1,
                            divisions: 100,
                            value: afterDetailOption['ad_mask_max_ratio'],
                            onChanged: (value) {
                              setState(() {
                                afterDetailOption['ad_mask_max_ratio'] = double.parse(value.toStringAsFixed(2));
                              });
                            }))
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 160,
                      child: Text('蒙板顶部巨大K值(${afterDetailOption['ad_mask_k_largest'].toStringAsFixed(0)})',
                          style:  TextStyle(color: settings.getSelectedBgColor())),
                    ),
                    Expanded(
                        child: Slider(
                            min: 0,
                            max: 10,
                            divisions: 10,
                            value: afterDetailOption['ad_mask_k_largest'].toDouble(),
                            onChanged: (value) {
                              setState(() {
                                afterDetailOption['ad_mask_k_largest'] = int.parse(value.toStringAsFixed(0));
                              });
                            }))
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: settings.getSelectedBgColor(),
                width: 1.0,
              ),
            ),
            child: Column(
              children: [
                 Text('蒙板处理相关', style: TextStyle(color: settings.getSelectedBgColor())),
                Row(
                  children: [
                    SizedBox(
                        width: 160,
                        child: Text('蒙板X轴便偏移(${afterDetailOption['ad_x_offset'].toStringAsFixed(0)})',
                            style:  TextStyle(color: settings.getSelectedBgColor()))),
                    Expanded(
                        child: Slider(
                            min: -200,
                            max: 200,
                            divisions: 400,
                            value: afterDetailOption['ad_x_offset'].toDouble(),
                            onChanged: (value) {
                              setState(() {
                                afterDetailOption['ad_x_offset'] = int.parse(value.toStringAsFixed(0));
                              });
                            }))
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                        width: 160,
                        child: Text('蒙板Y轴便偏移(${afterDetailOption['ad_y_offset'].toStringAsFixed(0)})',
                            style:  TextStyle(color: settings.getSelectedBgColor()))),
                    Expanded(
                        child: Slider(
                            min: -200,
                            max: 200,
                            divisions: 400,
                            value: afterDetailOption['ad_y_offset'].toDouble(),
                            onChanged: (value) {
                              setState(() {
                                afterDetailOption['ad_y_offset'] = int.parse(value.toStringAsFixed(0));
                              });
                            }))
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                        width: 160,
                        child: Text('蒙板腐蚀/膨胀(${afterDetailOption['ad_dilate_erode'].toStringAsFixed(0)})',
                            style:  TextStyle(color: settings.getSelectedBgColor()))),
                    Expanded(
                        child: Slider(
                            min: -128,
                            max: 128,
                            divisions: 256,
                            value: afterDetailOption['ad_dilate_erode'].toDouble(),
                            onChanged: (value) {
                              setState(() {
                                afterDetailOption['ad_dilate_erode'] = int.parse(value.toStringAsFixed(0));
                              });
                            }))
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: settings.getSelectedBgColor(),
                width: 1.0,
              ),
            ),
            child: Column(
              children: [
                 Text('重绘相关', style: TextStyle(color: settings.getSelectedBgColor())),
                Row(
                  children: [
                    SizedBox(
                        width: 160,
                        child: Text('重绘蒙版边缘模糊度(${afterDetailOption['ad_mask_blur'].toStringAsFixed(0)})',
                            style:  TextStyle(color: settings.getSelectedBgColor()))),
                    Expanded(
                        child: Slider(
                            min: 0,
                            max: 64,
                            divisions: 64,
                            value: afterDetailOption['ad_mask_blur'].toDouble(),
                            onChanged: (value) {
                              setState(() {
                                afterDetailOption['ad_mask_blur'] = int.parse(value.toStringAsFixed(0));
                              });
                            }))
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                        width: 160,
                        child: Text('局部重绘幅度(${afterDetailOption['ad_denoising_strength'].toStringAsFixed(2)})',
                            style:  TextStyle(color: settings.getSelectedBgColor()))),
                    Expanded(
                        child: Slider(
                            min: 0,
                            max: 1,
                            divisions: 100,
                            value: afterDetailOption['ad_denoising_strength'],
                            onChanged: (value) {
                              setState(() {
                                afterDetailOption['ad_denoising_strength'] = double.parse(value.toStringAsFixed(2));
                              });
                            }))
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(
                      color: settings.getSelectedBgColor(),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      afterDetailOption['ad_inpaint_only_masked'] =
                                          !(afterDetailOption['ad_inpaint_only_masked'] ?? true);
                                    });
                                  },
                                  child: Row(
                                    children: [
                                       Expanded(
                                          child: Text(
                                        '仅重绘蒙版内容',
                                        style: TextStyle(color: settings.getSelectedBgColor()),
                                      )),
                                      Theme(
                                          data: ThemeData(
                                            unselectedWidgetColor: Colors.yellowAccent,
                                          ),
                                          child: Checkbox(
                                              value: afterDetailOption['ad_inpaint_only_masked'] ?? true,
                                              onChanged: (value) {
                                                setState(() {
                                                  afterDetailOption['ad_inpaint_only_masked'] = value!;
                                                });
                                              })),
                                    ],
                                  ))),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(
                              width: 160,
                              child: Text(
                                  '重绘边缘预留像素(${afterDetailOption['ad_inpaint_only_masked_padding'].toStringAsFixed(0)})',
                                  style:  TextStyle(color: settings.getSelectedBgColor()))),
                          Expanded(
                              child: Slider(
                                  min: 0,
                                  max: 256,
                                  divisions: 256,
                                  value: afterDetailOption['ad_inpaint_only_masked_padding'].toDouble(),
                                  onChanged: (value) {
                                    setState(() {
                                      afterDetailOption['ad_inpaint_only_masked_padding'] =
                                          int.parse(value.toStringAsFixed(0));
                                    });
                                  }))
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(
                      color: settings.getSelectedBgColor(),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      afterDetailOption['ad_use_inpaint_width_height'] =
                                          !(afterDetailOption['ad_use_inpaint_width_height'] ?? false);
                                    });
                                  },
                                  child: Row(
                                    children: [
                                       Expanded(
                                          child: Text(
                                        '使用独立重绘宽高',
                                        style: TextStyle(color: settings.getSelectedBgColor()),
                                      )),
                                      Theme(
                                          data: ThemeData(
                                            unselectedWidgetColor: Colors.yellowAccent,
                                          ),
                                          child: Checkbox(
                                              value: afterDetailOption['ad_use_inpaint_width_height'] ?? false,
                                              onChanged: (value) {
                                                setState(() {
                                                  afterDetailOption['ad_use_inpaint_width_height'] = value!;
                                                });
                                              })),
                                    ],
                                  ))),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(
                              width: 160,
                              child: Text('重绘宽度(${afterDetailOption['ad_inpaint_width'].toStringAsFixed(0)})',
                                  style:  TextStyle(color: settings.getSelectedBgColor()))),
                          Expanded(
                              child: Slider(
                                  min: 64,
                                  max: 2048,
                                  divisions: 1984,
                                  value: afterDetailOption['ad_inpaint_width'].toDouble(),
                                  onChanged: (value) {
                                    setState(() {
                                      afterDetailOption['ad_inpaint_width'] = int.parse(value.toStringAsFixed(0));
                                    });
                                  }))
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(
                              width: 160,
                              child: Text('重绘高度(${afterDetailOption['ad_inpaint_height'].toStringAsFixed(0)})',
                                  style:  TextStyle(color: settings.getSelectedBgColor()))),
                          Expanded(
                              child: Slider(
                                  min: 64,
                                  max: 2048,
                                  divisions: 1984,
                                  value: afterDetailOption['ad_inpaint_height'].toDouble(),
                                  onChanged: (value) {
                                    setState(() {
                                      afterDetailOption['ad_inpaint_height'] = int.parse(value.toStringAsFixed(0));
                                    });
                                  }))
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(
                      color: settings.getSelectedBgColor(),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      afterDetailOption['ad_use_steps'] = !(afterDetailOption['ad_use_steps'] ?? false);
                                    });
                                  },
                                  child: Row(
                                    children: [
                                       Expanded(
                                          child: Text(
                                        '使用独立迭代步数',
                                        style: TextStyle(color: settings.getSelectedBgColor()),
                                      )),
                                      Theme(
                                          data: ThemeData(
                                            unselectedWidgetColor: Colors.yellowAccent,
                                          ),
                                          child: Checkbox(
                                              value: afterDetailOption['ad_use_steps'] ?? false,
                                              onChanged: (value) {
                                                setState(() {
                                                  afterDetailOption['ad_use_steps'] = value!;
                                                });
                                              })),
                                    ],
                                  ))),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(
                              width: 160,
                              child: Text('ADetailer迭代步数(${afterDetailOption['ad_steps'].toStringAsFixed(0)})',
                                  style:  TextStyle(color: settings.getSelectedBgColor()))),
                          Expanded(
                              child: Slider(
                                  min: 1,
                                  max: 150,
                                  divisions: 150,
                                  value: afterDetailOption['ad_steps'].toDouble(),
                                  onChanged: (value) {
                                    setState(() {
                                      afterDetailOption['ad_steps'] = int.parse(value.toStringAsFixed(0));
                                    });
                                  }))
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(
                      color: settings.getSelectedBgColor(),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      afterDetailOption['ad_use_cfg_scale'] =
                                          !(afterDetailOption['ad_use_cfg_scale'] ?? false);
                                    });
                                  },
                                  child: Row(
                                    children: [
                                       Expanded(
                                          child: Text(
                                        '使用独立的提示词引导系数',
                                        style: TextStyle(color: settings.getSelectedBgColor()),
                                      )),
                                      Theme(
                                          data: ThemeData(
                                            unselectedWidgetColor: Colors.yellowAccent,
                                          ),
                                          child: Checkbox(
                                              value: afterDetailOption['ad_use_cfg_scale'] ?? false,
                                              onChanged: (value) {
                                                setState(() {
                                                  afterDetailOption['ad_use_cfg_scale'] = value!;
                                                });
                                              })),
                                    ],
                                  ))),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(
                              width: 160,
                              child: Text('提示词引导系数(${afterDetailOption['ad_cfg_scale'].toStringAsFixed(1)})',
                                  style:  TextStyle(color: settings.getSelectedBgColor()))),
                          Expanded(
                              child: Slider(
                                  min: 0,
                                  max: 30,
                                  divisions: 60,
                                  value: afterDetailOption['ad_cfg_scale'],
                                  onChanged: (value) {
                                    setState(() {
                                      afterDetailOption['ad_cfg_scale'] = double.parse(value.toStringAsFixed(1));
                                    });
                                  }))
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(
                      color: settings.getSelectedBgColor(),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      afterDetailOption['ad_use_noise_multiplier'] =
                                          !(afterDetailOption['ad_use_noise_multiplier'] ?? false);
                                    });
                                  },
                                  child: Row(
                                    children: [
                                       Expanded(
                                          child: Text(
                                        '使用独立噪声倍率',
                                        style: TextStyle(color: settings.getSelectedBgColor()),
                                      )),
                                      Theme(
                                          data: ThemeData(
                                            unselectedWidgetColor: Colors.yellowAccent,
                                          ),
                                          child: Checkbox(
                                              value: afterDetailOption['ad_use_noise_multiplier'] ?? false,
                                              onChanged: (value) {
                                                setState(() {
                                                  afterDetailOption['ad_use_noise_multiplier'] = value!;
                                                });
                                              })),
                                    ],
                                  ))),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(
                              width: 160,
                              child: Text('图生图噪声倍率(${afterDetailOption['ad_noise_multiplier'].toStringAsFixed(2)})',
                                  style:  TextStyle(color: settings.getSelectedBgColor()))),
                          Expanded(
                              child: Slider(
                                  min: 0.5,
                                  max: 1.5,
                                  divisions: 100,
                                  value: afterDetailOption['ad_noise_multiplier'],
                                  onChanged: (value) {
                                    setState(() {
                                      afterDetailOption['ad_noise_multiplier'] = double.parse(value.toStringAsFixed(2));
                                    });
                                  }))
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(
                      color: settings.getSelectedBgColor(),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      afterDetailOption['ad_use_clip_skip'] =
                                          !(afterDetailOption['ad_use_clip_skip'] ?? false);
                                    });
                                  },
                                  child: Row(
                                    children: [
                                       Expanded(
                                          child: Text(
                                        '使用独立 CLIP 终止层数',
                                        style: TextStyle(color: settings.getSelectedBgColor()),
                                      )),
                                      Theme(
                                          data: ThemeData(
                                            unselectedWidgetColor: Colors.yellowAccent,
                                          ),
                                          child: Checkbox(
                                              value: afterDetailOption['ad_use_clip_skip'] ?? false,
                                              onChanged: (value) {
                                                setState(() {
                                                  afterDetailOption['ad_use_clip_skip'] = value!;
                                                });
                                              })),
                                    ],
                                  ))),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(
                              width: 160,
                              child: Text('CLIP 终止层数(${afterDetailOption['ad_clip_skip'].toStringAsFixed(0)})',
                                  style:  TextStyle(color: settings.getSelectedBgColor()))),
                          Expanded(
                              child: Slider(
                                  min: 1,
                                  max: 12,
                                  divisions: 12,
                                  value: afterDetailOption['ad_clip_skip'].toDouble(),
                                  onChanged: (value) {
                                    setState(() {
                                      afterDetailOption['ad_clip_skip'] = int.parse(value.toStringAsFixed(0));
                                    });
                                  }))
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(
                      color: settings.getSelectedBgColor(),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      afterDetailOption['ad_restore_face'] =
                                          !(afterDetailOption['ad_restore_face'] ?? false);
                                    });
                                  },
                                  child: Row(
                                    children: [
                                       Expanded(
                                          child: Text(
                                        '在 After Detailer 之后修复面部',
                                        style: TextStyle(color: settings.getSelectedBgColor()),
                                      )),
                                      Theme(
                                          data: ThemeData(
                                            unselectedWidgetColor: Colors.yellowAccent,
                                          ),
                                          child: Checkbox(
                                              value: afterDetailOption['ad_restore_face'] ?? false,
                                              onChanged: (value) {
                                                setState(() {
                                                  afterDetailOption['ad_restore_face'] = value!;
                                                });
                                              })),
                                    ],
                                  ))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(
                        color: settings.getSelectedBgColor(),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        afterDetailOption['ad_use_sampler'] =
                                            !(afterDetailOption['ad_use_sampler'] ?? false);
                                      });
                                    },
                                    child: Row(
                                      children: [
                                         Expanded(
                                            child: Text(
                                          '使用独立采样方法',
                                          style: TextStyle(color: settings.getSelectedBgColor()),
                                        )),
                                        Theme(
                                            data: ThemeData(
                                              unselectedWidgetColor: Colors.yellowAccent,
                                            ),
                                            child: Checkbox(
                                                value: afterDetailOption['ad_use_sampler'] ?? false,
                                                onChanged: (value) {
                                                  setState(() {
                                                    afterDetailOption['ad_use_sampler'] = value!;
                                                  });
                                                })),
                                      ],
                                    ))),
                          ],
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Row(
                          children: [
                             Text(
                              '采样方法:',
                              style: TextStyle(color: settings.getSelectedBgColor()),
                            ),
                            const SizedBox(
                              width: 6,
                            ),
                            Expanded(
                                child: CommonDropdownWidget(
                              dropdownData: _samplers,
                              onChangeValue: (model) {
                                setState(() {
                                  selectSampler = model;
                                });
                              },
                              selectedValue: selectSampler,
                            ))
                          ],
                        ),
                      ],
                    )),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(
                  color: settings.getSelectedBgColor(),
                  width: 1.0,
                ),
              ),
              child: Column(
                children: [
                   Text('controlnet处理相关', style: TextStyle(color: settings.getSelectedBgColor())),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                       Text(
                        'controlnet模型:',
                        style: TextStyle(color: settings.getSelectedBgColor()),
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      Expanded(
                          child: CommonDropdownWidget(
                        dropdownData: adControlNetModels,
                        onChangeValue: (model) {
                          setState(() {
                            afterDetailOption['ad_controlnet_model'] = model;
                          });
                        },
                        selectedValue: afterDetailOption['ad_controlnet_model'],
                      ))
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      SizedBox(
                          width: 160,
                          child: Text('引导介入时机(${afterDetailOption['ad_controlnet_guidance_start'].toStringAsFixed(2)})',
                              style:  TextStyle(color: settings.getSelectedBgColor()))),
                      Expanded(
                          child: Slider(
                              min: 0,
                              max: 1,
                              divisions: 100,
                              value: afterDetailOption['ad_controlnet_guidance_start'],
                              onChanged: (value) {
                                setState(() {
                                  afterDetailOption['ad_controlnet_guidance_start'] =
                                      double.parse(value.toStringAsFixed(2));
                                });
                              }))
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      SizedBox(
                          width: 160,
                          child: Text('引导结束时机(${afterDetailOption['ad_controlnet_guidance_end'].toStringAsFixed(2)})',
                              style:  TextStyle(color: settings.getSelectedBgColor()))),
                      Expanded(
                          child: Slider(
                              min: 0,
                              max: 1,
                              divisions: 100,
                              value: afterDetailOption['ad_controlnet_guidance_end'],
                              onChanged: (value) {
                                setState(() {
                                  afterDetailOption['ad_controlnet_guidance_end'] =
                                      double.parse(value.toStringAsFixed(2));
                                });
                              }))
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      SizedBox(
                          width: 160,
                          child: Text('ControlNet权重(${afterDetailOption['ad_controlnet_weight'].toStringAsFixed(2)})',
                              style:  TextStyle(color: settings.getSelectedBgColor()))),
                      Expanded(
                          child: Slider(
                              min: 0,
                              max: 1,
                              divisions: 100,
                              value: afterDetailOption['ad_controlnet_weight'],
                              onChanged: (value) {
                                setState(() {
                                  afterDetailOption['ad_controlnet_weight'] = double.parse(value.toStringAsFixed(2));
                                });
                              }))
                    ],
                  ),
                ],
              ))
        ]));
  }
}
