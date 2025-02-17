import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'package:tuitu/widgets/common_dropdown.dart';

import '../config/config.dart';
import '../net/my_api.dart';

class GetImageTagsWidget extends StatefulWidget {
  final List<String> interrogators;
  final String base64Image;
  final String imageUrl;
  final int drawEngine;
  final Function(String tag)? onTaggerClicked;

  const GetImageTagsWidget(
      {super.key,
      required this.interrogators,
      required this.base64Image,
      required this.drawEngine,
      required this.imageUrl,
      this.onTaggerClicked});

  @override
  State<GetImageTagsWidget> createState() => _GetImageTagsWidgetState();
}

class _GetImageTagsWidgetState extends State<GetImageTagsWidget> {
  late String selectInterrogator;
  late TextEditingController taggerController;
  late TextEditingController urlController;
  late MyApi myApi;
  late double threshold;
  bool isUnloadInterrogator = true;
  List<String> tagsList = [];

  String removeBracketsAndParentheses(String input) {
    // 移除()中的整个字符串
    String resultWithoutParentheses = input.replaceAll(RegExp(r'\([^)]*\)'), '');
    // 移除[]中的中括号，但保留括号内的内容
    String finalResult = resultWithoutParentheses.replaceAllMapped(RegExp(r'\[(.*?)\]'), (match) {
      return match.group(1) ?? '';
    });

    return finalResult.trim();
  }

  void _getImageTags() async {
    setState(() {
      taggerController.text = '';
    });
    tagsList = [];
    showHint('正在反推中，请稍后...', showType: 5);
    Map<String, dynamic> requestBody = {};
    String sdUrl = '';
    String zsyDescribeToken = '';
    Map<String, dynamic> settings = await Config.loadSettings();
    if (widget.drawEngine == 0) {
      sdUrl = settings['sdUrl'];
      requestBody['image'] = widget.base64Image;
      requestBody['model'] = selectInterrogator;
      requestBody['threshold'] = double.parse(threshold.toStringAsFixed(2));
      requestBody['escape_tag'] = false;
      requestBody['add_confident_as_weight'] = false;
    } else if (widget.drawEngine == 1) {
      zsyDescribeToken = settings['zsy_describe_token'] ?? '';
      if (zsyDescribeToken == '') {
        if (mounted) {
          showHint('当前绘图模型为知数云MJ，但是未配置知数云图生文Token，请先在设置页面配置', showTime: 3);
        }
        dismissHint();
        return;
      } else if (urlController.text == '') {
        if (mounted) {
          showHint('当前绘图模型为知数云MJ，需要图片的在线地址', showTime: 3);
        }
        dismissHint();
        return;
      } else {
        requestBody['image_url'] = urlController.text;
      }
    } else if (widget.drawEngine == 2) {
      requestBody['base64'] = 'data:image/png;base64,${await compressBase64Image(widget.base64Image)}';
    }
    dio.Response response;
    try {
      switch (widget.drawEngine) {
        case 1:
          response = await myApi.mjDescribe(zsyDescribeToken, requestBody);
          break;
        case 2:
          response = await myApi.selfMjDescribe(requestBody);
          break;
        default:
          response = await myApi.getTaggerTags(sdUrl, requestBody);
          break;
      }
      if (response.statusCode == 200) {
        if (response.data is String) {
          response.data = jsonDecode(response.data);
        }
        String tags = '';
        if (widget.drawEngine == 0) {
          Map<String, dynamic> tagsData = response.data['caption']['tag'];
          for (String key in tagsData.keys) {
            tags += '$key, ';
          }
          taggerController.text = tags.substring(0, tags.length - 2);
        } else if (widget.drawEngine == 1) {
          List<String> tagsData = List<String>.from(response.data['description']);
          for (int i = 0; i < tagsData.length; i++) {
            if (i != tagsData.length - 1) {
              tags += '${removeBracketsAndParentheses(tagsData[i])}\n';
            } else {
              tags += removeBracketsAndParentheses(tagsData[i]);
            }
          }
          taggerController.text = tags;
        } else if (widget.drawEngine == 2) {
          int code = response.data['code'];
          if (code == 1) {
            String result = response.data['result'];
            while (true) {
              dio.Response taskResponse = await myApi.selfMjDrawQuery(result);
              if (taskResponse.statusCode == 200) {
                if (taskResponse.data is String) {
                  taskResponse.data = jsonDecode(taskResponse.data);
                }
                String status = taskResponse.data['status'];
                if (status == '' ||
                    status == 'IN_PROGRESS' ||
                    status == 'NOT_START' ||
                    status == 'SUBMITTED' ||
                    status == 'SUCCESS') {
                  if (status == 'SUCCESS') {
                    String prompt = taskResponse.data['promptEn'];
                    List<String> prompts = prompt.split('\n\n');
                    tagsList = prompts;
                    for (int i = 0; i < prompts.length; i++) {
                      if (i == 0) {
                        tags += '${prompts[i]}\n';
                      } else if (i != prompts.length - 1) {
                        tags += '\n${prompts[i]}\n';
                      } else {
                        tags += '\n${prompts[i]}';
                      }
                    }
                    taggerController.text = tags;
                    break;
                  }
                } else if (status == 'FAILURE') {
                  showHint('图生文任务失败，原因是${taskResponse.data['description']}');
                  break;
                } else {
                  break;
                }
              } else {
                if (mounted) {
                  showHint('图生文任务失败，原因是${taskResponse.statusMessage}');
                }
              }
              await Future.delayed(const Duration(seconds: 5));
            }
          } else {
            if (mounted) {
              showHint('图生文任务提交失败，原因是${response.data['description']}');
            }
          }
        }
        setState(() {});
      } else {
        if (mounted) {
          taggerController.text = '反推失败，请检查配置或者稍后重试';
          showHint('反推失败，原因是${response.statusMessage}');
        }
      }
    } catch (e) {
      if (mounted) {
        showHint('反推失败，原因是$e', showType: 3);
      }
    } finally {
      dismissHint();
      if (widget.drawEngine == 0) {
        if (isUnloadInterrogator) {
          _unloadInterrogators();
        }
      }
    }
  }

  void _unloadInterrogators() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String sdUrl = settings['sdUrl'] ?? '';
    try {
      dio.Response response = await myApi.unloadTaggerModels(sdUrl, null);
      if (response.statusCode == 200) {
        if (mounted) {
          showHint('卸载反推模型成功，${response.data}');
        }
      } else {
        if (mounted) {
          showHint('卸载反推模型失败，原因是${response.statusMessage}');
        }
      }
    } catch (e) {
      if (mounted) {
        showHint('卸载反推模型失败，原因是$e');
      }
    }
  }

  @override
  void initState() {
    threshold = 0.35;
    if (widget.interrogators.isNotEmpty) {
      selectInterrogator = widget.interrogators[0];
    } else {
      selectInterrogator = '';
    }
    taggerController = TextEditingController();
    urlController = TextEditingController(text: widget.imageUrl);
    myApi = MyApi();
    super.initState();
  }

  String removeEmoji(String text) {
    // 定义正则表达式，匹配 Emoji
    RegExp emojiRegex = RegExp(
      r'[\u0030-\u0039]\uFE0F?\u20E3|[\u1F1E6-\u1F1FF]{2}|[\u1F600-\u1F64F]|[\u2702-\u27B0]|[\u1F680-\u1F6FF]|[\u2600-\u26FF]',
      unicode: true,
    );
    // 查找第一个匹配的 Emoji
    Match? match = emojiRegex.firstMatch(text);
    if (match != null) {
      // 获取 Emoji 后面的字符串
      String restOfString = text.substring(match.end);
      return restOfString;
    } else {
      return text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(10.0),
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: settings.getSelectedBgColor(),
              width: 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.0),
                image: DecorationImage(
                  image: MemoryImage(base64Decode(widget.base64Image)),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: TextField(
              controller: taggerController,
              maxLines: 10,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              style: TextStyle(color: settings.getTextColor()),
              decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: settings.getSelectedBgColor(), width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: settings.getSelectedBgColor(), width: 1.0),
                  ),
                  labelText: '反推结果将显示在这里',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  labelStyle: TextStyle(color: settings.getTextColor()))),
        ),
        Visibility(
          visible: widget.drawEngine == 1,
          child: Padding(
            padding: const EdgeInsets.only(top: 6, left: 10, right: 10),
            child: TextField(
                controller: urlController,
                style: const TextStyle(color: Colors.yellowAccent),
                decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 1.0),
                    ),
                    labelText: '图片地址',
                    labelStyle: TextStyle(color: Colors.white))),
          ),
        ),
        Visibility(
            visible: widget.drawEngine == 0,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 10, right: 10),
                  child: Row(
                    children: [
                      Text(
                        '反推模型:',
                        style: TextStyle(color: settings.getTextColor()),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                          child: CommonDropdownWidget(
                              dropdownData: widget.interrogators,
                              selectedValue: selectInterrogator,
                              onChangeValue: (interrogator) {
                                setState(() {
                                  selectInterrogator = interrogator;
                                });
                              }))
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 10, right: 10),
                  child: Row(
                    children: [
                      Text(
                        '反推阈值(${threshold.toStringAsFixed(2)})',
                        style: TextStyle(color: settings.getTextColor()),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Slider(
                          value: threshold,
                          min: 0,
                          max: 1,
                          divisions: 100,
                          onChanged: (value) {
                            setState(() {
                              threshold = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 10, right: 10),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        isUnloadInterrogator = !isUnloadInterrogator;
                      });
                    },
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(
                          '反推完成后自动卸载反推模型',
                          style: TextStyle(color: settings.getTextColor()),
                        )),
                        Theme(
                            data: ThemeData(
                              unselectedWidgetColor: Colors.yellowAccent,
                            ),
                            child: Checkbox(
                                value: isUnloadInterrogator,
                                onChanged: (value) {
                                  setState(() {
                                    isUnloadInterrogator = value!;
                                  });
                                })),
                      ],
                    ),
                  ),
                ),
              ],
            )),
        Visibility(
            visible: widget.drawEngine == 2 && taggerController.text.isNotEmpty,
            child: SizedBox(
              height: 50,
              child: Padding(
                  padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            String tag = removeEmoji(tagsList[0]);
                            widget.onTaggerClicked?.call(tag);
                            Navigator.of(context).pop();
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all<Color>(settings.getSelectedBgColor()),
                            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                          child: const Text('1', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            String tag = removeEmoji(tagsList[1]);
                            widget.onTaggerClicked?.call(tag);
                            Navigator.of(context).pop();
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all<Color>(settings.getSelectedBgColor()),
                            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                          child: const Text('2', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            String tag = removeEmoji(tagsList[2]);
                            widget.onTaggerClicked?.call(tag);
                            Navigator.of(context).pop();
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all<Color>(settings.getSelectedBgColor()),
                            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                          child: const Text('3', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            String tag = removeEmoji(tagsList[3]);
                            widget.onTaggerClicked?.call(tag);
                            Navigator.of(context).pop();
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all<Color>(settings.getSelectedBgColor()),
                            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                          child: const Text('4', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  )),
            )),
        SizedBox(
            height: 50,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
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
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        _getImageTags();
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all<Color>(settings.getSelectedBgColor()),
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                      child: const Text('开始反推', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ))
      ],
    );
  }
}
