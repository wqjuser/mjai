import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tuitu/utils/native_communication.dart';  // 导入 NativeCommunication

typedef OnFilesReceived = void Function(List<String> filePaths);

class ClipboardListenerWidget extends StatefulWidget {
  final Widget child;
  final OnFilesReceived? onFilesReceived;

  const ClipboardListenerWidget({
    Key? key,
    required this.child,
    this.onFilesReceived,
  }) : super(key: key);

  @override
  State<ClipboardListenerWidget> createState() => _ClipboardListenerWidgetState();
}

class _ClipboardListenerWidgetState extends State<ClipboardListenerWidget> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleKeyEvent(KeyEvent event) async {
    // Windows 使用 Ctrl+V, macOS 使用 Command+V
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyV &&
        ((Platform.isMacOS && HardwareKeyboard.instance.isMetaPressed) ||
         (Platform.isWindows && HardwareKeyboard.instance.isControlPressed))) {
      await _handlePaste();
    }
  }

  Future<void> _handlePaste() async {
    try {
      final filePaths = await NativeCommunication.getClipboardFiles();
      if (filePaths != null && filePaths.isNotEmpty) {
        widget.onFilesReceived?.call(filePaths);
        return;
      }
      // 如果不是文件或者没有文件，让系统处理默认的粘贴行为
    } catch (e) {
      debugPrint('Error handling paste: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        _handleKeyEvent(event);
        return KeyEventResult.ignored;  // 让其他 widget 也能处理按键事件
      },
      child: widget.child,
    );
  }
}