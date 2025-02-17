import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class ImprovedTextField extends StatefulWidget {
  final TextEditingController? controller;
  final int? maxLines;
  final int? minLines;
  final TextStyle? style;
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;

  const ImprovedTextField({
    Key? key,
    this.controller,
    this.maxLines,
    this.minLines,
    this.style,
    this.decoration,
    this.onChanged,
    this.focusNode,
    this.inputFormatters,
  }) : super(key: key);

  @override
  State<ImprovedTextField> createState() => _ImprovedTextFieldState();
}

class _ImprovedTextFieldState extends State<ImprovedTextField> {
  final _methodChannel = const MethodChannel('ime_fix');
  final _fieldKey = GlobalKey();
  late FocusNode _focusNode;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = widget.controller ?? TextEditingController();

    if (Platform.isWindows) {
      _focusNode.addListener(_onFocusChange);
      _controller.addListener(_onTextChange);
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      _focusNode.removeListener(_onFocusChange);
      _controller.removeListener(_onTextChange);
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _updateImePosition();
    }
  }

  void _onTextChange() {
    if (_focusNode.hasFocus) {
      _updateImePosition();
    }
  }

  Future<void> _updateImePosition() async {
    if (!mounted) return;

    // 获取文本框的RenderBox
    final RenderBox? renderBox = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    // 获取文本框在屏幕上的位置
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    // 计算当前光标位置
    final TextPosition position = _controller.selection.baseOffset < 0
        ? const TextPosition(offset: 0)
        : TextPosition(offset: _controller.selection.baseOffset);

    // 创建TextPainter来计算光标位置
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: _controller.text.substring(0, position.offset),
        style: widget.style ?? Theme.of(context).textTheme.bodyMedium,
      ),
      textDirection: TextDirection.ltr,
      maxLines: widget.maxLines,
    );

    // 计算宽度约束
    final double maxWidth = renderBox.size.width;
    textPainter.layout(maxWidth: maxWidth);

    // 获取光标位置
    final Offset caretOffset = textPainter.getOffsetForCaret(position, Rect.zero);

    try {
      await _methodChannel.invokeMethod('updateImePosition', {
        'x': offset.dx,
        'y': offset.dy + caretOffset.dy,
        'width': renderBox.size.width,
        'height': textPainter.preferredLineHeight,
      });
    } catch (e) {
      debugPrint('Error updating IME position: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: _fieldKey,
      controller: _controller,
      focusNode: _focusNode,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      style: widget.style,
      decoration: widget.decoration,
      inputFormatters: widget.inputFormatters,
      onChanged: (value) {
        widget.onChanged?.call(value);
        if (Platform.isWindows) {
          _updateImePosition();
        }
      },
      onTap: () {
        if (Platform.isWindows) {
          _updateImePosition();
        }
      },
      textDirection: TextDirection.ltr,
    );
  }
}