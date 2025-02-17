import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';


class ImageCropper extends StatefulWidget {
  final String imageBase64;
  final Function(String mask) onConfirm;

  const ImageCropper({Key? key, required this.imageBase64, required this.onConfirm}) : super(key: key);

  @override
  State createState() => _ImageCropperState();
}

class _ImageCropperState extends State<ImageCropper> {
  ui.Image? image;
  late ui.PictureRecorder recorder;
  late Canvas canvas;

  // 裁剪形状
  CropShape cropShape = CropShape.lasso;

  // 裁剪路径点
  List<Offset> cropPoints = [];

  @override
  void initState() {
    super.initState();
    // 加载base64图片
    _loadImageFromBase64(widget.imageBase64);
  }

  // 从base64加载图片
  void _loadImageFromBase64(String base64) async {
    var imageBytes = const Base64Decoder().convert(base64);
    image = await decodeImageFromList(imageBytes);
    recorder = ui.PictureRecorder();
    canvas = Canvas(recorder);
    // 图片加载完成后的回调
    setState(() {});
  }

  // 保存裁剪图片
  Future<String> save() async {
    // 将canvas转换为Picture
    final picture = recorder.endRecording();
    // 编码为base64
    final finalImage = await picture.toImage(image!.width, image!.height);
    final pngBytes = await finalImage.toByteData(format: ui.ImageByteFormat.png);
    final base64 = base64Encode(pngBytes!.buffer.asUint8List());
    return base64;
    // // 返回base64图片
    // if(mounted){
    //   Navigator.of(context).pop(base64);
    // }
  }

  // 撤销上一步操作
  void undo() {
    if (cropPoints.isNotEmpty) {
      setState(() {
        cropPoints.removeLast();
      });
    }
  }

  // 取消裁剪
  void cancel() {
    // 清空裁剪
    cropPoints.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: image != null
                ? LayoutBuilder(builder: (context, constraints) {
                    final ratio = image!.width / image!.height;
                    final width = constraints.maxWidth;
                    final height = width / ratio;
                    return GestureDetector(
                      onPanUpdate: (details) {
                        // 记录裁剪路径点
                        setState(() {
                          cropPoints.add(details.localPosition);
                        });
                      },
                      onPanEnd: (details) {
                        // 重置路径
                        cropPoints.clear();
                      },
                      child: CustomPaint(
                        painter: _ImageCropperPainter(image!, cropPoints, cropShape, width, height),
                        child: SizedBox(
                          width: width,
                          height: height,
                        ),
                      ),
                    );
                  })
                : const Center(child: CircularProgressIndicator()),
          ),
        ),
        // 按钮区域
        Row(
          children: [
            ElevatedButton(
              onPressed: save,
              child: const Text('Save'),
            ),
            ElevatedButton(
              onPressed: undo,
              child: const Text('Undo'),
            ),
            ElevatedButton(
              onPressed: cancel,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }
}

// 自定义Painter
class _ImageCropperPainter extends CustomPainter {
  final ui.Image image;
  final List<Offset> cropPoints;
  final CropShape cropShape;
  final double height;
  final double width;

  _ImageCropperPainter(this.image, this.cropPoints, this.cropShape, this.width, this.height);

  // 计算矩形
  Rect calcRect(List<Offset> points) {
    return Rect.fromLTRB(0, 0, width, height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制缩放后的图片
    final scale = width / image.width;
    canvas.scale(scale);
    // 绘制原图
    canvas.drawImage(image, Offset.zero, Paint());

    canvas.saveLayer(null, Paint());
    // 根据裁剪形状绘制裁剪路径
    Path clipPath;
    switch (cropShape) {
      case CropShape.lasso:
        clipPath = Path()..addPolygon(cropPoints, true);
        break;
      case CropShape.oval:
        clipPath = Path()..addOval(calcRect(cropPoints));
        break;
      case CropShape.rect:
        clipPath = Path()..addRect(calcRect(cropPoints));
        break;
    }

    // 填充裁剪路径为半透明黑色
    canvas.drawPath(
      clipPath,
      Paint()
        ..blendMode = BlendMode.dstOut
        ..style = PaintingStyle.fill
        ..color = Colors.red.withAlpha(128),
    );

    // 外侧绘制半透明矩形马赛克
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        const Radius.circular(10),
      ),
      Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.black.withAlpha(128),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// 裁剪形状
enum CropShape { lasso, oval, rect }
