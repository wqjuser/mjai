
import 'package:flutter/material.dart';

class SelectionPainter extends CustomPainter {
  final Offset? startPosition;
  final Offset? currentPosition;

  SelectionPainter({
    this.startPosition,
    this.currentPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (startPosition == null || currentPosition == null) return;

    final rect = Rect.fromPoints(startPosition!, currentPosition!);

    // 绘制选区
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, paint);

    // 绘制半透明遮罩
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(rect);

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black54
    );
  }

  @override
  bool shouldRepaint(SelectionPainter oldDelegate) {
    return oldDelegate.startPosition != startPosition ||
        oldDelegate.currentPosition != currentPosition;
  }
}