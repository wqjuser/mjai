import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tuitu/net/my_api.dart';
import 'package:tuitu/utils/common_methods.dart';

class ShortenPromptOption extends StatefulWidget {
  final String originalPrompt;
  final Function(String newPrompt) onConfirm;

  const ShortenPromptOption({super.key, required this.originalPrompt, required this.onConfirm});

  @override
  State<ShortenPromptOption> createState() => _ShortenPromptOptionState();
}

class _ShortenPromptOptionState extends State<ShortenPromptOption> {
  late String originalPrompt;
  final TextEditingController contentEditingController = TextEditingController();
  final TextEditingController modifiedEditingController = TextEditingController();
  var selectedPosition = 0.obs;
  late MyApi myApi;
  List<dynamic> buttons = [];

  @override
  void initState() {
    originalPrompt = widget.originalPrompt;
    contentEditingController.text = originalPrompt;
    myApi = MyApi();
    super.initState();
  }

  Future<void> _shortenPrompt() async {
    dio.Response response;
    Map<String, dynamic> payload = {};
    payload['prompt'] = contentEditingController.text;
    try {
      showHint('优化提示词请求中...', showType: 5);
      response = await myApi.selfMjShorten(payload);
      if (response.statusCode == 200) {
        if (response.data is String) {
          response.data = jsonDecode(response.data);
        }
        int code = response.data['code'];
        if (code == 1) {
          String result = response.data['result'];
          while (true) {
            await Future.delayed(const Duration(seconds: 2));
            dio.Response progressResponse = await myApi.selfMjDrawQuery(result);
            if (progressResponse.statusCode == 200) {
              if (progressResponse.data is String) {
                progressResponse.data = jsonDecode(progressResponse.data);
              }
              String? status = progressResponse.data['status'];
              if (status == 'NOT_START' ||
                  status == 'IN_PROGRESS' ||
                  status == 'SUBMITTED' ||
                  status == 'MODAL' ||
                  status == 'SUCCESS') {
                if (status == 'SUCCESS') {
                  dismissHint();
                  String finalPrompt = progressResponse.data['properties']['finalPrompt'];
                  int index = finalPrompt.indexOf('1️⃣');
                  if (index != -1) {
                    String finalPromptCut = finalPrompt.substring(index, finalPrompt.length);
                    List<String> prompts = finalPromptCut.split('\n\n');
                    String realFinalPrompt = '';
                    for (var i = 0; i < prompts.length; i++) {
                      if (i != prompts.length - 1) {
                        realFinalPrompt += '${prompts[i]}\n';
                      } else {
                        realFinalPrompt += prompts[i];
                      }
                    }
                    setState(() {
                      buttons = progressResponse.data['buttons'];
                      modifiedEditingController.text = realFinalPrompt;
                    });
                  } else {
                    commonPrint('返回值是:$finalPrompt');
                  }
                  break;
                }
              }
            } else {
              if (mounted) {
                showHint('mj优化提示词失败,原因是${progressResponse.statusMessage}', showType: 3);
                commonPrint('mj优化提示词失败1,原因是${progressResponse.statusMessage}');
              }
              break;
            }
          }
        } else {
          if (mounted) {
            showHint('优化提示词任务创建失败，原因是${response.data['description']}');
          }
        }
      } else {
        if (mounted) {
          showHint('优化提示词任务创建失败，原因是${response.statusMessage}');
        }
      }
    } catch (e) {
      if (mounted) {
        showHint('优化提示词任务创建失败，原因是$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
      child: Column(
        children: [
          const Center(
            child: Text(
              '优化提示词',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
              child: SingleChildScrollView(
            child: Column(children: [
              Row(children: [
                Expanded(
                    child: TextField(
                  controller: contentEditingController,
                  maxLines: 2,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(
                    color: Colors.yellowAccent,
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
                    labelText: '原提示词',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                )),
              ]),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                        onPressed: () async {
                          await _shortenPrompt();
                        },
                        child: const Text('优化提示词')),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: TextField(
                    controller: modifiedEditingController,
                    maxLines: 10,
                    minLines: 1,
                    keyboardType: TextInputType.multiline,
                    style: TextStyle(
                      color: Colors.yellowAccent,
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
                      labelText: '优化后的提示词',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ))
                ],
              ),
            ]),
          )),
          Column(
            children: [
              const Text(
                '选择的提示词序号：',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Obx(() => Row(
                    children: [
                      Expanded(
                        child: RadioListTile<int>(
                          title: const Text(
                            '1',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: 0,
                          groupValue: selectedPosition.value,
                          onChanged: (value) async {
                            selectedPosition.value = value!;
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<int>(
                          title: const Text(
                            '2',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: 1,
                          groupValue: selectedPosition.value,
                          onChanged: (value) async {
                            selectedPosition.value = value!;
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<int>(
                          title: const Text(
                            '3',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: 2,
                          groupValue: selectedPosition.value,
                          onChanged: (value) async {
                            selectedPosition.value = value!;
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<int>(
                          title: const Text(
                            '4',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: 3,
                          groupValue: selectedPosition.value,
                          onChanged: (value) async {
                            selectedPosition.value = value!;
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<int>(
                          title: const Text(
                            '5',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: 4,
                          groupValue: selectedPosition.value,
                          onChanged: (value) async {
                            selectedPosition.value = value!;
                          },
                        ),
                      ),
                    ],
                  ))
            ],
          ),
          SizedBox(
            height: 60,
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
                      if (modifiedEditingController.text.isNotEmpty) {
                        int canSelected = buttons.length - 1;
                        if (canSelected <= selectedPosition.value) {
                          if (mounted) {
                            showHint('选择的序号与可选提示词数量不符');
                          }
                        } else {
                          List<String> newPrompts = modifiedEditingController.text.split('\n');
                          String newPrompt = newPrompts[selectedPosition.value];
                          widget.onConfirm(newPrompt.substring(4, newPrompt.length));
                        }
                      } else {
                        if (mounted) {
                          showHint('请先优化提示词');
                        }
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
                    child: const Text('确认', style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
