import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tuitu/utils/common_methods.dart';

import '../config/config.dart';
import '../net/my_api.dart';
import 'common_dropdown.dart';

class RedrawOptionWidget extends StatefulWidget {
  final String currentImagePath;
  final List<String> samplers;
  final bool isUseControlNet;

  const RedrawOptionWidget(
      {super.key, required this.currentImagePath, required this.samplers, required this.isUseControlNet});

  @override
  State<RedrawOptionWidget> createState() => _RedrawOptionsState();
}

class _RedrawOptionsState extends State<RedrawOptionWidget> {
  List<String> _samplers = ['Euler a'];
  String _selectedSampler = 'Euler a';
  double _redrawMagnification = 1;
  double _redrawRange = 0.75;
  double _redrawSteps = 20;
  bool isSaving = false;
  int width = 512;
  int height = 512;
  int newHeight = 512;
  int newWidth = 512;
  late MyApi myApi;
  bool isUseControlNet = true;

  Future<void> _getSamplers(String url) async {
    try {
      Response response = await myApi.getSDSamplers(url);
      if (response.statusCode == 200) {
        _samplers.clear();
        for (int i = 0; i < response.data.length; i++) {
          _samplers.add(response.data[i]['name']);
        }
      } else {
        commonPrint('获取采样器列表失败1，错误是${response.statusMessage}');
        if (mounted) {
          showHint('SD配置异常或者未启动，将无法生图，请检查sd状态');
        }
      }
    } catch (error) {
      commonPrint('获取模型采样器失败2，错误是$error');
      if (mounted) {
        showHint('SD配置异常或者未启动，将无法生图，请检查sd状态');
      }
    }
  }

  Future<void> initData() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    _selectedSampler = settings['Sampler'];
    _redrawSteps = settings['steps'].toDouble();
    _redrawRange = settings['redraw_range'] ?? 0.75;
    _redrawMagnification = settings['redraw_magnification'] ?? 1;
    String? sdUrl = settings['sdUrl'];
    _samplers = widget.samplers;
    isUseControlNet = widget.isUseControlNet;
    String base64Image = widget.currentImagePath;
    Uint8List bytes = base64Decode(base64Image);
    ui.Image? image;
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    image = await completer.future;
    width = image.width;
    height = image.height;
    newWidth = (image.width * _redrawMagnification).toInt();
    newHeight = (image.height * _redrawMagnification).toInt();
    if (sdUrl == null || sdUrl == '') {
      if (mounted) {
        showHint('sd配置异常，将无法生图，请检查sd配置和状态');
      }
    } else {
      await _getSamplers(sdUrl);
    }
    await Config.saveSettings(
        {'is_img2img_use_control_net': isUseControlNet, 'newWidth': newWidth, 'newHeight': newHeight});
    setState(() {});
  }

  @override
  void initState() {
    myApi = MyApi();
    initData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, left: 15, right: 15),
      child: Column(
        children: [
          Column(children: <Widget>[
            Visibility(
                visible: widget.isUseControlNet,
                child: Column(children: <Widget>[
                  InkWell(
                    onTap: () async {
                      await Config.saveSettings({'is_img2img_use_control_net': !isUseControlNet});
                      setState(() {
                        isUseControlNet = !isUseControlNet;
                      });
                    },
                    child: Row(
                      children: [
                        const Expanded(child: Text('启用文生图配置好的controlNet', style: TextStyle(color: Colors.white))),
                        Theme(
                            data: ThemeData(
                              unselectedWidgetColor: Colors.yellowAccent,
                            ),
                            child: Checkbox(
                                value: isUseControlNet,
                                onChanged: (value) async {
                                  await Config.saveSettings({'is_img2img_use_control_net': value!});
                                  setState(() {
                                    isUseControlNet = value;
                                  });
                                })),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ])),
            Row(
              children: [
                const Text(
                  '采样方法:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: CommonDropdownWidget(
                        selectedValue: _selectedSampler,
                        dropdownData: _samplers,
                        onChangeValue: (sampler) async {
                          await Config.saveSettings({
                            'Sampler': sampler,
                          });
                          setState(() {
                            _selectedSampler = sampler;
                          });
                        }))
              ],
            ),
            const SizedBox(height: 10),
            Row(children: <Widget>[
              Text(
                '迭代步数(${_redrawSteps.toStringAsFixed(0)}): ',
                style: const TextStyle(color: Colors.white),
              ),
              Expanded(
                child: Slider(
                  value: _redrawSteps,
                  min: 1,
                  max: 150,
                  divisions: 149,
                  onChanged: (value) async {
                    if (!isSaving) {
                      isSaving = true;
                      await Config.saveSettings({
                        'steps': value.toInt(),
                      });
                      setState(() {
                        _redrawSteps = value;
                      });
                      isSaving = false;
                    }
                  },
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: <Widget>[
              Text(
                '重绘幅度(${_redrawRange.toStringAsFixed(2)}): ',
                style: const TextStyle(color: Colors.white),
              ),
              Expanded(
                child: Slider(
                  value: _redrawRange,
                  min: 0,
                  max: 1,
                  divisions: 99,
                  onChanged: (value) async {
                    if (!isSaving) {
                      isSaving = true;
                      await Config.saveSettings({
                        'redraw_range': double.parse(value.toStringAsFixed(2)),
                      });
                      setState(() {
                        _redrawRange = value;
                      });
                      isSaving = false;
                    }
                  },
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: <Widget>[
              Text(
                '放大倍数(${_redrawMagnification.toStringAsFixed(1)}倍): ',
                style: const TextStyle(color: Colors.white),
              ),
              Expanded(
                child: Slider(
                  value: _redrawMagnification,
                  min: 1,
                  max: 4,
                  divisions: 30,
                  onChanged: (value) async {
                    if (!isSaving) {
                      isSaving = true;
                      await Config.saveSettings({
                        'redraw_magnification': double.parse(value.toStringAsFixed(1)),
                        'newWidth': (width * (double.parse(value.toStringAsFixed(1)))).toInt(),
                        'newHeight': (height * (double.parse(value.toStringAsFixed(1)))).toInt(),
                      });
                      setState(() {
                        newWidth = (width * (double.parse(value.toStringAsFixed(1)))).toInt();
                        newHeight = (height * (double.parse(value.toStringAsFixed(1)))).toInt();
                        _redrawMagnification = value;
                      });
                      isSaving = false;
                    }
                  },
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Text('图片尺寸将从$width*$height到$newWidth*$newHeight', style: const TextStyle(color: Colors.white))
          ]),
        ],
      ),
    );
  }
}
