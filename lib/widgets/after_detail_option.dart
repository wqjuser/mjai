import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/widgets/after_detail_option_item.dart';
import '../json_models/adtail_unit.dart';
import 'my_keep_alive_wrapper.dart';

// ignore: must_be_immutable
class AfterDetailOption extends StatefulWidget {
  List<Map<String, dynamic>> afterDetailOptions;
  final List<String> sdSamplers;
  final Function(List<Map<String, dynamic>> controlNetOptions) onConfirm;

  AfterDetailOption({super.key, required this.onConfirm, required this.afterDetailOptions, required this.sdSamplers});

  @override
  State<AfterDetailOption> createState() => _AfterDetailOptionState();
}

class _AfterDetailOptionState extends State<AfterDetailOption> {
  late List<Map<String, dynamic>> afterDetailOptions;
  late ScrollController _scrollController;

  void initData() async {
    _scrollController = ScrollController();
    afterDetailOptions = widget.afterDetailOptions.obs;
  }

  void _scrollToBottom({bool isReduceOne = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(milliseconds: 400), () {
        double lastItemOffset = _scrollController.position.maxScrollExtent;
        _scrollController.animateTo(
          isReduceOne ? lastItemOffset - 2 * (lastItemOffset - _scrollController.position.viewportDimension) : lastItemOffset + 20,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    });
  }

  @override
  void initState() {
    initData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return Column(
      children: [
        const SizedBox(height: 5),
        Stack(
          children: [
            Center(
              child: Text(
                'ADetail控制单元',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: settings.getForegroundColor()),
              ),
            ),
            Positioned(
              top: 5,
              right: 10,
              child: Visibility(
                visible: afterDetailOptions.isNotEmpty,
                child: InkWell(
                  child: Tooltip(
                    message: '添加ADetail控制单元',
                    child: Container(
                      width: 20,
                      height: 20,
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: settings.getSelectedBgColor(),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: SvgPicture.asset('assets/images/add.svg',
                          colorFilter: ColorFilter.mode(settings.getCardTextColor(), BlendMode.srcIn), semanticsLabel: '添加ADetail控制单元'),
                    ),
                  ),
                  onTap: () {
                    Map<String, dynamic> aDetailOption = ADetailUnit().toJson();
                    afterDetailOptions.add(aDetailOption);
                    _scrollToBottom();
                  },
                ),
              ),
            ),
            Positioned(
              top: 5,
              left: 10,
              child: Visibility(
                visible: afterDetailOptions.isNotEmpty,
                child: InkWell(
                  child: Tooltip(
                    message: '删除上一个添加的ADetail控制单元',
                    child: Container(
                      width: 20,
                      height: 20,
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: settings.getSelectedBgColor(),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: SvgPicture.asset('assets/images/remove.svg',
                          colorFilter: ColorFilter.mode(settings.getCardTextColor(), BlendMode.srcIn), semanticsLabel: '删除上一个添加的ADetail控制单元'),
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      afterDetailOptions.removeLast();
                      if (afterDetailOptions.isNotEmpty) {
                        _scrollToBottom(isReduceOne: true);
                      }
                    });
                  },
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 5),
        Obx(
          () => Expanded(
            child: afterDetailOptions.isEmpty
                ? Center(
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // 设置主轴居中
                    children: [
                      InkWell(
                        child: Tooltip(
                          message: '添加ADetail控制单元',
                          child: Container(
                            width: 40,
                            height: 40,
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: settings.getSelectedBgColor(),
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: SvgPicture.asset('assets/images/add.svg',
                                colorFilter: ColorFilter.mode(settings.getCardTextColor(), BlendMode.srcIn), semanticsLabel: '添加ADetail控制单元'),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            Map<String, dynamic> controlNetOption = ADetailUnit().toJson();
                            afterDetailOptions.add(controlNetOption);
                          });
                        },
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      const Text('点击按钮添加ADetail控制单元', style: TextStyle(color: Colors.white))
                    ],
                  ))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: afterDetailOptions.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> afterDetailOption = afterDetailOptions[index];
                      return MyKeepAliveWrapper(
                          child: AfterDetailOptionItem(
                        sdSamplers: widget.sdSamplers,
                        index: index,
                        afterDetailOption: afterDetailOption,
                      ));
                    },
                  ),
          ),
        ),
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
                        widget.onConfirm(afterDetailOptions);
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
                      child: const Text('确认', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ))
      ],
    );
  }
}
