import 'dart:io';
import 'dart:ui';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/config/global_params.dart';
import 'package:tuitu/pages/first_step_view.dart';
import 'package:tuitu/pages/fourth_step_view.dart';
import 'package:tuitu/pages/second_step_view.dart';
import 'package:tuitu/pages/third_step_view.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'package:tuitu/widgets/common_dropdown.dart';

import '../config/config.dart';
import '../utils/landscape_stateful_mixin.dart';
import '../widgets/custom_dialog.dart';

class ArticleGeneratorView extends StatefulWidget {
  const ArticleGeneratorView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ArticleGeneratorViewState();
}

class _ArticleGeneratorViewState extends State<ArticleGeneratorView> with LandscapeStatefulMixin {
  int _currentIndex = 0;
  final defaultColor = GlobalParams.themeColor;
  final responseController = TextEditingController();
  final originalController = TextEditingController();
  final sceneController = TextEditingController();
  String aiResponse = '';
  String sceneResponse = '';
  String selectedAiModel = '';
  String _selectedHistoryTitle = '';
  List<String> historyTitles = ['请选择一个历史记录'];
  bool _isDirectlyInto = false;
  int _useAiMode = 0;

  Future<void> _updateCurrentIndexAndNextStep(String param) async {
    // 更新currentIndex并触发UI更新
    selectedAiModel = param;
    Map<String, dynamic> settings = await Config.loadSettings();
    String? novelFolder = settings['current_novel_folder'];
    if (novelFolder == null || novelFolder == '') {
      showHint('没有设置小说标题，无法进行下一步', showPosition: 2, showType: 3);
    } else if (responseController.text == '' && originalController.text == '') {
      showHint('没有原文或者还未对原文进行AI处理，无法进行下一步', showPosition: 2, showType: 3);
    } else {
      setState(() {
        aiResponse = responseController.text != '' ? responseController.text : originalController.text;
        _currentIndex = 1;
      });
    }
  }

  Future<void> _updateCurrentIndexAndNextStep2(String param, int useAiMode) async {
    // 更新currentIndex并触发UI更新
    Map<String, dynamic> settings = await Config.loadSettings();
    String? novelFolder = settings['current_novel_folder'];
    if (novelFolder == null || novelFolder == '') {
      showHint('没有设置小说标题，无法进行下一步', showPosition: 2, showType: 3);
    } else if (param == '') {
      showHint('没有场景信息，无法进行下一步', showPosition: 2, showType: 3);
    } else {
      setState(() {
        sceneController.text = param;
        sceneResponse = param;
        _currentIndex = 2;
        _useAiMode = useAiMode;
        _isDirectlyInto = false;
      });
    }
  }

  Future<void> _goToThird() async {
    Map<String, dynamic> settings = await Config.loadSettings();
    String historyPath = '${settings['image_save_path']}/history';
    final directory = Directory(historyPath);
    if (directory.existsSync()) {
      final folderCount = countSubFolders(historyPath);
      if (folderCount > 0) {
        try {
          historyTitles = getSubdirectories(historyPath);
          if (historyTitles.isNotEmpty) {
            if (mounted) {
              setState(() {
                _selectedHistoryTitle = historyTitles[0];
              });
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return CustomDialog(
                    title: '选择一个历史记录',
                    titleColor: Colors.white,
                    description: null,
                    maxWidth: 500,
                    confirmButtonText: '确认',
                    cancelButtonText: '取消',
                    contentBackgroundColor: Colors.black,
                    contentBackgroundOpacity: 0.5,
                    content: Padding(
                        padding: const EdgeInsets.all(10),
                        child: CommonDropdownWidget(
                            selectedValue: _selectedHistoryTitle,
                            dropdownData: historyTitles,
                            onChangeValue: (historyTitle) {
                              setState(() {
                                _selectedHistoryTitle = historyTitle;
                              });
                            })),
                    onCancel: () {},
                    onConfirm: () {
                      setState(() {
                        _isDirectlyInto = true;
                        _currentIndex = 2;
                        _useAiMode = 1;
                      });
                    },
                  );
                },
              );
            }
          } else {
            showHint('未发现存在历史记录', showType: 3);
          }
        } catch (e) {
          commonPrint('An error occurred: $e');
        }
      } else {
        showHint('未发现存在历史记录', showType: 3);
      }
    } else {
      showHint('未发现存在历史记录', showType: 3);
    }
  }

  void _preStep(int currentPage) {
    setState(() {
      _currentIndex = currentPage - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return SafeArea(
        child: Stack(children: [
      // 背景图片
      Positioned.fill(
        child: ExtendedImage.asset(
          'assets/images/drawer_top_bg.png',
          fit: BoxFit.cover,
        ),
      ),
      // 毛玻璃效果只应用于内容区域
      Positioned.fill(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
          child: Container(
            color: Colors.transparent,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
        child: Column(
          children: [
            Row(
              children: [
                // Replace ElevatedButtons with TextButtons for better color customization
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _currentIndex = 0;
                      });
                    },
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: _currentIndex >= 0 ? settings.getSelectedBgColor() : Colors.transparent,
                    ),
                    child: Text(
                      '第一步(优化及配音)',
                      style: TextStyle(color: _currentIndex >= 0 ? Colors.white : Colors.grey),
                    ),
                  ),
                ),
                // Add arrows and SizedBox for spacing
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward, color: _currentIndex >= 1 ? Colors.yellowAccent : Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      Map<String, dynamic> settings = await Config.loadSettings();
                      String? novelFolder = settings['current_novel_folder'];
                      if (novelFolder == null || novelFolder == '') {
                        showHint('没有设置小说标题，无法进行下一步', showPosition: 2, showType: 3);
                      } else if (responseController.text == '' && originalController.text == '') {
                        showHint('没有原文或者还未对原文进行AI处理，无法进行下一步', showPosition: 2, showType: 3);
                      } else {
                        setState(() {
                          aiResponse = responseController.text != '' ? responseController.text : originalController.text;
                          _currentIndex = 1;
                        });
                      }
                    },
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: _currentIndex >= 1 ? settings.getSelectedBgColor() : Colors.transparent,
                    ),
                    child: Text(
                      '第二步(分镜转换)',
                      style: TextStyle(color: _currentIndex >= 1 ? Colors.white : Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward, color: _currentIndex >= 2 ? Colors.yellowAccent : Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      if (_currentIndex < 1) {
                        showHint('请先完成此步骤之前的步骤', showPosition: 2, showType: 3);
                      } else {
                        if (sceneController.text == '') {
                          showHint('没有场景信息，无法进行下一步', showPosition: 2, showType: 3);
                        } else {
                          setState(() {
                            sceneResponse = sceneController.text;
                            _currentIndex = 2;
                          });
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: _currentIndex >= 2 ? settings.getSelectedBgColor() : Colors.transparent,
                    ),
                    child: Text(
                      '第三步(图片生成)',
                      style: TextStyle(color: _currentIndex >= 2 ? Colors.white : Colors.grey),
                    ),
                  ),
                ),
                Visibility(
                    visible: false,
                    child: Row(
                      children: [
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward, color: _currentIndex >= 3 ? Colors.yellowAccent : Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              if (_currentIndex < 2) {
                                showHint('请先完成此步骤之前的步骤', showPosition: 2, showType: 3);
                              } else {
                                setState(() {
                                  _currentIndex = 3;
                                });
                              }
                            },
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              backgroundColor: _currentIndex >= 3 ? defaultColor : Colors.transparent,
                            ),
                            child: Text(
                              '第四步',
                              style: TextStyle(color: _currentIndex >= 3 ? Colors.white : Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    )),
              ],
            ),
            // Use IndexedStack to display the selected step
            const SizedBox(
              height: 16,
            ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  FirstStepView(
                    responseController: responseController,
                    articleController: originalController,
                    goToThirdStep: _goToThird,
                    onNextStep: _updateCurrentIndexAndNextStep,
                  ),
                  // 当跳转到界面显示的时候再初始化界面内容
                  _currentIndex >= 1
                      ? SecondStepView(
                          aiArticle: aiResponse,
                          selectedAiModel: selectedAiModel,
                          onNextStep: _updateCurrentIndexAndNextStep2,
                          sceneController: sceneController,
                          onPreStep: _preStep,
                        )
                      : Container(),
                  _currentIndex >= 2
                      ? ThirdStepView(
                          scenes: sceneResponse,
                          useAiMode: _useAiMode,
                          isDirectlyInto: _isDirectlyInto,
                          novelTitle: _selectedHistoryTitle)
                      : Container(),
                  _currentIndex >= 3 ? const FourthStepView() : Container(),
                ],
              ),
            ),
          ],
        ),
      )
    ]));
  }
}
