import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tuitu/json_models/display.dart';
import 'package:tuitu/widgets/selection_painter.dart';

class ScreenshotOverlay extends StatefulWidget {
  final Display display;
  final Function(Rect) onSelected;
  final VoidCallback onCancel;

  const ScreenshotOverlay({
    Key? key,
    required this.display,
    required this.onSelected,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<ScreenshotOverlay> createState() => _ScreenshotOverlayState();
}

class _ScreenshotOverlayState extends State<ScreenshotOverlay> {
  Offset? _startPosition;
  Offset? _currentPosition;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.display.x,
      top: widget.display.y,
      width: widget.display.width,
      height: widget.display.height,
      child: GestureDetector(
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        child: Stack(
          children: [
            Container(
              color: Colors.black54,
              child: CustomPaint(
                painter: SelectionPainter(
                  startPosition: _startPosition,
                  currentPosition: _currentPosition,
                ),
              ),
            ),
            if (_startPosition != null && _currentPosition != null)
              _buildSelectionInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionInfo() {
    final rect = _getSelectionRect();
    final width = rect.width.round();
    final height = rect.height.round();

    return Positioned(
      left: rect.left,
      top: rect.top - 25,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '$width × $height',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  void _handlePanStart(DragStartDetails details) {
    setState(() {
      _startPosition = details.localPosition;
      _currentPosition = details.localPosition;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentPosition = details.localPosition;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_startPosition != null && _currentPosition != null) {
      widget.onSelected(_getSelectionRect());
    }
  }

  Rect _getSelectionRect() {
    if (_startPosition == null || _currentPosition == null) {
      return Rect.zero;
    }

    return Rect.fromPoints(_startPosition!, _currentPosition!);
  }

  @override
  void initState() {
    super.initState();
    // 监听ESC键取消截图
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        widget.onCancel();
      }
    }
    return true;
  }
}