import 'package:flutter/material.dart';
import 'dart:math' show pi;

class NotchedRectanglePainter extends CustomPainter {
  final Color strokeColor;    // 线条颜色
  final double strokeWidth;   // 线条粗细
  final double circleDiameter; // 圆形缺口的直径
  final double topLeftRadius;    // 左上角圆角
  final double topRightRadius;   // 右上角圆角
  final double bottomLeftRadius; // 左下角圆角
  final double bottomRightRadius; // 右下角圆角
  final Color backgroundColor; // 背景颜色

  NotchedRectanglePainter({
    this.strokeColor = Colors.black,
    this.strokeWidth = 2.0,
    this.circleDiameter = 60.0,
    this.topLeftRadius = 0.0,
    this.topRightRadius = 0.0,
    this.bottomLeftRadius = 0.0,
    this.bottomRightRadius = 0.0,
    this.backgroundColor = Colors.transparent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = circleDiameter / 2;

    // 创建背景路径（带圆角的矩形）
    final backgroundPath = Path();

    // 起点从左上角开始
    backgroundPath.moveTo(0, topLeftRadius);

    // 左上角圆角
    backgroundPath.quadraticBezierTo(0, 0, topLeftRadius, 0);

    // 上边线
    backgroundPath.lineTo(size.width - topRightRadius, 0);

    // 右上角圆角
    backgroundPath.quadraticBezierTo(size.width, 0, size.width, topRightRadius);

    // 右边线
    backgroundPath.lineTo(size.width, size.height - bottomRightRadius);

    // 右下角圆角
    backgroundPath.quadraticBezierTo(
        size.width,
        size.height,
        size.width - bottomRightRadius,
        size.height
    );

    // 底边线
    backgroundPath.lineTo(bottomLeftRadius, size.height);

    // 左下角圆角
    backgroundPath.quadraticBezierTo(0, size.height, 0, size.height - bottomLeftRadius);

    // 左边线回到起点
    backgroundPath.lineTo(0, topLeftRadius);

    backgroundPath.close();

    // 创建半圆缺口路径
    final notchPath = Path()
      ..addArc(
        Rect.fromCenter(
          center: Offset(size.width / 2, 0),
          width: circleDiameter,
          height: circleDiameter,
        ),
        0,
        pi,
      );

    // 使用 Path.combine 从背景中减去缺口
    final finalBackgroundPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      notchPath,
    );

    // 绘制背景
    if (backgroundColor != Colors.transparent) {
      final Paint backgroundPaint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(finalBackgroundPath, backgroundPaint);
    }

    // 绘制边框路径
    final borderPath = Path();

    // 左上部分到缺口
    borderPath.moveTo(0, topLeftRadius);
    borderPath.quadraticBezierTo(0, 0, topLeftRadius, 0);
    borderPath.lineTo(size.width / 2 - radius, 0);

    // 绘制半圆缺口
    borderPath.arcTo(
        Rect.fromCenter(
          center: Offset(size.width / 2, 0),
          width: circleDiameter,
          height: circleDiameter,
        ),
        0,
        pi,
        false
    );

    // 从缺口到右上角
    borderPath.moveTo(size.width / 2 + radius, 0);
    borderPath.lineTo(size.width - topRightRadius, 0);
    borderPath.quadraticBezierTo(size.width, 0, size.width, topRightRadius);

    // 右边线
    borderPath.lineTo(size.width, size.height - bottomRightRadius);

    // 右下角
    borderPath.quadraticBezierTo(
        size.width,
        size.height,
        size.width - bottomRightRadius,
        size.height
    );

    // 底边线
    borderPath.lineTo(bottomLeftRadius, size.height);

    // 左下角
    borderPath.quadraticBezierTo(0, size.height, 0, size.height - bottomLeftRadius);

    // 左边线
    borderPath.lineTo(0, topLeftRadius);

    // 绘制边框
    final Paint borderPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is NotchedRectanglePainter) {
      return oldDelegate.strokeColor != strokeColor ||
          oldDelegate.strokeWidth != strokeWidth ||
          oldDelegate.circleDiameter != circleDiameter ||
          oldDelegate.topLeftRadius != topLeftRadius ||
          oldDelegate.topRightRadius != topRightRadius ||
          oldDelegate.bottomLeftRadius != bottomLeftRadius ||
          oldDelegate.bottomRightRadius != bottomRightRadius ||
          oldDelegate.backgroundColor != backgroundColor;
    }
    return true;
  }
}

// 使用示例
class NotchedRectangle extends StatelessWidget {
  final Color strokeColor;
  final double strokeWidth;
  final double width;
  final double height;
  final double circleDiameter;
  final double topLeftRadius;
  final double topRightRadius;
  final double bottomLeftRadius;
  final double bottomRightRadius;
  final Color backgroundColor;

  const NotchedRectangle({
    Key? key,
    this.strokeColor = Colors.black,
    this.strokeWidth = 2.0,
    this.width = 300,
    this.height = 400,
    this.circleDiameter = 60.0,
    this.topLeftRadius = 0.0,
    this.topRightRadius = 0.0,
    this.bottomLeftRadius = 0.0,
    this.bottomRightRadius = 0.0,
    this.backgroundColor = Colors.transparent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: NotchedRectanglePainter(
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
        circleDiameter: circleDiameter,
        topLeftRadius: topLeftRadius,
        topRightRadius: topRightRadius,
        bottomLeftRadius: bottomLeftRadius,
        bottomRightRadius: bottomRightRadius,
        backgroundColor: backgroundColor,
      ),
      size: Size(width, height),
    );
  }
}

// 在页面中使用的示例
class MyPage extends StatelessWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: NotchedRectangle(
          strokeColor: Colors.blue,    // 设置蓝色线条
          strokeWidth: 3.0,           // 设置线条粗细为3.0
          width: 300,                 // 设置宽度
          height: 400,                // 设置高度
          circleDiameter: 80.0,       // 设置圆形缺口直径
          topLeftRadius: 20.0,        // 左上角圆角
          topRightRadius: 20.0,       // 右上角圆角
          bottomLeftRadius: 20.0,     // 左下角圆角
          bottomRightRadius: 20.0,    // 右下角圆角
          backgroundColor: Colors.lightBlue, // 设置浅蓝色背景
        ),
      ),
    );
  }
}