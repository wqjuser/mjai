import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../utils/common_methods.dart';

class BlendImageOptionItem extends StatefulWidget {
  final Map<String, dynamic> base64Image;
  final int index;

  const BlendImageOptionItem({super.key, required this.base64Image, required this.index});

  @override
  State<BlendImageOptionItem> createState() => _BlendImageOptionItemState();
}

class _BlendImageOptionItemState extends State<BlendImageOptionItem> {
  late Map<String, dynamic> base64Image;
  late int index;

  @override
  void initState() {
    base64Image = widget.base64Image;
    index = widget.index;
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
            Text('图片${index + 1}', style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold)),
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
              child: widget.base64Image['input_image'] == ''
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
                          setState(() {
                            base64Image['input_image'] = base64Path;
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
                              image: MemoryImage(base64Decode(widget.base64Image['input_image'])),
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
                                  setState(() {
                                    base64Image['input_image'] = base64Path;
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
                                  base64Image['input_image'] = '';
                                });
                              },
                            ),
                          ])),
                        )
                      ],
                    ),
            ),
          ],
        ));
  }
}
