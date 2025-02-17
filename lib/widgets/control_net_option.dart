import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../json_models/control_net_unit.dart';
import '../net/my_api.dart';
import 'my_keep_alive_wrapper.dart';
import 'control_net_option_item.dart';

// ignore: must_be_immutable
class ControlNetOptionWidget extends StatefulWidget {
  final Function(List<Map<String, dynamic>> controlNetOptions) onConfirm;
  List<Map<String, dynamic>> controlNetOptions;
  final List<String> controlTypes;
  final List<String> controlModels;
  final List<String> controlModules;
  final bool canAddOrDelete;

  ControlNetOptionWidget(
      {super.key,
      required this.onConfirm,
      required this.controlNetOptions,
      required this.controlTypes,
      required this.controlModels,
      required this.controlModules,
      this.canAddOrDelete = true});

  @override
  State<ControlNetOptionWidget> createState() => _ControlNetOptionWidgetState();
}

class _ControlNetOptionWidgetState extends State<ControlNetOptionWidget> {
  int controlNetMaxModelsNum = 1;
  late List<Map<String, dynamic>> controlNetOptions;
  late MyApi myApi;
  late ScrollController _scrollController;
  late List<String> _controlTypes;
  late List<String> _controlModels;
  late List<String> _controlModules;

  Future<void> _initData() async {
    controlNetOptions = (widget.controlNetOptions).obs;
    _scrollController = ScrollController();
    _controlTypes = widget.controlTypes;
    _controlModels = widget.controlModels;
    _controlModules = widget.controlModules;
  }

  void _scrollToBottom({bool isReduceOne = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(milliseconds: 400), () {
        double lastItemOffset = _scrollController.position.maxScrollExtent;
        _scrollController.animateTo(
          isReduceOne
              ? lastItemOffset - 2 * (lastItemOffset - _scrollController.position.viewportDimension)
              : lastItemOffset + 20,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    });
  }

  @override
  void initState() {
    myApi = MyApi();
    _initData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 5),
        Stack(
          children: [
            const Center(
              child: Text(
                'controlnet控制单元',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            Visibility(
                visible: widget.canAddOrDelete,
                child: Positioned(
                  top: 5,
                  right: 10,
                  child: Visibility(
                    visible: controlNetOptions.isNotEmpty,
                    child: InkWell(
                      child: Tooltip(
                        message: '添加controlnet控制单元',
                        child: Container(
                          width: 20,
                          height: 20,
                          padding: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: SvgPicture.asset('assets/images/add.svg', semanticsLabel: '添加controlnet控制单元'),
                        ),
                      ),
                      onTap: () {
                        Map<String, dynamic> controlNetOption = ControlNetUnit().toJson();
                        controlNetOptions.add(controlNetOption);
                        _scrollToBottom();
                      },
                    ),
                  ),
                )),
            Visibility(
                visible: widget.canAddOrDelete,
                child: Positioned(
                  top: 5,
                  left: 10,
                  child: Visibility(
                    visible: controlNetOptions.isNotEmpty,
                    child: InkWell(
                      child: Tooltip(
                        message: '删除上一个添加的controlnet控制单元',
                        child: Container(
                          width: 20,
                          height: 20,
                          padding: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: SvgPicture.asset('assets/images/remove.svg', semanticsLabel: '删除上一个添加的controlnet控制单元'),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          controlNetOptions.removeLast();
                          if (controlNetOptions.isNotEmpty) {
                            _scrollToBottom(isReduceOne: true);
                          }
                        });
                      },
                    ),
                  ),
                )),
          ],
        ),
        const SizedBox(height: 5),
        Obx(
          () => Expanded(
            child: controlNetOptions.isEmpty
                ? Center(
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // 设置主轴居中
                    children: [
                      InkWell(
                        child: Tooltip(
                          message: '添加controlnet控制单元',
                          child: Container(
                            width: 40,
                            height: 40,
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: SvgPicture.asset('assets/images/add.svg', semanticsLabel: '添加controlnet控制单元'),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            Map<String, dynamic> controlNetOption = ControlNetUnit().toJson();
                            controlNetOptions.add(controlNetOption);
                          });
                        },
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      const Text('点击按钮添加controlnet控制单元', style: TextStyle(color: Colors.white))
                    ],
                  ))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: controlNetOptions.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> controlNetOption = controlNetOptions[index];
                      return MyKeepAliveWrapper(
                          child: ControlNetOptionItem(
                        index: index,
                        controlNetOption: controlNetOption,
                        controlModels: _controlModels,
                        controlModules: _controlModules,
                        controlTypes: _controlTypes,
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
                        widget.onConfirm(controlNetOptions);
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
              ),
            ))
      ],
    );
  }
}
