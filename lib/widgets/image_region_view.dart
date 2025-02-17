import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../utils/common_methods.dart';

class ImageRegion extends StatefulWidget {
  final String base64Image;
  final String imageContent;
  final Function(String maskImage, String regionContent) onConfirm;

  const ImageRegion({super.key, required this.base64Image, required this.imageContent, required this.onConfirm});

  @override
  State<ImageRegion> createState() => _ImageRegionState();
}

class _ImageRegionState extends State<ImageRegion> {
  final GlobalKey _maskKey = GlobalKey();
  bool isEditing = true;
  Offset dragStart = const Offset(0, 0);
  Offset dragEnd = const Offset(0, 0);
  Rect? selectionRect;
  Path? selectionPath;
  late String base64Image;
  var mosaicRects = [].obs;
  var mosaicPaths = [].obs;
  ui.Image? image;
  int currentIndex = 0;
  int currentRectIndex = 0;
  int currentPathIndex = 0;
  Rect? currentSelectionRect; // 用于保存实时预览的矩形
  late Function(String maskImage, String regionContent) onConfirm;
  int currentType = 0;
  Path? currentPath;
  final TextEditingController regionController = TextEditingController();

  Future<ui.Image> convertBase64ToImage(String base64String) async {
    // 解码Base64字符串为字节数组
    Uint8List bytes = Uint8List.fromList(base64.decode(base64String));
    // 使用decodeImageFromList将字节数组转换为ui.Image
    ui.Codec codec = await ui.instantiateImageCodec(bytes);
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  Future<String> saveSelectionAsImage() async {
    if (image != null) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final scale = 560 / image!.width;
      final scale1 = 560 / image!.height;
      final finalScale = math.min(scale1, scale);
      //由于绘制图片的时候存在画布的偏移量，这里需要将绘制的偏移量减去
      final double offsetX = (560 - (image!.width * finalScale)) / 2;
      final double offsetY = (540 - (image!.height * finalScale)) / 2 + 20 * finalScale;

      // 计算黑色背景的尺寸与图像尺寸相匹配
      final double bgWidth = image!.width.toDouble();
      final double bgHeight = image!.height.toDouble();
      // 绘制黑色背景
      canvas.drawRect(
        Rect.fromPoints(const Offset(0, 0), Offset(bgWidth, bgHeight)),
        Paint()..color = Colors.black,
      );

      // 绘制白色选中区域
      for (int i = 0; i < mosaicRects.length; i++) {
        final rect = mosaicRects[i];
        // 减去绘制的时候偏移量
        final adjustedRect = Rect.fromLTRB(
          (rect.left - offsetX) / finalScale,
          (rect.top - offsetY) / finalScale,
          (rect.right - offsetX) / finalScale,
          (rect.bottom - offsetY) / finalScale,
        );
        canvas.drawRect(adjustedRect, Paint()..color = Colors.white);
        // drawMosaicRect(canvas, rect, finalScale, color: Colors.white);
      }
      for (int i = 0; i < mosaicPaths.length; i++) {
        final path = mosaicPaths[i];
        // 应用偏移量,并转换为原始图片的尺寸
        final adjustedPath = path
            .shift(Offset(-offsetX, -offsetY))
            .transform(Matrix4.diagonal3Values(1 / finalScale, 1 / finalScale, 1.0).storage);
        canvas.drawPath(adjustedPath, Paint()..color = Colors.white);
        // drawMosaicPath(canvas, path, finalScale, color: Colors.white);
      }
      final picture = recorder.endRecording();
      final img = await picture.toImage(bgWidth.toInt(), bgHeight.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();
      final base64String = base64Encode(buffer);
      return base64String;
    } else {
      return '';
    }
  }

  bool isInsideImageArea(Offset point) {
    final scale = 560 / image!.width;
    final scale1 = 560 / image!.height;
    final finalScale = math.min(scale1, scale);
    final double offsetX = (560 - (image!.width * finalScale)) / 2;
    final double offsetY = (540 - (image!.height * finalScale)) / 2 + 20 * finalScale;
    final Rect imageRect = Rect.fromPoints(
      Offset(offsetX, offsetY),
      Offset(offsetX + image!.width * finalScale, offsetY + image!.height * finalScale),
    );
    return imageRect.contains(point);
  }

  Future<void> urlToBase64()async{
    String base64Url = await imageUrlToBase64(base64Image);
    // 将Base64图像转换为ui.Image
    convertBase64ToImage(base64Url).then((img) {
      setState(() {
        image = img;
      });
    });
  }

  @override
  void initState() {
    base64Image = widget.base64Image;
    onConfirm = widget.onConfirm;
    regionController.text = widget.imageContent;
    super.initState();
    urlToBase64();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 560,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: image != null
                  ? Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: ImagePainter(image!, 560, 560),
                          ),
                        ),
                        Positioned.fill(
                          child: GestureDetector(
                              onPanStart: (details) {
                                setState(() {
                                  dragStart = details.localPosition;
                                  dragEnd = details.localPosition;
                                  // 初始化路径
                                  currentPath = Path()..moveTo(dragStart.dx, dragStart.dy);
                                });
                              },
                              onPanUpdate: (details) {
                                setState(() {
                                  dragEnd = details.localPosition;
                                  // 确保马赛克只能在画布内部绘制
                                  double x = math.max(0, math.min(dragEnd.dx, 560)); // 560 是画布宽度
                                  double y = math.max(0, math.min(dragEnd.dy, 560)); // 560 是画布高度
                                  dragEnd = Offset(x, y);
                                  if (isInsideImageArea(details.localPosition)) {
                                    if (currentType == 0) {
                                      if (details.localPosition != dragStart) {
                                        selectionRect = Rect.fromPoints(dragStart, dragEnd);
                                      }
                                    } else {
                                      if (details.localPosition != dragStart) {
                                        currentPath?.lineTo(dragEnd.dx, dragEnd.dy);
                                        selectionPath = currentPath;
                                      }
                                    }
                                  }
                                });
                              },
                              onPanEnd: (details) {
                                setState(() {
                                  if (currentType == 0) {
                                    if (selectionRect != null) {
                                      mosaicRects.add(selectionRect!);
                                      currentRectIndex++;
                                    }
                                  } else {
                                    // 创建并添加路径到mosaicPaths列表
                                    if (currentPath != null) {
                                      mosaicPaths.add(currentPath!);
                                      currentPathIndex++;
                                    }
                                  }
                                  selectionRect = null;
                                  currentPath = null; // 清空当前路径
                                });
                              },
                              child: Obx(
                                () => CustomPaint(
                                  key: _maskKey,
                                  painter: SelectionPainter(
                                      image!,
                                      List<Rect>.from(mosaicRects.toList()),
                                      560,
                                      560,
                                      // _maskKey,
                                      selectionRect,
                                      currentRectIndex,
                                      currentPathIndex,
                                      List<Path>.from(mosaicPaths.toList()),
                                      currentType,
                                      selectionPath),
                                ),
                              )),
                        )
                      ],
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          SizedBox(
              height: 50,
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          if (currentType != 0) {
                            setState(() {
                              currentType = 0;
                            });
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.all<Color>(currentType != 0 ? Colors.grey : Colors.blue),
                          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                        child: const Text('矩形选择框', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          if (currentType != 1) {
                            setState(() {
                              currentType = 1;
                            });
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.all<Color>(currentType != 1 ? Colors.grey : Colors.blue),
                          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                        child: const Text('套索选择框', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          if (currentType == 0) {
                            if (mosaicRects.isNotEmpty) {
                              mosaicRects.removeLast();
                              selectionRect = null;
                              currentRectIndex--;
                            } else {
                              if (mosaicPaths.isNotEmpty) {
                                mosaicPaths.removeLast();
                                selectionPath = null;
                                currentPathIndex--;
                              }
                            }
                            // setState(() {});
                          } else if (currentType == 1) {
                            if (mosaicPaths.isNotEmpty) {
                              mosaicPaths.removeLast();
                              selectionPath = null;
                              currentPathIndex--;
                            } else {
                              if (mosaicRects.isNotEmpty) {
                                mosaicRects.removeLast();
                                selectionRect = null;
                                currentRectIndex--;
                              }
                            }
                            // setState(() {});
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
                          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                        child: const Text('撤销上一步', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              )),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                      controller: regionController,
                      maxLines: 3,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(color: Colors.yellowAccent),
                      decoration: const InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white, width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white, width: 1.0),
                          ),
                          labelText: '重绘内容',
                          labelStyle: TextStyle(color: Colors.white))),
                ),
              ),
            ],
          ),
          SizedBox(
              height: 50,
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
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
                        onPressed: () async {
                          if (mosaicRects.isEmpty && mosaicPaths.isEmpty) {
                            if (mounted) {
                              showHint('请先绘制重绘区域');
                            }
                          } else {
                            String base64Image = await saveSelectionAsImage();
                            widget.onConfirm(base64Image, regionController.text);
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
      ),
    );
  }
}

class SelectionPainter extends CustomPainter {
  final List<Rect> mosaicRects; // 用于存储矩形位置
  final double height;
  final double width;
  final ui.Image image;
  // final GlobalKey _maskKey;
  final double mosaicBlockSize = 10.0;
  final Rect? rect;
  final int currentRectIndex;
  final int currentPathIndex;
  final List<Path> mosaicPaths; // 用于存储路径
  final int type;
  final Path? path;

  SelectionPainter(this.image, this.mosaicRects, this.width, this.height, this.rect,
      this.currentRectIndex, this.currentPathIndex, this.mosaicPaths, this.type, this.path);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = width / image.width;
    final scale1 = height / image.height;
    final finalScale = math.min(scale1, scale);
    for (int i = 0; i < mosaicRects.length; i++) {
      final rect = mosaicRects[i];
      drawMosaicRect(canvas, rect, finalScale);
    }
    for (int i = 0; i < mosaicPaths.length; i++) {
      final path = mosaicPaths[i];

      drawMosaicPath(canvas, path, finalScale);
    }
    // 绘制实时预览的选择区域（如果存在的话）
    if (rect != null && !mosaicRects.contains(rect)) {
      drawMosaicRect(canvas, rect!, finalScale);
    }
    if (path != null && !mosaicPaths.contains(path)) {
      drawMosaicPath(canvas, path!, finalScale);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class ImagePainter extends CustomPainter {
  final double height;
  final double width;
  final ui.Image image;

  ImagePainter(this.image, this.width, this.height);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = width / image.width;
    final scale1 = height / image.height;
    final finalScale = math.min(scale1, scale);
    // 计算图片在画布中的位置，使其居中显示
    final double offsetX = (560 - (image.width * finalScale)) / 2;
    final double offsetY = (540 - (image.height * finalScale)) / 2;
    canvas.save();
    canvas.translate(offsetX, offsetY + 20 * finalScale); // 将画布平移到居中位置
    canvas.scale(finalScale);
    // 绘制原图
    canvas.drawImage(image, Offset.zero, Paint());
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
