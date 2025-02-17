import 'dart:async';

// import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'package:tuitu/widgets/blend_image_option_item.dart';
import 'package:tuitu/widgets/common_dropdown.dart';

import 'my_keep_alive_wrapper.dart';

// ignore: must_be_immutable
class BlendImageOption extends StatefulWidget {
  final Function(List<Map<String, dynamic>> options) onConfirm;
  List<Map<String, dynamic>> base64Images;
  bool canAddOrDelete;
  int drawEngine;

  BlendImageOption(
      {super.key,
      required this.onConfirm,
      required this.base64Images,
      this.canAddOrDelete = true,
      this.drawEngine = 2});

  @override
  State<BlendImageOption> createState() => _BlendImageOptionState();
}

class _BlendImageOptionState extends State<BlendImageOption> {
  late List<Map<String, dynamic>> base64Images;
  late ScrollController _scrollController;
  List<String> imageProportion = ['方形纵横比(1:1)', '纵向纵横比(2:3)', '横向纵横比(3:2)'];
  String selectedImageProportion = '方形纵横比(1:1)';
  int drawEngine = 2;
  final TextEditingController imageUrl1TextController = TextEditingController();
  final TextEditingController imageUrl2TextController = TextEditingController();
  final TextEditingController imageUrl3TextController = TextEditingController();
  final TextEditingController imageUrl4TextController = TextEditingController();
  final TextEditingController imageUrl5TextController = TextEditingController();

  @override
  void initState() {
    base64Images = (widget.base64Images).obs;
    _scrollController = ScrollController();
    drawEngine = widget.drawEngine;
    super.initState();
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 5),
        Stack(
          children: [
            const Center(
              child: Text(
                'MJ融图',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            Visibility(
                visible: widget.canAddOrDelete,
                child: Positioned(
                  top: 5,
                  left: 10,
                  child: Obx(() => Visibility(
                        visible: base64Images.length > 2,
                        child: InkWell(
                          child: Tooltip(
                            message: '删除上一个添加的图片',
                            child: Container(
                              width: 20,
                              height: 20,
                              padding: const EdgeInsets.all(4.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: SvgPicture.asset('assets/images/remove.svg', semanticsLabel: '删除上一个添加的图片'),
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              base64Images.removeLast();
                              if (base64Images.isNotEmpty) {
                                _scrollToBottom(isReduceOne: true);
                              }
                            });
                          },
                        ),
                      )),
                )),
            Visibility(
                visible: widget.canAddOrDelete,
                child: Positioned(
                  top: 5,
                  right: 10,
                  child: Obx(
                    () => Visibility(
                      visible: base64Images.length < 5,
                      child: InkWell(
                        child: Tooltip(
                          message: '添加图片',
                          child: Container(
                            width: 20,
                            height: 20,
                            padding: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: SvgPicture.asset('assets/images/add.svg', semanticsLabel: '添加图片'),
                          ),
                        ),
                        onTap: () {
                          Map<String, dynamic> emptyBase64Image = {'input_image': ''};
                          base64Images.add(emptyBase64Image);
                          _scrollToBottom();
                        },
                      ),
                    ),
                  ),
                )),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          '为保证融图效果,请上传与生成比例一致的图片',
          style: TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 5),
        drawEngine == 2
            ? Obx(
                () => Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: base64Images.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> base64Image = base64Images[index];
                      return MyKeepAliveWrapper(child: BlendImageOptionItem(base64Image: base64Image, index: index));
                    },
                  ),
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: TextField(
                        style: const TextStyle(color: Colors.yellowAccent),
                        controller: imageUrl1TextController,
                        decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 2.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 2.0),
                            ),
                            labelText: '图片1在线地址，不能为空',
                            labelStyle: TextStyle(color: Colors.white))),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                    child: TextField(
                        style: const TextStyle(color: Colors.yellowAccent),
                        controller: imageUrl2TextController,
                        decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 2.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 2.0),
                            ),
                            labelText: '图片2在线地址，不能为空',
                            labelStyle: TextStyle(color: Colors.white))),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                    child: TextField(
                        style: const TextStyle(color: Colors.yellowAccent),
                        controller: imageUrl3TextController,
                        decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 2.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 2.0),
                            ),
                            labelText: '图片3在线地址，可为空',
                            labelStyle: TextStyle(color: Colors.white))),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                    child: TextField(
                        style: const TextStyle(color: Colors.yellowAccent),
                        controller: imageUrl4TextController,
                        decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 2.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 2.0),
                            ),
                            labelText: '图片4在线地址，可为空',
                            labelStyle: TextStyle(color: Colors.white))),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                    child: TextField(
                        style: const TextStyle(color: Colors.yellowAccent),
                        controller: imageUrl5TextController,
                        decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 2.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 2.0),
                            ),
                            labelText: '图片5在线地址，可为空',
                            labelStyle: TextStyle(color: Colors.white))),
                  ),
                ],
              ),
        const SizedBox(
          height: 5,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Row(
            children: [
              const Text('生成图片纵横比:', style: TextStyle(color: Colors.white)),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: CommonDropdownWidget(
                    dropdownData: imageProportion,
                    selectedValue: selectedImageProportion,
                    onChangeValue: (value) {
                      selectedImageProportion = value;
                    }),
              )
            ],
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
                        Map<String, dynamic> imageProportionMap = {'imageProportion': selectedImageProportion};
                        if (drawEngine == 1) {
                          base64Images.clear();
                          base64Images.add({'input_image': imageUrl1TextController.text});
                          base64Images.add({'input_image': imageUrl2TextController.text});
                          if (imageUrl3TextController.text != '') {
                            base64Images.add({'input_image': imageUrl3TextController.text});
                          }
                          if (imageUrl4TextController.text != '') {
                            base64Images.add({'input_image': imageUrl4TextController.text});
                          }
                          if (imageUrl5TextController.text != '') {
                            base64Images.add({'input_image': imageUrl5TextController.text});
                          }
                        }
                        List<Map<String, dynamic>> finalData = List<Map<String, dynamic>>.from(base64Images);
                        finalData.add(imageProportionMap);

                        int images = 0;
                        for (int i = 0; i < base64Images.length; i++) {
                          if (base64Images[i]['input_image'] != '') {
                            images++;
                          }
                        }
                        if (images < 2) {
                          if (mounted) {
                            showHint('请至少上传两张图片');
                          }
                        } else {
                          widget.onConfirm(finalData);
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
                  ),
                ],
              ),
            ))
      ],
    );
  }
}
