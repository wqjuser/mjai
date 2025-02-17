import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../utils/common_methods.dart';

// ignore: must_be_immutable
class SwapFaceView extends StatefulWidget {
  String swapFaceImage;
  final Function()? onCancel;
  final Function(String swapFaceImage) onConfirm;

  SwapFaceView({super.key, required this.swapFaceImage, required this.onCancel, required this.onConfirm});

  @override
  State<SwapFaceView> createState() => _SwapFaceViewState();
}

class _SwapFaceViewState extends State<SwapFaceView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(10.0),
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: Colors.white,
              width: 1.0,
            ),
          ),
          child: widget.swapFaceImage == ''
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
                        widget.swapFaceImage = compress;
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
                          image: MemoryImage(base64Decode(widget.swapFaceImage)),
                          fit: BoxFit.contain,
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
                                widget.swapFaceImage = compress;
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
                              widget.swapFaceImage = '';
                            });
                          },
                        ),
                      ])),
                    )
                  ],
                ),
        ),
        const SizedBox(
          height: 16,
        ),
        Padding(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              Expanded(
                  child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(Colors.blue),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                child: const Text('取消', style: TextStyle(color: Colors.white)),
              )),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                  child: TextButton(
                onPressed: () {
                  widget.onConfirm(widget.swapFaceImage);
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
              ))
            ]))
      ],
    );
  }
}
